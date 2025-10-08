import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../reminders/reminders_model.dart';
import '../reminders/reminders_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late RemindersSettings _s;
  bool _loading = true;
  bool _saving = false;

  final _mealCtrl = TextEditingController(); // add meal time as HH:mm

  DocumentReference<Map<String, dynamic>> get _doc {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('reminders')
        .doc('settings');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snap = await _doc.get();
      if (snap.exists) {
        _s = RemindersSettings.fromMap(snap.data()!);
      } else {
        _s = RemindersSettings.defaults();
      }
    } catch (_) {
      _s = RemindersSettings.defaults();
    }
    setState(() => _loading = false);
  }

  Future<void> _saveAndSchedule() async {
    setState(() => _saving = true);
    try {
      await _doc.set(_s.toMap(), SetOptions(merge: true));

      await RemindersService.instance.schedule24h(
        enabled: _s.enabled,
        bfIntervalMins: _s.bfIntervalMins,
        quietStart: _s.quietStart,
        quietEnd: _s.quietEnd,
        meals: _s.meals,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminders saved & scheduled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save/schedule failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime({
    required String initial,
    required void Function(String hhmm) onPicked,
  }) async {
    final parts = initial.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final t = await showTimePicker(context: context, initialTime: initialTime);
    if (t != null) {
      onPicked('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Enable reminders'),
            value: _s.enabled,
            onChanged: (v) => setState(() => _s = RemindersSettings(
              enabled: v,
              bfIntervalMins: _s.bfIntervalMins,
              quietStart: _s.quietStart,
              quietEnd: _s.quietEnd,
              meals: _s.meals,
            )),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Breastfeeding interval'),
            subtitle: Text('${(_s.bfIntervalMins / 60).toStringAsFixed(1)} hours'),
          ),
          Slider(
            min: 120,
            max: 210,
            divisions: 18,
            label: '${(_s.bfIntervalMins / 60).toStringAsFixed(1)}h',
            value: _s.bfIntervalMins.toDouble(),
            onChanged: (v) => setState(() => _s = RemindersSettings(
              enabled: _s.enabled,
              bfIntervalMins: v.round(),
              quietStart: _s.quietStart,
              quietEnd: _s.quietEnd,
              meals: _s.meals,
            )),
          ),
          const Divider(height: 24),
          ListTile(
            title: const Text('Quiet hours'),
            subtitle: Text('${_s.quietStart} – ${_s.quietEnd}'),
            trailing: Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _pickTime(
                    initial: _s.quietStart,
                    onPicked: (hhmm) => _s = RemindersSettings(
                      enabled: _s.enabled,
                      bfIntervalMins: _s.bfIntervalMins,
                      quietStart: hhmm,
                      quietEnd: _s.quietEnd,
                      meals: _s.meals,
                    ),
                  ),
                  child: const Text('Start'),
                ),
                OutlinedButton(
                  onPressed: () => _pickTime(
                    initial: _s.quietEnd,
                    onPicked: (hhmm) => _s = RemindersSettings(
                      enabled: _s.enabled,
                      bfIntervalMins: _s.bfIntervalMins,
                      quietStart: _s.quietStart,
                      quietEnd: hhmm,
                      meals: _s.meals,
                    ),
                  ),
                  child: const Text('End'),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          Text('Meal times', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final m in _s.meals)
                InputChip(
                  label: Text(m),
                  onDeleted: () {
                    final next = [..._s.meals]..remove(m);
                    setState(() => _s = RemindersSettings(
                      enabled: _s.enabled,
                      bfIntervalMins: _s.bfIntervalMins,
                      quietStart: _s.quietStart,
                      quietEnd: _s.quietEnd,
                      meals: next,
                    ));
                  },
                ),
              ActionChip(
                label: const Text('+ add'),
                onPressed: () async {
                  final added = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 12, minute: 0),
                  );
                  if (added != null) {
                    final hhmm =
                        '${added.hour.toString().padLeft(2, '0')}:${added.minute.toString().padLeft(2, '0')}';
                    final next = {..._s.meals, hhmm}.toList()..sort();
                    setState(() => _s = RemindersSettings(
                      enabled: _s.enabled,
                      bfIntervalMins: _s.bfIntervalMins,
                      quietStart: _s.quietStart,
                      quietEnd: _s.quietEnd,
                      meals: next,
                    ));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _saveAndSchedule,
            icon: const Icon(Icons.save),
            label: Text(_saving ? 'Saving…' : 'Save & schedule'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await RemindersService.instance.cancelAll();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All reminders cancelled')),
                );
              }
            },
            child: const Text('Cancel all'),
          ),
        ],
      ),
    );
  }
}
