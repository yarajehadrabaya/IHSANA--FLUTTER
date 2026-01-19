import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart'; 
import 'package:path_provider/path_provider.dart';
import '../../utils/moca_api_service.dart'; // ✅ استدعاء السيرفس
import '../../session/session_context.dart'; // ✅ للتحقق من المود المختار
import '../test_mode_selection_screen.dart'; // ✅ للوصول لـ TestMode
import 'naming_camel_screen.dart';

class NamingRhinoScreen extends StatefulWidget {
  final String lionAudioPath; // استلام صوت الأسد من الشاشة السابقة

  const NamingRhinoScreen({super.key, required this.lionAudioPath});

  @override
  State<NamingRhinoScreen> createState() => _NamingRhinoScreenState();
}

class _NamingRhinoScreenState extends State<NamingRhinoScreen> {
  FlutterSoundRecorder? _recorder = FlutterSoundRecorder();
  final AudioPlayer _instructionPlayer = AudioPlayer();
  final MocaApiService _apiService = MocaApiService(); // محرك الـ API

  bool _isRecording = false;
  bool _isLoading = false; // لحالة الانتظار عند سحب الملف من الرايزبري
  bool _hasRecorded = false; // للتأكد من وجود تسجيل
  String? _rhinoPath;

  // ✅ عنوان الـ IP الخاص بالرايزبري باي كما حددتِ
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
    _recorder?.closeRecorder();
    _instructionPlayer.dispose();
    super.dispose();
  }

  Future<void> _playInstruction() async {
    try {
      await _instructionPlayer.play(AssetSource('audio/naming.mp3'));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  // 🎤 دالة التسجيل الهجينة (تختار بين مايك الجوال أو مايك الرايزبري)
  Future<void> _handleRecordingAction() async {
    if (SessionContext.testMode == TestMode.hardware) {
      // 🖥️ مسار الهاردوير: طلب الصوت من الرايزبري
      setState(() => _isLoading = true);
      try {
        debugPrint("--- [HARDWARE MODE] جاري طلب تسجيل وحيد القرن من الرايزبري ---");
        await _instructionPlayer.stop();

        final result = await _apiService.processHardwareTask(
          rpiIp: rpiIp,
          taskType: "audio",
          functionName: "NONE", // نحتاج الملف فقط الآن لنمرره للشاشة الأخيرة
        );

        if (result.containsKey('tempPath')) {
           setState(() {
             _rhinoPath = result['tempPath'];
             _hasRecorded = true;
           });
           debugPrint("✅ تم استلام ملف وحيد القرن من الرايزبري: $_rhinoPath");
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
          _rhinoPath = path;
          _hasRecorded = true;
        });
      } else {
        await _instructionPlayer.stop();
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/rhino_res.wav';
        await _recorder!.startRecorder(
          toFile: path,
          codec: Codec.pcm16WAV,
          sampleRate: 16000,
          numChannels: 1,
        );
        setState(() {
          _isRecording = true;
          _rhinoPath = null;
          _hasRecorded = false;
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
          title: 'ما هذا الحيوان؟',
          instruction: isHardware 
              ? 'انطق اسم الحيوان في ميكروفون الجهاز الخارجي.' 
              : 'استمع للجملة جيداً ثم سجل إجابة وحيد القرن.',
          content: Column(
            children: [
              Image.asset('assets/images/rhino.png', height: 200),
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
                    ? "طلب تسجيل وحيد القرن من الجهاز" 
                    : (_isRecording ? 'إيقاف التسجيل' : 'تسجيل إجابة وحيد القرن')),
              ),
              
              const SizedBox(height: 16),
              if (_hasRecorded && !_isRecording)
                const Text("✅ تم تجهيز تسجيل وحيد القرن", 
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          isNextEnabled: _rhinoPath != null && !_isRecording && !_isLoading,
          onNext: () {
            _instructionPlayer.stop();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NamingCamelScreen(
                  lionPath: widget.lionAudioPath, // تمرير مسار الأسد المستلم
                  rhinoPath: _rhinoPath!,         // تمرير مسار وحيد القرن الجديد
                ),
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
                  Text("جاري معالجة الصوت...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}