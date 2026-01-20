import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../../session/session_context.dart'; // ✅ للتحقق من المود
import '../test_mode_selection_screen.dart'; // ✅ الوصول لـ TestMode
import 'clock_drawing_screen.dart';

class CubeCopyScreen extends StatefulWidget {
  const CubeCopyScreen({super.key});

  @override
  State<CubeCopyScreen> createState() => _CubeCopyScreenState();
}

class _CubeCopyScreenState extends State<CubeCopyScreen> {
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _instructionPlayer = AudioPlayer();
  final MocaApiService _apiService = MocaApiService();

  File? _capturedImage; // للصورة الملتقطة بالجوال
  bool _isLoading = false;
  final String rpiIp = "192.168.1.33"; // ✅ عنوان الرازبيري الخاص بكِ

  @override
  void initState() {
    super.initState();
    _playInstruction(); // ✅ تشغيل صوت cube.mp3 فوراً
  }

  @override
  void dispose() {
    _instructionPlayer.dispose();
    super.dispose();
  }

  Future<void> _playInstruction() async {
    try {
      await _instructionPlayer.play(AssetSource('audio/cube.mp3'));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  // 📸 التقاط الصورة باستخدام كاميرا الجوال
  Future<void> _captureImageMobile() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _capturedImage = File(image.path);
      });
    }
  }

  // 🚀 دالة الإرسال والتحليل (تتعامل مع الجوال أو الهاردوير)
  Future<void> _submitAndAnalyze() async {
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result;

      if (SessionContext.testMode == TestMode.hardware) {
        // 🖥️ مسار الهاردوير: سحب الصورة من الرازبيري وتحليلها
        debugPrint("--- [HARDWARE MODE] جاري سحب صورة المكعب من الرازبيري ---");
        result = await _apiService.processHardwareTask(
          rpiIp: rpiIp,
          taskType: "image",
          functionName: "checkCube",
        );
      } else {
        // 📱 مسار الجوال: إرسال الصورة الملتقطة محلياً
        if (_capturedImage == null) return;
        debugPrint("--- [MOBILE MODE] جاري إرسال صورة المكعب من الجوال ---");
        result = await _apiService.checkVision(_capturedImage!.path, "cube");
      }

      // ✅ [تحقق] طباعة النتيجة في الكونسول
      debugPrint("--- !!! CUBE TEST RESULT !!! ---");
      debugPrint("Score: ${result['score']}");
      debugPrint("Analysis: ${result['analysis']}");
      debugPrint("---------------------------------");

      // ✅ حفظ السكور في الخزنة
      TestSession.cubeScore = (result['score'] as int? ?? 0);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClockDrawingScreen()),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("خطأ في التحليل: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = SessionContext.testMode == TestMode.mobile;

    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'رسم المكعب',
          instruction: isMobile
              ? 'ارسم مكعباً ثلاثي الأبعاد كما في المثال، ثم التقط صورة للرسم.'
              : 'ارسم المكعب على الورقة أمام الجهاز الخارجي، ثم اضغط التقاط.',
          content: Column(
            children: [
              // مثال المكعب يظهر دائماً
              Image.asset('assets/images/cube_example.png', height: 160),
              const SizedBox(height: 24),

              if (isMobile) ...[
                // واجهة الجوال
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _captureImageMobile,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('التقاط صورة بالجوال'),
                ),
                const SizedBox(height: 16),
                if (_capturedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _capturedImage!,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
              ] else ...[
                // واجهة الهاردوير
                const Icon(Icons.memory, size: 80, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  "الجهاز الخارجي جاهز للالتقاط",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          // زر "التالي" يتفعل إذا التقطنا صورة (جوال) أو كنا في وضع الهاردوير
          isNextEnabled:
              (isMobile ? _capturedImage != null : true) && !_isLoading,
          onNext: _submitAndAnalyze,
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
                  Text(
                    "جاري معالجة صورة المكعب...",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
