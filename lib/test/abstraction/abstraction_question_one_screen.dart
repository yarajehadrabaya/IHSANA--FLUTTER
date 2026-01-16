import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import 'abstraction_question_two_screen.dart';

class AbstractionQuestionOneScreen extends StatefulWidget {
  const AbstractionQuestionOneScreen({super.key});
  @override
  State<AbstractionQuestionOneScreen> createState() =>
      _AbstractionQuestionOneScreenState();
}

class _AbstractionQuestionOneScreenState
    extends State<AbstractionQuestionOneScreen> {
  final AudioPlayer _instructionPlayer = AudioPlayer();
  FlutterSoundRecorder? _recorder = FlutterSoundRecorder();
  final MocaApiService _apiService = MocaApiService();

  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _isLoading = false;
  String? _recordedPath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _playInstruction();
  }

  Future<void> _playInstruction() async {
    try {
      // ✅ التعديل: حذف كلمة assets
      await _instructionPlayer.play(AssetSource('audio/abstraction1.mp3'));
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }

  Future<void> _recordAnswer() async {
    if (_isRecording) {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _hasRecorded = true;
        _recordedPath = path;
      });
    } else {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/abs1.wav';
      await _recorder!.startRecorder(
        toFile: path,
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );
      setState(() {
        _isRecording = true;
        _recordedPath = null;
      });
    }
  }

  Future<void> _submitAndNext() async {
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.checkAbstraction(_recordedPath!, 1);
      debugPrint("--- ABS 1 RESULT: ${result['score']} ---");
      TestSession.abstractionScore =
          (result['score'] as int? ?? 0); // أول نتيجة

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AbstractionQuestionTwoScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _instructionPlayer.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }

  Future<void> _initRecorder() async {
    await _recorder!.openRecorder();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'التجريد (1/2)',
          instruction: 'ما وجه الشبه بين القطار والدراجة؟',
          content: Column(
            children: [
              const Icon(
                Icons.directions_transit,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _recordAnswer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                ),
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                label: Text(_isRecording ? 'إيقاف التسجيل' : 'سجل إجابتك'),
              ),
            ],
          ),
          isNextEnabled: _hasRecorded && !_isRecording,
          onNext: _submitAndNext,
          onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
