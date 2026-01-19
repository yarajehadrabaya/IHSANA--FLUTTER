import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// استيراد ملفات المشروع
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../../scoring/moca_result.dart';
import '../../results/results_screen.dart';
import '../../session/session_context.dart'; // ✅ المسار المحدث
import '../test_mode_selection_screen.dart'; // ✅ للوصول لـ TestMode

class OrientationScreen extends StatefulWidget {
  const OrientationScreen({super.key});

  @override
  State<OrientationScreen> createState() => _OrientationScreenState();
}

class _OrientationScreenState extends State<OrientationScreen> {
  final AudioPlayer _instructionPlayer = AudioPlayer();
  FlutterSoundRecorder? _recorder = FlutterSoundRecorder();
  final MocaApiService _apiService = MocaApiService();

  String expectedPlace = "...";
  String expectedCity = "...";
  final String rpiIp = "192.168.1.22"; // ✅ عنوان الرايزبري باي

  final Map<String, String?> _recordedPaths = {
    'day': null, 'month': null, 'year': null, 'place': null, 'city': null,
  };

  final List<String> _order = ['day', 'month', 'year', 'place', 'city'];
  int _currentIndex = 0;
  bool _isRecording = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // نفتح المايكروفون فقط إذا كان المود هو الجوال
    if (SessionContext.testMode == TestMode.mobile) {
      _recorder!.openRecorder();
    }
    _fetchFirebaseData();
    _playStep(0);
  }

  // جلب البيانات التي أدخلها المستخدم في بداية الاختبار من الفايربيس
  Future<void> _fetchFirebaseData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final sessionId = SessionContext.sessionId;

      if (user != null && sessionId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('sessions')
            .doc(sessionId)
            .get();

        if (doc.exists) {
          setState(() {
            expectedCity = doc.data()?['city_before'] ?? "نابلس";
            expectedPlace = doc.data()?['place_before'] ?? "البيت";
          });
          debugPrint("✅ جلب بيانات المقارنة: $expectedCity - $expectedPlace");
        }
      }
    } catch (e) {
      debugPrint("Error fetching firebase data: $e");
    }
  }

  @override
  void dispose() {
    _instructionPlayer.dispose();
    _recorder?.closeRecorder();
    _recorder = null;
    super.dispose();
  }

  // 🔊 تشغيل فويس السؤال (تم تصحيح المسار)
  Future<void> _playStep(int index) async {
    if (index < _order.length) {
      try {
        await _instructionPlayer.play(AssetSource('audio/${_order[index]}.mp3'));
      } catch (e) {
        debugPrint("Error playing audio: $e");
      }
    }
  }

  // 🎤 تسجيل الصوت (هجين: جوال أو رايزبري)
  Future<void> _handleRecording(String key) async {
    if (SessionContext.testMode == TestMode.hardware) {
      // 🖥️ مسار الهاردوير: سحب الصوت من الرايزبري
      setState(() => _isLoading = true);
      try {
        await _instructionPlayer.stop();
        final result = await _apiService.processHardwareTask(
          rpiIp: rpiIp,
          taskType: "audio",
          functionName: "NONE", // نحتاج الملف فقط حالياً
        );

        if (result.containsKey('tempPath')) {
          setState(() {
            _recordedPaths[key] = result['tempPath'];
          });
          // تشغيل فويس السؤال التالي تلقائياً
          _moveToNextStep();
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في الجهاز الخارجي: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      // 📱 مسار الجوال: التسجيل بالمايك الداخلي
      if (_isRecording) {
        final path = await _recorder!.stopRecorder();
        setState(() {
          _isRecording = false;
          _recordedPaths[key] = path;
        });
        _moveToNextStep();
      } else {
        await _instructionPlayer.stop();
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/ori_${key}.wav';
        await _recorder!.startRecorder(
          toFile: path,
          codec: Codec.pcm16WAV,
          sampleRate: 16000,
          numChannels: 1,
        );
        setState(() { _isRecording = true; });
      }
    }
  }

  // دالة مساعدة للانتقال للسؤال التالي تلقائياً
  void _moveToNextStep() {
    if (_currentIndex < _order.length - 1) {
      _currentIndex++;
      _playStep(_currentIndex);
    }
  }

  // 🚀 الإرسال النهائي للـ API المجمع
  Future<void> _finish() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.checkOrientation(
        place: expectedPlace,
        city: expectedCity,
        audioPaths: [
          _recordedPaths['day']!,
          _recordedPaths['month']!,
          _recordedPaths['year']!,
          _recordedPaths['place']!,
          _recordedPaths['city']!,
        ],
      );

      // حفظ سكور التوجه في الخزنة
      TestSession.orientationScore = (res['score'] as int? ?? 0);

      // بناء كائن النتيجة النهائية المجمع
      MocaResult finalResult = MocaResult(
        visuospatial: TestSession.finalVisuospatial,
        naming: TestSession.namingScore,
        attention: TestSession.finalAttention,
        language: TestSession.finalLanguage,
        abstraction: TestSession.abstractionScore,
        delayedRecall: TestSession.memoryScore,
        orientation: TestSession.orientationScore,
        educationBelow12Years: TestSession.educationBelow12Years,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResultsScreen(result: finalResult)),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في التحليل النهائي: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canDone = _recordedPaths.values.every((v) => v != null);

    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'التوجّه',
          content: SingleChildScrollView(
            child: Column(
              children: _order.map((key) {
                bool isDone = _recordedPaths[key] != null;
                bool isCurrent = _order[_currentIndex] == key;

                return Card(
                  color: isCurrent ? Colors.blue.shade50 : Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Text(_getLabel(key), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(isDone ? "تم الحفظ ✓" : (isCurrent ? "سجل الآن..." : "بانتظار دورك")),
                    trailing: IconButton(
                      icon: Icon(
                        _isRecording && isCurrent ? Icons.stop : Icons.mic,
                        color: _isRecording && isCurrent ? Colors.red : (isDone ? Colors.green : Colors.blue),
                      ),
                      onPressed: _isLoading ? null : () => _handleRecording(key),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          isNextEnabled: canDone && !_isLoading,
          onNext: _finish,
          onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        if (_isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("جاري معالجة البيانات...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _getLabel(String key) {
    switch (key) {
      case 'day': return 'ما هو اسم اليوم؟';
      case 'month': return 'ما هو الشهر الحالي؟';
      case 'year': return 'ما هي السنة الحالية؟';
      case 'place': return 'أين أنت الآن؟';
      case 'city': return 'في أي مدينة أنت؟';
      default: return '';
    }
  }
}