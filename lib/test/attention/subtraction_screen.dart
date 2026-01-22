import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../language/sentence_repetition_screen_one.dart';

class SubtractionScreen extends StatefulWidget {
  const SubtractionScreen({super.key});

  @override
  State<SubtractionScreen> createState() => _SubtractionScreenState();
}

class _SubtractionScreenState extends State<SubtractionScreen> {
  final AudioPlayer _instructionPlayer = AudioPlayer();
  FlutterSoundRecorder? _recorder;
  final MocaApiService _apiService = MocaApiService();

  bool _isRecording = false;
  bool _isLoading = false;
  int _count = 0;
  String? _recordedPath;

  @override
  void initState() {
    super.initState();

    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }

    _playInstruction();
  }

  // 🔊 تشغيل التعليمات
  Future<void> _playInstruction() async {
    await _instructionPlayer.play(
      AssetSource('audio/subtraction.mp3'),
    );
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
        _recordedPath = path;
      });
      debugPrint("✅ Subtraction mobile stopped: $path");
    } else {
      final dir = await getTemporaryDirectory();
      await _instructionPlayer.stop();

      await _recorder!.startRecorder(
        toFile: '${dir.path}/subtraction_mobile.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );

      setState(() {
        _isRecording = true;
        _recordedPath = null;
        _count = 0;
      });

      debugPrint("🎙️ Subtraction mobile started");
    }
  }

  // ================= 🖥️ HARDWARE =================
  Future<void> _recordFromHardware() async {
    setState(() => _isLoading = true);
    await _instructionPlayer.stop();

    try {
      final uri = Uri.parse('${SessionContext.raspberryBaseUrl}/get-audio');
      debugPrint("[HARDWARE] Requesting subtraction audio from $uri");

      final res = await http.get(uri).timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        throw Exception("Hardware error ${res.statusCode}");
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/subtraction_hw.wav');
      await file.writeAsBytes(res.bodyBytes);

      setState(() {
        _recordedPath = file.path;
        _count = 5; // يعتبرها مكتملة
      });

      debugPrint("✅ Subtraction audio received from hardware");
    } catch (e) {
      debugPrint("❌ Subtraction hardware error: $e");
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

  // ================= 🚀 SUBMIT =================
  Future<void> _submit() async {
    if (_recordedPath == null) return;

    setState(() => _isLoading = true);
    try {
      final result = await _apiService.checkAttention(
        _recordedPath!,
        "subtraction",
      );

      TestSession.subtractionScore = result['score'] ?? 0;

      debugPrint("=================================");
      debugPrint("🧠 SUBTRACTION RESULT");
      debugPrint("Score: ${result['score']}");
      debugPrint("Analysis: ${result['analysis']}");
      debugPrint("=================================");

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SentenceRepetitionOneScreen(),
        ),
      );
    } catch (e) {
      debugPrint("Submit error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _instructionPlayer.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isHardware = SessionContext.testMode == TestMode.hardware;

    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'الطرح من 100',
          instruction: isHardware
              ? 'انطق الأرقام بوضوح في ميكروفون الجهاز'
              : 'اطرح 7 من 100 خمس مرات متتالية',
          content: Column(
            children: [
              Text(
                "المحاولات: $_count / 5",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),

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
                      : (_isRecording ? 'إيقاف التسجيل' : 'بدء التسجيل'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),

              const SizedBox(height: 20),

              if (_recordedPath != null && !_isRecording)
                const Text(
                  '✅ تم تسجيل الإجابة',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          isNextEnabled:
              _recordedPath != null && !_isRecording && !_isLoading,
          onNext: _submit,
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
