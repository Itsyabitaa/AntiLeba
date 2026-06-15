import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:anti_leba/core/router/app_router.dart';
import 'package:anti_leba/features/auth/presentation/providers/auth_providers.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<dynamic>>(authControllerProvider, (previous, next) {
      if (next.isLoading) return;
      final destination =
          next.valueOrNull != null ? AppRoutes.dashboard : AppRoutes.login;
      context.go(destination);
    });

    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.shield_moon_rounded, size: 96, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'Anti-Leba',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
