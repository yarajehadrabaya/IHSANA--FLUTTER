import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../scoring/moca_result.dart';
import '../session/session_context.dart';

class ResultsScreen extends StatelessWidget {
  final MocaResult result;

  const ResultsScreen({
    super.key,
    required this.result,
  });

  Future<void> _saveResult(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser!;
    final sessionId = SessionContext.sessionId!;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .doc(sessionId)
        .update({
      'moca_score': result.totalScore,
      'risk_level': result.classification.name,
      'is_completed': true,
      'updated_at': FieldValue.serverTimestamp(),
    });

    SessionContext.sessionId = null;

    Navigator.popUntil(context, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final score = result.totalScore;

    return Scaffold(
      appBar: AppBar(
        title: const Text('نتيجة التقييم'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$score / 30',
                style:
                    const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () => _saveResult(context),
              child: const Text('إنهاء وحفظ الجلسة'),
            ),
          ],
        ),
      ),
    );
  }
}
