import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import '../../utils/test_session.dart';
import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';
import 'package:ihsana/test/naming/naming_rhino_screen.dart';

class NamingLionScreen extends StatefulWidget {
  const NamingLionScreen({super.key});

  @override
  State<NamingLionScreen> createState() => _NamingLionScreenState();
}

class _NamingLionScreenState extends State<NamingLionScreen> {
  FlutterSoundRecorder? _recorder;
  final AudioPlayer _instructionPlayer = AudioPlayer();
  final AudioPlayer _actionAudioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isLoading = false;
  String? _lionPath;
  
  // 🛡️ متغير الحماية لمراقبة حالة مشغل التعليمات
  bool _isInstructionPlaying = false;

  @override
  void initState() {
    super.initState();
    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }

    // 🔊 مراقبة انتهاء الصوت لإعادة إظهار زر الإعادة
    _instructionPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() => _isInstructionPlaying = false);
      }
    });

    _playInstruction();
  }

  @override
  void dispose() {
    _instructionPlayer.dispose();
    _actionAudioPlayer.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }

  Future<void> _playInstruction() async {
    try {
      if (mounted) setState(() => _isInstructionPlaying = true);
      await _instructionPlayer.stop(); // إيقاف أي صوت سابق
      await _instructionPlayer.play(
        AssetSource('audio/naming.mp3'),
      );
    } catch (_) {
      if (mounted) setState(() => _isInstructionPlaying = false);
    }
  }

  Future<void> _onRecordPressed() async {
    // إيقاف التعليمات فوراً إذا بدأت عملية التسجيل
    if (_isInstructionPlaying) {
      await _instructionPlayer.stop();
      setState(() => _isInstructionPlaying = false);
    }

    if (SessionContext.testMode == TestMode.hardware) {
      if (_isRecording) {
        await _stopHardwareRecording();
      } else {
        await _startHardwareRecording();
      }
    } else {
      await _recordFromMobile();
    }
  }

  Future<void> _recordFromMobile() async {
    if (_isRecording) {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _lionPath = path;
      });
    } else {
      final dir = await getTemporaryDirectory();
      await _instructionPlayer.stop();

      await _recorder!.startRecorder(
        toFile: '${dir.path}/lion_mobile.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );

      setState(() {
        _isRecording = true;
        _lionPath = null;
      });
    }
  }

  Future<void> _startHardwareRecording() async {
    setState(() {
      _isRecording = true;
      _lionPath = null;
    });

    await _instructionPlayer.stop();
    await http.post(
      Uri.parse('${SessionContext.raspberryBaseUrl}/start-recording'),
    );
  }

  Future<void> _stopHardwareRecording() async {
    setState(() => _isLoading = true);

    try {
      await http.post(
        Uri.parse('${SessionContext.raspberryBaseUrl}/stop-recording'),
      );

      final res = await http.get(
        Uri.parse('${SessionContext.raspberryBaseUrl}/get-audio'),
      );

      if (res.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/lion_hw.wav');
        await file.writeAsBytes(res.bodyBytes);

        setState(() {
          _lionPath = file.path;
          _isRecording = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔊 صوت الأزرار
  Future<void> _playActionVoice(String asset) async {
    try {
      await _actionAudioPlayer.stop();
      await _actionAudioPlayer.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> _stopActionVoice() async {
    try {
      await _actionAudioPlayer.stop();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'تسمية الحيوانات',
      // 🛡️ تمرير دالة الإعادة بشرط الحماية: الزر يختفي إذا كان الصوت يعمل أو التسجيل يعمل
      onRepeatInstruction: (_isInstructionPlaying || _isRecording) 
          ? null 
          : _playInstruction,
      instruction: SessionContext.testMode == TestMode.hardware
          ? 'انطق اسم الحيوان في ميكروفون الجهاز'
          : 'ما اسم هذا الحيوان؟',
      content: Column(
        children: [
          // 🖼️ صورة مكبّرة أكثر
          Image.asset(
            'assets/images/lion.png',
            height: 300,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),

          // 🎙️ زر التسجيل المعدل
          GestureDetector(
            onLongPressStart: (_) {
              if (_isRecording) {
                _playActionVoice('audio/stop_recording.mp3');
              } else if (_lionPath != null) {
                _playActionVoice('audio/retry_recording.mp3');
              } else {
                _playActionVoice('audio/start_recording.mp3');
              }
            },
            onLongPressEnd: (_) => _stopActionVoice(),
            onTapCancel: _stopActionVoice,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading 
                    ? null 
                    : () {
                        _stopActionVoice(); 
                        _onRecordPressed();
                      },
                icon: AnimatedScale(
                  scale: _isRecording ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                  ),
                ),
                label: Text(
                  _isRecording
                      ? 'إيقاف التسجيل'
                      : (_lionPath != null
                          ? 'إعادة التسجيل'
                          : 'تسجيل الإجابة'),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  backgroundColor: _isRecording ? Colors.red : null,
                  foregroundColor: _isRecording ? Colors.white : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),

          // 🔴 نبض التسجيل
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: AnimatedOpacity(
                opacity: _isRecording ? 1 : 0.4,
                duration: const Duration(milliseconds: 700),
                child: Column(
                  children: const [
                    Icon(
                      Icons.fiber_manual_record,
                      color: Colors.red,
                      size: 30,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'جاري التسجيل...',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),

          // ✅ نجاح التسجيل
          if (_lionPath != null && !_isRecording) ...[
            const SizedBox(height: 36),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'تم تسجيل الإجابة بنجاح',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      isNextEnabled: _lionPath != null && !_isRecording && !_isLoading,
      onNext: () {
        _instructionPlayer.stop(); // إيقاف أي صوت عند الانتقال
        TestSession.nextQuestion();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                NamingRhinoScreen(lionAudioPath: _lionPath!),
          ),
        );
      },
      onEndSession: () {
        _instructionPlayer.stop();
        Navigator.popUntil(context, (route) => route.isFirst);
      },
    );
  }
}