import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';

class DigitSpanBackwardScreen extends StatefulWidget {
  const DigitSpanBackwardScreen({super.key});

  @override
  State<DigitSpanBackwardScreen> createState() =>
      _DigitSpanBackwardScreenState();
}

class _DigitSpanBackwardScreenState
    extends State<DigitSpanBackwardScreen> {
  bool _isPlaying = false;
  bool _hasPlayed = false;
  bool _isRecording = false;
  bool _hasRecorded = false;

  bool get _canPlay => !_hasPlayed && !_isPlaying;
  bool get _canRecord =>
      _hasPlayed && !_isPlaying && !_isRecording;
  bool get _canContinue =>
      _hasRecorded && !_isRecording;

  Future<void> _playDigits() async {
    setState(() {
      _isPlaying = true;
      _hasPlayed = true;
    });

    // ⏱️ محاكاة تشغيل الصوت
    await Future.delayed(const Duration(seconds: 4));

    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _recordResponse() async {
    setState(() {
      _isRecording = true;
    });

    // ⏱️ محاكاة تسجيل الصوت
    await Future.delayed(const Duration(seconds: 4));

    setState(() {
      _isRecording = false;
      _hasRecorded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'تكرار الأرقام بالعكس',
      instruction:
          'استمع إلى سلسلة من الأرقام، ثم أعد تكرارها بالترتيب العكسي.',
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canPlay ? _playDigits : null,
              icon: const Icon(Icons.volume_up),
              label: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  _isPlaying
                      ? 'جاري تشغيل الأرقام...'
                      : 'تشغيل الأرقام',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canRecord ? _recordResponse : null,
              icon: const Icon(Icons.mic),
              label: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
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
        // NEXT: Letter A Test
      },
      onEndSession: () {
        Navigator.popUntil(context, (r) => r.isFirst);
      },
    );
  }
}
