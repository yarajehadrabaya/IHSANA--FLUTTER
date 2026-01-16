import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'naming_rhino_screen.dart';

class NamingLionScreen extends StatefulWidget {
  const NamingLionScreen({super.key});
  @override
  State<NamingLionScreen> createState() => _NamingLionScreenState();
}

class _NamingLionScreenState extends State<NamingLionScreen> {
  FlutterSoundRecorder? _recorder = FlutterSoundRecorder();
  final AudioPlayer _instructionPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _lionPath;

  @override
  void initState() {
    super.initState();
    _recorder!.openRecorder();
    _playInstruction();
  }

  Future<void> _playInstruction() async {
    await _instructionPlayer.play(AssetSource('audio/naming.mp3'));
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _lionPath = path;
      });
    } else {
      final dir = await getTemporaryDirectory();
      await _recorder!.startRecorder(
        toFile: '${dir.path}/lion.wav',
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

  @override
  void dispose() {
    _instructionPlayer.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'تسمية الحيوانات',
      content: Column(
        children: [
          Image.asset('assets/images/lion.png', height: 200),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _toggleRecording,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRecording ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
            ),
            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
            label: Text(_isRecording ? 'إيقاف التسجيل' : 'تسجيل إجابة الأسد'),
          ),
        ],
      ),
      isNextEnabled: _lionPath != null && !_isRecording,
      onNext: () {
        _instructionPlayer.stop();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NamingRhinoScreen(lionAudioPath: _lionPath!),
          ),
        );
      },
      onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
    );
  }
}
