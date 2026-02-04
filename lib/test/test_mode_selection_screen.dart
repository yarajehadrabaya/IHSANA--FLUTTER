import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../session/session_context.dart';
import '../utils/test_session.dart'; // 🔥 مهم
import 'instructions_screen.dart';

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
      // 🔥🔥🔥 الحل النهائي
      TestSession.reset();

      final user = FirebaseAuth.instance.currentUser!;
      final sessionsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sessions');

      final newSession = await sessionsRef.add({
        'capture_mode':
            _selectedMode == TestMode.mobile ? 'جوال' : 'جهاز خارجي',
        'is_completed': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'test_version': 'MoCA 8.1',
      });

      SessionContext.sessionId = newSession.id;
      SessionContext.testMode = _selectedMode;

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InstructionsScreen()),
      );
    } catch (_) {
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
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 22,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'طريقة إجراء الاختبار',
                          style:
                              Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        const Text('اختر الطريقة الأنسب لإجراء الاختبار'),
                        const SizedBox(height: 32),

                        _ModeCard(
                          icon: Icons.smartphone,
                          title: 'على الهاتف',
                          description:
                              'استخدام كاميرا وميكروفون الهاتف',
                          selected:
                              _selectedMode == TestMode.mobile,
                          onTap: () =>
                              setState(() => _selectedMode = TestMode.mobile),
                        ),
                        const SizedBox(height: 16),

                        _ModeCard(
                          icon: Icons.memory,
                          title: 'باستخدام جهاز خارجي',
                          description:
                              'للعيادات باستخدام مايك وكاميرا خارجية',
                          selected:
                              _selectedMode == TestMode.hardware,
                          onTap: () =>
                              setState(() => _selectedMode = TestMode.hardware),
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _selectedMode == null || _loading
                                ? null
                                : _startSession,
                            child: _loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('متابعة'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ================= MODE CARD ================= */

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
          color: selected
              ? AppTheme.primary.withOpacity(0.08)
              : Colors.white,
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
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
