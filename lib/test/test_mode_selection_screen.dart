import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../session/session_context.dart'; // ✅ الملف الذي سيخزن الخيار
import 'instructions_screen.dart';

// ✅ الـ Enum موجود لتعريف الخيارات
enum TestMode { mobile, hardware }

class TestModeSelectionScreen extends StatefulWidget {
  const TestModeSelectionScreen({super.key});

  @override
  State<TestModeSelectionScreen> createState() =>
      _TestModeSelectionScreenState();
}

class _TestModeSelectionScreenState extends State<TestModeSelectionScreen> {
  TestMode? _selectedMode;
  bool _loading = false;

  Future<void> _startSession() async {
    if (_selectedMode == null) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final sessionsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sessions');

      // 1. الحفظ في الفايربيس للتوثيق
      final newSession = await sessionsRef.add({
        'capture_mode': _selectedMode == TestMode.mobile
            ? 'جوال'
            : 'جهاز خارجي',
        'is_completed': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'test_version': 'MoCA 8.1',
      });

      // 2. ✅ أهم خطوة: حفظ الخيار "محلياً" في الذاكرة لتستخدمه باقي الشاشات
      SessionContext.sessionId = newSession.id;
      SessionContext.testMode = _selectedMode; // حفظ (mobile أو hardware)

      debugPrint(
        "--- [SYSTEM] تم اختيار وضع الاختبار: ${SessionContext.testMode} ---",
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InstructionsScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حصل خطأ أثناء إنشاء الجلسة')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

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
                  Text(
                    'طريقة إجراء الاختبار',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'اختر الطريقة الأنسب لإجراء الاختبار',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // بطاقة الهاتف
                  _ModeCard(
                    icon: Icons.smartphone,
                    title: 'على الهاتف',
                    description: 'استخدام شاشة الهاتف والمايك والكاميرا',
                    selected: _selectedMode == TestMode.mobile,
                    onTap: () => setState(() {
                      _selectedMode = TestMode.mobile;
                    }),
                  ),
                  const SizedBox(height: 16),

                  // بطاقة الجهاز الخارجي
                  _ModeCard(
                    icon: Icons.memory,
                    title: 'باستخدام جهاز خارجي',
                    description:
                        'استخدام جهاز مخصص (الرايزبري باي) مع كاميرا ومايك',
                    selected: _selectedMode == TestMode.hardware,
                    onTap: () => setState(() {
                      _selectedMode = TestMode.hardware;
                    }),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedMode == null || _loading
                          ? null
                          : _startSession,
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('متابعة'),
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

/* ======================= MODE CARD ======================= */

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
            color: selected ? AppTheme.primary : Colors.grey.shade300,
            width: 2,
          ),
          color: selected ? AppTheme.primary.withOpacity(0.08) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 42,
              color: selected ? AppTheme.primary : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
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
