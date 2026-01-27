import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../../test/widgets/test_question_scaffold.dart';
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
  FlutterSoundRecorder? _recorder;
  final MocaApiService _apiService = MocaApiService();

  bool _isRecording = false;
  bool _isLoading = false;
  bool _hwRecording = false;

  String? _recordedPath;

  @override
  void initState() {
    super.initState();

    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }

    _instructionPlayer.play(AssetSource('audio/abstraction1.mp3'));
  }

  @override
  void dispose() {
    _instructionPlayer.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }

  // ================= 📱 MOBILE =================
  Future<void> _recordFromMobile() async {
    if (_isRecording) {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });
      debugPrint('✅ ABSTRACTION Q1 MOBILE STOP: $path');
    } else {
      final dir = await getTemporaryDirectory();
      await _recorder!.startRecorder(
        toFile: '${dir.path}/abstraction1_mobile.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );

      setState(() {
        _isRecording = true;
        _recordedPath = null;
      });

      debugPrint('🎙️ ABSTRACTION Q1 MOBILE START');
    }
  }

  // ================= 🖥️ HARDWARE =================
  Future<void> _toggleHardwareRecording() async {
    if (_hwRecording) {
      setState(() => _isLoading = true);

      final res = await http.post(
        Uri.parse('${SessionContext.raspberryBaseUrl}/stop-recording'),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/abstraction1_hw.wav');
      await file.writeAsBytes(res.bodyBytes);

      setState(() {
        _recordedPath = file.path;
        _hwRecording = false;
        _isLoading = false;
      });

      debugPrint('✅ ABSTRACTION Q1 HW STOP: ${file.path}');
    } else {
      await http.post(
        Uri.parse('${SessionContext.raspberryBaseUrl}/start-recording'),
      );

      setState(() => _hwRecording = true);
      debugPrint('🎙️ ABSTRACTION Q1 HW START');
    }
  }

  // ================= 🚀 SUBMIT =================
  Future<void> _submit() async {
    if (_recordedPath == null) return;

    setState(() => _isLoading = true);

    final result =
        await _apiService.checkAbstraction(_recordedPath!, 1);

    final score = (result['score'] as int?) ?? 0;
    TestSession.abstractionScore = score;

    // ✅ طباعة النتيجة
    debugPrint('==============================');
    debugPrint('🧠 ABSTRACTION Q1 RESULT');
    debugPrint('FULL RESPONSE: $result');
    debugPrint('SCORE Q1: $score');
    debugPrint('==============================');

    setState(() => _isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AbstractionQuestionTwoScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHw = SessionContext.testMode == TestMode.hardware;

    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'التجريد (1/2)',
          instruction: isHw
              ? 'انطق الإجابة في ميكروفون الجهاز الخارجي'
              : 'ما وجه الشبه بين القطار والدراجة؟',
          content: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : isHw
                        ? _toggleHardwareRecording
                        : _recordFromMobile,
                icon: Icon(
                  isHw
                      ? Icons.settings_remote
                      : (_isRecording ? Icons.stop : Icons.mic),
                ),
                label: Text(
                  isHw
                      ? (_hwRecording ? 'إيقاف التسجيل' : 'بدء التسجيل')
                      : (_isRecording ? 'إيقاف التسجيل' : 'سجل إجابتك'),
                ),
              ),
              if (_recordedPath != null && !_isRecording)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    '✅ تم تسجيل الإجابة',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
            ],
          ),
          isNextEnabled: _recordedPath != null && !_isLoading,
          onNext: _submit,
          onEndSession: () =>
              Navigator.popUntil(context, (r) => r.isFirst),
        ),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
