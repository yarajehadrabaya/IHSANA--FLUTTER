import 'package:flutter/material.dart';
import 'about_screen.dart';
import 'privacy_screen.dart';
import 'reminder_screen.dart';
import 'account_screen.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _settingsCard(
            context,
            icon: Icons.person_outline,
            title: 'الحساب',
            subtitle: 'معلوماتك الشخصية وإعدادات الدخول',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AccountScreen(),
                ),
              );
            },
          ),
          _settingsCard(
            context,
            icon: Icons.notifications_none,
            title: 'التذكير',
            subtitle: 'إدارة تنبيهات وتذكير الاختبارات',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReminderScreen(),
                ),
              );
            },
          ),

        _settingsCard(
          context,
          icon: Icons.lock_outline,
          title: 'الخصوصية',
          subtitle: 'سياسة الخصوصية واستخدام البيانات',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PrivacyScreen(),
              ),
            );
          },
        ),

         _settingsCard(
            context,
            icon: Icons.info_outline,
            title: 'حول التطبيق',
            subtitle: 'معلومات عن إحسانا والإصدار',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AboutScreen(),
                ),
    );
  },
),

        ],
      ),
    );
  }

  Widget _settingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              // أيقونة كبيرة داخل دائرة
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: primary,
                ),
              ),

              const SizedBox(width: 20),

              // النصوص
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                size: 30,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
