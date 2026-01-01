import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import 'instructions_screen.dart';

enum TestMode {
  mobile,
  hardware,
}

class TestModeSelectionScreen extends StatefulWidget {
  const TestModeSelectionScreen({super.key});

  @override
  State<TestModeSelectionScreen> createState() =>
      _TestModeSelectionScreenState();
}

class _TestModeSelectionScreenState
    extends State<TestModeSelectionScreen> {
  TestMode? _selectedMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🧠 العنوان
                  Text(
                    'طريقة إجراء الاختبار',
                    style:
                        Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'اختر الطريقة الأنسب لإجراء الاختبار',
                    style:
                        Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // 📱 الهاتف
                  _ModeCard(
                    icon: Icons.smartphone,
                    title: 'على الهاتف',
                    description:
                        'استخدام شاشة الهاتف والمايك والكاميرا',
                    selected:
                        _selectedMode == TestMode.mobile,
                    onTap: () {
                      setState(() {
                        _selectedMode = TestMode.mobile;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // 🧠 جهاز خارجي
                  _ModeCard(
                    icon: Icons.memory,
                    title: 'باستخدام جهاز خارجي',
                    description:
                        'استخدام جهاز مخصص مع كاميرا ومايك',
                    selected:
                        _selectedMode == TestMode.hardware,
                    onTap: () {
                      setState(() {
                        _selectedMode = TestMode.hardware;
                      });
                    },
                  ),

                  const SizedBox(height: 32),

                  // ▶️ متابعة
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedMode == null
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const InstructionsScreen(),
                                ),
                              );
                            },
                      child: const Text('متابعة'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ========================================================= */
/* ======================= MODE CARD ======================= */
/* ========================================================= */

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppTheme.primary
                : Colors.grey.shade300,
            width: 2,
          ),
          color: selected
              ? AppTheme.primary.withOpacity(0.08)
              : Colors.white,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTheme.primary
                        .withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 42,
              color: selected
                  ? AppTheme.primary
                  : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
