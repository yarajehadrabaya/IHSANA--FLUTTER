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
      debugPrint("Instruction audio error: $e");
      setState(() => _isPlaying = false);
    }
  }

  // 🎤 زر التسجيل الموحد
  Future<void> _onRecordPressed() async {
    if (SessionContext.testMode == TestMode.hardware) {
      await _recordFromHardware();
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
      debugPrint("✅ Memory mobile recording stopped");
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
      debugPrint("🎙️ Memory mobile recording started");
    }
  }

  // ================= 🖥️ HARDWARE =================
  Future<void> _recordFromHardware() async {
    setState(() => _isLoading = true);
    await _instructionPlayer.stop();

    try {
      final uri =
          Uri.parse('${SessionContext.raspberryBaseUrl}/get-audio');

      debugPrint("[HARDWARE] Requesting delayed recall audio from $uri");

      final res = await http.get(uri).timeout(
            const Duration(seconds: 20),
          );

      if (res.statusCode != 200) {
        throw Exception("Hardware error ${res.statusCode}");
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/memory_hw.wav');
      await file.writeAsBytes(res.bodyBytes);

      setState(() {
        _audioPath = file.path;
        _hasRecorded = true;
      });

      debugPrint("✅ Memory hardware audio received");
    } catch (e) {
      debugPrint("❌ Hardware error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في التسجيل من الجهاز الخارجي'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🚀 الإرسال للتحليل
  Future<void> _submitAndNext() async {
    if (_audioPath == null) return;

    setState(() => _isLoading = true);
    try {
      final res = await _apiService.checkMemory(_audioPath!);

      TestSession.memoryScore = res['score'] ?? 0;

      debugPrint("=================================");
      debugPrint("🧠 DELAYED RECALL RESULT");
      debugPrint("Score: ${res['score']}");
      debugPrint("Patient Said: ${res['patient_said']}");
      debugPrint("Analysis: ${res['analysis']}");
      debugPrint("=================================");

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const OrientationScreen(),
        ),
      );
    } catch (e) {
      debugPrint("❌ Memory submit error: $e");
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
                      ? 'التقاط الصوت من الجهاز'
                      : (_isRecording
                          ? 'إيقاف التسجيل'
                          : 'بدء تسجيل الإجابة'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isRecording ? Colors.red : null,
                  foregroundColor:
                      _isRecording ? Colors.white : null,
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
