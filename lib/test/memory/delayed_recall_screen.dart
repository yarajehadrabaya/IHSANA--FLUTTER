import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../orientation/orientation_screen.dart';

class DelayedRecallScreen extends StatefulWidget {
  const DelayedRecallScreen({super.key});
  @override
  State<DelayedRecallScreen> createState() => _DelayedRecallScreenState();
}

class _DelayedRecallScreenState extends State<DelayedRecallScreen> {
  final AudioPlayer _instructionPlayer = AudioPlayer();
  FlutterSoundRecorder? _recorder = FlutterSoundRecorder();
  final MocaApiService _apiService = MocaApiService();

  bool _isPlaying = false;
  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _isLoading = false;
  String? _recordedPath;

  @override
  void initState() {
    super.initState();
    _recorder!.openRecorder();
    _playInstruction(); // ✅ سيشتغل الصوت فوراً الآن
  }

  @override
  void dispose() {
    _instructionPlayer.dispose();
    _recorder?.closeRecorder();
    _recorder = null;
    super.dispose();
  }

  Future<void> _initRecorder() async {
    await _recorder!.openRecorder();
  }

  Future<void> _playInstruction() async {
    try {
      setState(() => _isPlaying = true);
      // ✅ التعديل: حذف كلمة assets
      await _instructionPlayer.play(AssetSource('audio/memory.mp3'));

      _instructionPlayer.onPlayerComplete.listen((event) {
        if (mounted) setState(() => _isPlaying = false);
      });
    } catch (e) {
      debugPrint("Error playing audio: $e");
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _recordAnswer() async {
    try {
      if (_isRecording) {
        final path = await _recorder!.stopRecorder();
        setState(() {
          _isRecording = false;
          _hasRecorded = true;
          _recordedPath = path;
        });
      } else {
        await _instructionPlayer.stop();
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/memory_recall_res.wav';
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
    } catch (e) {
      debugPrint("Recording Error: $e");
    }
  }

  Future<void> _submitAndNext() async {
    if (_recordedPath == null) return;
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.checkMemory(_recordedPath!);

      // ✅ [تحقق] طباعة النتيجة في الكونسول
      debugPrint("--- !!! MEMORY RESULT: ${result['score']} !!! ---");

      TestSession.memoryScore = (result['score'] as int? ?? 0);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrientationScreen()),
        );
      }
    } catch (e) {
      debugPrint("❌ API Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'استدعاء الكلمات',
          instruction: 'اذكر الكلمات الخمس التي سمعتها في بداية الاختبار.',
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.psychology_alt, size: 90, color: Colors.purple),
              const SizedBox(height: 30),
              if (!_isRecording && !_isLoading)
                TextButton.icon(
                  onPressed: _isPlaying ? null : _playInstruction,
                  icon: const Icon(Icons.replay),
                  label: const Text("إعادة سماع التعليمات"),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _recordAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? Colors.red : Colors.blue,
                  ),
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  label: Text(
                    _isRecording ? 'إيقاف التسجيل' : 'بدء تسجيل الإجابة',
                  ),
                ),
              ),
              if (_hasRecorded && !_isRecording)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('✅ تم التسجيل بنجاح'),
                ),
            ],
          ),
          isNextEnabled: _hasRecorded && !_isRecording && !_isLoading,
          onNext: _submitAndNext,
          onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
