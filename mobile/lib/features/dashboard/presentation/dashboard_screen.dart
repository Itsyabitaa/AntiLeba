import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:anti_leba/core/router/app_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.go(AppRoutes.login),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const <Widget>[
          _StatusCard(
            title: 'Tracking',
            subtitle: 'GPS service idle',
            icon: Icons.location_on_outlined,
          ),
          SizedBox(height: 12),
          _StatusCard(
            title: 'SIM watch',
            subtitle: 'Monitoring SIM changes',
            icon: Icons.sim_card_outlined,
          ),
          SizedBox(height: 12),
          _StatusCard(
            title: 'Offline buffer',
            subtitle: '0 unsynced events',
            icon: Icons.cloud_off_outlined,
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
