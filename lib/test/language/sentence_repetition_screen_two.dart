import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../../session/session_context.dart'; // ✅ للتحقق من المود المختار
import '../test_mode_selection_screen.dart'; // ✅ للوصول لـ TestMode
import 'verbal_fluency_screen.dart'; 

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

  bool _isRec = false;
  bool _hasRec = false;
  bool _load = false;
  bool _isPlay = false;
  String? _path;

  // ✅ عنوان الـ IP الخاص بالرايزبري باي كما ذكرتِ
  final String rpiIp = "192.168.1.22";

  @override
  void initState() {
    super.initState();
    // نفتح المايكروفون فقط إذا كان المود هو الجوال
    if (SessionContext.testMode == TestMode.mobile) {
      _r!.openRecorder();
    }
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
    try {
      setState(() => _isPlay = true);
      await _p.play(AssetSource('audio/sentance2.mp3'));
      _p.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlay = false);
      });
    } catch (e) {
      debugPrint("Error playing audio: $e");
      setState(() => _isPlay = false);
    }
  }

  // 🎤 دالة التسجيل الهجينة (تختار بين مايك الجوال أو مايك الرايزبري)
  Future<void> _handleRecording() async {
    if (SessionContext.testMode == TestMode.hardware) {
      // 🖥️ مسار الهاردوير: سحب الصوت من الرايزبري
      setState(() => _load = true);
      try {
        debugPrint("--- [HARDWARE MODE] جاري طلب تسجيل الجملة 2 من الرايزبري ---");
        
        // نطلب من الرايزبري تسجيل الصوت وإرساله للموبايل
        final result = await _apiService.processHardwareTask(
          rpiIp: rpiIp,
          taskType: "audio",
          functionName: "NONE", // نحتاج الملف فقط حالياً
        );

        // التأكد من أن الملف تم حفظه بنجاح في الموبايل
        if (result.containsKey('tempPath')) {
           _path = result['tempPath'];
           setState(() {
             _hasRec = true;
           });
           debugPrint("✅ تم استلام ملف الصوت من الرايزبري: $_path");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ في جلب الصوت من الجهاز الخارجي: $e")),
        );
      } finally {
        setState(() => _load = false);
      }
    } else {
      // 📱 مسار الجوال: التسجيل بالمايك الداخلي
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
  }

  Future<void> _submit() async {
    if (_path == null) return;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في تحليل الجملة: $e")),
      );
    } finally {
      if (mounted) setState(() => _load = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isHardware = SessionContext.testMode == TestMode.hardware;

    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'تكرار الجملة (2/2)',
          instruction: isHardware 
              ? 'استمع للجملة، ثم أعد نطقها في ميكروفون الجهاز الخارجي.' 
              : 'استمع للجملة جيداً ثم أعدها كما سمعتها تماماً.',
          content: Column(
            children: [
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isPlay || _isRec ? null : _playInstruction,
                icon: const Icon(Icons.volume_up),
                label: Text(
                  _isPlay ? 'جاري التشغيل...' : 'سماع الجملة مرة أخرى',
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _isPlay || _load ? null : _handleRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRec ? Colors.red : (isHardware ? Colors.orange : Colors.blue),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: Icon(isHardware ? Icons.settings_input_component : (_isRec ? Icons.stop : Icons.mic)),
                label: Text(isHardware 
                    ? "طلب التسجيل من الجهاز" 
                    : (_isRec ? "إيقاف التسجيل" : "سجّل إعادتك للجملة")),
              ),
              const SizedBox(height: 16),
              if (_hasRec && !_isRec)
                const Text("✅ تم استلام التسجيل بنجاح", 
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          isNextEnabled: _hasRec && !_isRec && !_load,
          onNext: _submit,
          onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        if (_load)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("جاري معالجة الصوت...", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}