import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../language/sentence_repetition_screen_one.dart';

class SubtractionScreen extends StatefulWidget {
  const SubtractionScreen({super.key});
  @override
  State<SubtractionScreen> createState() => _SubtractionScreenState();
}

class _SubtractionScreenState extends State<SubtractionScreen> {
  final AudioPlayer _p = AudioPlayer();
  FlutterSoundRecorder? _r = FlutterSoundRecorder();
  bool _isRec = false, _isPause = false, _load = false;
  String? _path;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _r!.openRecorder();
    _play();
  }

  Future<void> _play() async {
    await _p.play(AssetSource('audio/subtraction.mp3'));
  }

  Future<void> _handleRec() async {
    if (!_isRec) {
      final dir = await getTemporaryDirectory();
      _path = '${dir.path}/sub.wav';
      await _r!.startRecorder(
        toFile: _path,
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );
      setState(() {
        _isRec = true;
        _isPause = false;
      });
    } else {
      if (!_isPause && _r!.isRecording) {
        await _r!.pauseRecorder();
        setState(() {
          _isPause = true;
          _count++;
        });
      } else {
        await _r!.resumeRecorder();
        setState(() {
          _isPause = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    setState(() => _load = true);
    final path = await _r!.stopRecorder();
    final res = await MocaApiService().checkAttention(path!, "subtraction");
    TestSession.subtractionScore = res['score'] ?? 0;
    debugPrint("--- Subtraction Score: ${TestSession.subtractionScore} ---");
    if (mounted)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SentenceRepetitionOneScreen()),
      );
  }

  @override
  void dispose() {
    _p.dispose();
    _r?.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'الطرح من 100',
          content: Column(
            children: [
              Text("الأرقام: $_count / 5"),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _handleRec,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: !_isRec
                      ? Colors.blue
                      : (_isPause ? Colors.orange : Colors.red),
                  child: Icon(
                    !_isRec
                        ? Icons.mic
                        : (_isPause ? Icons.play_arrow : Icons.pause),
                    color: Colors.white,
                  ),
                ),
              ),
              if (_isRec)
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text("إنهاء وإرسال"),
                ),
            ],
          ),
          isNextEnabled: false,
          onNext: () {},
          onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        if (_load) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
