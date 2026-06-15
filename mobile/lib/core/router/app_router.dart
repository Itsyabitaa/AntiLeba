import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:anti_leba/features/auth/presentation/login_screen.dart';
import 'package:anti_leba/features/auth/presentation/providers/auth_providers.dart';
import 'package:anti_leba/features/auth/presentation/register_screen.dart';
import 'package:anti_leba/features/dashboard/presentation/dashboard_screen.dart';
import 'package:anti_leba/features/splash/presentation/splash_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
}

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  final authRouter = ref.watch(authRouterNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: authRouter,
    redirect: (context, state) {
      if (authRouter.isLoading) return null;

      final loggedIn = authRouter.isAuthenticated;
      final location = state.matchedLocation;
      final onSplash = location == AppRoutes.splash;
      final onAuth =
          location == AppRoutes.login || location == AppRoutes.register;

      if (onSplash) return null;
      if (!loggedIn && !onAuth) return AppRoutes.login;
      if (loggedIn && onAuth) return AppRoutes.dashboard;
      return null;
    },
    routes: <GoRoute>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
});
