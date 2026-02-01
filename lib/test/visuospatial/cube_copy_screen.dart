import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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
    try {
      await _instructionPlayer.play(
        AssetSource('audio/cube.mp3'),
      );
    } catch (_) {}
  }

  Future<void> _captureImageMobile() async {
    setState(() {
      _imageBytes = null;
      _imagePath = null;
    });

    final XFile? image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);

    if (image == null) return;

    final file = File(image.path);
    final bytes = await file.readAsBytes();

    setState(() {
      _imagePath = image.path;
      _imageBytes = bytes;
    });
  }

  Future<void> _captureImageHardware() async {
    setState(() {
      _isLoading = true;
      _imageBytes = null;
      _imagePath = null;
    });

    try {
      final imagePath = await HardwareCaptureService.captureImage();
      final file = File(imagePath);
      final bytes = await file.readAsBytes();

      setState(() {
        _imagePath = imagePath;
        _imageBytes = bytes;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في التقاط الصورة')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitAndAnalyze() async {
    if (_imagePath == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.checkVision(
        _imagePath!,
        'cube',
      );

      TestSession.cubeScore = result['score'] ?? 0;

      if (mounted) {
        TestSession.nextQuestion();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ClockDrawingScreen(),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطأ في تحليل الصورة')),
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
      title: 'رسم المكعب',
      instruction:
          isMobile ? 'التقط صورة باستخدام الجوال' : 'التقط صورة من الجهاز الخارجي',
      content: Column(
        children: [
          Image.asset(
            'assets/images/cube_example.png',
            height: 140,
          ),
          const SizedBox(height: 20),

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

          const SizedBox(height: 20),

          // ===== معاينة الصورة =====
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _imageBytes!,
                          key: ValueKey(_imagePath),
                          fit: BoxFit.contain,
                        ),
                      )
                    : const Center(child: Text('لا توجد صورة'))),
          ),
        ],
      ),
      isNextEnabled: _imageBytes != null && !_isLoading,
      onNext: _submitAndAnalyze,
      onEndSession: () =>
          Navigator.popUntil(context, (route) => route.isFirst),
    );
  }
}
