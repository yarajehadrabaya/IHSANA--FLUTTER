import 'package:flutter/material.dart';
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
                        prefixIcon:
                            const Icon(Icons.email_outlined),
                        helperText: _emailHint,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 🔘 Send Button
                    ElevatedButton(
                      onPressed: () {
                        // UI فقط – لا منطق حالياً
                      },
                      child: const Text('إرسال رابط الاستعادة'),
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
}
