import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'splitaa_reminders';
  static const _channelName = 'Debt Reminders';

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _initialized = true;
  }

  static Future<void> requestPermission() async {
    await init();
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<bool> hasPermission() async {
    await init();
    return await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled() ?? false;
  }

  static Future<void> scheduleReminder({
    required String entryId,
    required String personName,
    required double amount,
    required DateTime scheduledDate,
  }) async {
    await init();
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    await _plugin.zonedSchedule(
      id: _idFor(entryId),
      title: 'Payment reminder — $personName',
      body: 'RM ${amount.toStringAsFixed(2)} is due today.',
      scheduledDate: tzDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Reminders for unpaid split bills',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: entryId,
    );
  }

  static Future<void> cancelReminder(String entryId) async {
    await init();
    await _plugin.cancel(id: _idFor(entryId));
  }

  static int _idFor(String entryId) =>
      entryId.hashCode.abs() % 2147483647;
}
