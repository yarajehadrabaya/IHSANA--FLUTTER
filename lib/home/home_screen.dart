import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../test/test_mode_selection_screen.dart';

import 'sessions_history_screen.dart';

class HomeScreen extends StatelessWidget {
  final String username;

  const HomeScreen({
    super.key,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 👋 Greeting
                Text(
                  'مرحباً، $username',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'اختبار الإدراك المعرفي باللغة العربية',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // ▶️ Start New Test
                _PrimaryButton(
                  label: 'ابدأ الاختبار الجديد',
                  icon: Icons.arrow_forward,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const TestModeSelectionScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // 📊 Previous Sessions
                _SecondaryButton(
                  label: 'جلساتي السابقة',
                  icon: Icons.history,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const SessionsHistoryScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // ⚙️ Settings
                _SecondaryButton(
                  label: 'الإعدادات',
                  icon: Icons.settings,
                  onPressed: () {
                    // لاحقاً: SettingsScreen
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ========================================================= */
/* ====================== BUTTONS ========================== */
/* ========================================================= */

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}
