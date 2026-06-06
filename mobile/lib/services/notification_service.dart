part of '../main.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    tzdata.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.local);
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings: settings);
    await _requestPermissions();
    _initialized = true;
  }

  Future<bool> _requestPermissions() async {
    if (kIsWeb) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    final androidGranted = await android?.requestNotificationsPermission();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return androidGranted ?? iosGranted ?? true;
  }

  Future<void> syncReminders(List reminders) async {
    if (kIsWeb) return;
    await initialize();
    await _plugin.cancelAll();

    for (final item in reminders) {
      if (item is! Map) continue;
      final reminder = Map<String, dynamic>.from(item);
      if (reminder['isActive'] == false) continue;
      if (reminder['completedToday'] == true) continue;
      final timeOfDay = reminder['timeOfDay']?.toString();
      if (timeOfDay == null || !RegExp(r'^\d{2}:\d{2}$').hasMatch(timeOfDay)) {
        continue;
      }

      await _scheduleDaily(reminder, timeOfDay);
    }
  }

  Future<void> _scheduleDaily(
    Map<String, dynamic> reminder,
    String timeOfDay,
  ) async {
    final parts = timeOfDay.split(':').map(int.parse).toList();
    final scheduledAt = _nextInstanceOf(parts[0], parts[1]);
    final id =
        reminder['id']?.toString().hashCode.abs() ?? timeOfDay.hashCode.abs();

    await _plugin.zonedSchedule(
      id: id,
      title: reminder['title']?.toString() ?? 'Lembrete Vitalis',
      body: reminder['message']?.toString().isNotEmpty == true
          ? reminder['message'].toString()
          : 'Hora de cuidar da sua rotina.',
      scheduledDate: scheduledAt,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'vitalis_reminders',
          'Lembretes Vitalis',
          channelDescription: 'Lembretes de habitos e rotina do Vitalis',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
