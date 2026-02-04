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
import 'clock_drawing_screen.dart';
import 'cube_capture_preview_screen.dart';

class CubeCopyScreen extends StatefulWidget {
  const CubeCopyScreen({super.key});

  @override
  State<CubeCopyScreen> createState() => _CubeCopyScreenState();
}

class _CubeCopyScreenState extends State<CubeCopyScreen> {
  final AudioPlayer _instructionPlayer = AudioPlayer();
  final AudioPlayer _retakeAudioPlayer = AudioPlayer(); // 🔊 زر الإعادة
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
    _retakeAudioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playInstruction() async {
    try {
      await _instructionPlayer.play(
        AssetSource('audio/cube.mp3'),
      );
    } catch (_) {}
  }

  // ===== صوت إعادة الالتقاط (Press & Hold) =====
  Future<void> _playRetakeVoice() async {
    try {
      await _retakeAudioPlayer.stop();
      await _retakeAudioPlayer.play(
        AssetSource('audio/retake_photo.mp3'),
      );
    } catch (_) {}
  }

  Future<void> _stopRetakeVoice() async {
    try {
      await _retakeAudioPlayer.stop();
    } catch (_) {}
  }

  // ================= 🚀 ANALYZE & SUBMIT (لم يُمس) =================
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
      debugPrint('🧠 Cube analysis score: $score');

      if (!mounted) return;

      TestSession.nextQuestion();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ClockDrawingScreen(),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ أثناء تحليل صورة المكعب'),
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
      title: 'نسخ المكعب',
      instruction: isMobile
          ? 'انسخ شكل المكعب على الورقة ثم صوره بالهاتف.'
          : 'انسخ شكل المكعب على الورقة ثم صوره بالكاميرا.',
      
      // ✅ تفعيل زر إعادة الاستماع بربطه بالدالة الموجودة مسبقاً
      onRepeatInstruction: _playInstruction,

      content: SingleChildScrollView(
        child: Column(
          children: [
            // ===== زر التصوير / إعادة الالتقاط (تم رفعه للأعلى) =====
            SizedBox(
              width: 300,
              child: _imageBytes == null
                  ? ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text(
                        'التقاط الصورة',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CubeCapturePreviewScreen(
                                    isMobile: isMobile,
                                  ),
                                ),
                              );

                              if (result != null && mounted) {
                                setState(() {
                                  _imagePath = result['path'];
                                  _imageBytes = result['bytes'];
                                });
                              }
                            },
                    )
                  : GestureDetector(
                      onTapDown: (_) => _playRetakeVoice(),
                      onTapUp: (_) => _stopRetakeVoice(),
                      onTapCancel: _stopRetakeVoice,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(30),
                        onTap: _isLoading
                            ? null
                            : () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CubeCapturePreviewScreen(
                                      isMobile: isMobile,
                                    ),
                                  ),
                                );

                                if (result != null && mounted) {
                                  setState(() {
                                    _imagePath = result['path'];
                                    _imageBytes = result['bytes'];
                                  });
                                }
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.08),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.6),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.refresh,
                                size: 22,
                                color: Colors.blue,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'إعادة التقاط الصورة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 5), // مسافة بسيطة بين الزر والصورة

            // ===== صورة المكعب (أصبحت بالأسفل) =====
            Image.asset(
              'assets/images/cube_example.png',
              width: MediaQuery.of(context).size.width * 0.85,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
      isNextEnabled: _imageBytes != null && !_isLoading,
      onNext: _submitAndAnalyze,
      onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
    );
  }
}