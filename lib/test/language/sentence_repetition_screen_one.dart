import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';
import 'sentence_repetition_screen_two.dart';

class SentenceRepetitionOneScreen extends StatefulWidget {
  const SentenceRepetitionOneScreen({super.key});

  @override
  State<SentenceRepetitionOneScreen> createState() =>
      _SentenceRepetitionOneScreenState();
}

class _SentenceRepetitionOneScreenState
    extends State<SentenceRepetitionOneScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _instructionPlayer = AudioPlayer();
  final AudioPlayer _btnSfxPlayer = AudioPlayer(); // مشغل أصوات الأزرار
  FlutterSoundRecorder? _recorder;
  final MocaApiService _apiService = MocaApiService();

  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _isLoading = false;
  bool _isPlaying = false;
  bool _audioFinished = false;
  bool _hasPlayedOnce = false;

  String? _audioPath;

  // ===== Controller لنبض السماعة (بدون Animation late) =====
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _instructionPlayer.dispose();
    _btnSfxPlayer.dispose();
    _recorder?.closeRecorder();
    super.dispose();
  }

  // ================= 🔊 تشغيل الجملة (مرة واحدة فقط) =================
  Future<void> _playInstruction() async {
    setState(() {
      _isPlaying = true;
      _audioFinished = false;
      _hasPlayedOnce = true;
    });

    _pulseController.repeat(reverse: true);

    await _instructionPlayer.play(
      AssetSource('audio/sentance1.mp3'),
    );

    _instructionPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      _pulseController.stop();
      setState(() {
        _isPlaying = false;
        _audioFinished = true;
      });
    });
  }

  // ================= 🎤 زر التسجيل =================
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
        _hasRecorded = true;
        _audioPath = path;
      });
      debugPrint("🎙️ SENTENCE 1 MOBILE STOP: $path");
    } else {
      final dir = await getTemporaryDirectory();
      await _instructionPlayer.stop();

      await _recorder!.startRecorder(
        toFile: '${dir.path}/sentence1_mobile.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );

      setState(() {
        _isRecording = true;
        _hasRecorded = false;
        _audioPath = null;
      });
      debugPrint("🎙️ SENTENCE 1 MOBILE START");
    }
  }

  // ================= 🖥️ HARDWARE =================
  Future<void> _recordFromHardware() async {
    final baseUrl = SessionContext.raspberryBaseUrl;

    if (_isRecording) {
      setState(() => _isLoading = true);
      try {
        await http.post(Uri.parse('$baseUrl/stop-recording'));
        final res = await http.get(Uri.parse('$baseUrl/get-audio'));

        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/sentence1_hw.wav');
        await file.writeAsBytes(res.bodyBytes);

        setState(() {
          _audioPath = file.path;
          _isRecording = false;
          _hasRecorded = true;
        });

        debugPrint("🎙️ SENTENCE 1 HW SAVED: ${file.path}");
      } catch (e) {
        debugPrint("❌ SENTENCE 1 HW STOP ERROR: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      await _instructionPlayer.stop();
      await http.post(Uri.parse('$baseUrl/start-recording'));

      setState(() {
        _isRecording = true;
        _hasRecorded = false;
        _audioPath = null;
      });

      debugPrint("🎙️ SENTENCE 1 HW START");
    }
  }

  // ================= 🚀 SUBMIT =================
  Future<void> _submit() async {
    if (_audioPath == null) return;

    setState(() => _isLoading = true);
    try {
      final res = await _apiService.checkSentence1(_audioPath!);

      final score = res['score'] ?? 0;
      final text = res['text'] ?? res['transcript'] ?? '—';

      TestSession.sentence1Score = score;

      debugPrint("=========== SENTENCE 1 ===========");
      debugPrint("🗣️ Text: $text");
      debugPrint("⭐ Score: $score");
      debugPrint("📦 Full response: $res");
      debugPrint("=================================");

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SentenceRepetitionTwoScreen(),
        ),
      );
    } catch (e) {
      debugPrint("❌ SENTENCE 1 SUBMIT ERROR: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHardware = SessionContext.testMode == TestMode.hardware;

    // تحديد صوت زر التسجيل بناءً على الحالة
    String recordingSfx = _isRecording 
        ? 'audio/stop_recording.mp3' 
        : (_hasRecorded ? 'audio/retry_recording.mp3' : 'audio/start_recording.mp3');

    return TestQuestionScaffold(
      title: 'تكرار الجملة (1/2)',
      instruction: isHardware
          ? 'اضغط على سماع الجملة مرة واحدة، ثم أعد تكرارها صوتيًا'
          : 'استمع للجملة مرة واحدة، ثم أعدها كما سمعتها',
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
                // ===== سماعة تنبض أثناء السماع =====
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = _isPlaying
                        ? (0.95 + (_pulseController.value * 0.15))
                        : 1.0;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isPlaying
                          ? Colors.blue.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.12),
                    ),
                    child: Icon(
                      Icons.volume_up,
                      size: 64,
                      color: _isPlaying ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ===== زر سماع الجملة =====
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onLongPressStart: (_) => _btnSfxPlayer.play(AssetSource('audio/play_Sentence.mp3')),
                    onLongPressEnd: (_) => _btnSfxPlayer.stop(),
                    child: ElevatedButton.icon(
                      onPressed:
                          (_hasPlayedOnce || _isPlaying || _isRecording)
                              ? null
                              : _playInstruction,
                      icon: const Icon(Icons.volume_up),
                      label: const Text('سماع الجملة'),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ===== زر تسجيل الإجابة (ناطق بالضغط المطول) =====
               SizedBox(
  width: double.infinity,
  child: GestureDetector(
    onLongPressStart: (_) => _btnSfxPlayer.play(AssetSource(recordingSfx)),
    onLongPressEnd: (_) => _btnSfxPlayer.stop(),
    child: ElevatedButton.icon(
      // الزر يكون معطل إذا كان الصوت يعمل، أو جاري التحميل، أو (الأهم) إذا لم ينتهِ الصوت بعد
      onPressed: (_isPlaying || _isLoading || !_audioFinished) ? null : _onRecordPressed,
      icon: Icon(
        _isRecording ? Icons.stop : Icons.mic,
      ),
      label: Text(
        _isRecording
            ? 'إيقاف التسجيل'
            : (_hasRecorded ? 'إعادة التسجيل' : 'بدء التسجيل'),
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

                // ===== جاري التسجيل =====
                if (_isRecording)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: const [
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

                if (_hasRecorded && !_isRecording)
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
      isNextEnabled:
          _hasRecorded && !_isRecording && !_isLoading,
      onNext: _submit,
      onEndSession: () =>
          Navigator.popUntil(context, (r) => r.isFirst),
    );
  }
}