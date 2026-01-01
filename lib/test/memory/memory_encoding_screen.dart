import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';

class MemoryEncodingScreen extends StatefulWidget {
  const MemoryEncodingScreen({super.key});

  @override
  State<MemoryEncodingScreen> createState() =>
      _MemoryEncodingScreenState();
}

class _MemoryEncodingScreenState
    extends State<MemoryEncodingScreen> {
  int _playCount = 0;
  bool _isPlaying = false;

  bool get _canPlay => _playCount < 2 && !_isPlaying;
bool get _canContinue => _playCount == 2 && !_isPlaying;

  Future<void> _playWords() async {
    setState(() {
      _isPlaying = true;
      _playCount++;
    });

    // ⏱️ محاكاة تشغيل الصوت (5 ثواني)
    await Future.delayed(const Duration(seconds: 5));

    setState(() {
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      // 🧠 عنوان أوضح وأكبر
      title: 'تعلّم وحفظ الكلمات',

      // 📘 تعليمة تشرح الهدف
      instruction:
          'سيتم تشغيل قائمة من خمس كلمات. استمع جيداً وحاول حفظها، '
          'سيتم إعادة الكلمات مرتين فقط.',

      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // مسافة إضافية لإنزال المحتوى
          const SizedBox(height: 12),

          Icon(
            Icons.volume_up,
            size: 90,
            color: _canPlay
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),

          const SizedBox(height: 28),

          Text(
            'عدد مرات التشغيل: $_playCount / 2',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontSize: 20),
          ),

          const SizedBox(height: 28),

       SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: _canPlay ? _playWords : null,
    icon: const Icon(Icons.play_arrow),
    label: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        _isPlaying
            ? 'جاري تشغيل الكلمات...'
            : 'تشغيل قائمة الكلمات',
        style: const TextStyle(fontSize: 18),
        textAlign: TextAlign.center,
      ),
    ),
  ),
),


        ],
      ),
      isNextEnabled: _canContinue,
      onNext: () {
        // NEXT: Attention - Digit Span Forward
      },
      onEndSession: () {
        Navigator.popUntil(context, (r) => r.isFirst);
      },
    );
  }
}
