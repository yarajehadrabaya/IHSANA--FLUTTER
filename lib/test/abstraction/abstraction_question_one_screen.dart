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
  final AudioPlayer _btnSfxPlayer = AudioPlayer(); // 🆕 مشغل أصوات الأزرار الناطقة
  FlutterSoundRecorder? _recorder;
  final MocaApiService _apiService = MocaApiService();

  bool _isRecording = false;
  bool _isLoading = false;
  bool _hwRecording = false;
  bool _audioFinished = false; // 🆕 لمتابعة انتهاء صوت التعليمات

  String? _recordedPath;

  @override
  void initState() {
    super.initState();

    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }

    _playInstruction(); // 🆕 استدعاء دالة التشغيل
  }

  // 🆕 دالة تشغيل التعليمات ومراقبة انتهائها
  Future<void> _playInstruction() async {
    setState(() => _audioFinished = false);
    await _instructionPlayer.play(AssetSource('audio/abstraction1.mp3'));
    _instructionPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _audioFinished = true);
    });
  }

  @override
  void dispose() {
    _instructionPlayer.dispose();
    _btnSfxPlayer.dispose();
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

    final result = await _apiService.checkAbstraction(_recordedPath!, 1);

    final score = (result['score'] as int?) ?? 0;
    TestSession.abstractionScore = score;
    debugPrint("Score from API: ${result['score']}");
      debugPrint("Analysis: ${result['analysis']}");

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
    
    // 🆕 تحديد صوت الزر بناءً على الحالة
    String recordingSfx = (_isRecording || _hwRecording) 
        ? 'audio/stop_recording.mp3' 
        : 'audio/start_recording.mp3';

    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'التجريد (1/2)',
          instruction: isHw
              ? 'انطق الإجابة في ميكروفون الجهاز الخارجي'
              : 'ما وجه الشبه بين القطار والدراجة؟',
          // 🆕 زر إعادة التشغيل يظهر فقط عند انتهاء الصوت وعدم وجود تسجيل جاري
          onRepeatInstruction: (_audioFinished && !_isRecording && !_hwRecording) 
              ? _playInstruction 
              : null,
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.compare_arrows,
                      size: 64,
                      color: Colors.blue.shade600,
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'سجّل إجابتك صوتيًا',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 24),

                    // ===== 🆕 SPEAKING RECORD BUTTON =====
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onLongPressStart: (_) {
                          if (_audioFinished && !_isLoading) {
                            _btnSfxPlayer.play(AssetSource(recordingSfx));
                          }
                        },
                        onLongPressEnd: (_) => _btnSfxPlayer.stop(),
                        child: ElevatedButton.icon(
                          onPressed: (_isLoading || !_audioFinished) // معطل أثناء الأوتو بلاي
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
                                : (_isRecording ? 'إيقاف التسجيل' : 'سجّل إجابتك'),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: (_isRecording || _hwRecording) ? Colors.red : null,
                            foregroundColor: (_isRecording || _hwRecording) ? Colors.white : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (_isRecording || _hwRecording)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Column(
                          children: [
                            Icon(Icons.fiber_manual_record, color: Colors.red, size: 28),
                            SizedBox(height: 6),
                            Text(
                              'جاري التسجيل...',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),

                    if (_recordedPath != null && !_isRecording && !_hwRecording)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'تم تسجيل الإجابة بنجاح',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          isNextEnabled: _recordedPath != null && !_isLoading,
          onNext: _submit,
          onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),

        if (_isLoading)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}