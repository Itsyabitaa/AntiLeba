import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:anti_leba/core/router/app_router.dart';
import 'package:anti_leba/features/auth/presentation/providers/auth_providers.dart';
import 'package:anti_leba/features/devices/domain/device.dart';
import 'package:anti_leba/features/tracking/presentation/providers/tracking_providers.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _trackingStarted = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final deviceAsync = ref.watch(enrolledDeviceProvider);
    final tracking = ref.watch(trackingControllerProvider);

    ref.listen<AsyncValue<Device?>>(enrolledDeviceProvider, (previous, next) {
      next.whenData((Device? device) async {
        if (device == null || _trackingStarted) return;
        _trackingStarted = true;
        await ref.read(trackingControllerProvider.notifier).start(device.id);
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(trackingControllerProvider.notifier).stop();
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
          _StatusCard(
            title: 'Tracking',
            subtitle: _trackingSubtitle(tracking),
            icon: tracking.isRunning
                ? Icons.location_on
                : Icons.location_on_outlined,
            trailing: tracking.isRunning
                ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                : null,
          ),
          if (tracking.error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              tracking.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          const _StatusCard(
            title: 'SIM watch',
            subtitle: 'Monitoring SIM changes',
            icon: Icons.sim_card_outlined,
          ),
          const SizedBox(height: 12),
          _StatusCard(
            title: 'Offline buffer',
            subtitle: '${tracking.unsyncedCount} unsynced location(s)',
            icon: Icons.cloud_off_outlined,
            trailing: tracking.unsyncedCount > 0
                ? TextButton(
                    onPressed: () =>
                        ref.read(trackingControllerProvider.notifier).syncNow(),
                    child: const Text('Sync'),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  String _trackingSubtitle(TrackingState tracking) {
    if (!tracking.isRunning) return 'GPS service idle';
    final last = tracking.lastLocation;
    if (last == null) return 'Active · waiting for first fix…';
    final when = tracking.lastCollectedAt != null
        ? DateFormat.Hm().format(tracking.lastCollectedAt!.toLocal())
        : 'unknown';
    return 'Active · ${last.latitude.toStringAsFixed(5)}, '
        '${last.longitude.toStringAsFixed(5)} · $when';
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;

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
        trailing: trailing ?? const Icon(Icons.chevron_right),
      ),
    );
  }
}
