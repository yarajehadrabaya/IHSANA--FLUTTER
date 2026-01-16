import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import 'digit_span_backward_screen.dart';

class DigitSpanForwardScreen extends StatefulWidget {
  const DigitSpanForwardScreen({super.key});
  @override
  State<DigitSpanForwardScreen> createState() => _DigitSpanForwardScreenState();
}

class _DigitSpanForwardScreenState extends State<DigitSpanForwardScreen> {
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
    await _p.play(AssetSource('audio/forword.mp3')); // تطابق مع اسم ملفك
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
        toFile: '${dir.path}/fwd.wav',
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
    final res = await MocaApiService().checkAttention(_path!, "digits-forward");
    TestSession.forwardScore = res['score'] ?? 0;
    debugPrint("--- Forward Score: ${TestSession.forwardScore} ---");
    if (mounted)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DigitSpanBackwardScreen()),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'الأرقام للأمام',
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
