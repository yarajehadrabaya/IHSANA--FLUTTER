import '../test/test_mode_selection_screen.dart';

class SessionContext {
  static String? sessionId;

  // وضع الاختبار
  static TestMode? testMode;

  // IP الرازبيري + البورت
  static String raspberryBaseUrl = 'http://10.74.124.111:5000';

  static void clear() {
    sessionId = null;
    testMode = null;
  }
}

