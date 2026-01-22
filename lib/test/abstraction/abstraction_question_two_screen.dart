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
import '../memory/delayed_recall_screen.dart';

class AbstractionQuestionTwoScreen extends StatefulWidget {
  const AbstractionQuestionTwoScreen({super.key});

  @override
  State<AbstractionQuestionTwoScreen> createState() =>
      _AbstractionQuestionTwoScreenState();
}

class _AbstractionQuestionTwoScreenState
    extends State<AbstractionQuestionTwoScreen> {
  final AudioPlayer _instructionPlayer = AudioPlayer();
  FlutterSoundRecorder? _recorder;
  final MocaApiService _apiService = MocaApiService();

  bool _isRecording = false;
  bool _isLoading = false;
  String? _recordedPath;

  @override
  void initState() {
    super.initState();

    // 📱 فتح المايك فقط في وضع الجوال
    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }

    _playInstruction();
  }

  Future<void> _playInstruction() async {
    try {
      await _instructionPlayer.play(
        AssetSource('audio/abstraction2.mp3'),
      );
    } catch (e) {
      debugPrint("Instruction audio error: $e");
    }
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
      debugPrint("✅ Mobile record stopped: $path");
    } else {
      final dir = await getTemporaryDirectory();
      await _instructionPlayer.stop();

      await _recorder!.startRecorder(
        toFile: '${dir.path}/abstraction2_mobile.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );

      setState(() {
        _isRecording = true;
        _recordedPath = null;
      });
      debugPrint("🎙️ Mobile recording started...");
    }
  }

  // ================= 🖥️ HARDWARE =================
  Future<void> _recordFromHardware() async {
    setState(() => _isLoading = true);
    await _instructionPlayer.stop();

    try {
      final uri = Uri.parse('${SessionContext.raspberryBaseUrl}/get-audio');
      debugPrint("[HARDWARE] Requesting audio from $uri");

      final res = await HttpClient()
          .getUrl(uri)
          .then((req) => req.close());

      if (res.statusCode != 200) {
        throw Exception("Hardware error ${res.statusCode}");
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/abstraction2_hw.wav');
      final bytes = await consolidateHttpClientResponseBytes(res);
      await file.writeAsBytes(bytes);

      setState(() {
        _recordedPath = file.path;
      });

      debugPrint("✅ Hardware audio received: ${file.path}");
    } catch (e) {
      debugPrint("❌ Hardware record failed: $e");
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
  Future<void> _submitAndNext() async {
    if (_recordedPath == null) return;

    setState(() => _isLoading = true);
    try {
      final result = await _apiService.checkAbstraction(_recordedPath!, 2);

      // جمع نتيجة السؤالين
      TestSession.abstractionScore +=
          (result['score'] as int? ?? 0);

      debugPrint("=================================");
      debugPrint("🧠 ABSTRACTION Q2 RESULT");
      debugPrint("Score: ${result['score']}");
      debugPrint("Total Abstraction Score: ${TestSession.abstractionScore}");
      debugPrint("Analysis: ${result['analysis']}");
      debugPrint("=================================");

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DelayedRecallScreen(),
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
          title: 'التجريد (2/2)',
          instruction: isHardware
              ? 'انطق الإجابة في ميكروفون الجهاز الخارجي'
              : 'ما وجه الشبه بين الساعة والمسطرة؟',
          content: Column(
            children: [
              const Icon(
                Icons.straighten,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _onRecordPressed,
                icon: Icon(
                  isHardware
                      ? Icons.settings_remote
                      : (_isRecording ? Icons.stop : Icons.mic),
                ),
                label: Text(
                  isHardware
                      ? 'التقاط الصوت من الجهاز'
                      : (_isRecording ? 'إيقاف التسجيل' : 'سجل إجابتك'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : null,
                  foregroundColor: _isRecording ? Colors.white : null,
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
          onNext: _submitAndNext,
          onEndSession: () =>
              Navigator.popUntil(context, (r) => r.isFirst),
        ),

        if (_isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'جاري معالجة الصوت...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
