import 'dart:async';
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
import '../abstraction/abstraction_question_one_screen.dart';

class VerbalFluencyScreen extends StatefulWidget {
  const VerbalFluencyScreen({super.key});
  @override
  State<VerbalFluencyScreen> createState() => _VerbalFluencyScreenState();
}

class _VerbalFluencyScreenState extends State<VerbalFluencyScreen> {
  int _sec = 60;
  Timer? _t;
  final AudioPlayer _p = AudioPlayer();
  FlutterSoundRecorder? _r = FlutterSoundRecorder();
  final MocaApiService _apiService = MocaApiService();

  bool _isRun = false, _isFin = false, _load = false;
  String? _path;

  // ✅ عنوان الـ IP الخاص بالرايزبري باي
  final String rpiIp = "192.168.1.22";

  @override
  void initState() {
    super.initState();
    // نفتح المايكروفون فقط إذا كان المود هو الجوال
    if (SessionContext.testMode == TestMode.mobile) {
      _r!.openRecorder();
    }
    _play();
  }

  Future<void> _play() async {
    try {
      await _p.play(AssetSource('audio/fluency.mp3'));
    } catch (e) {
      debugPrint("Error playing fluency audio: $e");
    }
  }

  // 🎤 دالة البدء الهجينة (تختار بين مايك الجوال أو مايك الرايزبري)
  Future<void> _start() async {
    if (SessionContext.testMode == TestMode.hardware) {
      // 🖥️ مسار الهاردوير
      setState(() {
        _isRun = true;
        _isFin = false;
        _sec = 60;
        _load = true; // نُظهر لودينج خفيف لأن الطلب سيبقى معلقاً دقيقة
      });

      _startTimer(); // نشغل المؤقت في الواجهة للمريض

      try {
        debugPrint("--- [HARDWARE MODE] جاري طلب تسجيل 60 ثانية من الرايزبري ---");
        // نطلب من الرايزبري يسجل (تأكدي أن الرايزبري مبرمج ليسجل لفترة طويلة لهذا السؤال)
        final result = await _apiService.processHardwareTask(
          rpiIp: rpiIp,
          taskType: "audio",
          functionName: "NONE",
        );

        if (result.containsKey('tempPath')) {
          _path = result['tempPath'];
          setState(() {
            _isFin = true;
            _isRun = false;
          });
        }
      } catch (e) {
        debugPrint("Error fetching audio from RPi: $e");
        setState(() { _isRun = false; _isFin = false; });
      } finally {
        setState(() => _load = false);
      }
    } else {
      // 📱 مسار الجوال: التسجيل بالمايك الداخلي
      final dir = await getTemporaryDirectory();
      _path = '${dir.path}/flu.wav';
      await _r!.startRecorder(
        toFile: _path,
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );
      setState(() {
        _isRun = true;
        _isFin = false;
        _sec = 60;
      });
      _startTimer();
    }
  }

  // وظيفة المؤقت الزمني
  void _startTimer() {
    _t = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sec == 0) {
        timer.cancel();
        if (SessionContext.testMode == TestMode.mobile) {
          _stopMobileRecording();
        }
      } else {
        setState(() => _sec--);
      }
    });
  }

  Future<void> _stopMobileRecording() async {
    await _r!.stopRecorder();
    setState(() {
      _isRun = false;
      _isFin = true;
    });
  }

  Future<void> _submit() async {
    if (_path == null) return;
    setState(() => _load = true);
    try {
      final res = await _apiService.checkFluency(_path!);
      TestSession.fluencyScore = res['score'] ?? 0;
      debugPrint("--- Fluency Score: ${TestSession.fluencyScore} ---");
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AbstractionQuestionOneScreen()),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _load = false);
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _p.dispose();
    _r?.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isHardware = SessionContext.testMode == TestMode.hardware;

    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'الطلاقة اللفظية',
          content: Column(
            children: [
              // دائرة المؤقت
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _isRun ? Colors.red : Colors.blue, width: 5),
                ),
                child: Text(
                  "$_sec",
                  style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              const Text("ثانية متبقية", style: TextStyle(fontSize: 18, color: Colors.grey)),
              
              const SizedBox(height: 40),
              
              ElevatedButton.icon(
                onPressed: _isRun || _isFin || _load ? null : _start,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isHardware ? Colors.orange : Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                icon: Icon(isHardware ? Icons.settings_input_component : Icons.mic),
                label: Text(isHardware ? "بدء التسجيل من الجهاز" : "ابدأ الدقيقة"),
              ),
              
              if (_isFin && !_load)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text("✅ انتهى الوقت، اضغط متابعة للتحليل", 
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          isNextEnabled: _isFin && !_load,
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
                  Text("جاري معالجة الكلمات...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}