import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../widgets/app_background.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailHint;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🧾 Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'نسيت كلمة المرور؟',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة تعيين كلمة المرور',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // 📧 Email Field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (value) {
                        setState(() {
                          _emailHint = value.contains('@')
                              ? null
                              : 'مثال: example@email.com';
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        prefixIcon: const Icon(Icons.email_outlined),
                        helperText: _emailHint,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 🔘 Send Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendResetEmail,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('إرسال رابط الاستعادة'),
                    ),

                    const SizedBox(height: 12),

                    // 🔙 Back to Login
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('العودة لتسجيل الدخول'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* ===================== RESET LOGIC ===================== */

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('يرجى إدخال البريد الإلكتروني');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);

      if (mounted) {
        _showMessage(
          'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showMessage('لا يوجد حساب مرتبط بهذا البريد');
      } else if (e.code == 'invalid-email') {
        _showMessage('البريد الإلكتروني غير صالح');
      } else {
        _showMessage('حدث خطأ، حاول مرة أخرى');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تنبيه'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}
