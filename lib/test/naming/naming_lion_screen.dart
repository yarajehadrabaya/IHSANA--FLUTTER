import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';
import '../widgets/test_question_scaffold.dart';
import 'naming_rhino_screen.dart';

class NamingLionScreen extends StatefulWidget {
  const NamingLionScreen({super.key});

  @override
  State<NamingLionScreen> createState() => _NamingLionScreenState();
}

class _NamingLionScreenState extends State<NamingLionScreen> {
  FlutterSoundRecorder? _recorder;
  final AudioPlayer _instructionPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isLoading = false;
  String? _lionPath;

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

  Future<void> _playInstruction() async {
    await _instructionPlayer.play(AssetSource('audio/naming.mp3'));
  }

  Future<void> _onRecordPressed() async {
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

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'تسمية الحيوانات',
      instruction: SessionContext.testMode == TestMode.hardware
          ? 'انطق اسم الحيوان في ميكروفون الجهاز'
          : 'ما اسم هذا الحيوان؟',
      content: Column(
        children: [
          Image.asset('assets/images/lion.png', height: 200),
          const SizedBox(height: 24),

          // ===== زر التسجيل =====
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _onRecordPressed,
              icon: Icon(
                _isRecording ? Icons.stop : Icons.mic,
              ),
              label: Text(
                _isRecording ? 'إيقاف التسجيل' : 'تسجيل الإجابة',
              ),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                backgroundColor: _isRecording ? Colors.red : null,
                foregroundColor: _isRecording ? Colors.white : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          // ===== مؤشر التسجيل =====
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: const [
                  Icon(Icons.fiber_manual_record,
                      color: Colors.red, size: 28),
                  SizedBox(height: 6),
                  Text('جاري التسجيل...',
                      style: TextStyle(color: Colors.red)),
                ],
              ),
            ),

          if (_lionPath != null && !_isRecording)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                '✅ تم تسجيل إجابة الأسد',
                style:
                    TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      isNextEnabled: _lionPath != null && !_isRecording && !_isLoading,
      onNext: () {
        _instructionPlayer.stop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NamingRhinoScreen(lionAudioPath: _lionPath!),
          ),
        );
      },
      onEndSession: () =>
          Navigator.popUntil(context, (route) => route.isFirst),
    );
  }
}
