import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../utils/test_session.dart';

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
      backgroundColor: Colors.transparent,

      // ================= Bottom Area =================
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          12 + MediaQuery.of(context).viewPadding.bottom,
        ),
        color: AppTheme.background,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===== الزر (بدون ارتفاع ثابت) =====
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isNextEnabled ? onNext : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'إنهاء وتحليل',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.4, // يسمح للنص يتمدد
                  ),
                ),
              ),
            ),

            // ===== الهنت تحت الزر =====
            if (!isNextEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'يرجى إكمال الخطوة الحالية للمتابعة',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),

      // ================= Body =================
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 4),
                    Text(
                      'سؤال ${TestSession.currentQuestion} / ${TestSession.totalQuestions}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),

                    TextButton.icon(
                      onPressed: () => _showEndSessionDialog(context),
                      icon: const Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'إنهاء الجلسة',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    if (instruction != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          instruction!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration,
                    child: content,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEndSessionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('إنهاء الجلسة'),
        content: const Text(
          'هل أنت متأكد أنك تريد إنهاء الجلسة؟ سيتم فقدان التقدم الحالي.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
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
