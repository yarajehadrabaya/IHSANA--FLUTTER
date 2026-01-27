import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';
import '../orientation/orientation_screen.dart';

class DelayedRecallScreen extends StatefulWidget {
  const DelayedRecallScreen({super.key});

  @override
  State<DelayedRecallScreen> createState() => _DelayedRecallScreenState();
}

class _DelayedRecallScreenState extends State<DelayedRecallScreen> {
  final AudioPlayer _instructionPlayer = AudioPlayer();
  FlutterSoundRecorder? _recorder;
  final MocaApiService _apiService = MocaApiService();

  bool _isPlaying = false;
  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _isLoading = false;
  bool _hwRecording = false;

  String? _audioPath;

  @override
  void initState() {
    super.initState();

    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }

    _playInstruction();
  }

  @override
  void dispose() {
    _instructionPlayer.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }

  // 🔊 تشغيل التعليمات
  Future<void> _playInstruction() async {
    try {
      setState(() => _isPlaying = true);
      await _instructionPlayer.play(
        AssetSource('audio/memory.mp3'),
      );
      _instructionPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    } catch (e) {
      debugPrint('❌ Instruction audio error: $e');
      setState(() => _isPlaying = false);
    }
  }

  // 🎤 زر التسجيل
  Future<void> _onRecordPressed() async {
    if (SessionContext.testMode == TestMode.hardware) {
      await _toggleHardwareRecording();
    } else {
      await _recordFromMobile();
    }
  }

  // ================= 📱 MOBILE =================
  Future<void> _recordFromMobile() async {
    if (_isRecording) {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _hasRecorded = true;
        _audioPath = path;
      });
      debugPrint('✅ MEMORY MOBILE STOP: $path');
    } else {
      await _instructionPlayer.stop();
      final dir = await getTemporaryDirectory();

      await _recorder!.startRecorder(
        toFile: '${dir.path}/memory_mobile.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );

      setState(() {
        _isRecording = true;
        _hasRecorded = false;
        _audioPath = null;
      });

      debugPrint('🎙️ MEMORY MOBILE START');
    }
  }

  // ================= 🖥️ HARDWARE =================
  Future<void> _toggleHardwareRecording() async {
    if (_hwRecording) {
      setState(() => _isLoading = true);

      final res = await http.post(
        Uri.parse('${SessionContext.raspberryBaseUrl}/stop-recording'),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/memory_hw.wav');
      await file.writeAsBytes(res.bodyBytes);

      setState(() {
        _audioPath = file.path;
        _hasRecorded = true;
        _hwRecording = false;
        _isLoading = false;
      });

      debugPrint('✅ MEMORY HW STOP: ${file.path}');
    } else {
      await _instructionPlayer.stop();

      await http.post(
        Uri.parse('${SessionContext.raspberryBaseUrl}/start-recording'),
      );

      setState(() {
        _hwRecording = true;
        _hasRecorded = false;
      });

      debugPrint('🎙️ MEMORY HW START');
    }
  }

  // ================= 🚀 SUBMIT =================
  Future<void> _submitAndNext() async {
    if (_audioPath == null) return;

    setState(() => _isLoading = true);

    try {
      final res = await _apiService.checkMemory(_audioPath!);

      final int score = res['score'] ?? 0;
      TestSession.memoryScore = score;

      // 🧠 LOG واضح
      debugPrint('================ MEMORY RESULT ================');
      debugPrint('🧠 MEMORY SCORE: $score');
      debugPrint('FULL RESPONSE: $res');
      debugPrint('Patient Said: ${res['patient_said']}');
      debugPrint('Analysis: ${res['analysis']}');
      debugPrint('==============================================');

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const OrientationScreen(),
        ),
      );
    } catch (e) {
      debugPrint('❌ MEMORY SUBMIT ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التحليل: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isHardware = SessionContext.testMode == TestMode.hardware;

    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'استدعاء الكلمات',
          instruction: isHardware
              ? 'اذكر الكلمات الخمس في ميكروفون الجهاز الخارجي.'
              : 'اذكر الكلمات الخمس التي سمعتها في بداية الاختبار.',
          content: Column(
            children: [
              const Icon(
                Icons.psychology_alt,
                size: 90,
                color: Colors.purple,
              ),
              const SizedBox(height: 30),

              if (!_isRecording && !_isLoading)
                TextButton.icon(
                  onPressed: _isPlaying ? null : _playInstruction,
                  icon: const Icon(Icons.replay),
                  label: const Text('إعادة سماع التعليمات'),
                ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _onRecordPressed,
                icon: Icon(
                  isHardware
                      ? Icons.settings_remote
                      : (_isRecording ? Icons.stop : Icons.mic),
                ),
                label: Text(
                  isHardware
                      ? (_hwRecording ? 'إيقاف التسجيل' : 'بدء التسجيل')
                      : (_isRecording ? 'إيقاف التسجيل' : 'بدء تسجيل الإجابة'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isRecording || _hwRecording ? Colors.red : null,
                  foregroundColor:
                      _isRecording || _hwRecording ? Colors.white : null,
                ),
              ),

              if (_hasRecorded && !_isRecording)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    '✅ تم تسجيل الإجابة بنجاح',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          isNextEnabled: _hasRecorded && !_isRecording && !_isLoading,
          onNext: _submitAndNext,
          onEndSession: () =>
              Navigator.popUntil(context, (r) => r.isFirst),
        ),

        if (_isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
