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

  // -------- 📱 MOBILE --------
  Future<void> _recordFromMobile(String key) async {
    if (_isRecording) {
      final path = await _recorder!.stopRecorder();
      setState(() {
        _isRecording = false;
        _recordedPaths[key] = path;
      });
      _moveNext();
    } else {
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

    final res = await http.post(
      Uri.parse('${SessionContext.raspberryBaseUrl}/stop-recording'),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ori_${key}_hw.wav');
    await file.writeAsBytes(res.bodyBytes);

    setState(() {
      _recordedPaths[key] = file.path;
      _isHardwareRecording = false;
      _isLoading = false;
    });

    _moveNext();
  }

  // ================= ➡️ NEXT =================
  void _moveNext() {
    if (_currentIndex < _order.length - 1) {
      _currentIndex++;
      _playStep(_currentIndex);
    }
  }

  // ================= 🚀 FINISH =================
  Future<void> _finish() async {
    final res = await _apiService.checkOrientation(
      place: expectedPlace,
      city: expectedCity,
      audioPaths: _order.map((k) => _recordedPaths[k]!).toList(),
    );

    final int score = res['score'] ?? 0;
    TestSession.orientationScore = score;

    // 🧠 LOG واضح
    debugPrint('============== ORIENTATION RESULT ==============');
    debugPrint('🧠 ORIENTATION SCORE: $score');
    debugPrint('FULL RESPONSE: $res');
    debugPrint('================================================');

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
  }

  // ================= 🧱 UI =================
  @override
  Widget build(BuildContext context) {
    final canFinish = _recordedPaths.values.every((v) => v != null);

    return TestQuestionScaffold(
      title: 'التوجّه',
      content: Column(
        children: _order.map((key) {
          final isCurrent = _order[_currentIndex] == key;
          final isDone = _recordedPaths[key] != null;

          return ListTile(
            title: Text(_label(key)),
            subtitle: Text(
              isDone
                  ? 'تم التسجيل ✓'
                  : (isCurrent ? 'سجل الآن' : 'بانتظار دورك'),
            ),
            trailing: IconButton(
              icon: Icon(
                _isHardwareRecording && isCurrent
                    ? Icons.stop
                    : Icons.mic,
                color: isDone ? Colors.green : Colors.blue,
              ),
              onPressed:
                  _isLoading ? null : () => _onRecordPressed(key),
            ),
          );
        }).toList(),
      ),
      isNextEnabled: canFinish && !_isLoading,
      onNext: _finish,
      onEndSession: () =>
          Navigator.popUntil(context, (r) => r.isFirst),
    );
  }

  String _label(String key) {
    switch (key) {
      case 'day':
        return 'ما هو اسم اليوم؟';
      case 'month':
        return 'ما هو الشهر الحالي؟';
      case 'year':
        return 'ما هي السنة الحالية؟';
      case 'place':
        return 'أين أنت الآن؟';
      case 'city':
        return 'في أي مدينة أنت؟';
      default:
        return '';
    }
  }
}
