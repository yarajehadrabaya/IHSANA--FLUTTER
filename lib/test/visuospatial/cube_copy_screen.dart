import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:ihsana/utils/hardware_capture_service.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';

import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';
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
    await _instructionPlayer.play(
      AssetSource('audio/cube.mp3'),
    );
  }

  // ================= 📱 MOBILE CAMERA =================
  Future<void> _captureImageMobile() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);

    if (image == null) return;

    final bytes = await File(image.path).readAsBytes();

    // 🔥 تنظيف كاش الصور
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    setState(() {
      _imagePath = image.path;
      _imageBytes = bytes;
    });

    debugPrint('📷 Mobile image captured: ${image.path}');
  }

  // ================= 🖥️ HARDWARE CAMERA =================
  Future<void> _captureImageHardware() async {
    setState(() {
      _isLoading = true;
      _imageBytes = null;
      _imagePath = null;
    });

    try {
      final imagePath = await HardwareCaptureService.captureImage();
      final bytes = await File(imagePath).readAsBytes();

      // 🔥 تنظيف كاش الصور (إجباري)
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      setState(() {
        _imagePath = imagePath;
        _imageBytes = bytes;
      });

      debugPrint('📷 Hardware image captured: $imagePath');
      debugPrint('🧠 Image hash: ${bytes.hashCode}');
    } catch (e) {
      debugPrint('❌ Hardware capture error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ في التقاط الصورة')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= 🚀 ANALYZE =================
  Future<void> _submitAndAnalyze() async {
    if (_imagePath == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.checkVision(
        _imagePath!,
        'cube',
      );

      final score = result['score'] ?? 0;
      TestSession.cubeScore = score;

      // 🧪 طباعة النتيجة
      debugPrint('🟦 Cube score: $score');
      debugPrint('📊 Full model response: $result');

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ClockDrawingScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Analyze error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('خطأ أثناء تحليل الصورة')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final bool isMobile = SessionContext.testMode == TestMode.mobile;

    return TestQuestionScaffold(
      title: 'رسم المكعب',
      instruction: isMobile
          ? 'ارسم المكعب ثم التقط صورة بالجوال'
          : 'ارسم المكعب أمام الكاميرا الخارجية ثم اضغط التقاط',
      content: Column(
        children: [
          Image.asset(
            'assets/images/cube_example.png',
            height: 160,
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: Text(
              isMobile ? 'التقاط بالجوال' : 'التقاط من الجهاز',
            ),
            onPressed: _isLoading
                ? null
                : (isMobile
                    ? _captureImageMobile
                    : _captureImageHardware),
          ),

          const SizedBox(height: 20),

          // 🖼️ IMAGE PREVIEW (CACHE FIXED)
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
            ),
            child: _imageBytes != null
                ? Image.memory(
                    _imageBytes!,
                    key: ValueKey(_imageBytes.hashCode), // 🔥 الحل
                    fit: BoxFit.contain,
                  )
                : const Center(
                    child: Text('لا توجد صورة'),
                  ),
          ),
        ],
      ),
      isNextEnabled: _imageBytes != null && !_isLoading,
      onNext: _submitAndAnalyze,
      onEndSession: () =>
          Navigator.popUntil(context, (r) => r.isFirst),
    );
  }
}
