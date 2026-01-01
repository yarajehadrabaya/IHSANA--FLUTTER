import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscurePassword = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailHint;
  String? _passwordHint;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            // 🔵 LOGO AREA (نفس Login)
            SizedBox(
              height: height * 0.38,
              child: Center(
                child: SvgPicture.asset(
                  'assets/logo/ihsana_logo.svg',
                  height: 440,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // 📄 CONTENT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      'إنشاء حساب جديد',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'يرجى إدخال البيانات التالية',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    _SignupCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ===================== SIGNUP CARD ===================== */

  Widget _SignupCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 👤 الاسم
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'الاسم الكامل',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),

          const SizedBox(height: 12),

          // 📧 البريد الإلكتروني
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

          const SizedBox(height: 12),

          // 🔐 كلمة المرور
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: (value) {
              setState(() {
                _passwordHint = value.length < 8
                    ? 'كلمة المرور يجب أن تكون 8 أحرف على الأقل'
                    : null;
              });
            },
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              helperText: _passwordHint,
            ),
          ),

          const SizedBox(height: 16),

          // ✅ زر إنشاء الحساب
          ElevatedButton(
            onPressed: () {},
            child: const Text('إنشاء حساب'),
          ),

          const SizedBox(height: 12),

          // 🔁 العودة لتسجيل الدخول
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('لديك حساب؟ تسجيل الدخول'),
          ),
        ],
      ),
    );
  }
}
