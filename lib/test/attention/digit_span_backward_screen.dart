import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

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

class _DigitSpanBackwardScreenState extends State<DigitSpanBackwardScreen> {
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

    // 📱 نفتح المايك فقط في وضع الجوال
    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }

    _playInstruction();
  }

  // 🔊 تشغيل الأرقام
  Future<void> _playInstruction() async {
    setState(() => _isPlaying = true);
    await _instructionPlayer.play(
      AssetSource('audio/backword.mp3'),
    );
    _instructionPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  // 🎤 زر التسجيل الموحد
  Future<void> _onRecordPressed() async {
    if (SessionContext.testMode == TestMode.hardware) {
      await _recordFromHardware();
    } else {
      await _recordFromMobile();
    }
  }

  // ================= 📱 MOBILE =================
  Future<void> _recordFromMobile() async {
    if (_isRecording) {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });
      debugPrint("✅ Mobile backward record stopped: $path");
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
      debugPrint("🎙️ Mobile backward recording started...");
    }
  }

  // ================= 🖥️ HARDWARE =================
  Future<void> _recordFromHardware() async {
    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse('${SessionContext.raspberryBaseUrl}/get-audio');
      debugPrint("[HARDWARE] Requesting backward audio from $uri");

      final res = await HttpClient()
          .getUrl(uri)
          .then((req) => req.close());

      if (res.statusCode != 200) {
        throw Exception("Hardware error ${res.statusCode}");
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/digits_backward_hw.wav');
      final bytes = await consolidateHttpClientResponseBytes(res);
      await file.writeAsBytes(bytes);

      setState(() {
        _recordedPath = file.path;
      });

      debugPrint("✅ Hardware backward audio received");
    } catch (e) {
      debugPrint("❌ Backward hardware error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في التسجيل من الجهاز الخارجي'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= 🚀 SUBMIT =================
  Future<void> _submit() async {
    if (_recordedPath == null) return;

    setState(() => _isLoading = true);
    try {
      final result = await _apiService.checkAttention(
        _recordedPath!,
        "digits-backward",
      );

      TestSession.backwardScore = result['score'] ?? 0;

      debugPrint("=================================");
      debugPrint("🧠 DIGIT SPAN BACKWARD RESULT");
      debugPrint("Score: ${result['score']}");
      debugPrint("Analysis: ${result['analysis']}");
      debugPrint("=================================");

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LetterAScreen(),
        ),
      );
    } catch (e) {
      debugPrint("Submit error: $e");
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

  @override
  Widget build(BuildContext context) {
    final bool isHardware = SessionContext.testMode == TestMode.hardware;

    return Stack(
      children: [
        TestQuestionScaffold(
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
                onPressed: (_isLoading || _isPlaying)
                    ? null
                    : _onRecordPressed,
                icon: Icon(
                  isHardware
                      ? Icons.settings_remote
                      : (_isRecording ? Icons.stop : Icons.mic),
                ),
                label: Text(
                  isHardware
                      ? 'التقاط الصوت من الجهاز'
                      : (_isRecording ? 'إيقاف التسجيل' : 'تسجيل إجابتك'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              if (_recordedPath != null && !_isRecording)
                const Text(
                  '✅ تم تسجيل الإجابة',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          isNextEnabled:
              _recordedPath != null && !_isRecording && !_isLoading,
          onNext: _submit,
          onEndSession: () =>
              Navigator.popUntil(context, (r) => r.isFirst),
        ),

        if (_isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
