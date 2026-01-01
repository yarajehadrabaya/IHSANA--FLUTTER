import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

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
            // 🔵 LOGO AREA
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
                      'مرحباً بك',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'يرجى تسجيل الدخول للمتابعة',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    _LoginCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ===================== LOGIN CARD ===================== */

  Widget _LoginCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'تسجيل الدخول',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

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

          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: (value) {
              setState(() {
                _passwordHint = value.length < 6
                    ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'
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

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text('نسيت كلمة المرور؟'),
            ),
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: () {},
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }
}

