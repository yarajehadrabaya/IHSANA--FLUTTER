import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'orientation_location_screen.dart';

class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key});

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioFinished = false;

  @override
  void initState() {
    super.initState();
    _playInstructionAudio();
  }

  Future<void> _playInstructionAudio() async {
    try {
      await _audioPlayer.play(
        AssetSource('audio/instruction_en.mp3'),
      );

      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isAudioFinished = true;
          });
        }
      });
    } catch (_) {
      setState(() {
        _isAudioFinished = true;
      });
    }
  }

  // ===== تخطي التعليمات =====
  void _skipAudio() {
    _audioPlayer.stop(); // 🔇 قطع الصوت فورًا
    setState(() {
      _isAudioFinished = true;
    });
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // ===== المحتوى =====
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.cardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ===== تخطي (داخل الكارد) =====
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: _skipAudio,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.primary
                                          .withOpacity(0.6),
                                      width: 1,
                                    ),
                                    color:
                                        Colors.white.withOpacity(0.9),
                                  ),
                                  child: Text(
                                    'تخطي',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ===== العنوان =====
                            Text(
                              'تعليمات الاختبار',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 24),

                            const _InstructionItem(
                              icon: Icons.timer,
                              text:
                                  'تستغرق مدة الاختبار تقريبًا من عشر إلى خمس عشرة دقيقة.',
                            ),
                            const _InstructionItem(
                              icon: Icons.volume_off,
                              text:
                                  'يرجى الجلوس في مكان هادئ وخالٍ من المقاطعات أثناء الاختبار.',
                            ),
                            const _InstructionItem(
                              icon: Icons.check_circle_outline,
                              text:
                                  'أجب عن جميع الأسئلة حسب أفضل ما تستطيع.',
                            ),
                            const _InstructionItem(
                              icon: Icons.stop_circle_outlined,
                              text:
                                  'يمكنك إنهاء الجلسة في أي وقت تشاء.',
                            ),
                            const _InstructionItem(
                              icon: Icons.edit,
                              text:
                                  'يرجى تجهيز ورقة وقلم قبل البدء بالاختبار.',
                            ),
                            const _InstructionItem(
                              icon: Icons.mic,
                              text:
                                  'الأسئلة التي تتطلّب إجابة صوتية سيتم تسجيل صوتك فيها.',
                            ),
                            const _InstructionItem(
                              icon: Icons.camera_alt,
                              text:
                                  'الأسئلة التي تتطلّب رسمًا سيتم فيها استخدام كاميرا الجهاز لتصوير الرسم.',
                            ),

                            const SizedBox(height: 32),

                            // ===== زر ابدأ الاختبار =====
                            SizedBox(
                              width: double.infinity,
                              height: 64,
                              child: ElevatedButton(
                                onPressed: _isAudioFinished
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const OrientationLocationScreen(),
                                          ),
                                        );
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isAudioFinished
                                    ? const Text(
                                        'ابدأ الاختبار',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'جاري تشغيل التعليمات الصوتية...',
                                            style:
                                                TextStyle(fontSize: 16),
                                          ),
                                        ],
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
          ),
        ),
      ),
    );
  }
}

/* ================= Instruction Item ================= */

class _InstructionItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstructionItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
