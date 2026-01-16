import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../abstraction/abstraction_question_one_screen.dart';

class VerbalFluencyScreen extends StatefulWidget {
  const VerbalFluencyScreen({super.key});
  @override
  State<VerbalFluencyScreen> createState() => _VerbalFluencyScreenState();
}

class _VerbalFluencyScreenState extends State<VerbalFluencyScreen> {
  int _sec = 60;
  Timer? _t;
  final AudioPlayer _p = AudioPlayer();
  FlutterSoundRecorder? _r = FlutterSoundRecorder();
  bool _isRun = false, _isFin = false, _load = false;
  String? _path;

  @override
  void initState() {
    super.initState();
    _r!.openRecorder();
    _play();
  }

  Future<void> _play() async {
    await _p.play(AssetSource('audio/fluency.mp3'));
  }

  Future<void> _start() async {
    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/flu.wav';
    await _r!.startRecorder(
      toFile: _path,
      codec: Codec.pcm16WAV,
      sampleRate: 16000,
      numChannels: 1,
    );
    setState(() {
      _isRun = true;
      _isFin = false;
      _sec = 60;
    });
    _t = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sec == 0) {
        timer.cancel();
        _stop();
      } else {
        setState(() => _sec--);
      }
    });
  }

  Future<void> _stop() async {
    await _r!.stopRecorder();
    setState(() {
      _isRun = false;
      _isFin = true;
    });
  }

  Future<void> _submit() async {
    setState(() => _load = true);
    final res = await MocaApiService().checkFluency(_path!);
    TestSession.fluencyScore = res['score'] ?? 0;
    debugPrint("--- Fluency Score: ${TestSession.fluencyScore} ---");
    if (mounted)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AbstractionQuestionOneScreen()),
      );
  }

  @override
  void dispose() {
    _t?.cancel();
    _p.dispose();
    _r?.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'الطلاقة اللفظية',
          content: Column(
            children: [
              Text(
                "$_sec",
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isRun || _isFin ? null : _start,
                icon: const Icon(Icons.mic),
                label: const Text("ابدأ الدقيقة"),
              ),
            ],
          ),
          isNextEnabled: _isFin && !_load,
          onNext: _submit,
          onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        if (_load) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
