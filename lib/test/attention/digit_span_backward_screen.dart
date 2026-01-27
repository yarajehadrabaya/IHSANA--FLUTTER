import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import 'letter_a_screen.dart';

class DigitSpanBackwardScreen extends StatefulWidget {
  const DigitSpanBackwardScreen({super.key});

  @override
  State<DigitSpanBackwardScreen> createState() =>
      _DigitSpanBackwardScreenState();
}

class _DigitSpanBackwardScreenState
    extends State<DigitSpanBackwardScreen> {
  final AudioPlayer _instructionPlayer = AudioPlayer();
  FlutterSoundRecorder? _recorder;
  final MocaApiService _apiService = MocaApiService();

  bool _isRecording = false;
  bool _isLoading = false;
  bool _isPlaying = false;
  String? _recordedPath;

  @override
  void initState() {
    super.initState();
    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }
    _playInstruction();
  }

  Future<void> _playInstruction() async {
    setState(() => _isPlaying = true);
    await _instructionPlayer.play(
      AssetSource('audio/backword.mp3'),
    );
    _instructionPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  Future<void> _onRecordPressed() async {
    if (SessionContext.testMode == TestMode.hardware) {
      await _recordFromHardware();
    } else {
      await _recordFromMobile();
    }
  }

  // 📱 MOBILE
  Future<void> _recordFromMobile() async {
    if (_isRecording) {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });
    } else {
      final dir = await getTemporaryDirectory();
      await _recorder!.startRecorder(
        toFile: '${dir.path}/digits_backward_mobile.wav',
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

  // 🖥️ HARDWARE
  Future<void> _recordFromHardware() async {
    final baseUrl = SessionContext.raspberryBaseUrl;

    if (_isRecording) {
      setState(() => _isLoading = true);
      try {
        await http.post(Uri.parse('$baseUrl/stop-recording'));
        final res = await http.get(Uri.parse('$baseUrl/get-audio'));

        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/digits_backward_hw.wav');
        await file.writeAsBytes(res.bodyBytes);

        setState(() {
          _recordedPath = file.path;
          _isRecording = false;
        });
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      await http.post(Uri.parse('$baseUrl/start-recording'));
      setState(() {
        _isRecording = true;
        _recordedPath = null;
      });
    }
  }

  // 🚀 SUBMIT
  Future<void> _submit() async {
    if (_recordedPath == null) return;

    setState(() => _isLoading = true);
    try {
      final result = await _apiService.checkAttention(
        _recordedPath!,
        "digits-backward",
      );

      final score = result['score'] ?? 0;
      final spokenText =
          result['text'] ?? result['transcript'] ?? '—';

      TestSession.backwardScore = score;

      debugPrint("========= DIGITS BACKWARD =========");
      debugPrint("🗣️ User said: $spokenText");
      debugPrint("⭐ Score: $score");
      debugPrint("📦 Full result: $result");
      debugPrint("==================================");

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LetterAScreen(),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'الأرقام بالعكس',
      content: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _isPlaying ? null : _playInstruction,
            icon: const Icon(Icons.volume_up),
            label: const Text("سماع الأرقام"),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed:
                (_isLoading || _isPlaying) ? null : _onRecordPressed,
            icon:
                Icon(_isRecording ? Icons.stop : Icons.mic),
            label: Text(
              _isRecording ? 'إيقاف التسجيل' : 'تسجيل الإجابة',
            ),
          ),
        ],
      ),
      isNextEnabled:
          _recordedPath != null && !_isRecording && !_isLoading,
      onNext: _submit,
      onEndSession: () =>
          Navigator.popUntil(context, (r) => r.isFirst),
    );
  }
}
