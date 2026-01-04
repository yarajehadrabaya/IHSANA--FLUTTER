import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/login_screen.dart';
import '../profile/profile_setup_screen.dart';
import '../home/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ⏳ لسه بنتحقق
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // ❌ مش مسجّل
        if (user == null) {
          return const LoginScreen();
        }

        // ✅ مسجّل → نفحص البروفايل
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, profileSnapshot) {
            if (!profileSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data =
                profileSnapshot.data!.data() as Map<String, dynamic>?;

            final profileCompleted =
                data?['profileCompleted'] == true;

            final displayName =
                data?['displayName'] ?? 'أهلاً بك';

            if (!profileCompleted) {
              return const ProfileSetupScreen();
            }

            return HomeScreen(username: displayName);
          },
        );
      },
    );
  }
}
