import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ihsana/test/attention/attention_intro_screen.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import '../attention/digit_span_forward_screen.dart';
import '../../utils/test_session.dart';

class MemoryEncodingScreen extends StatefulWidget {
  const MemoryEncodingScreen({super.key});

  @override
  State<MemoryEncodingScreen> createState() =>
      _MemoryEncodingScreenState();
}

class _MemoryEncodingScreenState extends State<MemoryEncodingScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  int _count = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    // ===== نبض أيقونة السماعة =====
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

Future<void> _play() async {
    setState(() {
      _isPlaying = true;
      _count++;
    });

    _pulseController.repeat(reverse: true); // ▶️ يبدأ النبض

    // فحص المحاولة: إذا كانت الثانية استخدم الملف الجديد، وإلا استخدم القديم
    String assetToPlay = _count == 2 ? 'audio/memory-repeat2.mp3' : 'audio/memory-repeat.mp3';
    await _player.play(AssetSource(assetToPlay));

    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        _pulseController.stop(); // ⏹️ يوقف النبض
        setState(() => _isPlaying = false);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'حفظ الكلمات',
      instruction:
          'استمع إلى الكلمات جيدًا. يمكنك الاستماع مرتين فقط قبل الانتقال للسؤال التالي.',
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ===== CARD =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // ===== ICON (نبض أثناء التشغيل) =====
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isPlaying
                        ? Colors.blue.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.12),
                  ),
                  child: ScaleTransition(
                    scale: _isPlaying
                        ? _pulseAnimation
                        : const AlwaysStoppedAnimation(1.0),
                    child: Icon(
                      Icons.volume_up,
                      size: 64,
                      color:
                          _isPlaying ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ===== COUNTER =====
                Text(
                  'مرات الاستماع',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_count / 2',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 24),

              // ===== PLAY BUTTON =====
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    // 🔊 نطق اسم الزر عند الضغط المطول
                    onLongPressStart: (_) {
                      if (_count < 2 && !_isPlaying) {
                        _player.play(AssetSource('audio/play_words.mp3'));
                      }
                    },
                    // ⏹️ إيقاف الصوت عند رفع الإصبع (اختياري لراحة المستخدم)
                    onLongPressEnd: (_) => _player.stop(),
                    child: ElevatedButton.icon(
                      onPressed:
                          (_count < 2 && !_isPlaying) ? _play : null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('تشغيل الكلمات'),
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                // ===== HELPER TEXT =====
                if (_count < 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'يمكنك الاستماع ${2 - _count} مرة أخرى',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),

                if (_count == 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle,
                            color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'اكتمل الاستماع',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

      // ===== NEXT =====
      isNextEnabled: _count == 2 && !_isPlaying,
      onNext: () {
        TestSession.nextQuestion(); // ✅ زيادة السؤال
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AttentionIntroScreen(),
          ),
        );
      },
      onEndSession: () =>
          Navigator.popUntil(context, (r) => r.isFirst),
    );
  }
}
