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
import '../orientation/orientation_screen.dart'; 

class DelayedRecallScreen extends StatefulWidget {
  const DelayedRecallScreen({super.key});
  @override
  State<DelayedRecallScreen> createState() => _DelayedRecallScreenState();
}

class _DelayedRecallScreenState extends State<DelayedRecallScreen> {
  // المحركات والخدمات
  final AudioPlayer _instructionPlayer = AudioPlayer();
  FlutterSoundRecorder? _recorder = FlutterSoundRecorder();
  final MocaApiService _apiService = MocaApiService();

  // متغيرات الحالة
  bool _isPlaying = false;
  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _isLoading = false;
  String? _recordedPath;

  // ✅ عنوان الـ IP الخاص بالرايزبري باي
  final String rpiIp = "192.168.1.22";

  @override
  void initState() {
    super.initState();
    // نفتح المايكروفون فقط إذا كان المود هو الجوال
    if (SessionContext.testMode == TestMode.mobile) {
      _recorder!.openRecorder();
    }
    _playInstruction(); 
  }

  @override
  void dispose() {
    _instructionPlayer.dispose();
    _recorder?.closeRecorder();
    _recorder = null;
    super.dispose();
  }

  // 🔊 تشغيل تعليمات الذاكرة
  Future<void> _playInstruction() async {
    try {
      setState(() => _isPlaying = true);
      await _instructionPlayer.play(AssetSource('audio/memory.mp3'));
      _instructionPlayer.onPlayerComplete.listen((event) {
        if (mounted) setState(() => _isPlaying = false);
      });
    } catch (e) {
      debugPrint("Error playing audio: $e");
      setState(() => _isPlaying = false);
    }
  }

  // 🎤 دالة التسجيل الهجينة (تختار بين مايك الجوال أو مايك الرايزبري)
  Future<void> _handleRecordingAction() async {
    if (SessionContext.testMode == TestMode.hardware) {
      // 🖥️ مسار الهاردوير: طلب الصوت من الرايزبري
      setState(() => _isLoading = true);
      try {
        debugPrint("--- [HARDWARE MODE] جاري طلب تسجيل الذاكرة من الرايزبري ---");
        await _instructionPlayer.stop();

        final result = await _apiService.processHardwareTask(
          rpiIp: rpiIp,
          taskType: "audio",
          functionName: "NONE", // نحتاج الملف فقط حالياً
        );

        if (result.containsKey('tempPath')) {
           _recordedPath = result['tempPath'];
           setState(() {
             _hasRecorded = true;
           });
           debugPrint("✅ تم استلام تسجيل الذاكرة من الرايزبري: $_recordedPath");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في جلب الصوت: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      // 📱 مسار الجوال: التسجيل بالمايك الداخلي
      try {
        if (_isRecording) {
          final path = await _recorder!.stopRecorder();
          setState(() {
            _isRecording = false;
            _hasRecorded = true;
            _recordedPath = path;
          });
        } else {
          await _instructionPlayer.stop();
          final dir = await getTemporaryDirectory();
          final path = '${dir.path}/memory_res.wav';
          await _recorder!.startRecorder(
            toFile: path,
            codec: Codec.pcm16WAV,
            sampleRate: 16000,
            numChannels: 1,
          );
          setState(() {
            _isRecording = true;
            _recordedPath = null;
          });
        }
      } catch (e) {
        debugPrint("Recording Error: $e");
      }
    }
  }

  // 🚀 الإرسال للـ API والتحليل
  Future<void> _submitAndNext() async {
    if (_recordedPath == null) return;
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.checkMemory(_recordedPath!);

      // ✅ [تحقق] طباعة النتيجة في الكونسول
      debugPrint("--- !!! MEMORY API RESULT !!! ---");
      debugPrint("Score: ${result['score']}"); 
      debugPrint("Patient Said: ${result['patient_said']}");
      debugPrint("Analysis: ${result['analysis']}");
      debugPrint("---------------------------------");

      // حفظ النتيجة في الخزنة
      TestSession.memoryScore = (result['score'] as int? ?? 0);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrientationScreen()),
        );
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في التحليل: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isHardware = SessionContext.testMode == TestMode.hardware;

    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'استدعاء الكلمات',
          instruction: isHardware 
              ? 'اذكر الكلمات الخمس في ميكروفون الجهاز الخارجي.' 
              : 'اذكر الكلمات الخمس التي سمعتها في بداية الاختبار.',
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.psychology_alt, size: 90, color: Colors.purple),
              const SizedBox(height: 30),
              
              if (!_isRecording && !_isLoading)
                TextButton.icon(
                  onPressed: _isPlaying ? null : _playInstruction,
                  icon: const Icon(Icons.replay),
                  label: const Text("إعادة سماع التعليمات"),
                ),

              const SizedBox(height: 20),

              // زر التسجيل الهجين
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleRecordingAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? Colors.red : (isHardware ? Colors.orange : Colors.blue),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  icon: Icon(isHardware ? Icons.settings_input_component : (_isRecording ? Icons.stop : Icons.mic)),
                  label: Text(isHardware 
                      ? "طلب التسجيل من الجهاز" 
                      : (_isRecording ? 'إيقاف التسجيل' : 'بدء تسجيل الإجابة')),
                ),
              ),
              
              if (_hasRecorded && !_isRecording)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text('✅ تم استلام التسجيل بنجاح', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          isNextEnabled: _hasRecorded && !_isRecording && !_isLoading,
          onNext: _submitAndNext,
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
                  Text("جاري معالجة الصوت...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}