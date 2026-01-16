import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import 'clock_drawing_screen.dart'; // ✅ الانتقال للساعة بعد المكعب

class CubeCopyScreen extends StatefulWidget {
  const CubeCopyScreen({super.key});

  @override
  State<CubeCopyScreen> createState() => _CubeCopyScreenState();
}

class _CubeCopyScreenState extends State<CubeCopyScreen> {
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _instructionPlayer = AudioPlayer();
  final MocaApiService _apiService = MocaApiService();

  File? _capturedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _playInstruction(); // ✅ تشغيل صوت المكعب فوراً
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

  Future<void> _captureImage() async {
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

  Future<void> _submitAndNext() async {
    if (_capturedImage == null) return;
    setState(() => _isLoading = true);
    try {
      final result = await _apiService.checkVision(
        _capturedImage!.path,
        "cube",
      );

      // -----------------------------------------------------------
      // >>> [تحقق] طباعة نتيجة المكعب في الكونسول <<<
      debugPrint("--- !!! CUBE TEST RESULT !!! ---");
      debugPrint("Score: ${result['score']}");
      debugPrint("Analysis: ${result['analysis']}");
      debugPrint("---------------------------------");
      // -----------------------------------------------------------

      // ✅ حفظ السكور في خانة المكعب
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
    return Stack(
      children: [
        TestQuestionScaffold(
          title: 'رسم المكعب',
          instruction:
              'ارسم مكعباً ثلاثي الأبعاد كما في المثال، ثم التقط صورة للرسم.',
          content: Column(
            children: [
              Image.asset('assets/images/cube_example.png', height: 160),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _captureImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('التقاط صورة'),
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
            ],
          ),
          isNextEnabled: _capturedImage != null && !_isLoading,
          onNext: _submitAndNext,
          onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
