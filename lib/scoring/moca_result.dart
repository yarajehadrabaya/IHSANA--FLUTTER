enum CognitiveStatus {
  normal,
  mci,
  dementia,
}

class MocaResult {
  final int visuospatial;
  final int naming;
  final int attention;
  final int language;
  final int abstraction;
  final int delayedRecall;
  final int orientation;
  final bool educationBelow12Years;

  MocaResult({
    required this.visuospatial,
    required this.naming,
    required this.attention,
    required this.language,
    required this.abstraction,
    required this.delayedRecall,
    required this.orientation,
    this.educationBelow12Years = false,
  });

  int get totalScore {
    final baseScore =
        visuospatial +
        naming +
        attention +
        language +
        abstraction +
        delayedRecall +
        orientation;

    return educationBelow12Years ? baseScore + 1 : baseScore;
  }

  CognitiveStatus get classification {
    final score = totalScore;

    if (score >= 26) {
      return CognitiveStatus.normal;
    } else if (score >= 18) {
      return CognitiveStatus.mci;
    } else {
      return CognitiveStatus.dementia;
    }
  }
}
