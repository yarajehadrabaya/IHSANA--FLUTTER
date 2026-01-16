class TestSession {
  // خانات العلامات المنفصلة
  static int clockScore = 0;
  static int cubeScore = 0;
  static int trailsScore = 0;
  static int namingScore = 0;
  static int forwardScore = 0;
  static int backwardScore = 0;
  static int letterAScore = 1; // نقطة تعويضية
  static int subtractionScore = 0;
  static int sentence1Score = 0;
  static int sentence2Score = 0;
  static int fluencyScore = 0;
  static int abstractionScore = 0;
  static int memoryScore = 0;
  static int orientationScore = 0;

  static bool educationBelow12Years = false;

  // دوال تجميع الأقسام لـ MocaResult
  static int get finalVisuospatial => clockScore + cubeScore + trailsScore;
  static int get finalAttention =>
      forwardScore + backwardScore + letterAScore + subtractionScore;
  static int get finalLanguage =>
      sentence1Score + sentence2Score + fluencyScore;

  static void reset() {
    clockScore = cubeScore = trailsScore = namingScore = forwardScore = 0;
    backwardScore = subtractionScore = sentence1Score = sentence2Score = 0;
    fluencyScore = abstractionScore = memoryScore = orientationScore = 0;
    letterAScore = 1;
  }
}
