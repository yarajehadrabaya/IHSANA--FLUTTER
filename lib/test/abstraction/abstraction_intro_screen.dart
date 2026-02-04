import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ihsana/test/abstraction/abstraction_question_one_screen.dart';
class AbstractionIntroScreen extends StatefulWidget {
  const AbstractionIntroScreen({super.key});

  @override
  State<AbstractionIntroScreen> createState() => _AbstractionIntroScreenState();
}

class _AbstractionIntroScreenState extends State<AbstractionIntroScreen>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _player = AudioPlayer();
  bool _canStart = false;

  AnimationController? _iconAnimation;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _iconAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(
      CurvedAnimation(
        parent: _iconAnimation!,
        curve: Curves.easeInOut,
      ),
    );

    _playVoice();
  }

  Future<void> _playVoice() async {
    _iconAnimation?.repeat(reverse: true);

    await _player.play(
      AssetSource('audio/abstraction_intro.mp3'),
    );

    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      _iconAnimation?.stop();
      setState(() => _canStart = true);
    });
  }

  Future<void> _skipVoice() async {
    await _player.stop();
    if (_iconAnimation != null && mounted) {
      if (_iconAnimation!.isAnimating) {
        _iconAnimation!.stop();
      }
    }
    setState(() => _canStart = true);
  }

  @override
  void dispose() {
    _iconAnimation?.dispose();
    _player.dispose();
    super.dispose();
  }

  Widget _instructionItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: const Color(0xFF2563EB)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                height: 1.6,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text(
          'قسم التجريد',
          style: TextStyle(fontSize: 22),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 8,
            right: 16,
            child: TextButton(
              onPressed: _canStart ? null : _skipVoice,
              child: const Text(
                'تخطي',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            child: Column(
              children: [
                if (_scaleAnimation != null)
                  ScaleTransition(
                    scale: _scaleAnimation!,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF2563EB).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology_outlined, // تغيير الأيقونة لتناسب التجريد
                        size: 50,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                const SizedBox(height: 15),
                const Text(
                  'تعليمات القسم',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _instructionItem(
                        Icons.record_voice_over_outlined,
                        'ستُعرض عليك أسئلة يتم قراءتها عليك صوتيًا.',
                      ),
                      _instructionItem(
                        Icons.mic_none,
                        'بعد سماع السؤال، قم بتسجيل إجابتك صوتيًا.',
                      ),
                      _instructionItem(
                        Icons.refresh,
                        'يمكنك إعادة تسجيل صوتك إذا لزم الأمر.',
                      ),
                      _instructionItem(
                        Icons.analytics_outlined,
                        'بعد الانتهاء اضغط على زر الإنهاء والتحليل.',
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 68,
                  child: ElevatedButton(
                    onPressed: _canStart
                        ? () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AbstractionQuestionOneScreen(),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      disabledBackgroundColor:
                          const Color(0xFF2563EB).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'بدء القسم',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}