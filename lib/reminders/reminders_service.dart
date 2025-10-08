import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

/// Channel IDs
const _chanMeals = AndroidNotificationChannel(
  'meals_channel',
  'Meals',
  description: 'Meal time reminders',
  importance: Importance.defaultImportance,
);
const _chanBF = AndroidNotificationChannel(
  'bf_channel',
  'Breastfeeding',
  description: 'Breastfeeding interval reminders',
  importance: Importance.high,
);

class RemindersService {
  RemindersService._();
  static final RemindersService instance = RemindersService._();

  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Timezone
    tzdata.initializeTimeZones();
    final String local = DateTime.now().timeZoneName;
    try {
      tz.setLocalLocation(tz.getLocation(local));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _fln.initialize(initSettings);

    // Android channels
    final android = _fln.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(_chanMeals);
      await android.createNotificationChannel(_chanBF);
      // Post notifications permission (Android 13+)
      await android.requestNotificationsPermission();
    }

    _initialized = true;
  }

  Future<void> cancelAll() => _fln.cancelAll();

  /// Schedule next 24h based on settings.
  Future<void> schedule24h({
    required bool enabled,
    required int bfIntervalMins,
    required String quietStart, // "22:00"
    required String quietEnd, // "06:00"
    required List<String> meals, // ["08:00","13:00",...]
  }) async {
    await init();
    await cancelAll();
    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    final end = now.add(const Duration(hours: 24));

    // Helper to parse "HH:mm" to today's TZ time
    tz.TZDateTime _todayAt(String hhmm) {
      final parts = hhmm.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
    }

    /// quiet window as TZ times relative to a given day
    bool _inQuiet(tz.TZDateTime t) {
      final qs = _todayAt(quietStart);
      final qe = _todayAt(quietEnd);
      if (qs.isBefore(qe)) {
        // same day window: 22:00-23:59 for example (rare)
        return !t.isBefore(qs) && t.isBefore(qe);
      } else {
        // wraps midnight (typical 22:00-06:00)
        return !t.isBefore(qs) || t.isBefore(qe);
      }
    }

    tz.TZDateTime _nextAllowed(tz.TZDateTime t) {
      // If inside quiet hours, bump to quietEnd today/tomorrow accordingly
      final qe = _todayAt(quietEnd);
      if (_inQuiet(t)) {
        // If time before quietEnd -> today’s quietEnd,
        // else it’s after quietStart -> move to tomorrow quietEnd.
        if (t.isBefore(qe)) {
          return tz.TZDateTime(tz.local, t.year, t.month, t.day, qe.hour, qe.minute);
        } else {
          final tomorrow = t.add(const Duration(days: 1));
          return tz.TZDateTime(
              tz.local, tomorrow.year, tomorrow.month, tomorrow.day, qe.hour, qe.minute);
        }
      }
      return t;
    }

    int idCounter = 1000;

    // Meals: schedule for today & tomorrow (within 24h horizon)
    for (int dayOffset = 0; dayOffset <= 1; dayOffset++) {
      for (final hhmm in meals) {
        var t = _todayAt(hhmm).add(Duration(days: dayOffset));
        if (t.isBefore(now)) continue;
        t = _nextAllowed(t);
        if (t.isAfter(end)) continue;

        await _fln.zonedSchedule(
          idCounter++,
          'Meal time',
          'It\'s time for your meal ($hhmm)',
          t,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _chanMeals.id,
              _chanMeals.name,
              channelDescription: _chanMeals.description,
            ),
          ),
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // repeats daily
        );
      }
    }

    // Breastfeeding interval: walk forward from now to 24h
    if (bfIntervalMins > 0) {
      var t = now.add(Duration(minutes: bfIntervalMins));
      while (t.isBefore(end)) {
        var allowed = _nextAllowed(t);
        if (!allowed.isBefore(end)) break;

        await _fln.zonedSchedule(
          idCounter++,
          'Feeding reminder',
          'Next feeding interval reached',
          allowed,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'bf_channel',
              'Breastfeeding',
              channelDescription: 'Breastfeeding interval reminders',
              priority: Priority.high,
              importance: Importance.high,
            ),
          ),
          androidAllowWhileIdle: true,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );

        t = t.add(Duration(minutes: bfIntervalMins));
      }
    }
  }
}
