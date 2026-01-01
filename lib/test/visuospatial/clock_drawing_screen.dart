import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';

class ClockDrawingScreen extends StatefulWidget {
  const ClockDrawingScreen({super.key});

  @override
  State<ClockDrawingScreen> createState() =>
      _ClockDrawingScreenState();
}

class _ClockDrawingScreenState
    extends State<ClockDrawingScreen> {
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
      title: 'رسم الساعة',
      instruction:
          'ارسم ساعة، ضع جميع الأرقام، واجعل العقارب تشير إلى الساعة 11:10.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: _captureImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('التقاط صورة'),
          ),

          const SizedBox(height: 20),

          if (_capturedImage != null)
            Column(
              children: [
                const Text(
                  'الصورة الملتقطة',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
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
        ],
      ),
      isNextEnabled: _capturedImage != null,
      onNext: () {
        // NEXT: Naming - Lion
      },
      onEndSession: () {
        Navigator.popUntil(context, (route) => route.isFirst);
      },
    );
  }
}
