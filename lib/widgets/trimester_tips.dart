// lib/widgets/trimester_tips.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
