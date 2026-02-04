import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart'; // 🔥 Haptic

import 'package:ihsana/utils/hardware_capture_service.dart';
import '../../theme/app_theme.dart';

class CubeCapturePreviewScreen extends StatefulWidget {
  final bool isMobile;

  const CubeCapturePreviewScreen({
    super.key,
    required this.isMobile,
  });

  @override
  State<CubeCapturePreviewScreen> createState() =>
      _CubeCapturePreviewScreenState();
}

class _CubeCapturePreviewScreenState
    extends State<CubeCapturePreviewScreen> {
  Uint8List? _imageBytes;
  String? _imagePath;
  bool _loading = false;

  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _capture();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playVoice(String asset) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> _stopVoice() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  Future<void> _capture() async {
    setState(() => _loading = true);

    try {
      if (widget.isMobile) {
        final XFile? image =
            await _picker.pickImage(source: ImageSource.camera);
        if (image == null) return;

        _imagePath = image.path;
        _imageBytes = await File(image.path).readAsBytes();
      } else {
        final path = await HardwareCaptureService.captureImage();
        _imagePath = path;
        _imageBytes = await File(path).readAsBytes();
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // ===== العنوان =====
              Text(
                'تأكيد الصورة',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'تأكد أن الرسم واضح ومكتمل داخل الإطار',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade700,
                      fontSize: 18,
                    ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // ===== حاوية الصورة (محسّنة بصريًا فقط) =====
              Expanded(
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator()
                      : _imageBytes != null
                          ? Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color:
                                      AppTheme.primary.withOpacity(0.6),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withOpacity(0.08),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                          : const SizedBox(),
                ),
              ),

              const SizedBox(height: 28),

              // ===== الأزرار (تعديل نطق الصوت فقط) =====
              Row(
                children: [
                  // إعادة الالتقاط
                  Expanded(
                    child: GestureDetector(
                      onLongPressStart: (_) async {
                        HapticFeedback.selectionClick();
                        await _playVoice('audio/retake_photo.mp3');
                      },
                      onLongPressEnd: (_) => _stopVoice(),
                      onTapCancel: _stopVoice,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, size: 26),
                        label: const Text(
                          'إعادة الالتقاط',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: BorderSide(
                            color: AppTheme.primary,
                            width: 2.2,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          _stopVoice(); // إيقاف الصوت فوراً عند الضغط الفعلي
                          _capture();
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // تأكيد
                  Expanded(
                    child: GestureDetector(
                      onLongPressStart: (_) async {
                        HapticFeedback.selectionClick();
                        await _playVoice('audio/confirm_photo.mp3');
                      },
                      onLongPressEnd: (_) => _stopVoice(),
                      onTapCancel: _stopVoice,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 26),
                        label: const Text(
                          'تأكيد',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _imageBytes == null
                            ? null
                            : () {
                                _stopVoice(); // إيقاف الصوت فوراً عند الضغط الفعلي
                                Navigator.pop(context, {
                                  'path': _imagePath!,
                                  'bytes': _imageBytes!,
                                });
                              },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}