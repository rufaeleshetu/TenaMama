// lib/widgets/upcoming_appointments.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UpcomingAppointments extends StatelessWidget {
  const UpcomingAppointments({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    final q = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('appointments')
        .where('at', isGreaterThan: DateTime.now())
        .orderBy('at')
        .limit(3);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Text('Loading appointments…');
        }
        if (snap.hasError) return Text('Appt error: ${snap.error}');
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const Text('No upcoming appointments');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upcoming',
                style: Theme.of(context).textTheme.titleMedium),
            ...docs.map((d) {
              final data = d.data();
              final ts = data['at'];
              final at = ts is Timestamp ? ts.toDate() : ts as DateTime;
              final title = (data['title'] as String?) ?? 'Appointment';
              final location = (data['location'] as String?) ?? '';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(title),
                subtitle: Text(
                  '${location.isEmpty ? '' : '$location • '}$at',
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
