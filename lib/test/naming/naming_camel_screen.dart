import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../../session/session_context.dart'; // ✅ للتحقق من المود المختار
import '../test_mode_selection_screen.dart'; // ✅ للوصول لـ TestMode
import '../memory/memory_encoding_screen.dart';

class NamingCamelScreen extends StatefulWidget {
  final String lionPath;
  final String rhinoPath;

  const NamingCamelScreen({
    super.key,
    required this.lionPath,
    required this.rhinoPath,
  });

  @override
  State<NamingCamelScreen> createState() => _NamingCamelScreenState();
}

class _NamingCamelScreenState extends State<NamingCamelScreen> {
  FlutterSoundRecorder? _recorder = FlutterSoundRecorder();
  final AudioPlayer _instructionPlayer = AudioPlayer();
  final MocaApiService _apiService = MocaApiService();
  
  bool _isRecording = false;
  bool _isLoading = false;
  bool _hasRec = false;
  String? _camelPath;

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
    _recorder?.closeRecorder();
    _instructionPlayer.dispose();
    super.dispose();
  }

  Future<void> _playInstruction() async {
    try {
      await _instructionPlayer.play(AssetSource('audio/naming.mp3'));
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // 🎤 دالة التسجيل الهجينة (تختار بين مايك الجوال أو مايك الرايزبري)
  Future<void> _handleRecording() async {
    if (SessionContext.testMode == TestMode.hardware) {
      // 🖥️ مسار الهاردوير: طلب تسجيل صوت الجمل من الرايزبري
      setState(() => _isLoading = true);
      try {
        debugPrint("--- [HARDWARE MODE] جاري طلب تسجيل الجمل من الرايزبري ---");
        await _instructionPlayer.stop();

        final result = await _apiService.processHardwareTask(
          rpiIp: rpiIp,
          taskType: "audio",
          functionName: "NONE", // نحتاج الملف فقط حالياً
        );

        if (result.containsKey('tempPath')) {
           _camelPath = result['tempPath'];
           setState(() {
             _hasRec = true;
           });
           debugPrint("✅ تم استلام ملف الجمل من الرايزبري: $_camelPath");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطأ في جلب الصوت من الجهاز: $e")),
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
          _camelPath = path;
          _hasRec = true;
        });
      } else {
        await _instructionPlayer.stop();
        final dir = await getTemporaryDirectory();
        _camelPath = '${dir.path}/camel_res.wav';
        await _recorder!.startRecorder(
          toFile: _camelPath,
          codec: Codec.pcm16WAV,
          sampleRate: 16000,
          numChannels: 1,
        );
        setState(() {
          _isRecording = true;
          _hasRec = false;
        });
      }
    }
  }

  // 🚀 إرسال الملفات الثلاثة للتحليل النهائي
  Future<void> _submit() async {
    if (_camelPath == null) return;

    setState(() => _isLoading = true);
    try {
      // تجميع المسارات الثلاثة (التي قد تكون محلية أو مجلوبة من الرايزبري)
      List<String> allAudios = [
        widget.lionPath,
        widget.rhinoPath,
        _camelPath!,
      ];

      debugPrint("--- جاري إرسال 3 ملفات للتحليل ---");
      final res = await _apiService.checkNaming(allAudios);

      // حفظ السكور في الخزنة
      TestSession.namingScore = (res['score'] as int? ?? 0);
      debugPrint("--- Naming Result: ${res['score']} ---");

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MemoryEncodingScreen()),
        );
      }
    } catch (e) {
      debugPrint("Error during submission: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في تحليل الاختبار: $e")),
      );
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
          title: 'تسمية الحيوانات',
          instruction: isHardware 
              ? 'انطق اسم الحيوان الأخير في ميكروفون الجهاز الخارجي.' 
              : 'ما اسم هذا الحيوان؟ (سجل إجابتك)',
          content: Column(
            children: [
              Image.asset('assets/images/camel.png', height: 200),
              const SizedBox(height: 24),
              
              ElevatedButton.icon(
                onPressed: _isPlay || _isLoading ? null : _handleRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : (isHardware ? Colors.orange : Colors.blue),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: Icon(isHardware ? Icons.settings_input_component : (_isRecording ? Icons.stop : Icons.mic)),
                label: Text(isHardware 
                    ? "طلب تسجيل الجمل من الجهاز" 
                    : (_isRecording ? 'إيقاف التسجيل' : 'تسجيل إجابة الجمل')),
              ),
              
              const SizedBox(height: 16),
              if (_hasRec && !_isRecording)
                const Text("✅ تم تجهيز تسجيل الجمل", 
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          isNextEnabled: _hasRec && !_isRecording && !_isLoading,
          onNext: _submit,
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
                  Text("جاري معالجة الأصوات وتحليلها...", 
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  bool get _isPlay => false; // مضافة لتسهيل شروط الأزرار
}