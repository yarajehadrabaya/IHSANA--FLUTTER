// lib/results/results_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// استيراد الموديل بشكل صحيح
import '../scoring/moca_result.dart';
import '../session/session_context.dart';

class ResultsScreen extends StatelessWidget {
  final MocaResult result;

  const ResultsScreen({
    super.key,
    required this.result,
  });

  // دوال مساعدة للتصميم فقط
  Color _getStatusColor(CognitiveStatus status) {
    switch (status) {
      case CognitiveStatus.normal: return Colors.green;
      case CognitiveStatus.mci: return Colors.orange;
      case CognitiveStatus.dementia: return Colors.red;
    }
  }

  String _getStatusLabel(CognitiveStatus status) {
    switch (status) {
      case CognitiveStatus.normal: return "إدراك طبيعي";
      case CognitiveStatus.mci: return "ضعف إدراكي بسيط";
      case CognitiveStatus.dementia: return "تدهور إدراكي محتمل";
    }
  }

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
    final status = result.classification;
    final statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text('ملخص النتيجة'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        // ✅ تم إضافة هذا السطر لحذف زر الرجوع
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const Text('الدرجة النهائية', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120, height: 120,
                        child: CircularProgressIndicator(
                          value: score / 30,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.shade100,
                          color: statusColor,
                        ),
                      ),
                      Text('$score/30', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: statusColor)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(_getStatusLabel(status), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: statusColor)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // عرض التفاصيل
            _buildDetailCard(),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => _saveResult(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: const Text('إنهاء وحفظ الجلسة', style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          _row('الذاكرة', result.delayedRecall),
          _row('التوجه', result.orientation),
          _row('الانتباه', result.attention),
          _row('اللغة', result.language),
          if(result.educationBelow12Years) const Text("+1 نقطة إضافية للتعليم", style: TextStyle(color: Colors.blue, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _row(String t, int s) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(t), Text('$s', style: const TextStyle(fontWeight: FontWeight.bold))]),
  );
}