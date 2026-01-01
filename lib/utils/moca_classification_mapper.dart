import 'package:flutter/material.dart';

enum CognitiveStatus {
  normal,
  mci,
  dementia,
}

class CognitiveClassification {
  final CognitiveStatus status;
  final String label;
  final String description;
  final Color color;
  final bool requiresDoctorFollowUp;

  const CognitiveClassification({
    required this.status,
    required this.label,
    required this.description,
    required this.color,
    required this.requiresDoctorFollowUp,
  });
}

class MocaThresholds {
  static const int maxScore = 30;
  static const int normalMin = 26;
  static const int mciMin = 18;
}

CognitiveClassification classifyMocaScore({
  required int rawScore,
  bool educationBelow12Years = false,
}) {
  final int adjustedScore =
      educationBelow12Years && rawScore < MocaThresholds.maxScore
          ? rawScore + 1
          : rawScore;

  if (adjustedScore >= MocaThresholds.normalMin) {
    return const CognitiveClassification(
      status: CognitiveStatus.normal,
      label: 'طبيعي',
      description: 'الأداء الإدراكي ضمن المعدل الطبيعي',
      color: Color(0xFF2E7D32),
      requiresDoctorFollowUp: false,
    );
  }

  if (adjustedScore >= MocaThresholds.mciMin) {
    return const CognitiveClassification(
      status: CognitiveStatus.mci,
      label: 'ضعف إدراكي بسيط (MCI)',
      description: 'يوصى بالمتابعة الطبية الدورية',
      color: Color(0xFFF9A825),
      requiresDoctorFollowUp: true,
    );
  }

  return const CognitiveClassification(
    status: CognitiveStatus.dementia,
    label: 'اشتباه ضعف إدراكي شديد',
    description: 'يوصى بمراجعة الطبيب المختص',
    color: Color(0xFFC62828),
    requiresDoctorFollowUp: true,
  );
}
