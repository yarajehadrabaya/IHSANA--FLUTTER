import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';

class LetterAScreen extends StatefulWidget {
  const LetterAScreen({super.key});

  @override
  State<LetterAScreen> createState() => _LetterAScreenState();
}

class _LetterAScreenState extends State<LetterAScreen> {
  bool _isPlaying = false;
  bool _hasPlayed = false;
  int _tapCount = 0;

  bool get _canPlay => !_hasPlayed && !_isPlaying;
  bool get _canContinue => _hasPlayed && !_isPlaying;

  Future<void> _playLetters() async {
    setState(() {
      _isPlaying = true;
      _hasPlayed = true;
      _tapCount = 0; // نبدأ العد من الصفر
    });

    // ⏱️ محاكاة تشغيل الحروف
    await Future.delayed(const Duration(seconds: 8));

    setState(() {
      _isPlaying = false;
    });
  }

  void _tapOnA() {
    if (_isPlaying) {
      setState(() {
        _tapCount++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'حرف الألف',
      instruction:
          'سيتم تشغيل مجموعة من الحروف. اضغط على الزر كلما سمعت حرف (أ).',
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🔊 تشغيل الحروف
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canPlay ? _playLetters : null,
              icon: const Icon(Icons.volume_up),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  _isPlaying
                      ? 'جاري تشغيل الحروف...'
                      : 'تشغيل الحروف',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 👆 زر الضغط
          SizedBox(
            width: double.infinity,
            height: 80,
            child: ElevatedButton(
              onPressed: _isPlaying ? _tapOnA : null,
              child: const Text(
                'اضغط عند سماع (أ)',
                style: TextStyle(fontSize: 22),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 🔢 العداد
          Text(
            'عدد الضغطات: $_tapCount',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      isNextEnabled: _canContinue,
      onNext: () {
        // NEXT: Language Section
      },
      onEndSession: () {
        Navigator.popUntil(context, (r) => r.isFirst);
      },
    );
  }
}
