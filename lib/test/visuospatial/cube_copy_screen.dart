import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/test_question_scaffold.dart';

class CubeCopyScreen extends StatefulWidget {
  const CubeCopyScreen({super.key});

  @override
  State<CubeCopyScreen> createState() => _CubeCopyScreenState();
}

class _CubeCopyScreenState extends State<CubeCopyScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;

  Future<void> _captureImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _capturedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'رسم المكعب',
      instruction:
          'ارسم مكعباً ثلاثي الأبعاد كما في المثال، ثم التقط صورة للرسم.',
      content: Column(
        children: [
          // 🟦 Cube Example
          Image.asset(
            'assets/images/cube_example.png',
            height: 160,
          ),

          const SizedBox(height: 24),

          // 📷 Capture Button
          ElevatedButton.icon(
            onPressed: _captureImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('التقاط صورة'),
          ),

          const SizedBox(height: 16),

          // 🖼️ Preview
          if (_capturedImage != null)
            Column(
              children: [
                const Text(
                  'الصورة الملتقطة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
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
        ],
      ),
      isNextEnabled: _capturedImage != null,
      onNext: () {
        // NEXT: Trail Making
      },
      onEndSession: () {
        Navigator.popUntil(context, (r) => r.isFirst);
      },
    );
  }
}
