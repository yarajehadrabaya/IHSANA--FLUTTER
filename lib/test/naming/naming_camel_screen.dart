import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';

class NamingCamelScreen extends StatefulWidget {
  const NamingCamelScreen({super.key});

  @override
  State<NamingCamelScreen> createState() =>
      _NamingCamelScreenState();
}

class _NamingCamelScreenState extends State<NamingCamelScreen> {
  bool _recorded = false;

  void _recordVoice() {
    // TODO: تسجيل صوت فعلي لاحقاً
    setState(() {
      _recorded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TestQuestionScaffold(
      title: 'ما اسم هذا الحيوان؟',
      content: Column(
        children: [
          Image.asset(
            'assets/images/camel.png',
            height: 220,
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _recordVoice,
            icon: const Icon(Icons.mic),
            label: const Text('تسجيل الإجابة'),
          ),

          if (_recorded)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'تم تسجيل الإجابة الصوتية',
                style: TextStyle(color: Colors.green),
              ),
            ),
        ],
      ),
      isNextEnabled: _recorded,
      onNext: () {
        // NEXT: Memory Encoding Screen
        // سنربطها بالخطوة القادمة
      },
      onEndSession: () {
        Navigator.popUntil(context, (r) => r.isFirst);
      },
    );
  }
}
