import 'package:flutter/material.dart';
import '../widgets/app_background.dart';
import '../theme/app_theme.dart';
import '../models/session_result.dart';
import '../utils/moca_classification_mapper.dart';

class SessionsHistoryScreen extends StatelessWidget {
  const SessionsHistoryScreen({super.key});

  // بيانات وهمية (لاحقاً من Backend)
  List<SessionResult> get sessions => const [
        SessionResult(date: '12 أيلول 2025', score: 28),
        SessionResult(date: '3 أيلول 2025', score: 22),
        SessionResult(date: '22 آب 2025', score: 15, educationBelow12Years: true),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جلساتي السابقة'),
        centerTitle: true,
      ),
      body: AppBackground(
        child: ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            final classification = classifyMocaScore(
              rawScore: session.score,
              educationBelow12Years: session.educationBelow12Years,
            );

            return SessionCard(
              date: session.date,
              score: session.score,
              classification: classification,
            );
          },
        ),
      ),
    );
  }
}

/* ===================== SESSION CARD ===================== */

class SessionCard extends StatelessWidget {
  final String date;
  final int score;
  final CognitiveClassification classification;

  const SessionCard({
    super.key,
    required this.date,
    required this.score,
    required this.classification,
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
              border: Border.all(color: classification.color, width: 4),
            ),
            child: Center(
              child: Text(
                score.toString(),
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
                // Date
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

                // Status
                Text(
                  classification.label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: classification.color),
                ),

                const SizedBox(height: 4),

                // Description
                Text(
                  classification.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                if (classification.requiresDoctorFollowUp) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(Icons.medical_services,
                          size: 16, color: Colors.redAccent),
                      SizedBox(width: 6),
                      Text(
                        'يوصى بالمتابعة الطبية',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
