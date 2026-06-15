import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:anti_leba/core/router/app_router.dart';
import 'package:anti_leba/features/auth/presentation/providers/auth_providers.dart';
import 'package:anti_leba/features/devices/domain/device.dart';
import 'package:anti_leba/features/sms/presentation/providers/sms_providers.dart';
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
    final sms = ref.watch(smsControllerProvider);

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
          _StatusCard(
            title: 'SMS fallback',
            subtitle: _smsSubtitle(sms),
            icon: sms.isSending ? Icons.sms : Icons.sms_outlined,
            trailing: sms.pendingCount > 0 && !sms.isSending
                ? TextButton(
                    onPressed: () =>
                        ref.read(smsControllerProvider.notifier).retryNow(),
                    child: const Text('Retry'),
                  )
                : sms.isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
          ),
          if (sms.error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              sms.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          _StatusCard(
            title: 'SIM watch',
            subtitle: sms.simSnapshot != null
                ? '${sms.simSnapshot!.displayLabel}'
                    '${sms.simChanged ? ' · change detected' : ''}'
                : 'Reading SIM status…',
            icon: Icons.sim_card_outlined,
          ),
          const SizedBox(height: 12),
          _StatusCard(
            title: 'Offline buffer',
            subtitle: tracking.isSyncing
                ? 'Syncing ${tracking.unsyncedCount} location(s)…'
                : '${tracking.unsyncedCount} unsynced location(s)'
                    '${tracking.lastSyncedAt != null ? ' · last sync ${DateFormat.Hm().format(tracking.lastSyncedAt!.toLocal())}' : ''}',
            icon: Icons.cloud_off_outlined,
            trailing: tracking.unsyncedCount > 0 && !tracking.isSyncing
                ? TextButton(
                    onPressed: () =>
                        ref.read(trackingControllerProvider.notifier).syncNow(),
                    child: const Text('Sync'),
                  )
                : tracking.isSyncing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
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

  String _smsSubtitle(SmsState sms) {
    if (!sms.emergencyNumberConfigured) {
      return 'Set EMERGENCY_SMS_NUMBER dart-define';
    }
    if (sms.isSending) return 'Sending emergency alert…';
    final parts = <String>['${sms.pendingCount} pending SMS'];
    if (sms.lastSentAt != null) {
      parts.add(
        'last sent ${DateFormat.Hm().format(sms.lastSentAt!.toLocal())}',
      );
    }
    return parts.join(' · ');
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
