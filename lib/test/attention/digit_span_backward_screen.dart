import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import 'letter_a_screen.dart';

class DigitSpanBackwardScreen extends StatefulWidget {
  const DigitSpanBackwardScreen({super.key});
  @override
  State<DigitSpanBackwardScreen> createState() =>
      _DigitSpanBackwardScreenState();
}

class _DigitSpanBackwardScreenState extends State<DigitSpanBackwardScreen> {
  final AudioPlayer _p = AudioPlayer();
  FlutterSoundRecorder? _r = FlutterSoundRecorder();
  bool _isRec = false, _hasRec = false, _load = false, _isPlay = false;
  String? _path;

  @override
  void initState() {
    super.initState();
    _r!.openRecorder();
    _play();
  }

  Future<void> _play() async {
    setState(() => _isPlay = true);
    await _p.play(AssetSource('audio/backword.mp3'));
    _p.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlay = false);
    });
  }

  Future<void> _rec() async {
    if (_isRec) {
      _path = await _r!.stopRecorder();
      setState(() {
        _isRec = false;
        _hasRec = true;
      });
    } else {
      final dir = await getTemporaryDirectory();
      await _r!.startRecorder(
        toFile: '${dir.path}/bwd.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );
      setState(() {
        _isRec = true;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _load = true);
    final res = await MocaApiService().checkAttention(
      _path!,
      "digits-backward",
    );
    TestSession.backwardScore = res['score'] ?? 0;
    debugPrint("--- Backward Score: ${TestSession.backwardScore} ---");
    if (mounted)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LetterAScreen()),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'الأرقام بالعكس',
          content: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _isPlay ? null : _play,
                icon: const Icon(Icons.volume_up),
                label: const Text("سماع الأرقام"),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isPlay ? null : _rec,
                icon: Icon(_isRec ? Icons.stop : Icons.mic),
                label: Text(_isRec ? "إيقاف" : "تسجيل إجابتك"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRec ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          isNextEnabled: _hasRec && !_isRec && !_load,
          onNext: _submit,
          onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        if (_load) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
