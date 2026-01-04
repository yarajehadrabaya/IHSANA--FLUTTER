import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../profile/profile_setup_screen.dart';

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
  bool _isLoading = false;

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
                      'إنشاء حساب جديد',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 12),
                    _signupCard(),
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
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'الاسم الكامل',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (v) =>
                setState(() => _emailHint = v.contains('@') ? null : 'مثال: example@email.com'),
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
                setState(() => _passwordHint = v.length < 6 ? 'كلمة المرور 6 أحرف على الأقل' : null),
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

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _isLoading ? null : _signup,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('إنشاء حساب'),
          ),
        ],
      ),
    );
  }

  Future<void> _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('يرجى تعبئة جميع الحقول');
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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.code == 'email-already-in-use'
          ? 'البريد مستخدم مسبقًا'
          : 'حدث خطأ');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('خطأ'),
        content: Text(msg),
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
