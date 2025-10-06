import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (_) => AppState(),
    child: const MyApp(),
  ),
);

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              Text('Weeks pregnant: ${app.weeksPregnant}',
                  style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            const Text('Your daily tip / reminder will appear here…'),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('I am pregnant'),
            value: app.pregnant,
            onChanged: (v) => context.read<AppState>().setPregnant(v),
          ),
          if (app.pregnant) ...[
            const SizedBox(height: 8),
            Text('Weeks pregnant: ${app.weeksPregnant}',
                style: Theme.of(context).textTheme.titleMedium),
            Slider(
              min: 4,
              max: 41,
              divisions: 37,
              label: '${app.weeksPregnant}',
              value: app.weeksPregnant.toDouble(),
              onChanged: (v) => context.read<AppState>().setWeeks(v.round()),
            ),
            const SizedBox(height: 8),
            Text('This maps to Trimester ${app.trimester ?? '-'}'),
          ],
        ],
      ),
    );
  }
}
