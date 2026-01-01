import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'orientation_location_screen.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 🧠 العنوان
                      Text(
                        'تعليمات الاختبار',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      _InstructionItem(
                        icon: Icons.timer,
                        text:
                            'مدة الاختبار تقريباً 10 إلى 15 دقيقة.',
                      ),

                      _InstructionItem(
                        icon: Icons.volume_off,
                        text:
                            'يرجى الجلوس في مكان هادئ بدون مقاطعة.',
                      ),

                      _InstructionItem(
                        icon: Icons.check_circle_outline,
                        text:
                            'أجب عن الأسئلة حسب أفضل ما تستطيع.',
                      ),

                      _InstructionItem(
                        icon: Icons.stop_circle_outlined,
                        text:
                            'يمكنك إنهاء الجلسة في أي وقت.',
                      ),

                      const SizedBox(height: 32),

                      // ▶️ ابدأ الاختبار
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const OrientationLocationScreen(),
                            ),
                          );
                        },
                        child: const Text('ابدأ الاختبار'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ========================================================= */
/* ================== Instruction Item ===================== */
/* ========================================================= */

class _InstructionItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstructionItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
