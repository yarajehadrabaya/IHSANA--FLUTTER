import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../../session/session_context.dart'; // ✅ للتحقق من المود
import '../test_mode_selection_screen.dart'; // ✅ للوصول لـ TestMode
import 'subtraction_screen.dart';

class LetterAScreen extends StatefulWidget {
  const LetterAScreen({super.key});
  @override
  State<LetterAScreen> createState() => _LetterAScreenState();
}

class _LetterAScreenState extends State<LetterAScreen> {
  final AudioPlayer _p = AudioPlayer();
  final MocaApiService _apiService = MocaApiService();
  
  bool _isPlay = false, _done = false;
  bool _isFeedbackActive = false; // وميض الزر عند النقر
  bool _isLoading = false; // لانتظار رد الهاردوير
  int _err = 0;
  final String rpiIp = "192.168.1.22";

  // 🎯 توقيتات حرف الألف (ثواني)
  final List<double> _ts = [9.0, 11.5, 15.0, 18.0, 19.0, 20.0, 23.0];
  final List<double> _hits = [];

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  // 🚀 بدء الاختبار (حسب المود المختار)
  Future<void> _startTest() async {
    if (SessionContext.testMode == TestMode.hardware) {
      _runHardwareVigilance();
    } else {
      _runMobileVigilance();
    }
  }

  // 📱 منطق الجوال (نقر على الشاشة)
  Future<void> _runMobileVigilance() async {
    setState(() { _isPlay = true; _err = 0; _hits.clear(); _done = false; });
    await _p.play(AssetSource('audio/attention-a.mp3'));
    _p.onPlayerComplete.listen((_) {
      if (mounted) {
        _calcMobileScore();
        setState(() { _isPlay = false; _done = true; });
      }
    });
  }

  // 🖥️ منطق الهاردوير (طلب النتيجة من الرازبيري)
  Future<void> _runHardwareVigilance() async {
    setState(() => _isLoading = true);
    try {
      debugPrint("--- [HARDWARE MODE] جاري طلب اختبار حرف الألف من الرازبيري ---");
      // نطلب من الرازبيري باي تشغيل الاختبار وإرجاع النتيجة
      final result = await _apiService.processHardwareTask(
        rpiIp: rpiIp,
        taskType: "action", // نوع جديد للمهام التفاعلية
        functionName: "runVigilance",
      );

      TestSession.letterAScore = (result['score'] as int? ?? 0);
      
      debugPrint("✅ نتيجة حرف الألف من الهاردوير: ${TestSession.letterAScore}");
      
      setState(() { _done = true; });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في اتصال الهاردوير: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _tap() async {
    if (!_isPlay) return;

    // تأثير بصري عند النقر (الزر ينور أبيض)
    setState(() => _isFeedbackActive = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _isFeedbackActive = false);
    });

    final pos = await _p.getCurrentPosition();
    if (pos == null) return;
    double sec = pos.inMilliseconds / 1000.0;
    bool ok = false;
    for (var t in _ts) {
      if (sec >= t && sec <= t + 1.2) {
        if (!_hits.contains(t)) { _hits.add(t); ok = true; }
        break;
      }
    }
    if (!ok) _err++;
  }

  void _calcMobileScore() {
    int miss = _ts.length - _hits.length;
    TestSession.letterAScore = ((_err + miss) <= 1) ? 1 : 0;
    debugPrint("--- Mobile Letter A Score: ${TestSession.letterAScore} ---");
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = SessionContext.testMode == TestMode.mobile;

    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'اختبار الانتباه (حرف الألف)',
          instruction: isMobile 
            ? 'انقر على الدائرة فور سماع حرف "ألف".' 
            : 'استخدم الزر الموجود على الجهاز الخارجي للنقر عند سماع حرف "ألف".',
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isPlay && !_done && !_isLoading)
                ElevatedButton.icon(
                  onPressed: _startTest, 
                  icon: const Icon(Icons.play_arrow),
                  label: Text(isMobile ? "ابدأ الاختبار" : "تشغيل عبر الجهاز الخار"),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(15)),
                ),
              
              const SizedBox(height: 40),

              // 🔘 الدائرة التفاعلية (تظهر في وضع الجوال فقط للنقر)
              if (isMobile) 
                GestureDetector(
                  onTapDown: (_) => _tap(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      color: _isFeedbackActive 
                        ? Colors.white 
                        : (_isPlay ? Colors.red : Colors.grey),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: _isFeedbackActive ? [const BoxShadow(color: Colors.white, blurRadius: 20)] : [],
                    ),
                    child: Center(
                      child: Text(
                        _isPlay ? "انقر الآن!" : "انتظر البدء", 
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                      )
                    ),
                  ),
                )
              else if (_isLoading || _isPlay)
                const Column(
                  children: [
                    Icon(Icons.memory, size: 80, color: Colors.blue),
                    SizedBox(height: 16),
                    Text("الاختبار يعمل الآن على الجهاز الخارجي...", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),

              if (_done)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text("✅ اكتمل الاختبار بنجاح", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          isNextEnabled: _done && !_isLoading,
          onNext: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SubtractionScreen()));
          },
          onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        if (_isLoading) 
          Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
      ],
    );
  }
}