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
import 'naming_camel_screen.dart';

class NamingRhinoScreen extends StatefulWidget {
  final String lionAudioPath;
  const NamingRhinoScreen({super.key, required this.lionAudioPath});

  @override
  State<NamingRhinoScreen> createState() => _NamingRhinoScreenState();
}

class _NamingRhinoScreenState extends State<NamingRhinoScreen> {
  FlutterSoundRecorder? _recorder;
  final AudioPlayer _actionAudioPlayer = AudioPlayer();
  final AudioPlayer _instructionPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isLoading = false;
  String? _rhinoPath;
  
  // 🛡️ متغير الحماية: لمعرفة ما إذا كان صوت التعليمات يعمل الآن
  bool _isInstructionPlaying = false;

  @override
  void initState() {
    super.initState();
    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }
    
    // 🔊 مراقبة انتهاء الصوت لإظهار الزر مرة أخرى
    _instructionPlayer.onPlayerComplete.listen((event) {
      if (mounted) setState(() => _isInstructionPlaying = false);
    });

    // 🔊 تشغيل التعليمات تلقائياً عند فتح الصفحة
    _playInstruction();
  }

  Future<void> _playInstruction() async {
    try {
      if (mounted) setState(() => _isInstructionPlaying = true);
      await _instructionPlayer.stop(); 
      await _instructionPlayer.play(AssetSource('audio/naming.mp3'));
    } catch (_) {
      if (mounted) setState(() => _isInstructionPlaying = false);
    }
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _actionAudioPlayer.dispose();
    _instructionPlayer.dispose();
    super.dispose();
  }

  Future<void> _onRecordPressed() async {
    // إيقاف أي تعليمات شغالة عند البدء بالتسجيل يدوياً
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
        _rhinoPath = path;
      });
    } else {
      final dir = await getTemporaryDirectory();
      await _instructionPlayer.stop();
      await _recorder!.startRecorder(
        toFile: '${dir.path}/rhino_mobile.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );
      setState(() {
        _isRecording = true;
        _rhinoPath = null;
      });
    }
  }

  Future<void> _startHardwareRecording() async {
    setState(() {
      _isRecording = true;
      _rhinoPath = null;
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
        final file = File('${dir.path}/rhino_hw.wav');
        await file.writeAsBytes(res.bodyBytes);
        setState(() {
          _rhinoPath = file.path;
          _isRecording = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
      // 🛡️ منطق الحماية: الزر يظهر فقط إذا كان الصوت متوقفاً والتسجيل متوقفاً
      onRepeatInstruction: (_isInstructionPlaying || _isRecording) 
          ? null 
          : _playInstruction,
      content: Column(
        children: [
          const SizedBox(height: 16),
          Image.asset(
            'assets/images/rhino.png',
            height: 300,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onLongPressStart: (_) {
              if (_isRecording) {
                _playActionVoice('audio/stop_recording.mp3');
              } else if (_rhinoPath != null) {
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
                      : (_rhinoPath != null
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
          if (_rhinoPath != null && !_isRecording) ...[
            const SizedBox(height: 24),
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
      isNextEnabled: _rhinoPath != null && !_isRecording && !_isLoading,
      onNext: () {
        _instructionPlayer.stop();
        _actionAudioPlayer.stop();
        TestSession.nextQuestion();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NamingCamelScreen(
              lionPath: widget.lionAudioPath,
              rhinoPath: _rhinoPath!,
            ),
          ),
        );
      },
      onEndSession: () {
        _instructionPlayer.stop();
        _actionAudioPlayer.stop();
        Navigator.popUntil(context, (route) => route.isFirst);
      },
    );
  }
}