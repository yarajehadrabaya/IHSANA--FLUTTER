import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';

class TestQuestionScaffold extends StatelessWidget {
  final String title;
  final String? instruction;
  final Widget content;
  final VoidCallback onNext;
  final VoidCallback onEndSession;
  final bool isNextEnabled;

  const TestQuestionScaffold({
    super.key,
    required this.title,
    this.instruction,
    required this.content,
    required this.onNext,
    required this.onEndSession,
    this.isNextEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // 🔹 Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _confirmEndSession(context);
                      },
                      child: const Text(
                        'إنهاء الجلسة',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),

                if (instruction != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    instruction!,
                    style:
                        Theme.of(context).textTheme.bodyMedium,
                  ),
                ],

                const SizedBox(height: 16),

                // 🔹 Content Area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration,
                    child: content,
                  ),
                ),

                const SizedBox(height: 16),

                // 🔹 Footer Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isNextEnabled ? onNext : null,
                    child: const Text('متابعة'),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmEndSession(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إنهاء الجلسة'),
        content: const Text(
          'هل أنت متأكد أنك تريد إنهاء الاختبار؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              onEndSession();
            },
            child: const Text(
              'إنهاء',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
