import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../../scoring/moca_result.dart';
import '../../results/results_screen.dart';
import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';

class OrientationScreen extends StatefulWidget {
  const OrientationScreen({super.key});

  @override
  State<OrientationScreen> createState() => _OrientationScreenState();
}

class _OrientationScreenState extends State<OrientationScreen> {
  final AudioPlayer _instructionPlayer = AudioPlayer();
  FlutterSoundRecorder? _recorder;
  final MocaApiService _apiService = MocaApiService();

  Timer? _forceStopTimer;

  String expectedPlace = "...";
  String expectedCity = "...";

  final Map<String, String?> _recordedPaths = {
    'day': null,
    'month': null,
    'year': null,
    'place': null,
    'city': null,
  };

  final List<String> _order = ['day', 'month', 'year', 'place', 'city'];
  int _currentIndex = 0;

  bool _isRecording = false;
  bool _isLoading = false;
  bool _isHardwareRecording = false;

  @override
  void initState() {
    super.initState();

    if (SessionContext.testMode == TestMode.mobile) {
      _recorder = FlutterSoundRecorder()..openRecorder();
    }

    _fetchFirebaseData();
    _playStep(0);
  }

  @override
  void dispose() {
    _instructionPlayer.dispose();
    _recorder?.closeRecorder();
    _forceStopTimer?.cancel();
    super.dispose();
  }

  // ================= 🔊 AUDIO =================
  Future<void> _playStep(int index) async {
    if (index < _order.length) {
      await _instructionPlayer.stop();
      await _instructionPlayer.play(
        AssetSource('audio/${_order[index]}.mp3'),
      );
    }
  }

  // ================= 🔥 FIREBASE =================
  Future<void> _fetchFirebaseData() async {
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
        expectedCity = doc.data()?['city_before'] ?? "نابلس";
        expectedPlace = doc.data()?['place_before'] ?? "البيت";
      }
    }
  }

  // ================= 🎤 RECORD =================
  Future<void> _onRecordPressed(String key) async {
    if (SessionContext.testMode == TestMode.hardware) {
      await _toggleHardware(key);
    } else {
      await _recordFromMobile(key);
    }
  }

  Future<void> _recordFromMobile(String key) async {
    if (_isRecording) {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _recordedPaths[key] = path;
      });
    } else {
      await _instructionPlayer.stop();
      final dir = await getTemporaryDirectory();
      await _recorder!.startRecorder(
        toFile: '${dir.path}/ori_$key.wav',
        codec: Codec.pcm16WAV,
        sampleRate: 16000,
        numChannels: 1,
      );
      setState(() => _isRecording = true);
    }
  }

  // -------- 🖥️ HARDWARE --------
  Future<void> _toggleHardware(String key) async {
    if (_isHardwareRecording) {
      await _stopHardware(key);
    } else {
      await _startHardware();
    }
  }

  Future<void> _startHardware() async {
    await _instructionPlayer.stop();
    setState(() => _isHardwareRecording = true);

    await http.post(
      Uri.parse('${SessionContext.raspberryBaseUrl}/start-recording'),
    );

    _forceStopTimer?.cancel();
    _forceStopTimer = Timer(const Duration(seconds: 60), () {
      if (_isHardwareRecording) {
        _stopHardware(_order[_currentIndex]);
      }
    });
  }

  Future<void> _stopHardware(String key) async {
    setState(() => _isLoading = true);

    try {
      await http.post(
        Uri.parse('${SessionContext.raspberryBaseUrl}/stop-recording'),
      );

      final res = await http.get(
        Uri.parse('${SessionContext.raspberryBaseUrl}/get-audio'),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ori_${key}_hw.wav');
      await file.writeAsBytes(res.bodyBytes);

      setState(() {
        _recordedPaths[key] = file.path;
        _isHardwareRecording = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= 🧱 NAVIGATION =================
  void _nextStep() {
    if (_currentIndex < _order.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _playStep(_currentIndex);
    } else {
      _finish();
    }
  }

  void _previousStep() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _playStep(_currentIndex);
    }
  }

  // ================= 🧱 UI =================
  @override
  Widget build(BuildContext context) {
    final String currentKey = _order[_currentIndex];
    final bool isLastStep = _currentIndex == _order.length - 1;
    final bool isDoneRecording = _recordedPaths[currentKey] != null;
    final bool isRecordingNow = _isRecording || _isHardwareRecording;

    return TestQuestionScaffold(
      title: 'اختبار التوجّه (${_currentIndex + 1} من 5)',
      onRepeatInstruction: isRecordingNow ? null : () => _playStep(_currentIndex), 
      content: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_order.length, (index) {
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentIndex
                        ? Colors.blue
                        : (index < _currentIndex ? Colors.green : Colors.grey.shade300),
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _label(currentKey),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: _isLoading ? null : () => _onRecordPressed(currentKey),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isRecordingNow
                            ? Colors.red.withOpacity(0.1)
                            : (isDoneRecording ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1)),
                      ),
                      child: Icon(
                        isRecordingNow ? Icons.stop : (isDoneRecording ? Icons.check_circle : Icons.mic),
                        size: 80,
                        color: isRecordingNow ? Colors.red : (isDoneRecording ? Colors.green : Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isRecordingNow
                        ? 'جاري التسجيل... اضغط للإيقاف'
                        : (isDoneRecording ? 'تم تسجيل الإجابة بنجاح' : 'اضغط على الميكروفون للبدء'),
                    style: TextStyle(
                      fontSize: 16,
                      color: isRecordingNow ? Colors.red : (isDoneRecording ? Colors.green : Colors.grey),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isDoneRecording && !isRecordingNow)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _recordedPaths[currentKey] = null;
                          });
                          _onRecordPressed(currentKey);
                        },
                        icon: const Icon(Icons.refresh, color: Colors.orange),
                        label: const Text('إعادة تسجيل الإجابة', style: TextStyle(color: Colors.orange)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: _currentIndex > 0
                        ? OutlinedButton.icon(
                            onPressed: _previousStep,
                            icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                            label: const Text('السابق'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (_currentIndex > 0 && !isLastStep) const SizedBox(width: 16),
                  // التعديل هنا: يختفي زر التالي فقط عند السؤال الأخير
                  if (!isLastStep)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (isDoneRecording && !_isLoading && !isRecordingNow) 
                          ? _nextStep 
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'التالي',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // ربط زر إنهاء السكافولد بالدالة النهائية وتفعيله فقط في آخر سؤال
      isNextEnabled: isLastStep && isDoneRecording && !isRecordingNow, 
      onNext: _finish, 
      onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
    );
  }

  Future<void> _finish() async {
    setState(() => _isLoading = true);
    
    try {
      final res = await _apiService.checkOrientation(
        place: expectedPlace,
        city: expectedCity,
        audioPaths: _order.map((k) => _recordedPaths[k]!).toList(),
      );

      TestSession.orientationScore = res['score'] ?? 0;

      final result = MocaResult(
        visuospatial: TestSession.finalVisuospatial,
        naming: TestSession.namingScore,
        attention: TestSession.finalAttention,
        language: TestSession.finalLanguage,
        abstraction: TestSession.abstractionScore,
        delayedRecall: TestSession.memoryScore,
        orientation: TestSession.orientationScore,
        educationBelow12Years: TestSession.educationBelow12Years,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(result: result),
        ),
      );
    } catch (e) {
      debugPrint("Error finishing orientation: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _label(String key) {
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