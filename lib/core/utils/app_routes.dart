import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stock_management/features/main/presentation/pages/attendance/attendance_history_screen.dart';
import 'package:stock_management/features/main/presentation/pages/holiday/holiday_screen.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/main/presentation/pages/dashboard/employee_profile_page.dart';
import '../../features/main/presentation/pages/dashboard/main_dashboard.dart';
import '../../features/main/presentation/pages/dashboard/dashboard_details_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

class AppRouter {
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',

    redirect: (context, state) async {
      if (!GetIt.I.isRegistered<FlutterSecureStorage>()) return null;

      final storage = GetIt.I<FlutterSecureStorage>();
      final String? token = await storage.read(key: 'access_token');

      final bool isAuth = token != null && token.isNotEmpty;
      final bool isLoggingIn = state.uri.path == '/login';
      final bool isOnSplash = state.uri.path == '/splash';

      if (isOnSplash) return null;

      // Unauthenticated users are redirected to login
      if (!isAuth && !isLoggingIn) {
        return '/login';
      }

      // Authenticated users are routed straight to the dashboard
      if (isAuth && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainDashboard(
          key: state.pageKey,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const HolidayScreen(),
          ),
          GoRoute(
            path: '/attendance',
            builder: (context, state) => const AttendanceScreen(),
          ),
        ],
      ),
    ],
  );
}