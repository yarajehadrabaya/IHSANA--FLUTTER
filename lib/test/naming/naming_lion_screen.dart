import 'package:flutter/material.dart';
import 'package:ihsana/test/widgets/test_question_scaffold.dart';
import 'naming_rhino_screen.dart';

class NamingLionScreen extends StatefulWidget {
  const NamingLionScreen({super.key});

  @override
  State<NamingLionScreen> createState() => _NamingLionScreenState();
}

class _NamingLionScreenState extends State<NamingLionScreen> {
  bool _recorded = false;

  void _recordVoice() {
    // TODO: ربط تسجيل الصوت لاحقاً
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
            'assets/images/lion.png',
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const NamingRhinoScreen(),
          ),
        );
      },
      onEndSession: () {
        Navigator.popUntil(context, (r) => r.isFirst);
      },
    );
  }
}
