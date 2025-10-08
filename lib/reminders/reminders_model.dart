import 'package:cloud_firestore/cloud_firestore.dart';

class RemindersSettings {
  final bool enabled;
  final int bfIntervalMins;         // 120–210 typical
  final String quietStart;          // "22:00"
  final String quietEnd;            // "06:00"
  final List<String> meals;         // ["08:00","13:00","19:00"]

  RemindersSettings({
    required this.enabled,
    required this.bfIntervalMins,
    required this.quietStart,
    required this.quietEnd,
    required this.meals,
  });

  factory RemindersSettings.defaults() => RemindersSettings(
        enabled: true,
        bfIntervalMins: 180,
        quietStart: '22:00',
        quietEnd: '06:00',
        meals: const ['08:00', '13:00', '19:00'],
      );

  factory RemindersSettings.fromMap(Map<String, dynamic> m) {
    return RemindersSettings(
      enabled: (m['enabled'] as bool?) ?? true,
      bfIntervalMins: (m['bfIntervalMins'] as num?)?.toInt() ?? 180,
      quietStart: (m['quietStart'] as String?) ?? '22:00',
      quietEnd: (m['quietEnd'] as String?) ?? '06:00',
      meals: ((m['meals'] as List?)?.cast<String>()) ??
          const ['08:00', '13:00', '19:00'],
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'bfIntervalMins': bfIntervalMins,
        'quietStart': quietStart,
        'quietEnd': quietEnd,
        'meals': meals,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
