// lib/dev_seed.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
      {'id': 'prenatal',   'label': 'Take prenatal vitamins',   'done': false},
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
    'text': 'Short walk today? Improves mood & sleep.'
  });
  await tips.add({
    'trimester': 1,
    'stage': 'pregnancy',
    'text': 'Small frequent meals help with nausea.'
  });
  await tips.add({
    'trimester': 2,
    'stage': 'pregnancy',
    'text': 'Start light pelvic floor exercises.'
  });
  await tips.add({
    'trimester': 3,
    'stage': 'pregnancy',
    'text': 'Pack your hospital bag checklist.'
  });
}
