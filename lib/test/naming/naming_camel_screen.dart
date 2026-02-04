import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:ihsana/test/memory/memory_intro_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import '../../utils/test_session.dart';
import '../../utils/moca_api_service.dart';
import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';

class NamingCamelScreen extends StatefulWidget {
  final String lionPath;
  final String rhinoPath;

  const NamingCamelScreen({
    super.key,
    required this.lionPath,
    required this.rhinoPath,
  });

  @override
  State<NamingCamelScreen> createState() => _NamingCamelScreenState();
}

class _NamingCamelScreenState extends State<NamingCamelScreen> {
  FlutterSoundRecorder? _recorder;
  final MocaApiService _apiService = MocaApiService();
  final AudioPlayer _instructionPlayer = AudioPlayer(); // 🔊 مشغل التعليمات
  final AudioPlayer _actionAudioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isLoading = false;
  String? _camelPath;
  bool _isInstructionPlaying = false; // 🛡️ حالة التشغيل

  @override
  void initState() {
    super.initState();
    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }

    // 🔊 مراقبة انتهاء الصوت لإعادة إظهار زر الإعادة
    _instructionPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() => _isInstructionPlaying = false);
      }
    });

    _playInstruction();
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _instructionPlayer.dispose();
    _actionAudioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playInstruction() async {
    try {
      if (mounted) setState(() => _isInstructionPlaying = true);
      await _instructionPlayer.stop();
      await _instructionPlayer.play(
        AssetSource('audio/naming.mp3'),
      );
    } catch (_) {
      if (mounted) setState(() => _isInstructionPlaying = false);
    }
  }

  Future<void> _onRecordPressed() async {
    // إيقاف التعليمات فوراً عند بدء التسجيل
    if (_isInstructionPlaying) {
      await _instructionPlayer.stop();
      setState(() => _isInstructionPlaying = false);
    }

    if (SessionContext.testMode == TestMode.hardware) {
      if (_isRecording) {
        await _stopHardwareRecording();
      } else {
        await _startHardwareRecording();
      }
    } else {
      await _recordFromMobile();
    }
  }

  // ================= 📱 MOBILE RECORDING =================
  Future<void> _recordFromMobile() async {
    if (_isRecording) {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _camelPath = path;
      });
    } else {
      final dir = await getTemporaryDirectory();
      await _recorder!.startRecorder(
        toFile: '${dir.path}/camel_mobile.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );
      setState(() {
        _isRecording = true;
        _camelPath = null;
      });
    }
  }

  // ================= 🖥️ HARDWARE RECORDING =================
  Future<void> _startHardwareRecording() async {
    setState(() {
      _isRecording = true;
      _camelPath = null;
    });

    await http.post(
      Uri.parse('${SessionContext.raspberryBaseUrl}/start-recording'),
    );
  }

  Future<void> _stopHardwareRecording() async {
    setState(() => _isLoading = true);

    try {
      await http.post(
        Uri.parse('${SessionContext.raspberryBaseUrl}/stop-recording'),
      );

      final res = await http.get(
        Uri.parse('${SessionContext.raspberryBaseUrl}/get-audio'),
      );

      if (res.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/camel_hw.wav');
        await file.writeAsBytes(res.bodyBytes);

        setState(() {
          _camelPath = file.path;
          _isRecording = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= 🚀 ANALYZE =================
  Future<void> _submitAndAnalyze() async {
    _instructionPlayer.stop(); // إيقاف أي صوت قبل الانتقال
    setState(() => _isLoading = true);

    try {
      final result = await _apiService.checkNaming([
        widget.lionPath,
        widget.rhinoPath,
        _camelPath!,
      ]);

      TestSession.namingScore = result['score'] ?? 0;
      debugPrint("Score from API: ${result['score']}");
      debugPrint("Analysis: ${result['analysis']}");

      if (!mounted) return;
      TestSession.nextQuestion();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MemoryIntroScreen(),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== أصوات زر التسجيل =====
  Future<void> _playActionVoice(String asset) async {
    try {
      await _actionAudioPlayer.stop();
      await _actionAudioPlayer.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> _stopActionVoice() async {
    try {
      await _actionAudioPlayer.stop();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'آخر حيوان',
      // 🛡️ زر إعادة الاستماع يظهر فقط إذا لم يكن هناك صوت يعمل حالياً ولم نكن في وضع التسجيل
      onRepeatInstruction: (_isInstructionPlaying || _isRecording) 
          ? null 
          : _playInstruction,
      content: Column(
        children: [
          Image.asset(
            'assets/images/camel.png',
            height: 300, 
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),

          // ===== زر التسجيل (مع صوت) =====
          GestureDetector(
            onTapDown: (_) {
              if (_isRecording) {
                _playActionVoice('audio/stop_recording.mp3');
              } else if (_camelPath != null) {
                _playActionVoice('audio/retry_recording.mp3');
              } else {
                _playActionVoice('audio/start_recording.mp3');
              }
            },
            onTapUp: (_) => _stopActionVoice(),
            onTapCancel: _stopActionVoice,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _onRecordPressed,
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                ),
                label: Text(
                  _isRecording
                      ? 'إيقاف التسجيل'
                      : (_camelPath != null
                          ? 'إعادة التسجيل'
                          : 'تسجيل الإجابة'),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  backgroundColor: _isRecording ? Colors.red : null,
                  foregroundColor: _isRecording ? Colors.white : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),

          // ===== حالة جاري التسجيل =====
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: const [
                  Icon(
                    Icons.fiber_manual_record,
                    color: Colors.red,
                    size: 28,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'جاري التسجيل...',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),

          // ===== رسالة نجاح التسجيل =====
          if (_camelPath != null && !_isRecording) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'تم تسجيل الإجابة بنجاح',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      isNextEnabled:
          _camelPath != null && !_isRecording && !_isLoading,
      onNext: _submitAndAnalyze,
      onEndSession: () {
        _instructionPlayer.stop();
        Navigator.popUntil(context, (route) => route.isFirst);
      },
    );
  }
}