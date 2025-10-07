// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'firebase_options.dart';
import 'app_state.dart'; // exposes pregnant, weeksPregnant, trimester

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase for this platform
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Ensure we have a signed-in user (anonymous is fine)
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TenaMama',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const TodayScreen(),
    );
  }
}

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tri = app.trimester;
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '(no user)';
    final authed = user != null;

    // Firebase options (diagnostics)
    final o = Firebase.app().options;

    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
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

              // Quick Firestore write sanity check
              ElevatedButton(
                onPressed: () => _testFirestoreWrite(context),
                child: const Text('Test Firestore write'),
              ),
              const SizedBox(height: 12),

              // ----- DEV SEED BUTTONS (tap both) -----
              Row(
                children: [
                  FilledButton(
                    onPressed: () async {
                      try {
                        await seedBaby();
                        await seedTips();
                        await seedAppointments();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Seed base done')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Seed base error: $e')),
                        );
                      }
                    },
                    child: const Text('Seed base'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      try {
                        await seedTodayPlan();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Seed today plan done')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Seed plan error: $e')),
                        );
                      }
                    },
                    child: const Text('Seed today plan'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status + diagnostics (helps catch project mismatches)
              Text('Auth UID: $uid'),
              Text('Status: ${authed ? 'Ready' : 'Not signed in'}'),
              Text('Project: ${o.projectId}'),
              Text('AppId: ${o.appId.substring(0, 8)}…'),
              Text('API: ${o.apiKey.substring(0, 6)}…'),
              const SizedBox(height: 16),

              // 1) Today checklist (streams & toggles)
              const TodayChecklist(),

              // 2) Two tips for current trimester
              const SizedBox(height: 8),
              TrimesterTips(trimester: tri),

              // 3) Upcoming appointments
              const SizedBox(height: 8),
              const UpcomingAppointments(),
            ],
          ),
        ),
      ),
    );
  }
}

/* =======================
 * Seeder helpers
 * ======================= */

DocumentReference<Map<String, dynamic>> _userDoc() {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  return FirebaseFirestore.instance.collection('users').doc(uid);
}

Future<void> seedBaby() async {
  final babies = _userDoc().collection('babies');
  await babies.doc('default').set({
    'name': 'Baby A',
    'dueDate': DateTime.now().add(const Duration(days: 140)),
    'dob': null,
  });
}

Future<void> seedTodayPlan() async {
  final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final planRef = _userDoc().collection('dailyPlans').doc(todayId);
  await planRef.set({
    'tasks': [
      {'id': 'drinkWater', 'label': 'Drink 8 glasses of water', 'done': false},
      {'id': 'prenatal', 'label': 'Take prenatal vitamins', 'done': false},
    ],
  });
}

Future<void> seedAppointments() async {
  final appts = _userDoc().collection('appointments');
  await appts.add({
    'title': 'Antenatal visit',
    'location': 'Clinic X',
    'at': DateTime.now().add(const Duration(days: 3)),
  });
}

Future<void> seedTips() async {
  final tips = _userDoc().collection('tips');
  await tips.add({
    'trimester': 1,
    'stage': 'pregnancy',
    'text': 'Short walk today? Improves mood & sleep.',
  });
  await tips.add({
    'trimester': 1,
    'stage': 'pregnancy',
    'text': 'Small frequent meals help with nausea.',
  });
  await tips.add({
    'trimester': 2,
    'stage': 'pregnancy',
    'text': 'Start light pelvic floor exercises.',
  });
  await tips.add({
    'trimester': 3,
    'stage': 'pregnancy',
    'text': 'Pack your hospital bag checklist.',
  });
}

/* =======================
 * Streaming widgets
 * ======================= */

class TodayChecklist extends StatelessWidget {
  const TodayChecklist({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Text('Not signed in');

    final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('dailyPlans')
        .doc(todayId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Text('Loading today…');
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

class TrimesterTips extends StatelessWidget {
  const TrimesterTips({super.key, required this.trimester});
  final int? trimester;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    if (trimester == null) return const Text('Set weeks to see tips');

    final q = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tips')
        .where('trimester', isEqualTo: trimester)
        .limit(2);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Text('Loading tips…');
        }
        if (snap.hasError) return Text('Tips error: ${snap.error}');
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const Text('No tips yet for this trimester');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tips for Trimester $trimester',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            ...docs.map(
              (d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• ${d.data()['text']}'),
              ),
            ),
          ],
        );
      },
    );
  }
}

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
            Text('Upcoming', style: Theme.of(context).textTheme.titleMedium),
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

/* =======================
 * Test write helper
 * ======================= */
Future<void> _testFirestoreWrite(BuildContext context) async {
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
