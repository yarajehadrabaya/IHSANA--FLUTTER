import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import 'verbal_fluency_screen.dart'; // الانتقال لطلاقة الكلام

class SentenceRepetitionTwoScreen extends StatefulWidget {
  const SentenceRepetitionTwoScreen({super.key});

  @override
  State<SentenceRepetitionTwoScreen> createState() =>
      _SentenceRepetitionTwoScreenState();
}

class _SentenceRepetitionTwoScreenState
    extends State<SentenceRepetitionTwoScreen> {
  final AudioPlayer _p = AudioPlayer();
  FlutterSoundRecorder? _r = FlutterSoundRecorder();
  final MocaApiService _apiService = MocaApiService();

  bool _isRec = false, _hasRec = false, _load = false, _isPlay = false;
  String? _path;

  @override
  void initState() {
    super.initState();
    _r!.openRecorder();
    _playInstruction();
  }

  @override
  void dispose() {
    _p.dispose();
    _r?.closeRecorder();
    super.dispose();
  }

  // 🔊 تشغيل ملف sentance2.mp3
  Future<void> _playInstruction() async {
    setState(() => _isPlay = true);
    await _p.play(AssetSource('audio/sentance2.mp3'));
    _p.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlay = false);
    });
  }

  Future<void> _handleRecording() async {
    if (_isRec) {
      _path = await _r!.stopRecorder();
      setState(() {
        _isRec = false;
        _hasRec = true;
      });
    } else {
      final dir = await getTemporaryDirectory();
      _path = '${dir.path}/s2_res.wav';
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

  Future<void> _submit() async {
    setState(() => _load = true);
    try {
      final res = await _apiService.checkSentence2(_path!);

      // ✅ [تحقق] طباعة النتيجة في الكونسول
      debugPrint("--- SENTENCE 2 RESULT: ${res['score']} ---");
      debugPrint("AI Analysis: ${res['analysis']}");

      // حفظ السكور في الخزنة (خانة مستقلة)
      TestSession.sentence2Score = (res['score'] as int? ?? 0);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VerbalFluencyScreen()),
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
          title: 'تكرار الجملة (2/2)',
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
                ),
                icon: Icon(_isRec ? Icons.stop : Icons.mic),
                label: Text(_isRec ? "إيقاف" : "سجّل إعادتك للجملة"),
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
