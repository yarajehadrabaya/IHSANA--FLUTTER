import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/moca_api_service.dart'; // ✅ استدعاء السيرفس
import '../../session/session_context.dart'; // ✅ للتحقق من المود المختار
import '../test_mode_selection_screen.dart'; // ✅ للوصول لـ TestMode
import 'naming_rhino_screen.dart';

class NamingLionScreen extends StatefulWidget {
  const NamingLionScreen({super.key});
  @override
  State<NamingLionScreen> createState() => _NamingLionScreenState();
}

class _NamingLionScreenState extends State<NamingLionScreen> {
  FlutterSoundRecorder? _recorder = FlutterSoundRecorder();
  final AudioPlayer _instructionPlayer = AudioPlayer();
  final MocaApiService _apiService = MocaApiService(); // محرك الـ API

  bool _isRecording = false;
  bool _isLoading = false; // لحالة الانتظار عند سحب الملف من الرايزبري
  String? _lionPath;
  
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

  Future<void> _playInstruction() async {
    try {
      await _instructionPlayer.play(AssetSource('audio/naming.mp3'));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  // 🎤 دالة التسجيل الهجينة
  Future<void> _handleRecordingAction() async {
    if (SessionContext.testMode == TestMode.hardware) {
      // 🖥️ مسار الهاردوير: طلب الصوت من الرايزبري
      setState(() => _isLoading = true);
      try {
        debugPrint("--- [HARDWARE MODE] جاري طلب تسجيل الأسد من الرايزبري ---");
        // نطلب من الرايزبري تسجيل الصوت وإرساله للموبايل
        final result = await _apiService.processHardwareTask(
          rpiIp: rpiIp,
          taskType: "audio",
          functionName: "NONE", // نحتاج الملف فقط الآن لنمرره للشاشة الأخيرة
        );

        if (result.containsKey('tempPath')) {
           setState(() {
             _lionPath = result['tempPath'];
           });
           debugPrint("✅ تم استلام ملف الأسد من الرايزبري: $_lionPath");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ في جلب الصوت من الجهاز الخارجي: $e")),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      // 📱 مسار الجوال: التسجيل بالمايك الداخلي
      if (_isRecording) {
        final path = await _recorder!.stopRecorder();
        setState(() {
          _isRecording = false;
          _lionPath = path;
        });
      } else {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/lion_res.wav';
        await _recorder!.startRecorder(
          toFile: path,
          codec: Codec.pcm16WAV,
          sampleRate: 16000,
          numChannels: 1,
        );
        setState(() {
          _isRecording = true;
          _lionPath = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isHardware = SessionContext.testMode == TestMode.hardware;

    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'تسمية الحيوانات',
          instruction: isHardware 
              ? 'انطق اسم الحيوان في ميكروفون الجهاز الخارجي.' 
              : 'ما اسم هذا الحيوان؟ (سجل إجابتك)',
          content: Column(
            children: [
              Image.asset('assets/images/lion.png', height: 200),
              const SizedBox(height: 24),
              
              // زر التسجيل يتغير شكله ولونه حسب المود المختار
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleRecordingAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : (isHardware ? Colors.orange : Colors.blue),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: Icon(isHardware ? Icons.settings_input_component : (_isRecording ? Icons.stop : Icons.mic)),
                label: Text(isHardware 
                    ? "طلب تسجيل الأسد من الجهاز" 
                    : (_isRecording ? 'إيقاف التسجيل' : 'تسجيل إجابة الأسد')),
              ),
              
              const SizedBox(height: 16),
              if (_lionPath != null && !_isRecording)
                const Text("✅ تم تجهيز تسجيل الأسد", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          isNextEnabled: _lionPath != null && !_isRecording && !_isLoading,
          onNext: () {
            _instructionPlayer.stop();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NamingRhinoScreen(lionAudioPath: _lionPath!),
              ),
            );
          },
          onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        
        // شاشة انتظار شفافة تظهر عند سحب الملف من الرايزبري
        if (_isLoading)
          Container(
            color: Colors.black26,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("جاري سحب الصوت من الجهاز...", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}