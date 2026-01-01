import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';

class SentenceRepetitionScreen extends StatefulWidget {
  const SentenceRepetitionScreen({super.key});

  @override
  State<SentenceRepetitionScreen> createState() =>
      _SentenceRepetitionScreenState();
}

class _SentenceRepetitionScreenState
    extends State<SentenceRepetitionScreen> {
  bool _isPlaying = false;
  bool _hasPlayed = false;
  bool _isRecording = false;
  bool _hasRecorded = false;

  bool get _canPlay => !_hasPlayed && !_isPlaying;
  bool get _canRecord =>
      _hasPlayed && !_isPlaying && !_isRecording;
  bool get _canContinue =>
      _hasRecorded && !_isRecording;

  Future<void> _playSentence() async {
    setState(() {
      _isPlaying = true;
      _hasPlayed = true;
    });

    // ⏱️ محاكاة تشغيل الجملة
    await Future.delayed(const Duration(seconds: 5));

    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _recordResponse() async {
    setState(() {
      _isRecording = true;
    });

    // ⏱️ محاكاة تسجيل الصوت
    await Future.delayed(const Duration(seconds: 5));

    setState(() {
      _isRecording = false;
      _hasRecorded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'تكرار الجملة',
      instruction:
          'استمع إلى الجملة ثم أعد تكرارها كما سمعتها تماماً.',
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🔊 تشغيل الجملة
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canPlay ? _playSentence : null,
              icon: const Icon(Icons.volume_up),
              label: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  _isPlaying
                      ? 'جاري تشغيل الجملة...'
                      : 'تشغيل الجملة',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 🎤 تسجيل الإجابة
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
        // NEXT: Verbal Fluency
      },
      onEndSession: () {
        Navigator.popUntil(context, (r) => r.isFirst);
      },
    );
  }
}
