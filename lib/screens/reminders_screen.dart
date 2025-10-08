import 'package:flutter/material.dart';
import '../services/notifications_service.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = NotificationsService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders (Test)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Use these buttons to verify local notifications on Android.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await svc.init();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Permission requested / ready')),
                );
              },
              child: const Text('1) Initialize / request permission'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                await svc.scheduleTestInFiveSeconds();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Scheduled test in 5s')),
                );
              },
              child: const Text('2) Schedule test (fires in 5s)'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: svc.cancelAll,
              child: const Text('Cancel all scheduled'),
            ),
          ],
        ),
      ),
    );
  }
}
