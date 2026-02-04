class TestSession {
  // ================= SCORES =================
  static int clockScore = 0;
  static int cubeScore = 0;
  static int trailsScore = 0;
  static int namingScore = 0;
  static int forwardScore = 0;
  static int backwardScore = 0;
  static int letterAScore = 0;
  static int subtractionScore = 0;
  static int sentence1Score = 0;
  static int sentence2Score = 0;
  static int fluencyScore = 0;
  static int abstractionScore = 0;
  static int memoryScore = 0;
  static int orientationScore = 0;

  static bool educationBelow12Years = false;

  // ================= PROGRESS =================
  static int currentQuestion = 1;
  static const int totalQuestions = 12;

  static void nextQuestion() {
    if (currentQuestion < totalQuestions) {
      currentQuestion++;
    }
  }

  // ================= TOTALS =================
  static int get finalVisuospatial =>
      clockScore + cubeScore + trailsScore;

  static int get finalAttention =>
      forwardScore +
      backwardScore +
      letterAScore +
      subtractionScore;

  static int get finalLanguage =>
      sentence1Score + sentence2Score + fluencyScore;

  // ================= RESET =================
  static void reset() {
    clockScore = 0;
    cubeScore = 0;
    trailsScore = 0;
    namingScore = 0;
    forwardScore = 0;
    backwardScore = 0;
    subtractionScore = 0;
    sentence1Score = 0;
    sentence2Score = 0;
    fluencyScore = 0;
    abstractionScore = 0;
    memoryScore = 0;
    orientationScore = 0;

    letterAScore = 1;
    educationBelow12Years = false;

    // 🔥 الحل الحقيقي
    currentQuestion = 1;
  }
}
