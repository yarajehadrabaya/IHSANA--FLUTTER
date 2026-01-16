import '../test/test_mode_selection_screen.dart'; // استيراد الـ Enum

class SessionContext {
  static String? sessionId;

  // ✅ هذا المتغير سيحمل القيمة (mobile أو hardware)
  static TestMode? testMode;

  // دالة لتنظيف البيانات عند تسجيل الخروج أو انتهاء الاختبار
  static void clear() {
    sessionId = null;
    testMode = null;
  }
}
