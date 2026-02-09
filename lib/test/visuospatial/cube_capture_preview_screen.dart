import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

import '../../theme/app_theme.dart';
import '../../session/session_context.dart';
import 'package:ihsana/utils/hardware_capture_service.dart';

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

  WebViewController? _webController;

  @override
  void initState() {
    super.initState();

    if (widget.isMobile) {
      _capture();
    } else {
      _initWebView();
    }
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse('${SessionContext.raspberryBaseUrl}/video-stream'),
      );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // ================= 🔊 VOICE =================
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

  // ================= 📸 CAPTURE =================
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
        final res = await http.post(
          Uri.parse('${SessionContext.raspberryBaseUrl}/capture-image'),
        );

        if (res.statusCode != 200) {
          throw Exception('Capture failed');
        }

        final dir = await Directory.systemTemp.createTemp();
        final path = '${dir.path}/cube.jpg';
        final file = File(path);
        await file.writeAsBytes(res.bodyBytes);

        _imagePath = path;
        _imageBytes = res.bodyBytes;
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ================= 🔄 RESET =================
  void _resetCapture() {
    if (widget.isMobile) {
      _capture();
    } else {
      _initWebView();
      setState(() {
        _imageBytes = null;
        _imagePath = null;
      });
    }
  }

  // ================= 🧱 UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'تأكيد الصورة',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'تأكد أن الرسم واضح ومكتمل داخل الإطار',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                        color: Colors.grey.shade700, fontSize: 18),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // ===== PREVIEW =====
              Expanded(
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator()
                      : Container(
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
                            borderRadius:
                                BorderRadius.circular(18),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                /// ===== عرض موحّد (ستريم + صورة) =====
                                if (!widget.isMobile &&
                                    _imageBytes == null &&
                                    _webController != null)
                                  ClipRect(
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        width: 640,
                                        height: 480,
                                        child: WebViewWidget(
                                          controller:
                                              _webController!,
                                        ),
                                      ),
                                    ),
                                  )
                                else if (_imageBytes != null)
                                  ClipRect(
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        width: 640,
                                        height: 480,
                                        child: Image.memory(
                                          _imageBytes!,
                                        ),
                                      ),
                                    ),
                                  ),

                                /// ===== زر الالتقاط =====
                                if (!widget.isMobile &&
                                    _imageBytes == null)
                                  Center(
                                    child: ElevatedButton.icon(
                                      icon: const Icon(
                                          Icons.camera_alt,
                                          size: 28),
                                      label: const Text(
                                        'التقاط',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                      style:
                                          ElevatedButton.styleFrom(
                                        backgroundColor:
                                            AppTheme.primary
                                                .withOpacity(0.9),
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 28,
                                          vertical: 16,
                                        ),
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  18),
                                        ),
                                      ),
                                      onPressed: _capture,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 28),

              // ===== الأزرار =====
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onLongPressStart: (_) async {
                        HapticFeedback.selectionClick();
                        await _playVoice(
                            'audio/retake_photo.mp3');
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
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          _stopVoice();
                          _resetCapture();
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: GestureDetector(
                      onLongPressStart: (_) async {
                        HapticFeedback.selectionClick();
                        await _playVoice(
                            'audio/confirm_photo.mp3');
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
                          padding:
                              const EdgeInsets.symmetric(
                                  vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _imageBytes == null
                            ? null
                            : () {
                                _stopVoice();
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
