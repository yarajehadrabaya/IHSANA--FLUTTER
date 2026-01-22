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
    super.dispose();
  }

  // ================= 🔊 VOICE =================
  Future<void> _playStep(int index) async {
    if (index < _order.length) {
      try {
        await _instructionPlayer.play(
          AssetSource('audio/${_order[index]}.mp3'),
        );
      } catch (e) {
        debugPrint("Orientation audio error: $e");
      }
    }
  }

  // ================= 🔥 FIREBASE =================
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
        }
      }
    } catch (e) {
      debugPrint("Firebase error: $e");
    }
  }

  // ================= 🎤 RECORD =================
  Future<void> _onRecordPressed(String key) async {
    if (SessionContext.testMode == TestMode.hardware) {
      await _recordFromHardware(key);
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
  Future<void> _recordFromHardware(String key) async {
    setState(() => _isLoading = true);
    await _instructionPlayer.stop();

    try {
      final uri =
          Uri.parse('${SessionContext.raspberryBaseUrl}/get-audio');

      debugPrint("[HARDWARE] Orientation request → $uri");

      final res = await http.get(uri).timeout(
            const Duration(seconds: 20),
          );

      if (res.statusCode != 200) {
        throw Exception("Hardware error ${res.statusCode}");
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ori_${key}_hw.wav');
      await file.writeAsBytes(res.bodyBytes);

      setState(() {
        _recordedPaths[key] = file.path;
      });

      _moveNext();
    } catch (e) {
      debugPrint("❌ Orientation hardware error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في التسجيل من الجهاز الخارجي'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(result: result),
        ),
      );
    } catch (e) {
      debugPrint("❌ Orientation submit error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التحليل النهائي: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= 🧱 UI =================
  @override
  Widget build(BuildContext context) {
    bool canFinish =
        _recordedPaths.values.every((v) => v != null);

    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'التوجّه',
          content: Column(
            children: _order.map((key) {
              bool isDone = _recordedPaths[key] != null;
              bool isCurrent = _order[_currentIndex] == key;

              return Card(
                color: isCurrent
                    ? Colors.blue.shade50
                    : Colors.white,
                child: ListTile(
                  title: Text(
                    _label(key),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isDone
                        ? 'تم الحفظ ✓'
                        : (isCurrent
                            ? 'سجل الآن...'
                            : 'بانتظار دورك'),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      _isRecording && isCurrent
                          ? Icons.stop
                          : Icons.mic,
                      color: isDone
                          ? Colors.green
                          : Colors.blue,
                    ),
                    onPressed: _isLoading
                        ? null
                        : () => _onRecordPressed(key),
                  ),
                ),
              );
            }).toList(),
          ),
          isNextEnabled: canFinish && !_isLoading,
          onNext: _finish,
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
