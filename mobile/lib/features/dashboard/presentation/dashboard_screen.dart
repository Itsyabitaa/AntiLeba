import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:anti_leba/core/router/app_router.dart';
import 'package:anti_leba/features/auth/presentation/providers/auth_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final deviceAsync = ref.watch(enrolledDeviceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (session != null)
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(session.fullName ?? session.email),
                subtitle: Text(session.email),
              ),
            ),
          const SizedBox(height: 12),
          deviceAsync.when(
            data: (device) => _StatusCard(
              title: 'This device',
              subtitle: device == null
                  ? 'Not enrolled yet'
                  : '${device.label} · ${device.status.name}',
              icon: Icons.smartphone,
            ),
            loading: () => const _StatusCard(
              title: 'This device',
              subtitle: 'Loading enrollment…',
              icon: Icons.smartphone,
            ),
            error: (_, __) => const _StatusCard(
              title: 'This device',
              subtitle: 'Could not load device info',
              icon: Icons.smartphone,
            ),
          ),
          const SizedBox(height: 12),
          const _StatusCard(
            title: 'Tracking',
            subtitle: 'GPS service idle',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 12),
          const _StatusCard(
            title: 'SIM watch',
            subtitle: 'Monitoring SIM changes',
            icon: Icons.sim_card_outlined,
          ),
          const SizedBox(height: 12),
          const _StatusCard(
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
