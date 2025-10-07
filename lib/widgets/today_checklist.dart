// lib/widgets/today_checklist.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodayChecklist extends StatelessWidget {
  const TodayChecklist({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Text('Not signed in');

    final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final ref = FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('dailyPlans').doc(todayId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Loading today…'),
          );
        }
        if (snap.hasError) return Text('Error: ${snap.error}');
        if (!snap.hasData || !snap.data!.exists) {
          return const Text('No plan yet. Tap "Seed today plan".');
        }

        final data = snap.data!.data()!;
        final tasks =
            (data['tasks'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today’s checklist',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            ...tasks.map((t) {
              final id = t['id'] as String;
              final label = t['label'] as String;
              final done = (t['done'] as bool?) ?? false;
              return CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: done,
                title: Text(label),
                onChanged: (v) async {
                  final newTasks = tasks.map((x) {
                    if (x['id'] == id) return {...x, 'done': v ?? false};
                    return x;
                  }).toList();
                  await ref.update({'tasks': newTasks});
                },
              );
            }),
          ],
        );
      },
    );
  }
}
