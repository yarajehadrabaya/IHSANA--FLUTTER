import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';
import '../abstraction/abstraction_question_one_screen.dart';
import '../../test/widgets/test_question_scaffold.dart';

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

  bool _isRecording = false;
  bool _isFinished = false;
  bool _isLoading = false;

  String? _audioPath;

  @override
  void initState() {
    super.initState();

    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }

    _instructionPlayer.play(AssetSource('audio/fluency.mp3'));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _instructionPlayer.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }

  // ================= TIMER =================
  void _startTimer() {
    _timer?.cancel();
    _seconds = 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        timer.cancel();
        _forceStopRecording();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  // ================= START =================
  Future<void> _startRecording() async {
    if (_isRecording) return;

    setState(() {
      _isRecording = true;
      _isFinished = false;
    });

    debugPrint('🎙️ FLUENCY RECORDING STARTED');

    if (SessionContext.testMode == TestMode.mobile) {
      final dir = await getTemporaryDirectory();
      _audioPath = '${dir.path}/fluency_mobile.wav';

      await _recorder!.startRecorder(
        toFile: _audioPath,
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );
    } else {
      await http.post(
        Uri.parse('${SessionContext.raspberryBaseUrl}/start-recording'),
      );
    }

    _startTimer();
  }

  // ================= FORCE STOP =================
  Future<void> _forceStopRecording() async {
    if (!_isRecording) return;

    debugPrint('⏹️ FLUENCY FORCE STOP AFTER 60s');

    _isRecording = false;
    setState(() => _isLoading = true);

    if (SessionContext.testMode == TestMode.mobile) {
      await _recorder!.stopRecorder();
    } else {
      // 1️⃣ stop recording
      await http.post(
        Uri.parse('${SessionContext.raspberryBaseUrl}/stop-recording'),
      );

      // 2️⃣ get audio file
      final audioRes = await http.get(
        Uri.parse('${SessionContext.raspberryBaseUrl}/get-audio'),
      );

      if (audioRes.statusCode != 200) {
        throw Exception('Failed to fetch fluency audio');
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/fluency_hw.wav');
      await file.writeAsBytes(audioRes.bodyBytes);

      debugPrint('✅ FLUENCY AUDIO SAVED: ${file.path}');
      _audioPath = file.path;
    }

    setState(() {
      _isFinished = true;
      _isLoading = false;
    });
  }

  // ================= SUBMIT =================
  Future<void> _submit() async {
    if (_audioPath == null) return;

    debugPrint('📤 Sending fluency audio to model: $_audioPath');

    final res = await _apiService.checkFluency(_audioPath!);
    TestSession.fluencyScore = res['score'] ?? 0;

    debugPrint('==============================');
    debugPrint('🧠 FLUENCY RESULT');
    debugPrint('Score: ${res['score']}');
    debugPrint('Analysis: ${res['analysis']}');
    debugPrint('==============================');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AbstractionQuestionOneScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'الطلاقة اللفظية',
      content: Column(
        children: [
          Text(
            '$_seconds',
            style: const TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _isRecording ? null : _startRecording,
            child: const Text('بدء التسجيل'),
          ),
        ],
      ),
      isNextEnabled: _isFinished && !_isLoading,
      onNext: _submit,
      onEndSession: () =>
          Navigator.popUntil(context, (r) => r.isFirst),
    );
  }
}
