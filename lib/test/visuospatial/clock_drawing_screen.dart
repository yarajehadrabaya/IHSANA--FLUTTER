import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:ihsana/utils/hardware_capture_service.dart'; // ✅ سيرفس الهاردوير

import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';
import '../naming/naming_lion_screen.dart';

class ClockDrawingScreen extends StatefulWidget {
  const ClockDrawingScreen({super.key});

  @override
  State<ClockDrawingScreen> createState() => _ClockDrawingScreenState();
}

class _ClockDrawingScreenState extends State<ClockDrawingScreen> {
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _instructionPlayer = AudioPlayer();
  final MocaApiService _apiService = MocaApiService();

  Uint8List? _imageBytes;
  String? _imagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _playInstruction();
  }

  @override
  void dispose() {
    _instructionPlayer.dispose();
    super.dispose();
  }

  Future<void> _playInstruction() async {
    try {
      await _instructionPlayer.play(AssetSource('audio/clock.mp3'));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  // ================= 📱 MOBILE CAMERA =================
  Future<void> _captureImageMobile() async {
    // تصفير الصورة القديمة فوراً لكسر الكاش
    setState(() {
      _imageBytes = null;
      _imagePath = null;
    });

    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera, 
      imageQuality: 85
    );

    if (image == null) return;

    final bytes = await File(image.path).readAsBytes();

    // طرد الصورة القديمة من ذاكرة فلاتر
    await PaintingBinding.instance.imageCache.evict(FileImage(File(image.path)));

    setState(() {
      _imagePath = image.path;
      _imageBytes = bytes;
    });
    
    debugPrint('📷 Mobile Clock image captured: ${image.path}');
  }

  // ================= 🖥️ HARDWARE CAMERA =================
  Future<void> _captureImageHardware() async {
    setState(() {
      _isLoading = true;
      _imageBytes = null;
      _imagePath = null;
    });

    try {
      // طلب الصورة من الرايزبري باي
      final imagePath = await HardwareCaptureService.captureImage();
      final bytes = await File(imagePath).readAsBytes();

      // تنظيف كاش الصور إجبارياً
       PaintingBinding.instance.imageCache.clear();
       PaintingBinding.instance.imageCache.clearLiveImages();

      setState(() {
        _imagePath = imagePath;
        _imageBytes = bytes;
      });

      debugPrint('📷 Hardware Clock image captured: $imagePath');
    } catch (e) {
      debugPrint('❌ Hardware capture error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في التقاط الصورة من الجهاز الخارجي')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= 🚀 ANALYZE & SUBMIT =================
  Future<void> _submitAndAnalyze() async {
    if (_imagePath == null) return;

    setState(() => _isLoading = true);

    try {
      // إرسال الصورة لـ API الساعة (Hugging Face)
      final result = await _apiService.checkVision(_imagePath!, 'clock');

      final score = result['score'] ?? 0;
      // ✅ حفظ النتيجة في الخزنة (من 3 نقاط)
      TestSession.clockScore = score;

      // 🧪 طباعة النتيجة للفحص
      debugPrint('====================================');
      debugPrint('🕒 CLOCK SCORE: $score / 3');
      debugPrint('📊 Analysis: ${result['analysis']}');
      debugPrint('====================================');

      if (mounted) {
        // الانتقال للقسم التالي (الأسد)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NamingLionScreen()),
        );
      }
    } catch (e) {
      debugPrint('❌ Clock Analyze error:$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ أثناء تحليل صورة الساعة')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = SessionContext.testMode == TestMode.mobile;

    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'رسم الساعة',
          instruction: isMobile
              ? 'ارسم ساعة كاملة بالأرقام والعقارب (11:10) ثم صورها بالجوال.'
              : 'ارسم الساعة على الورقة أمام الجهاز الخارجي ثم اضغط التقاط.',
          content: Column(
            children: [
              const SizedBox(height: 10),
              
              // زر الالتقاط (يتغير حسب المود)
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: Text(isMobile ? 'التقاط بالجوال' : 'التقاط من الجهاز'),
                onPressed: _isLoading
                    ? null
                    : (isMobile ? _captureImageMobile : _captureImageHardware),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),

              const SizedBox(height: 24),

              // 🖼️ منطقة المعاينة (Preview) مع حل مشكلة الكاش
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (_imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              _imageBytes!,
                              key: UniqueKey(), // 🔥 يضمن تحديث الصورة فوراً عند إعادة الالتقاط
                              fit: BoxFit.contain,
                            ),
                          )
                        : const Center(
                            child: Text('بانتظار التقاط الصورة...', 
                              style: TextStyle(color: Colors.grey)),
                          )),
              ),
              
              if (_imageBytes != null && !_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text("✅ تم التقاط الصورة بنجاح", 
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          isNextEnabled: _imageBytes != null && !_isLoading,
          onNext: _submitAndAnalyze,
          onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
      ],
    );
  }
}
