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
import 'sentence_repetition_screen_two.dart';

class SentenceRepetitionOneScreen extends StatefulWidget {
  const SentenceRepetitionOneScreen({super.key});

  @override
  State<SentenceRepetitionOneScreen> createState() =>
      _SentenceRepetitionOneScreenState();
}

class _SentenceRepetitionOneScreenState
    extends State<SentenceRepetitionOneScreen> {
  final AudioPlayer _instructionPlayer = AudioPlayer();
  FlutterSoundRecorder? _recorder;
  final MocaApiService _apiService = MocaApiService();

  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _isLoading = false;
  bool _isPlaying = false;
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

  // 🔊 تشغيل الجملة
  Future<void> _playInstruction() async {
    setState(() => _isPlaying = true);
    await _instructionPlayer.play(
      AssetSource('audio/sentance1.mp3'),
    );
    _instructionPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  // 🎤 زر التسجيل
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
      debugPrint("🎙️ SENTENCE 1 MOBILE STOP: $path");
    } else {
      final dir = await getTemporaryDirectory();
      await _instructionPlayer.stop();

      await _recorder!.startRecorder(
        toFile: '${dir.path}/sentence1_mobile.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );

      setState(() {
        _isRecording = true;
        _hasRecorded = false;
        _audioPath = null;
      });
      debugPrint("🎙️ SENTENCE 1 MOBILE START");
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
        final file = File('${dir.path}/sentence1_hw.wav');
        await file.writeAsBytes(res.bodyBytes);

        setState(() {
          _audioPath = file.path;
          _isRecording = false;
          _hasRecorded = true;
        });

        debugPrint("🎙️ SENTENCE 1 HW SAVED: ${file.path}");
      } catch (e) {
        debugPrint("❌ SENTENCE 1 HW STOP ERROR: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // ▶ START
      await _instructionPlayer.stop();
      await http.post(Uri.parse('$baseUrl/start-recording'));

      setState(() {
        _isRecording = true;
        _hasRecorded = false;
        _audioPath = null;
      });

      debugPrint("🎙️ SENTENCE 1 HW START");
    }
  }

  // ================= 🚀 SUBMIT =================
  Future<void> _submit() async {
    if (_audioPath == null) return;

    setState(() => _isLoading = true);
    try {
      final res = await _apiService.checkSentence1(_audioPath!);

      final score = res['score'] ?? 0;
      final text = res['text'] ?? res['transcript'] ?? '—';

      TestSession.sentence1Score = score;

      debugPrint("=========== SENTENCE 1 ===========");
      debugPrint("🗣️ Text: $text");
      debugPrint("⭐ Score: $score");
      debugPrint("📦 Full response: $res");
      debugPrint("=================================");

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SentenceRepetitionTwoScreen(),
        ),
      );
    } catch (e) {
      debugPrint("❌ SENTENCE 1 SUBMIT ERROR: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHardware = SessionContext.testMode == TestMode.hardware;

    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'تكرار الجملة (1/2)',
          instruction: isHardware
              ? 'اضغط بدء ثم أنهِ التسجيل من الجهاز الخارجي'
              : 'استمع للجملة ثم أعدها كما سمعتها',
          content: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _isPlaying ? null : _playInstruction,
                icon: const Icon(Icons.volume_up),
                label: const Text('سماع الجملة'),
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed:
                    (_isPlaying || _isLoading) ? null : _onRecordPressed,
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                ),
                label: Text(
                  _isRecording ? 'إيقاف التسجيل' : 'بدء التسجيل',
                ),
              ),

              const SizedBox(height: 16),

              if (_hasRecorded && !_isRecording)
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
              _hasRecorded && !_isRecording && !_isLoading,
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
