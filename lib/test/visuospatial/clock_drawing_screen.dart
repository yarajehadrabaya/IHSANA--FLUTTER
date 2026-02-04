import 'dart:io';
import 'dart:typed_data';
import 'package:ihsana/test/naming/naming_intro_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'package:ihsana/utils/hardware_capture_service.dart';
import '../../utils/moca_api_service.dart';
import '../../utils/test_session.dart';
import '../../session/session_context.dart';
import '../test_mode_selection_screen.dart';

class ClockDrawingScreen extends StatefulWidget {
  const ClockDrawingScreen({super.key});

  @override
  State<ClockDrawingScreen> createState() => _ClockDrawingScreenState();
}

class _ClockDrawingScreenState extends State<ClockDrawingScreen> {
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _instructionPlayer = AudioPlayer();
  final AudioPlayer _actionAudioPlayer = AudioPlayer();
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
    _actionAudioPlayer.dispose();
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
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) return;

    final bytes = await File(image.path).readAsBytes();

    setState(() {
      _imagePath = image.path;
      _imageBytes = bytes;
    });
  }

  // ================= 🖥️ HARDWARE CAMERA =================
  Future<void> _captureImageHardware() async {
    setState(() => _isLoading = true);

    try {
      final imagePath = await HardwareCaptureService.captureImage();
      final bytes = await File(imagePath).readAsBytes();

      setState(() {
        _imagePath = imagePath;
        _imageBytes = bytes;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ================= 🚀 ANALYZE =================
  Future<void> _submitAndAnalyze() async {
    if (_imagePath == null) return;

    setState(() => _isLoading = true);

    try {
      final result =
          await _apiService.checkVision(_imagePath!, 'clock');

      TestSession.clockScore = result['score'] ?? 0;

      if (!mounted) return;
      TestSession.nextQuestion();
      Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const NamingIntroScreen(),
  ),
);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== صوت إعادة الالتقاط =====
  Future<void> _playRetakeVoice() async {
    try {
      await _actionAudioPlayer.stop();
      await _actionAudioPlayer.play(
        AssetSource('audio/retake_photo.mp3'),
      );
    } catch (_) {}
  }

  Future<void> _stopRetakeVoice() async {
    try {
      await _actionAudioPlayer.stop();
    } catch (_) {}
  }

  // ===== 🔊 صوت زر الالتقاط =====
  Future<void> _playCaptureVoice() async {
    try {
      await _actionAudioPlayer.stop();
      await _actionAudioPlayer.play(
        AssetSource('audio/capture_photo.mp3'),
      );
    } catch (_) {}
  }

  Future<void> _stopCaptureVoice() async {
    try {
      await _actionAudioPlayer.stop();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile =
        SessionContext.testMode == TestMode.mobile;

    return TestQuestionScaffold(
      title: 'رسم الساعة',
      instruction: isMobile
          ? 'ارسم ساعة كاملة بالأرقام والعقارب (11:10) ثم صوّرها بالجوال.'
          : 'ارسم الساعة على الورقة أمام الجهاز ثم اضغط التقاط.',
      
      // ✅ تم تفعيل خاصية إعادة الاستماع هنا
      onRepeatInstruction: _playInstruction,

      content: Column(
        children: [
          const SizedBox(height: 12),

          Expanded(
            child: Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.45),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_imageBytes != null)
                        Image.memory(
                          _imageBytes!,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          color: Colors.grey.shade100,
                          alignment: Alignment.center,
                          child: const Text(
                            'بانتظار التقاط الصورة...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),

                      // ===== زر الالتقاط (مع صوت) =====
                      if (_imageBytes == null)
                        Center(
                          child: GestureDetector(
                            onTapDown: (_) => _playCaptureVoice(),
                            onTapUp: (_) => _stopCaptureVoice(),
                            onTapCancel: _stopCaptureVoice,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.camera_alt, size: 24),
                              label: Text(
                                isMobile
                                    ? 'التقاط بالجوال'
                                    : 'التقاط من الجهاز',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : (isMobile
                                      ? _captureImageMobile
                                      : _captureImageHardware),
                            ),
                          ),
                        ),

                      // ===== زر إعادة الالتقاط =====
                      if (_imageBytes != null)
                        Center(
                          child: GestureDetector(
                            onTapDown: (_) => _playRetakeVoice(),
                            onTapUp: (_) => _stopRetakeVoice(),
                            onTapCancel: _stopRetakeVoice,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text(
                                'إعادة الالتقاط',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.primary,
                                backgroundColor:
                                    Colors.white.withOpacity(0.75),
                                side: BorderSide(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : (isMobile
                                      ? _captureImageMobile
                                      : _captureImageHardware),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
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