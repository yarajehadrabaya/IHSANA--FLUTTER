import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:ihsana/utils/hardware_capture_service.dart';

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
      await _instructionPlayer.play(
        AssetSource('audio/clock.mp3'),
      );
    } catch (_) {}
  }

  // ================= 📱 MOBILE CAMERA =================
  Future<void> _captureImageMobile() async {
    setState(() {
      _imageBytes = null;
      _imagePath = null;
    });

    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) return;

    final bytes = await File(image.path).readAsBytes();

    await PaintingBinding.instance.imageCache
        .evict(FileImage(File(image.path)));

    setState(() {
      _imagePath = image.path;
      _imageBytes = bytes;
    });
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

      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      setState(() {
        _imagePath = imagePath;
        _imageBytes = bytes;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في التقاط الصورة من الجهاز الخارجي'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ================= 🚀 ANALYZE & SUBMIT =================
  Future<void> _submitAndAnalyze() async {
    if (_imagePath == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.checkVision(
        _imagePath!,
        'clock',
      );

      final score = result['score'] ?? 0;
      TestSession.clockScore = score;

      if (mounted) {
        TestSession.nextQuestion();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const NamingLionScreen(),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ أثناء تحليل صورة الساعة'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = SessionContext.testMode == TestMode.mobile;

    return TestQuestionScaffold(
      title: 'رسم الساعة',
      instruction: isMobile
          ? 'ارسم ساعة كاملة بالأرقام والعقارب (11:10) ثم صورها بالجوال.'
          : 'ارسم الساعة على الورقة أمام الجهاز الخارجي ثم اضغط التقاط.',
      content: Column(
        children: [
          const SizedBox(height: 10),

          // ===== زر الالتقاط / إعادة الالتقاط =====
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(
                _imageBytes == null ? Icons.camera_alt : Icons.refresh,
              ),
              label: Text(
                _imageBytes == null
                    ? (isMobile ? 'التقاط بالجوال' : 'التقاط من الجهاز')
                    : 'إعادة التقاط الصورة',
                textAlign: TextAlign.center,
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _isLoading
                  ? null
                  : (isMobile
                      ? _captureImageMobile
                      : _captureImageHardware),
            ),
          ),

          const SizedBox(height: 24),

          // ===== معاينة الصورة =====
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          _imageBytes!,
                          key: UniqueKey(),
                          fit: BoxFit.contain,
                        ),
                      )
                    : const Center(
                        child: Text(
                          'بانتظار التقاط الصورة...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )),
          ),

          // ===== رسالة نجاح =====
          if (_imageBytes != null && !_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                '✅ تم التقاط الصورة بنجاح',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      isNextEnabled: _imageBytes != null && !_isLoading,
      onNext: _submitAndAnalyze,
      onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
    );
  }
}
