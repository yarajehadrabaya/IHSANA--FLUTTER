import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import '../../utils/test_session.dart';
import 'subtraction_screen.dart';

class LetterAScreen extends StatefulWidget {
  const LetterAScreen({super.key});
  @override
  State<LetterAScreen> createState() => _LetterAScreenState();
}

class _LetterAScreenState extends State<LetterAScreen> {
  final AudioPlayer _p = AudioPlayer();
  bool _isPlay = false, _done = false;
  bool _isFeedbackActive = false; // ✅ حالة لتغيير لون الزر عند الضغط
  int _err = 0;
  final List<double> _ts = [9.0, 11.5, 15.0, 18.0, 19.0, 20.0, 23.0];
  final List<double> _hits = [];

  Future<void> _start() async {
    setState(() {
      _isPlay = true;
      _err = 0;
      _hits.clear();
      _done = false;
    });
    await _p.play(AssetSource('audio/attention-a.mp3')); // ✅ تصحيح المسار
    _p.onPlayerComplete.listen((_) {
      if (mounted) {
        _calc();
        setState(() {
          _isPlay = false;
          _done = true;
        });
      }
    });
  }

  void _tap() async {
    if (!_isPlay) return;

    // ✅ تأثير بصري للكبسة
    setState(() => _isFeedbackActive = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _isFeedbackActive = false);
    });

    final pos = await _p.getCurrentPosition();
    if (pos == null) return;
    double sec = pos.inMilliseconds / 1000.0;
    bool ok = false;
    for (var t in _ts) {
      if (sec >= t && sec <= t + 1.2) {
        if (!_hits.contains(t)) {
          _hits.add(t);
          ok = true;
        }
        break;
      }
    }
    if (!ok) _err++;
  }

  void _calc() {
    int miss = _ts.length - _hits.length;
    TestSession.letterAScore = ((_err + miss) <= 1) ? 1 : 0;
    debugPrint("--- Letter A Score: ${TestSession.letterAScore} ---");
  }

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'حرف الألف',
      content: Column(
        children: [
          if (!_isPlay && !_done)
            ElevatedButton(onPressed: _start, child: const Text("ابدأ")),
          const SizedBox(height: 40),
          GestureDetector(
            onTapDown: (_) => _tap(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),

              width: 160,
              height: 160,
              decoration: BoxDecoration(
                // ✅ يتغير اللون للأبيض عند الضغط (Feedback)
                color: _isFeedbackActive
                    ? Colors.white
                    : (_isPlay ? Colors.red : Colors.grey),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: _isFeedbackActive
                    ? [const BoxShadow(color: Colors.white, blurRadius: 20)]
                    : [],
              ),
              child: Center(
                child: Text(
                  _isPlay ? "انقر!" : "انتظر",
                  style: TextStyle(
                    color: _isFeedbackActive ? Colors.red : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      isNextEnabled: _done,
      onNext: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubtractionScreen()),
      ),
      onEndSession: () => Navigator.popUntil(context, (r) => r.isFirst),
    );
  }
}
