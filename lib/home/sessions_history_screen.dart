import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/app_background.dart';
import '../theme/app_theme.dart';
import '../utils/moca_classification_mapper.dart';

class SessionsHistoryScreen extends StatelessWidget {
  const SessionsHistoryScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _sessionsStream() {
    final user = FirebaseAuth.instance.currentUser!;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        // ❌ لا فلترة على is_completed (للاختبار)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جلساتي'),
        centerTitle: true,
      ),
      body: AppBackground(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _sessionsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('لا يوجد جلسات بعد'),
              );
            }

            final sessions = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final data = sessions[index].data();

                final score = data['moca_score'] ?? 0;
                final isCompleted = data['is_completed'] == true;
                final educationBelow12 =
                    data['education_below_12_years'] == true;

                final classification = classifyMocaScore(
                  rawScore: score,
                  educationBelow12Years: educationBelow12,
                );

                final timestamp = data['created_at'] as Timestamp?;
                final date = timestamp != null
                    ? _formatDate(timestamp.toDate())
                    : '—';

                final sessionNumber = index + 1;

                return SessionCard(
                  sessionNumber: sessionNumber,
                  date: date,
                  score: score,
                  classification: classification,
                  isCompleted: isCompleted,
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} / ${date.month} / ${date.year}';
  }
}

/* ===================== SESSION CARD ===================== */

class SessionCard extends StatelessWidget {
  final int sessionNumber;
  final String date;
  final int score;
  final CognitiveClassification classification;
  final bool isCompleted;

  const SessionCard({
    super.key,
    required this.sessionNumber,
    required this.date,
    required this.score,
    required this.classification,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          // 🔵 SCORE CIRCLE
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted
                    ? classification.color
                    : Colors.grey,
                width: 4,
              ),
            ),
            child: Center(
              child: Text(
                score == 0 ? '—' : score.toString(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),

          const SizedBox(width: 20),

          // 📄 DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔢 SESSION NUMBER
                Text(
                  'الجلسة رقم $sessionNumber',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                // 📅 DATE
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 🧠 STATUS
                Text(
                  isCompleted
                      ? classification.label
                      : 'غير مكتملة',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                        color: isCompleted
                            ? classification.color
                            : Colors.grey,
                      ),
                ),

                const SizedBox(height: 4),

                // 📝 DESCRIPTION
                Text(
                  isCompleted
                      ? classification.description
                      : 'تم إنشاء الجلسة ولم يتم إكمال الاختبار',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
