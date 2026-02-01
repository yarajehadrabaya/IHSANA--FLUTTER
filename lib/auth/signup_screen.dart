import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../profile/profile_setup_screen.dart';
import '../auth/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _nameErrorText;
  String? _emailErrorText;
  String? _passwordErrorText;

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      'إنشاء حساب جديد',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 12),
                    _signupCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _signupCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // الاسم
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() => _nameErrorText = null),
            decoration: InputDecoration(
              labelText: 'الاسم الكامل',
              prefixIcon: const Icon(Icons.person_outline),
              errorText: _nameErrorText,
            ),
          ),

          const SizedBox(height: 12),

          // البريد
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (v) {
              setState(() {
                _emailHint =
                    v.contains('@') ? null : 'مثال: example@email.com';
                _emailErrorText = null;
              });
            },
            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني',
              prefixIcon: const Icon(Icons.email_outlined),
              helperText: _emailHint,
              errorText: _emailErrorText,
            ),
          ),

          const SizedBox(height: 12),

          // كلمة المرور
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: (v) {
              setState(() {
                _passwordHint =
                    v.length < 6 ? 'كلمة المرور 6 أحرف على الأقل' : null;
                _passwordErrorText = null;
              });
            },
            decoration: InputDecoration(
              labelText: 'كلمة المرور',
              prefixIcon: const Icon(Icons.lock_outline),
              helperText: _passwordHint,
              errorText: _passwordErrorText,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // زر إنشاء حساب
          ElevatedButton(
            onPressed: _isLoading ? null : _signup,
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('إنشاء حساب'),
          ),

          // ✅ زر الرجوع لتسجيل الدخول (تصميم فقط)
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('لديك حساب بالفعل؟'),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* ===================== SIGNUP LOGIC (بدون تغيير) ===================== */

  Future<void> _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _nameErrorText = null;
      _emailErrorText = null;
      _passwordErrorText = null;
    });

    bool hasError = false;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

    if (name.isEmpty) {
      _nameErrorText = 'يرجى إدخال الاسم الكامل';
      hasError = true;
    }

    if (email.isEmpty) {
      _emailErrorText = 'يرجى إدخال البريد الإلكتروني';
      hasError = true;
    } else if (!emailRegex.hasMatch(email)) {
      _emailErrorText = 'يرجى إدخال بريد إلكتروني بصيغة صحيحة';
      hasError = true;
    }

    if (password.isEmpty) {
      _passwordErrorText = 'يرجى إدخال كلمة المرور';
      hasError = true;
    } else if (password.length < 6) {
      _passwordErrorText = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(cred.user!.uid).set({
        'originalName': name,
        'email': email,
        'profileCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfileSetupScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _emailErrorText = e.code == 'email-already-in-use'
            ? 'البريد الإلكتروني مستخدم مسبقًا'
            : 'حدث خطأ أثناء إنشاء الحساب';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
