import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🆕 لإضافة ميزة الاهتزاز (Vibration)
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:ihsana/test/abstraction/abstraction_intro_screen.dart';
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
  final AudioPlayer _btnSfxPlayer = AudioPlayer(); 
  FlutterSoundRecorder? _recorder;
  final MocaApiService _apiService = MocaApiService();

  bool _isRecording = false;
  bool _isFinished = false;
  bool _isLoading = false;
  bool _audioFinished = false; 
  bool _isTimeUp = false; // 🆕 لمتابعة حالة انتهاء الوقت

  String? _audioPath;

  @override
  void initState() {
    super.initState();

    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }

    _playInstruction(); 
  }

  Future<void> _playInstruction() async {
    setState(() => _audioFinished = false);
    await _instructionPlayer.play(AssetSource('audio/fluency.mp3'));
    _instructionPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _audioFinished = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _instructionPlayer.dispose();
    _btnSfxPlayer.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }

  // ================= TIMER =================
  void _startTimer() {
    _timer?.cancel();
    _seconds = 60;
    _isTimeUp = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        timer.cancel();
        _handleTimerCompletion(); // 🆕 استدعاء دالة المعالجة عند الصفر
      } else {
        setState(() => _seconds--);
      }
    });
  }

  // 🆕 دالة التعامل مع انتهاء الـ 60 ثانية
  void _handleTimerCompletion() {
    setState(() {
      _isTimeUp = true;
    });

    // 1. تشغيل صوت البيب الذي قمت بإنشائه
    _btnSfxPlayer.play(AssetSource('audio/timer_end.mp3'));

    // 2. تفعيل الرعشة (Vibration)
    HapticFeedback.heavyImpact(); 

    // 3. إيقاف التسجيل
    _forceStopRecording();
  }

  // ================= START RECORDING =================
  Future<void> _startRecording() async {
    if (_isRecording) return;

    setState(() {
      _isRecording = true;
      _isFinished = false;
      _isTimeUp = false;
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
    } 
    else {
      await http.post(
        Uri.parse('${SessionContext.raspberryBaseUrl}/start-recording'),
      );
    }

    _startTimer();
  }

  // ================= FORCE STOP =================
  Future<void> _forceStopRecording() async {
    if (!_isRecording) return;

    _isRecording = false;
    setState(() => _isLoading = true);

    if (SessionContext.testMode == TestMode.mobile) {
      await _recorder!.stopRecorder();
    } 
    else {
      await http.post(
        Uri.parse('${SessionContext.raspberryBaseUrl}/stop-recording'),
      );

      final audioRes = await http.get(
        Uri.parse('${SessionContext.raspberryBaseUrl}/get-audio'),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/fluency_hw.wav');
      await file.writeAsBytes(audioRes.bodyBytes);

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

    final res = await _apiService.checkFluency(_audioPath!);
    TestSession.fluencyScore = res['score'] ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AbstractionIntroScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String recordingSfx = _isRecording 
        ? 'audio/stop_recording.mp3' 
        : 'audio/start_recording.mp3';

    return TestQuestionScaffold(
      title: 'الطلاقة اللفظية',
      instruction: 'اذكر أكبر عدد ممكن من الكلمات خلال دقيقة واحدة.',
      onRepeatInstruction: _isRecording ? null : _playInstruction, 
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording
                        ? Colors.red.withOpacity(0.12)
                        : Colors.blue.withOpacity(0.12),
                  ),
                  child: Text(
                    '$_seconds',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: _isRecording ? Colors.red : Colors.blue,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 🆕 رسالة انتهى الوقت تظهر فوق الزر
                if (_isTimeUp)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'انتهى الوقت!',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // ===== RECORD BUTTON =====
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onLongPressStart: (_) {
                      if (_audioFinished && !_isFinished) {
                        _btnSfxPlayer.play(AssetSource(recordingSfx));
                      }
                    },
                    onLongPressEnd: (_) => _btnSfxPlayer.stop(),
                    child: ElevatedButton.icon(
                      onPressed: (_isRecording || _isFinished || !_audioFinished) ? null : _startRecording,
                      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                      label: Text(_isRecording ? 'جاري التسجيل' : 'بدء التسجيل'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _isRecording ? Colors.red : null,
                        foregroundColor: _isRecording ? Colors.white : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),

                if (_isRecording)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: const [
                        Icon(Icons.fiber_manual_record, color: Colors.red, size: 28),
                        SizedBox(height: 6),
                        Text(
                          'جاري التسجيل… الرجاء المتابعة',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                if (_isFinished)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'انتهى التسجيل',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      isNextEnabled: _isFinished && !_isLoading,
      onNext: _submit,
      onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
    );
  }
}