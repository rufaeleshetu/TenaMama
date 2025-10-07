// lib/screens/today_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../app_state.dart'; // exposes: pregnant, weeksPregnant, trimester
import '../dev_seed.dart'; // seedBaby, seedTodayPlan, seedAppointments, seedTips
import '../widgets/today_checklist.dart';
import '../widgets/trimester_tips.dart';
import '../widgets/upcoming_appointments.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tri = app.trimester;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '(no user)';
    final authed = user != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header chips
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(app.pregnant ? 'Pregnant' : 'Baby'),
                  avatar: const Icon(Icons.info, size: 18),
                ),
                if (tri != null)
                  Chip(
                    label: Text('Trimester $tri'),
                    avatar: const Icon(Icons.pregnant_woman, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (app.pregnant)
              Text(
                'Weeks pregnant: ${app.weeksPregnant}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 16),

            // Debug: quick write to Firestore
            ElevatedButton(
              onPressed: () => testFirestoreWrite(context),
              child: const Text('Test Firestore write'),
            ),
            const SizedBox(height: 12),

            // Dev-only seeders (remove later)
            Row(
              children: [
                FilledButton(
                  onPressed: () async {
                    await seedBaby();
                    await seedTips();
                    await seedAppointments();
                  },
                  child: const Text('Seed base'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: seedTodayPlan,
                  child: const Text('Seed today plan'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Auth status (helpful while developing)
            Text('Auth UID: $uid'),
            Text('Status: ${authed ? 'Ready' : 'Not signed in'}'),
            const SizedBox(height: 16),

            // 1) Today checklist (streams from Firestore; toggles persist)
            const TodayChecklist(),

            // 2) Two tips for current trimester (change weeks to change tips)
            const SizedBox(height: 8),
            TrimesterTips(trimester: tri),

            // 3) Upcoming appointments (optional)
            const SizedBox(height: 8),
            const UpcomingAppointments(),
          ],
        ),
      ),
    );
  }
}

/// Simple Firestore write test with snackbars for success/failure.
Future<void> testFirestoreWrite(BuildContext context) async {
  try {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('debug');

    final doc = await ref.add({
      'at': FieldValue.serverTimestamp(),
      'platform': 'web',
    });

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Write OK: ${doc.id}')),
    );
  } catch (e) {
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Write failed: $e')),
    );
  }
}
