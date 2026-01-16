import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../memory/memory_encoding_screen.dart';

class NamingCamelScreen extends StatefulWidget {
  final String lionPath;
  final String rhinoPath;
  const NamingCamelScreen({
    super.key,
    required this.lionPath,
    required this.rhinoPath,
  });
  @override
  State<NamingCamelScreen> createState() => _NamingCamelScreenState();
}

class _NamingCamelScreenState extends State<NamingCamelScreen> {
  FlutterSoundRecorder? _recorder = FlutterSoundRecorder();
  final AudioPlayer _instructionPlayer = AudioPlayer();
  final MocaApiService _apiService = MocaApiService();
  bool _isRecording = false;
  bool _isLoading = false;
  String? _camelPath;

  @override
  void initState() {
    super.initState();
    _recorder!.openRecorder();
    _playInstruction();
  }

  Future<void> _playInstruction() async {
    try {
      await _instructionPlayer.play(AssetSource('audio/naming.mp3'));
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _camelPath = path;
      });
    } else {
      await _instructionPlayer.stop();
      final dir = await getTemporaryDirectory();
      await _recorder!.startRecorder(
        toFile: '${dir.path}/camel.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );
      setState(() {
        _isRecording = true;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.checkNaming([
        widget.lionPath,
        widget.rhinoPath,
        _camelPath!,
      ]);
      TestSession.namingScore = res['score'] ?? 0;
      debugPrint("--- Naming Score: ${TestSession.namingScore} ---");
      if (mounted)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MemoryEncodingScreen()),
        );
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'آخر حيوان',
          content: Column(
            children: [
              Image.asset('assets/images/camel.png', height: 200),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _toggleRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                label: Text(_isRecording ? 'إيقاف' : 'تسجيل إجابة الجمل'),
              ),
            ],
          ),
          isNextEnabled: _camelPath != null && !_isRecording,
          onNext: _submit,
          onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
