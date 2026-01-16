import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../naming/naming_lion_screen.dart'; // ✅ الانتقال للأسد بعد الساعة

class ClockDrawingScreen extends StatefulWidget {
  const ClockDrawingScreen({super.key});

  @override
  State<ClockDrawingScreen> createState() => _ClockDrawingScreenState();
}

class _ClockDrawingScreenState extends State<ClockDrawingScreen> {
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _instructionPlayer = AudioPlayer();
  final MocaApiService _apiService = MocaApiService();

  File? _capturedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _playInstruction(); // ✅ تشغيل صوت الساعة فوراً
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
        "clock",
      );

      // -----------------------------------------------------------
      // >>> [تحقق] طباعة نتيجة الساعة في الكونسول <<<
      debugPrint("--- !!! CLOCK TEST RESULT !!! ---");
      debugPrint("Score: ${result['score']}");
      debugPrint("Analysis: ${result['analysis']}");
      debugPrint("---------------------------------");
      // -----------------------------------------------------------

      // ✅ حفظ السكور في خانة الساعة
      TestSession.clockScore = (result['score'] as int? ?? 0);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NamingLionScreen()),
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
          title: 'رسم الساعة',
          instruction:
              'ارسم ساعة، ضع جميع الأرقام، واجعل العقارب تشير إلى الساعة 11:10.',
          content: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _captureImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('التقاط صورة'),
              ),
              const SizedBox(height: 20),
              if (_capturedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _capturedImage!,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
          isNextEnabled: _capturedImage != null && !_isLoading,
          onNext: _submitAndNext,
          onEndSession: () =>
              Navigator.popUntil(context, (route) => route.isFirst),
        ),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
