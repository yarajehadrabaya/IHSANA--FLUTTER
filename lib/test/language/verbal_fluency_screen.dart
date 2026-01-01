import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';

class VerbalFluencyScreen extends StatefulWidget {
  const VerbalFluencyScreen({super.key});

  @override
  State<VerbalFluencyScreen> createState() =>
      _VerbalFluencyScreenState();
}

class _VerbalFluencyScreenState
    extends State<VerbalFluencyScreen> {
  static const int _totalSeconds = 60;

  int _remainingSeconds = _totalSeconds;
  Timer? _timer;

  bool _isRunning = false;
  bool _isFinished = false;

  bool get _canStart => !_isRunning && !_isFinished;
  bool get _canContinue => _isFinished;

  void _startTask() {
    setState(() {
      _isRunning = true;
      _remainingSeconds = _totalSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds == 0) {
        timer.cancel();
        setState(() {
          _isRunning = false;
          _isFinished = true;
        });
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'الطلاقة اللفظية',
      instruction:
          'اذكر أكبر عدد ممكن من الكلمات التي تبدأ بحرف (ف) خلال دقيقة واحدة.',
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ⏱️ المؤقت
          Text(
            'الوقت المتبقي: $_remainingSeconds ثانية',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 32),

          // 🎤 بدء المهمة
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canStart ? _startTask : null,
              icon: const Icon(Icons.mic),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  _isRunning
                      ? 'جاري التسجيل...'
                      : 'بدء المهمة',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          if (_isFinished)
            const Text(
              'انتهى الوقت وتم تسجيل الإجابة الصوتية',
              style: TextStyle(
                color: Colors.green,
                fontSize: 16,
              ),
            ),
        ],
      ),
      isNextEnabled: _canContinue,
      onNext: () {
        // NEXT: Abstraction
      },
      onEndSession: () {
        Navigator.popUntil(context, (r) => r.isFirst);
      },
    );
  }
}
