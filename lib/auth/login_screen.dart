import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../home/home_screen.dart';
import '../profile/profile_setup_screen.dart';
import 'forgot_password_screen.dart';

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

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: AppBackground(
        child: Column(
          children: [
            SizedBox(
              height: height * 0.38,
              child: Center(
                child: SvgPicture.asset(
                  'assets/logo/ihsana_logo.svg',
                  height: 440,
                ),
              ),
            ),
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
                    _loginCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginCard() {
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
            onChanged: (v) =>
                setState(() => _emailHint = v.contains('@') ? null : 'example@email.com'),
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
            onChanged: (v) =>
                setState(() => _passwordHint = v.length < 6 ? '6 أحرف على الأقل' : null),
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              prefixIcon: const Icon(Icons.lock_outline),
              helperText: _passwordHint,
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                );
              },
              child: const Text('نسيت كلمة المرور؟'),
            ),
          ),

          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: _login,
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }

  /* ===================== LOGIN LOGIC ===================== */

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('يرجى إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() ?? {};

      final bool profileCompleted = data['profileCompleted'] == true;
      final String displayName =
          data['displayName'] ?? data['originalName'] ?? 'أهلاً بك';

      if (!mounted) return;

      if (profileCompleted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(username: displayName),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfileSetupScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showError('لا يوجد حساب بهذا البريد');
      } else if (e.code == 'wrong-password') {
        _showError('كلمة المرور غير صحيحة');
      } else {
        _showError('فشل تسجيل الدخول');
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('خطأ'),
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
