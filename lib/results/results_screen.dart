import 'package:flutter/material.dart';
import 'package:ihsana/scoring/moca_result.dart';

class ResultsScreen extends StatelessWidget {
  final MocaResult result;

  const ResultsScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final classification = result.classification;
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
            // 🔢 المجموع
            Text(
              '$score / 30',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // 🧠 التصنيف
            _ClassificationBadge(classification: classification),

            const SizedBox(height: 32),

            // 📘 الرسالة الطبية
            Text(
              _getMessage(classification),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 40),

            // 💾 حفظ الجلسة (لاحقاً)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: حفظ الجلسة في قاعدة البيانات
                },
                icon: const Icon(Icons.save),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'حفظ الجلسة',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🏠 العودة للرئيسية
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
                  );
                },
                icon: const Icon(Icons.home),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'العودة للرئيسية',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMessage(CognitiveStatus status) {
    switch (status) {
      case CognitiveStatus.normal:
        return 'النتيجة ضمن المعدل الطبيعي. لا يوجد ما يدعو للقلق حالياً.';
      case CognitiveStatus.mci:
        return 'توجد بعض المؤشرات التي تستدعي المتابعة مع مختص.';
      case CognitiveStatus.dementia:
        return 'توجد مؤشرات واضحة تتطلب مراجعة مختص في أقرب وقت.';
    }
  }
}

class _ClassificationBadge extends StatelessWidget {
  final CognitiveStatus classification;

  const _ClassificationBadge({
    required this.classification,
  });

  @override
  Widget build(BuildContext context) {
    late Color color;
    late String text;

    switch (classification) {
      case CognitiveStatus.normal:
        color = Colors.green;
        text = 'طبيعي';
        break;
      case CognitiveStatus.mci:
        color = Colors.orange;
        text = 'ضعف إدراكي بسيط';
        break;
      case CognitiveStatus.dementia:
        color = Colors.red;
        text = 'خرف';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
