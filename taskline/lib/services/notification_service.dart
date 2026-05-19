import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';
import '../models/task.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'taskline_deadlines';
  static const String _channelName = 'Task deadlines';
  static const String _channelDescription =
      'Reminders fired when a task deadline is reached';

  static const String _windowsAppGuid =
      '3ec2a3e7-5b9d-4a8f-b1c4-7d2e6f8a9b3c';

  static const int _slotSize = 100;
  static const int _maxRemindersPerTask = 50;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final localInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localInfo.identifier));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open');
    const windowsSettings = WindowsInitializationSettings(
      appName: 'Taskline',
      appUserModelId: 'com.taskline.taskline',
      guid: _windowsAppGuid,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
        windows: windowsSettings,
      ),
    );

    await _requestPermissions();
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isMacOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Computes the UTC reminder timestamps for [task] given the user's [settings].
  ///
  /// Walks backward from the deadline through five distance buckets, emitting
  /// reminders at each bucket's configured frequency. The deadline itself is
  /// always included. Results are sorted ascending and capped at
  /// [_maxRemindersPerTask] (closest to deadline win).
  List<DateTime> computeReminders(
    Task task,
    AppSettings settings, {
    DateTime? now,
  }) {
    final reference = (now ?? DateTime.now()).toUtc();
    final deadline = task.deadline.toUtc();
    if (deadline.isBefore(reference)) return const [];

    final buckets = <_Bucket>[
      _Bucket(
        start: deadline.subtract(const Duration(hours: 1)),
        end: deadline,
        interval: settings.dueIn1Hour,
      ),
      _Bucket(
        start: deadline.subtract(const Duration(days: 1)),
        end: deadline.subtract(const Duration(hours: 1)),
        interval: settings.dueIn1Day,
      ),
      _Bucket(
        start: deadline.subtract(const Duration(days: 7)),
        end: deadline.subtract(const Duration(days: 1)),
        interval: settings.dueIn1Week,
      ),
      _Bucket(
        start: deadline.subtract(const Duration(days: 30)),
        end: deadline.subtract(const Duration(days: 7)),
        interval: settings.dueIn1Month,
      ),
      _Bucket(
        start: deadline.subtract(const Duration(days: 365)),
        end: deadline.subtract(const Duration(days: 30)),
        interval: settings.dueIn1Year,
      ),
      _Bucket(
        start: DateTime.utc(1970),
        end: deadline.subtract(const Duration(days: 365)),
        interval: settings.moreThan1Year,
      ),
    ];

    final reminders = <DateTime>[];
    for (final bucket in buckets) {
      if (reminders.length >= _maxRemindersPerTask) break;
      final step = bucket.interval.duration;
      if (step == null) continue;

      var cursor = bucket.end.subtract(step);
      while (!cursor.isBefore(bucket.start) &&
          cursor.isAfter(reference) &&
          reminders.length < _maxRemindersPerTask) {
        reminders.add(cursor);
        cursor = cursor.subtract(step);
      }
    }

    if (reminders.length < _maxRemindersPerTask) {
      reminders.add(deadline);
    }

    reminders.sort();
    return reminders;
  }

  Future<void> schedule(
    Task task,
    AppSettings settings, {
    DateTime? now,
  }) async {
    if (task.id == null || task.isDone) return;

    final reminders = computeReminders(task, settings, now: now);
    if (reminders.isEmpty) return;

    final baseId = task.id! * _slotSize;
    final tzNow = tz.TZDateTime.now(tz.local);

    for (var i = 0; i < reminders.length && i < _slotSize; i++) {
      final scheduled = tz.TZDateTime.from(reminders[i], tz.local);
      if (!scheduled.isAfter(tzNow)) continue;
      await _plugin.zonedSchedule(
        id: baseId + i,
        title: task.title,
        body: _reminderBody(task, reminders[i], task.deadline.toUtc()),
        scheduledDate: scheduled,
        notificationDetails: _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: task.id.toString(),
      );
    }
  }

  Future<void> cancel(int taskId) async {
    final baseId = taskId * _slotSize;
    for (var i = 0; i < _slotSize; i++) {
      await _plugin.cancel(id: baseId + i);
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> syncAll(
    Iterable<Task> tasks,
    AppSettings settings, {
    DateTime? now,
  }) async {
    await cancelAll();
    final ref = now ?? DateTime.now();
    for (final task in tasks) {
      await schedule(task, settings, now: ref);
    }
  }

  String _reminderBody(Task task, DateTime fireAt, DateTime deadline) {
    final remaining = deadline.difference(fireAt);
    if (remaining.inSeconds <= 30) {
      return task.description ?? 'Deadline reached';
    }
    final phrase = _formatRemaining(remaining);
    final base = task.description?.isNotEmpty == true
        ? '${task.description} • '
        : '';
    return '${base}Due in $phrase';
  }

  String _formatRemaining(Duration d) {
    if (d.inDays >= 365) return '${(d.inDays / 365).floor()}y';
    if (d.inDays >= 30) return '${(d.inDays / 30).floor()}mo';
    if (d.inDays >= 7) return '${(d.inDays / 7).floor()}w';
    if (d.inDays >= 1) return '${d.inDays}d';
    if (d.inHours >= 1) return '${d.inHours}h';
    return '${d.inMinutes}m';
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
      linux: LinuxNotificationDetails(),
      windows: WindowsNotificationDetails(),
    );
  }
}

class _Bucket {
  const _Bucket({
    required this.start,
    required this.end,
    required this.interval,
  });

  final DateTime start;
  final DateTime end;
  final ReminderInterval interval;
}
