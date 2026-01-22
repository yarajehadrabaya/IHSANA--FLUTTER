import 'dart:async';
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
import '../abstraction/abstraction_question_one_screen.dart';

class VerbalFluencyScreen extends StatefulWidget {
  const VerbalFluencyScreen({super.key});

  @override
  State<VerbalFluencyScreen> createState() => _VerbalFluencyScreenState();
}

class _VerbalFluencyScreenState extends State<VerbalFluencyScreen> {
  int _seconds = 60;
  Timer? _timer;

  final AudioPlayer _instructionPlayer = AudioPlayer();
  FlutterSoundRecorder? _recorder;
  final MocaApiService _apiService = MocaApiService();

  bool _isRunning = false;
  bool _isFinished = false;
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
    _timer?.cancel();
    _instructionPlayer.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }

  // 🔊 تشغيل التعليمات
  Future<void> _playInstruction() async {
    try {
      await _instructionPlayer.play(
        AssetSource('audio/fluency.mp3'),
      );
    } catch (e) {
      debugPrint("Audio error: $e");
    }
  }

  // ▶️ بدء التسجيل
  Future<void> _startRecording() async {
    if (SessionContext.testMode == TestMode.hardware) {
      await _recordFromHardware();
    } else {
      await _recordFromMobile();
    }
  }

  // ================= 📱 MOBILE =================
  Future<void> _recordFromMobile() async {
    final dir = await getTemporaryDirectory();
    _audioPath = '${dir.path}/fluency_mobile.wav';

    await _recorder!.startRecorder(
      toFile: _audioPath,
      codec: Codec.pcm16WAV,
      sampleRate: 16000,
      numChannels: 1,
    );

    setState(() {
      _isRunning = true;
      _isFinished = false;
      _seconds = 60;
    });

    _startTimer(onFinish: _stopMobileRecording);
    debugPrint("🎙️ Fluency mobile recording started");
  }

  Future<void> _stopMobileRecording() async {
    await _recorder!.stopRecorder();
    setState(() {
      _isRunning = false;
      _isFinished = true;
    });
    debugPrint("✅ Fluency mobile recording finished");
  }

  // ================= 🖥️ HARDWARE =================
  Future<void> _recordFromHardware() async {
    setState(() {
      _isRunning = true;
      _isFinished = false;
      _seconds = 60;
      _isLoading = true;
    });

    _startTimer(); // مؤقت واجهة فقط

    try {
      final uri =
          Uri.parse('${SessionContext.raspberryBaseUrl}/get-audio');
      debugPrint("[HARDWARE] Requesting 60s fluency audio from $uri");

      final res = await http.get(uri).timeout(
            const Duration(seconds: 70),
          );

      if (res.statusCode != 200) {
        throw Exception("Hardware error ${res.statusCode}");
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/fluency_hw.wav');
      await file.writeAsBytes(res.bodyBytes);

      setState(() {
        _audioPath = file.path;
        _isRunning = false;
        _isFinished = true;
      });

      debugPrint("✅ Fluency hardware audio received");
    } catch (e) {
      debugPrint("❌ Hardware error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في التسجيل من الجهاز الخارجي'),
          ),
        );
      }
      setState(() {
        _isRunning = false;
        _isFinished = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ⏱️ المؤقت
  void _startTimer({VoidCallback? onFinish}) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) {
        t.cancel();
        if (onFinish != null) onFinish();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  // 🚀 إرسال للتحليل
  Future<void> _submit() async {
    if (_audioPath == null) return;

    setState(() => _isLoading = true);
    try {
      final res = await _apiService.checkFluency(_audioPath!);

      TestSession.fluencyScore = res['score'] ?? 0;

      debugPrint("=================================");
      debugPrint("🧠 VERBAL FLUENCY RESULT");
      debugPrint("Score: ${res['score']}");
      debugPrint("Analysis: ${res['analysis']}");
      debugPrint("=================================");

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AbstractionQuestionOneScreen(),
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
          title: 'الطلاقة اللفظية',
          content: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isRunning ? Colors.red : Colors.blue,
                    width: 5,
                  ),
                ),
                child: Text(
                  '$_seconds',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('ثانية متبقية'),

              const SizedBox(height: 40),

              ElevatedButton.icon(
                onPressed:
                    (_isRunning || _isFinished || _isLoading)
                        ? null
                        : _startRecording,
                icon: Icon(
                  isHardware
                      ? Icons.settings_remote
                      : Icons.mic,
                ),
                label: Text(
                  isHardware
                      ? 'بدء التسجيل من الجهاز'
                      : 'ابدأ الدقيقة',
                ),
              ),

              if (_isFinished && !_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(
                    '✅ انتهى الوقت، اضغط متابعة للتحليل',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          isNextEnabled: _isFinished && !_isLoading,
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
