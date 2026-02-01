import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// تهيئة الإشعارات
  Future<void> init() async {
    // ===== Android settings =====
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // ===== iOS settings =====
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // ===== Initialize =====
    await _notifications.initialize(initSettings);

    // ===== Timezone =====
    tz.initializeTimeZones();
  }

  /// جدولة إشعار يومي
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // لو الوقت فات اليوم → نحجزه لبكرا
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminder',
      channelDescription: 'Daily cognitive test reminder',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      0,
      'تذكير',
      'حان وقت إجراء اختبار الإدراك',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// إلغاء كل الإشعارات
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
