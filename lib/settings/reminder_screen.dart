import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  bool _reminderEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التذكير'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        children: [
          Text(
            'يساعدك التذكير على المتابعة الدورية وإجراء '
            'اختبارات الإدراك في الوقت المناسب.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(height: 1.6),
          ),

          const SizedBox(height: 24),

          // ===== Enable / Disable Reminder =====
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 1.5,
            child: SwitchListTile(
              title: const Text(
                'تفعيل التذكير',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('تلقي تذكير لإجراء الاختبار'),
              value: _reminderEnabled,
              onChanged: (value) async {
                setState(() {
                  _reminderEnabled = value;
                });

                if (value) {
                  // 🔔 جدولة إشعار
                  await NotificationService.instance
                      .scheduleDailyReminder(
                    hour: _selectedTime.hour,
                    minute: _selectedTime.minute,
                  );
                } else {
                  // ❌ إلغاء كل الإشعارات
                  await NotificationService.instance.cancelAll();
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // ===== Time Picker =====
          if (_reminderEnabled)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 1.5,
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text(
                  'وقت التذكير',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(_selectedTime.format(context)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );

                  if (time != null) {
                    setState(() {
                      _selectedTime = time;
                    });

                    // 🔄 تحديث الإشعار بالوقت الجديد
                    await NotificationService.instance.cancelAll();
                    await NotificationService.instance
                        .scheduleDailyReminder(
                      hour: time.hour,
                      minute: time.minute,
                    );
                  }
                },
              ),
            ),

          const SizedBox(height: 32),

          // ===== Info Note =====
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'سيتم إرسال تذكير يومي في الوقت المحدد لمساعدتك '
                    'على المتابعة الدورية.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
