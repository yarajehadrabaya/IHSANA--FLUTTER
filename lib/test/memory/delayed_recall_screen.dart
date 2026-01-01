import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';

class DelayedRecallScreen extends StatefulWidget {
  const DelayedRecallScreen({super.key});

  @override
  State<DelayedRecallScreen> createState() =>
      _DelayedRecallScreenState();
}

class _DelayedRecallScreenState
    extends State<DelayedRecallScreen> {
  bool _isRecording = false;
  bool _hasRecorded = false;

  bool get _canRecord => !_isRecording;
  bool get _canContinue => _hasRecorded && !_isRecording;

  Future<void> _recordAnswer() async {
    setState(() {
      _isRecording = true;
    });

    // ⏱️ محاكاة تسجيل الصوت
    await Future.delayed(const Duration(seconds: 6));

    setState(() {
      _isRecording = false;
      _hasRecorded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'استدعاء الكلمات',
      instruction:
          'اذكر الكلمات التي سمعتها سابقاً. حاول تذكر أكبر عدد ممكن دون أي مساعدة.',
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canRecord ? _recordAnswer : null,
              icon: const Icon(Icons.mic),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  _isRecording
                      ? 'جاري تسجيل الإجابة...'
                      : 'تسجيل الإجابة',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (_hasRecorded)
            const Text(
              'تم تسجيل الإجابة الصوتية',
              style: TextStyle(
                color: Colors.green,
                fontSize: 16,
              ),
            ),
        ],
      ),
      isNextEnabled: _canContinue,
      onNext: () {
        // NEXT: Orientation
      },
      onEndSession: () {
        Navigator.popUntil(context, (r) => r.isFirst);
      },
    );
  }
}
