import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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
  String? _recordedPath;

  @override
  void initState() {
    super.initState();

    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }

    _playInstruction();
  }

  // 🔊 تعليمات
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
      debugPrint("🎙️ MOBILE SUBTRACTION STOP: $path");
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
      });

      debugPrint("🎙️ MOBILE SUBTRACTION START");
    }
  }

  // ================= 🖥️ HARDWARE =================
  Future<void> _recordFromHardware() async {
    final baseUrl = SessionContext.raspberryBaseUrl;

    if (_isRecording) {
      // ⛔ STOP
      setState(() => _isLoading = true);
      try {
        await http.post(Uri.parse('$baseUrl/stop-recording'));
        final res = await http.get(Uri.parse('$baseUrl/get-audio'));

        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/subtraction_hw.wav');
        await file.writeAsBytes(res.bodyBytes);

        setState(() {
          _recordedPath = file.path;
          _isRecording = false;
        });

        debugPrint("🎙️ HW SUBTRACTION SAVED: ${file.path}");
      } catch (e) {
        debugPrint("❌ HW STOP ERROR: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // ▶ START
      await _instructionPlayer.stop();
      await http.post(Uri.parse('$baseUrl/start-recording'));

      setState(() {
        _isRecording = true;
        _recordedPath = null;
      });

      debugPrint("🎙️ HW SUBTRACTION START");
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

      final score = result['score'] ?? 0;
      final spokenText =
          result['text'] ?? result['transcript'] ?? '—';

      TestSession.subtractionScore = score;

      debugPrint("=========== SUBTRACTION ===========");
      debugPrint("🗣️ User said: $spokenText");
      debugPrint("⭐ Score: $score");
      debugPrint("📦 Full result: $result");
      debugPrint("==================================");

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SentenceRepetitionOneScreen(),
        ),
      );
    } catch (e) {
      debugPrint("❌ SUBMIT ERROR: $e");
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
    final isHardware = SessionContext.testMode == TestMode.hardware;

    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'الطرح من 100',
          instruction: isHardware
              ? 'اضغط بدء ثم انهِ التسجيل من الجهاز الخارجي'
              : 'اطرح 7 من 100 خمس مرات متتالية',
          content: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _onRecordPressed,
                icon: Icon(
                  isHardware
                      ? (_isRecording ? Icons.stop : Icons.settings_remote)
                      : (_isRecording ? Icons.stop : Icons.mic),
                ),
                label: Text(
                  _isRecording ? 'إيقاف التسجيل' : 'بدء التسجيل',
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
