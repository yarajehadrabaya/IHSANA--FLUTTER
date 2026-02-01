import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../home/home_screen.dart';
import '../profile/profile_setup_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailHint;
  String? _passwordHint;

  // ===== ERROR STATE =====
  String? _emailErrorText;       // تحت خانة الإيميل
  String? _passwordErrorText;    // تحت خانة كلمة المرور
  String? _authErrorMessage;     // فوق الخانتين (Firebase)

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== SHAKE ANIMATION =====
  AnimationController? _shakeController;
  Animation<Offset>? _shakeAnimation;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: Offset.zero, end: const Offset(-0.015, 0)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween:
            Tween(begin: const Offset(-0.015, 0), end: const Offset(0.015, 0)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0.015, 0), end: Offset.zero),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _shakeController!,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _shakeController?.dispose();
    super.dispose();
  }

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
                      'مرحباً بك',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'يرجى تسجيل الدخول للمتابعة',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),

                    SlideTransition(
                      position: _shakeAnimation ??
                          const AlwaysStoppedAnimation(Offset.zero),
                      child: _loginCard(),
                    ),

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

          // ===== AUTH ERROR (فوق الخانتين) =====
          if (_authErrorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _authErrorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // ===== EMAIL FIELD =====
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              setState(() {
                _emailErrorText = null;
                _authErrorMessage = null;
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

          // ===== PASSWORD FIELD =====
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: (_) {
              setState(() {
                _passwordErrorText = null;
                _authErrorMessage = null;
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

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('ليس لديك حساب؟'),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SignupScreen(),
                    ),
                  );
                },
                child: const Text(
                  'إنشاء حساب',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* ===================== LOGIN LOGIC ===================== */

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _emailErrorText = null;
      _passwordErrorText = null;
      _authErrorMessage = null;
    });

    bool hasError = false;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

    // ===== EMAIL VALIDATION =====
    if (email.isEmpty) {
      _emailErrorText = 'يرجى إدخال البريد الإلكتروني';
      hasError = true;
    } else if (!emailRegex.hasMatch(email)) {
      _emailErrorText = 'يرجى إدخال بريد إلكتروني بصيغة صحيحة';
      hasError = true;
    }

    // ===== PASSWORD VALIDATION =====
    if (password.isEmpty) {
      _passwordErrorText = 'يرجى إدخال كلمة المرور';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    // ===== FIREBASE AUTH =====
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = _auth.currentUser!.uid;
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
    } on FirebaseAuthException {
      _passwordController.clear();
      FocusScope.of(context).unfocus();

      setState(() {
        _authErrorMessage =
            'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      });

      _shakeController?.forward(from: 0);
    }
  }
}
