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
import 'verbal_fluency_screen.dart';

class SentenceRepetitionTwoScreen extends StatefulWidget {
  const SentenceRepetitionTwoScreen({super.key});

  @override
  State<SentenceRepetitionTwoScreen> createState() =>
      _SentenceRepetitionTwoScreenState();
}

class _SentenceRepetitionTwoScreenState
    extends State<SentenceRepetitionTwoScreen> {
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

  // 🔊 تشغيل الجملة الثانية
  Future<void> _playInstruction() async {
    try {
      setState(() => _isPlaying = true);
      await _instructionPlayer.play(
        AssetSource('audio/sentance2.mp3'),
      );
      _instructionPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    } catch (e) {
      debugPrint("Audio error: $e");
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
      debugPrint("✅ Sentence 2 mobile recorded: $path");
    } else {
      final dir = await getTemporaryDirectory();
      await _instructionPlayer.stop();

      await _recorder!.startRecorder(
        toFile: '${dir.path}/sentence2_mobile.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );

      setState(() {
        _isRecording = true;
        _hasRecorded = false;
        _audioPath = null;
      });
      debugPrint("🎙️ Sentence 2 mobile recording started");
    }
  }

  // ================= 🖥️ HARDWARE =================
  Future<void> _recordFromHardware() async {
    setState(() => _isLoading = true);
    await _instructionPlayer.stop();

    try {
      final uri =
          Uri.parse('${SessionContext.raspberryBaseUrl}/get-audio');
      debugPrint("[HARDWARE] Requesting sentence 2 audio from $uri");

      final res = await http.get(uri).timeout(
            const Duration(seconds: 20),
          );

      if (res.statusCode != 200) {
        throw Exception("Hardware error ${res.statusCode}");
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/sentence2_hw.wav');
      await file.writeAsBytes(res.bodyBytes);

      setState(() {
        _audioPath = file.path;
        _hasRecorded = true;
      });

      debugPrint("✅ Sentence 2 audio received from hardware");
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

  // ================= 🚀 SUBMIT =================
  Future<void> _submit() async {
    if (_audioPath == null) return;

    setState(() => _isLoading = true);
    try {
      final res = await _apiService.checkSentence2(_audioPath!);

      TestSession.sentence2Score = res['score'] ?? 0;

      debugPrint("=================================");
      debugPrint("🧠 SENTENCE 2 RESULT");
      debugPrint("Score: ${res['score']}");
      debugPrint("Analysis: ${res['analysis']}");
      debugPrint("=================================");

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const VerbalFluencyScreen(),
        ),
      );
    } catch (e) {
      debugPrint("Submit error: $e");
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
          title: 'تكرار الجملة (2/2)',
          instruction: isHardware
              ? 'استمع للجملة ثم أعدها بوضوح في ميكروفون الجهاز.'
              : 'استمع للجملة ثم أعدها كما سمعتها.',
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
                  isHardware
                      ? Icons.settings_remote
                      : (_isRecording ? Icons.stop : Icons.mic),
                ),
                label: Text(
                  isHardware
                      ? 'التقاط الصوت من الجهاز'
                      : (_isRecording
                          ? 'إيقاف التسجيل'
                          : 'تسجيل الإجابة'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isRecording ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
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

