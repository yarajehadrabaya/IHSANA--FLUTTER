  import 'package:flutter/material.dart';
  import 'package:flutter_localizations/flutter_localizations.dart';
  import 'package:ihsana/auth/login_screen.dart';
  import 'auth/auth_gate.dart';

  import 'theme/app_theme.dart';
  import 'screens/splash_screen.dart';

  import 'home/home_screen.dart';
  import 'auth/signup_screen.dart';
  import 'auth/forgot_password_screen.dart';
  import 'home/sessions_history_screen.dart';
  import 'profile/profile_setup_screen.dart';
  import 'package:ihsana/test/memory/memory_encoding_screen.dart';
  import 'package:ihsana/test/attention/digit_span_forward_screen.dart';
  import 'package:ihsana/test/attention/digit_span_backward_screen.dart';
  import 'package:ihsana/test/attention/letter_a_screen.dart';
  import 'package:ihsana/test/language/sentence_repetition_screen.dart';
  import 'package:ihsana/test/language/verbal_fluency_screen.dart';
  import 'package:ihsana/test/abstraction/abstraction_question_one_screen.dart';
  import 'package:ihsana/test/memory/delayed_recall_screen.dart';
 import 'package:ihsana/test/orientation/orientation_screen.dart';

import 'package:ihsana/results/results_screen.dart';
import 'package:ihsana/scoring/moca_result.dart';

import 'package:firebase_core/firebase_core.dart';




  void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const IhsanaApp());
}


  class IhsanaApp extends StatelessWidget {
    const IhsanaApp({super.key});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,

        // 🌍 اللغة العربية
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
        ],

        // ✅ هذا السطر كان ناقص
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // ➡️ اتجاه من اليمين لليسار
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },

        theme: AppTheme.lightTheme,
        // home: const AuthGate(),
            // home: const LoginScreen()
          home: const SplashScreen(),
          // home: const ProfileSetupScreen(),
          //  home: const HomeScreen(username: 'يارا'),
          //  home: const SessionsHistoryScreen(),
          // home: const SignupScreen(),
          // home: const ForgotPasswordScreen(),
          // home: const MemoryEncodingScreen(),
          // home: const DigitSpanForwardScreen(),
          // home: const DigitSpanBackwardScreen(),
          // home: const LetterAScreen(),  
          // home: const SentenceRepetitionScreen(),
         // home: const VerbalFluencyScreen(),
         //  home: const AbstractionQuestionOneScreen(),
         //  home: const DelayedRecallScreen(),

         // home: const OrientationScreen(),

// home: ResultsScreen(
//   result: MocaResult(
//     visuospatial: 4,
//     naming: 3,
//     attention: 5,
//     language: 2,
//     abstraction: 1,
//     delayedRecall: 3,
//     orientation: 6,
//     educationBelow12Years: true,
//   ),
// ),

      );
    }
  }
