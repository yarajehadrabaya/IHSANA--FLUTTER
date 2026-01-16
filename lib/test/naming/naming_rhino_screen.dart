import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart'; // ✅ أضفنا المكتبة
import 'package:path_provider/path_provider.dart';
import 'naming_camel_screen.dart';

class NamingRhinoScreen extends StatefulWidget {
  final String lionAudioPath;
  const NamingRhinoScreen({super.key, required this.lionAudioPath});
  @override
  State<NamingRhinoScreen> createState() => _NamingRhinoScreenState();
}

class _NamingRhinoScreenState extends State<NamingRhinoScreen> {
  FlutterSoundRecorder? _recorder = FlutterSoundRecorder();
  final AudioPlayer _instructionPlayer = AudioPlayer(); // ✅ مشغل التعليمات
  bool _isRecording = false;
  String? _rhinoPath;

  @override
  void initState() {
    super.initState();
    _recorder!.openRecorder();
    _playInstruction(); // ✅ تشغيل التعليمات عند الفتح
  }

  Future<void> _playInstruction() async {
    try {
      await _instructionPlayer.play(AssetSource('audio/naming.mp3'));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _rhinoPath = path;
      });
    } else {
      await _instructionPlayer.stop(); // إيقاف التعليمات عند بدء التسجيل
      final dir = await getTemporaryDirectory();
      await _recorder!.startRecorder(
        toFile: '${dir.path}/rhino.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );
      setState(() {
        _isRecording = true;
      });
    }
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _instructionPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'ما هذا الحيوان؟',
      content: Column(
        children: [
          Image.asset('assets/images/rhino.png', height: 200),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _toggleRecording,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRecording ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
            ),
            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
            label: Text(_isRecording ? 'إيقاف' : 'تسجيل إجابة وحيد القرن'),
          ),
        ],
      ),
      isNextEnabled: _rhinoPath != null && !_isRecording,
      onNext: () {
        _instructionPlayer.stop();
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
      onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
    );
  }
}
