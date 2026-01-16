import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import 'sentence_repetition_screen_two.dart'; // الانتقال للجملة الثانية

class SentenceRepetitionOneScreen extends StatefulWidget {
  const SentenceRepetitionOneScreen({super.key});

  @override
  State<SentenceRepetitionOneScreen> createState() =>
      _SentenceRepetitionOneScreenState();
}

class _SentenceRepetitionOneScreenState
    extends State<SentenceRepetitionOneScreen> {
  final AudioPlayer _p = AudioPlayer();
  FlutterSoundRecorder? _r = FlutterSoundRecorder();
  final MocaApiService _apiService = MocaApiService();

  bool _isRec = false;
  bool _hasRec = false;
  bool _load = false;
  bool _isPlay = false;
  String? _path;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _playInstruction(); // تشغيل الجملة فور فتح الشاشة
  }

  @override
  void dispose() {
    _p.dispose();
    _r?.closeRecorder();
    super.dispose();
  }

  Future<void> _initRecorder() async {
    await _r!.openRecorder();
  }

  // 🔊 تشغيل ملف sentance1.mp3
  Future<void> _playInstruction() async {
    try {
      setState(() => _isPlay = true);
      await _p.play(AssetSource('audio/sentance1.mp3'));
      _p.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlay = false);
      });
    } catch (e) {
      debugPrint("Error playing audio: $e");
      setState(() => _isPlay = false);
    }
  }

  // 🎤 تسجيل إعادة المريض
  Future<void> _handleRecording() async {
    if (_isRec) {
      _path = await _r!.stopRecorder();
      setState(() {
        _isRec = false;
        _hasRec = true;
      });
    } else {
      final dir = await getTemporaryDirectory();
      _path = '${dir.path}/s1_res.wav';
      await _r!.startRecorder(
        toFile: _path,
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );
      setState(() {
        _isRec = true;
        _hasRec = false;
      });
    }
  }

  // 🚀 تحليل الجملة الأولى بالـ API
  Future<void> _submit() async {
    setState(() => _load = true);
    try {
      final res = await _apiService.checkSentence1(_path!);

      // ✅ [تحقق] طباعة النتيجة في الكونسول
      debugPrint("--- SENTENCE 1 RESULT: ${res['score']} ---");
      debugPrint("AI Analysis: ${res['analysis']}");

      // حفظ السكور في الخزنة
      TestSession.sentence1Score = (res['score'] as int? ?? 0);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SentenceRepetitionTwoScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _load = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'تكرار الجملة (1/2)',
          instruction: 'استمع للجملة جيداً ثم أعدها كما سمعتها تماماً.',
          content: Column(
            children: [
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isPlay ? null : _playInstruction,
                icon: const Icon(Icons.volume_up),
                label: Text(
                  _isPlay ? 'جاري التشغيل...' : 'سماع الجملة مرة أخرى',
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _isPlay ? null : _handleRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRec ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                ),
                icon: Icon(_isRec ? Icons.stop : Icons.mic),
                label: Text(_isRec ? "إيقاف التسجيل" : "سجّل إعادتك للجملة"),
              ),
              if (_hasRec && !_isRec)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text("✅ تم تسجيل الإجابة"),
                ),
            ],
          ),
          isNextEnabled: _hasRec && !_isRec && !_load,
          onNext: _submit,
          onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        if (_load) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
