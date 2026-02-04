import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ihsana/test/orientation/orientation_intro_screen.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';

class DelayedRecallScreen extends StatefulWidget {
  const DelayedRecallScreen({super.key});

  @override
  State<DelayedRecallScreen> createState() => _DelayedRecallScreenState();
}

class _DelayedRecallScreenState extends State<DelayedRecallScreen> {
  final AudioPlayer _instructionPlayer = AudioPlayer();
  final AudioPlayer _btnSfxPlayer = AudioPlayer(); // 🆕 مشغل أصوات الأزرار الناطقة
  FlutterSoundRecorder? _recorder;
  final MocaApiService _apiService = MocaApiService();

  bool _isPlaying = false;
  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _isLoading = false;
  bool _hwRecording = false;
  bool _audioFinished = false; // 🆕 لمتابعة انتهاء الصوت للسكافولد

  String? _audioPath;

  @override
  void initState() {
    super.initState();

    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }

    // 🆕 تحميل الملفات مسبقاً في الذاكرة لضمان التشغيل الفوري عند الضغط
    _preloadSfx();

    // 🆕 ربط المستمع لتحديث حالة السكافولد
    _instructionPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _audioFinished = true;
        });
      }
    });

    _playInstruction();
  }

  // 🆕 دالة تحميل الأصوات مسبقاً (تستخدم الأسماء الفعلية للملفات المرفوعة)
  Future<void> _preloadSfx() async {
    try {
      await _btnSfxPlayer.setSource(AssetSource('audio/start_recording.mp3'));
      await _btnSfxPlayer.setSource(AssetSource('audio/stop_recording.mp3'));
      await _btnSfxPlayer.setSource(AssetSource('audio/retry_recording.mp3'));
    } catch (e) {
      debugPrint('Error preloading sfx: $e');
    }
  }

  @override
  void dispose() {
    _instructionPlayer.dispose();
    _btnSfxPlayer.dispose(); // 🆕
    _recorder?.closeRecorder();
    super.dispose();
  }

  // ================= 🔊 INSTRUCTION =================
  Future<void> _playInstruction() async {
    try {
      setState(() {
        _isPlaying = true;
        _audioFinished = false;
      });
      await _instructionPlayer.stop(); // تأمين التوقف قبل البدء
      await _instructionPlayer.play(
        AssetSource('audio/memory.mp3'),
      );
    } catch (e) {
      debugPrint('❌ Instruction error: $e');
      setState(() => _isPlaying = false);
    }
  }

  // ================= 🎤 RECORD BUTTON =================
  Future<void> _onRecordPressed() async {
    if (SessionContext.testMode == TestMode.hardware) {
      await _toggleHardwareRecording();
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
        _hasRecorded = true;
        _audioPath = path;
      });
    } else {
      await _instructionPlayer.stop();
      final dir = await getTemporaryDirectory();

      await _recorder!.startRecorder(
        toFile: '${dir.path}/memory_mobile.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );

      setState(() {
        _isRecording = true;
        _hasRecorded = false;
        _audioPath = null;
      });
    }
  }

  // ================= 🖥️ HARDWARE =================
  Future<void> _toggleHardwareRecording() async {
    if (_hwRecording) {
      setState(() => _isLoading = true);

      try {
        await http.post(
          Uri.parse('${SessionContext.raspberryBaseUrl}/stop-recording'),
        );

        final res = await http.get(
          Uri.parse('${SessionContext.raspberryBaseUrl}/get-audio'),
        );

        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/memory_hw.wav');
        await file.writeAsBytes(res.bodyBytes);

        setState(() {
          _audioPath = file.path;
          _hasRecorded = true;
          _hwRecording = false;
        });
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      await _instructionPlayer.stop();
      await http.post(
        Uri.parse('${SessionContext.raspberryBaseUrl}/start-recording'),
      );

      setState(() {
        _hwRecording = true;
        _hasRecorded = false;
      });
    }
  }

  // ================= 🚀 SUBMIT =================
  Future<void> _submitAndNext() async {
    if (_audioPath == null) return;

    setState(() => _isLoading = true);

    try {
      final res = await _apiService.checkMemory(_audioPath!);
      TestSession.memoryScore = res['score'] ?? 0;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const OrientationIntroScreen(),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final bool isHardware = SessionContext.testMode == TestMode.hardware;

    // 🆕 منطق الصوت الناطق (البدء / الإيقاف / إعادة التسجيل) مع مطابقة اسم الملف المرفوع
    String recordingSfx;
    if (_isRecording || _hwRecording) {
      recordingSfx = 'audio/stop_recording.mp3';
    } else if (_hasRecorded) {
      recordingSfx = 'audio/retry_recording.mp3'; // تم التعديل ليطابق الملف المرفوع
    } else {
      recordingSfx = 'audio/start_recording.mp3';
    }

    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'استدعاء الكلمات',
          instruction: isHardware
              ? 'اذكر الكلمات الخمس في ميكروفون الجهاز الخارجي.'
              : 'اذكر الكلمات الخمس التي سمعتها في بداية الاختبار.',
          // 🆕 زر إعادة الاستماع يظهر عند انتهاء الصوت وعدم وجود تسجيل
          onRepeatInstruction: (_audioFinished && !_isRecording && !_hwRecording)
              ? _playInstruction
              : null,
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ===== CARD =====
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
                    const Icon(
                      Icons.psychology_alt,
                      size: 110,
                      color: Color.fromARGB(255, 100, 138, 226),
                    ),

                    const SizedBox(height: 20),

                 

                    // ===== زر التسجيل =====
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        // 🆕 حل مشكلة الصوت: استخدام Low Latency للتشغيل الفوري
                        onLongPressStart: (_) {
                          if (_audioFinished && !_isLoading) {
                            _btnSfxPlayer.play(AssetSource(recordingSfx), mode: PlayerMode.lowLatency);
                          }
                        },
                        onLongPressEnd: (_) => _btnSfxPlayer.stop(),
                        child: ElevatedButton.icon(
                          // 🆕 معطل أثناء الأوتو ربلاي
                          onPressed: (_isLoading || _isPlaying) ? null : _onRecordPressed,
                          icon: Icon(
                            isHardware
                                ? Icons.settings_remote
                                : (_isRecording ? Icons.stop : Icons.mic),
                          ),
                          label: Text(
                            isHardware
                                ? (_hwRecording
                                    ? 'إيقاف التسجيل'
                                    : (_hasRecorded ? 'إعادة التسجيل' : 'بدء التسجيل'))
                                : (_isRecording
                                    ? 'إيقاف التسجيل'
                                    : (_hasRecorded ? 'إعادة تسجيل الإجابة' : 'بدء تسجيل الإجابة')),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor:
                                _isRecording || _hwRecording
                                    ? Colors.red
                                    : null,
                            foregroundColor:
                                _isRecording || _hwRecording
                                    ? Colors.white
                                    : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ===== حالة التسجيل =====
                    if (_isRecording || _hwRecording)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Column(
                          children: [
                            Icon(Icons.fiber_manual_record,
                                color: Colors.red, size: 28),
                            SizedBox(height: 6),
                            Text(
                              'جاري التسجيل...',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_hasRecorded)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'تم تسجيل الإجابة بنجاح',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          isNextEnabled: _hasRecorded && !_isLoading,
          onNext: _submitAndNext,
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