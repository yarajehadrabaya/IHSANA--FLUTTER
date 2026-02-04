import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/language/language_intro_screen.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';

class SubtractionScreen extends StatefulWidget {
  const SubtractionScreen({super.key});

  @override
  State<SubtractionScreen> createState() => _SubtractionScreenState();
}

class _SubtractionScreenState extends State<SubtractionScreen> {
  final AudioPlayer _instructionPlayer = AudioPlayer();
  final AudioPlayer _btnSfxPlayer = AudioPlayer(); // مشغل أصوات الأزرار
  FlutterSoundRecorder? _recorder;
  final MocaApiService _apiService = MocaApiService();

  bool _isRecording = false;
  bool _isLoading = false;
  String? _recordedPath;
  bool _showRepeatButton = false; // التحكم في زر الإعادة بالسكافولد

  @override
  void initState() {
    super.initState();

    // ===== DEBUG =====
    debugPrint('🟢 [SUBTRACTION] Screen opened');
    debugPrint('🧪 TestMode = ${SessionContext.testMode}');

    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }

    // مراقبة انتهاء صوت التعليمات لإظهار زر الإعادة
    _instructionPlayer.onPlayerComplete.listen((_) {
      if (mounted && !_isRecording) {
        setState(() => _showRepeatButton = true);
      }
    });

    _playInstruction();
  }

  Future<void> _playInstruction() async {
    // ===== DEBUG =====
    debugPrint('🔊 Playing subtraction instruction audio');
    setState(() => _showRepeatButton = false);
    await _instructionPlayer.play(
      AssetSource('audio/subtraction.mp3'),
    );
  }

  Future<void> _onRecordPressed() async {
    // ===== DEBUG =====
    debugPrint('🎤 Record button pressed');
    debugPrint('🎤 isRecording BEFORE = $_isRecording');

    // إيقاف أي تعليمات صوتية عند بدء التسجيل
    await _instructionPlayer.stop();
    setState(() => _showRepeatButton = false);

    if (SessionContext.testMode == TestMode.hardware) {
      await _recordFromHardware();
    } else {
      await _recordFromMobile();
    }
  }

  // ================= 📱 MOBILE =================
  Future<void> _recordFromMobile() async {
    if (_isRecording) {
      // ===== DEBUG =====
      debugPrint('⛔ [MOBILE] STOP recording');

      final path = await _recorder!.stopRecorder();

      // ===== DEBUG =====
      debugPrint('📁 [MOBILE] Audio saved at: $path');

      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });
    } else {
      // ===== DEBUG =====
      debugPrint('▶️ [MOBILE] START recording');

      final dir = await getTemporaryDirectory();
      await _instructionPlayer.stop();

      await _recorder!.startRecorder(
        toFile: '${dir.path}/subtraction_mobile.wav',
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

  // ================= 🖥️ HARDWARE =================
  Future<void> _recordFromHardware() async {
    final baseUrl = SessionContext.raspberryBaseUrl;

    if (_isRecording) {
      // ===== DEBUG =====
      debugPrint('⛔ [HW] STOP recording');

      setState(() => _isLoading = true);
      try {
        await http.post(Uri.parse('$baseUrl/stop-recording'));
        final res = await http.get(Uri.parse('$baseUrl/get-audio'));

        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/subtraction_hw.wav');
        await file.writeAsBytes(res.bodyBytes);

        // ===== DEBUG =====
        debugPrint('📁 [HW] Audio saved at: ${file.path}');

        setState(() {
          _recordedPath = file.path;
          _isRecording = false;
        });
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // ===== DEBUG =====
      debugPrint('▶️ [HW] START recording');

      await _instructionPlayer.stop();
      await http.post(Uri.parse('$baseUrl/start-recording'));

      setState(() {
        _isRecording = true;
        _recordedPath = null;
      });
    }
  }

  // ================= 🚀 SUBMIT =================
  Future<void> _submit() async {
    if (_recordedPath == null) return;

    // ===== DEBUG =====
    debugPrint('🚀 Submitting subtraction audio for analysis');
    debugPrint('📤 Audio path = $_recordedPath');

    setState(() => _isLoading = true);
    try {
      final result = await _apiService.checkAttention(
        _recordedPath!,
        "subtraction",
      );

      // ===== DEBUG =====
      debugPrint('📊 Analysis result = $result');
      debugPrint('⭐ Score = ${result['score']}');

      TestSession.subtractionScore = result['score'] ?? 0;
        
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LanguageIntroScreen(),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _instructionPlayer.dispose();
    _btnSfxPlayer.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHardware = SessionContext.testMode == TestMode.hardware;

    // تحديد ملف صوت الزر بناءً على الحالة الحالية
    String sfxPath = _isRecording 
        ? 'audio/stop_recording.mp3' 
        : (_recordedPath != null ? 'audio/retry_recording.mp3' : 'audio/start_recording.mp3');

    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'الطرح من 100',
          instruction: isHardware
              ? 'اضغط بدء ثم أنهِ التسجيل من الجهاز الخارجي'
              : 'اطرح 7 من 100 خمس مرات متتالية',
          onRepeatInstruction: _showRepeatButton ? _playInstruction : null,
          content: Center(
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calculate,
                      size: 64,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'ابدأ الإجابة صوتيًا',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onLongPressStart: (_) => _btnSfxPlayer.play(AssetSource(sfxPath)),
                        onLongPressEnd: (_) => _btnSfxPlayer.stop(),
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _onRecordPressed,
                          icon: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                          ),
                          label: Text(
                            _isRecording
                                ? 'إيقاف التسجيل'
                                : (_recordedPath != null
                                    ? 'إعادة التسجيل'
                                    : 'بدء التسجيل'),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor:
                                _isRecording ? Colors.red : null,
                            foregroundColor:
                                _isRecording ? Colors.white : null,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (_isRecording)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          children: const [
                            Icon(Icons.fiber_manual_record,
                                color: Colors.red, size: 28),
                            SizedBox(height: 6),
                            Text('جاري التسجيل...',
                                style:
                                    TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),

                    if (_recordedPath != null && !_isRecording) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 14),
                        decoration: BoxDecoration(
                          color:
                              Colors.green.withOpacity(0.08),
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                Colors.green.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.check_circle,
                                color: Colors.green),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'تم تسجيل الإجابة بنجاح',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
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