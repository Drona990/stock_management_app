
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stock_management/features/auth/presentation/pages/login_page.dart';
import 'package:stock_management/features/inventory/presentation/pages/inventory_page.dart';
import 'package:stock_management/features/transaction/presentation/pages/stock_dashboard_view.dart';
import '../../features/main/presentation/pages/bar&resturant/user_management_page.dart';
import '../../features/transaction/presentation/pages/my_report.dart';
import '../../features/transaction/presentation/pages/salse_bill_screen.dart';
import '../../features/transaction/presentation/pages/stock_plus_screen.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/main/presentation/pages/bar&resturant/main_dashboard.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',

    // ==========================================================================
    // 🛡️ AUTH & ROLE-BASED REDIRECT LOGIC
    // ==========================================================================
    redirect: (context, state) async {
      if (!GetIt.I.isRegistered<FlutterSecureStorage>()) return null;

      final storage = GetIt.I<FlutterSecureStorage>();
      final String? token = await storage.read(key: 'access_token');
      final String? role = await storage.read(key: 'user_role');
      final String userRole = role?.toLowerCase() ?? '';

      final bool isLoggingIn = state.uri.path == '/login';
      final bool isOnSplash = state.uri.path == '/splash';

      // 1. If no token, force login
      if (token == null || token.isEmpty) {
        if (isLoggingIn || isOnSplash) return null;
        return '/login';
      }

      // 2. Role-Based Landing Page
      if (isLoggingIn || isOnSplash) {
        if (userRole == 'staff') {
          return '/sales_bill'; // Staff lands on Billing
        }
        return '/dashboard'; // Admin/Manager lands on Dashboard
      }

      // 3. Security: Restricted Paths for Staff
      final restrictedPaths = ['/dashboard', '/manage_user', '/inventory', '/stock_plus'];
      if (userRole == 'staff' && restrictedPaths.contains(state.uri.path)) {
        return '/sales_bill'; // Redirect unauthorized staff to billing
      }

      return null;
    },

    routes: [
      // Splash & Auth
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => LoginPage(),
      ),

      // Main App Shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainDashboard(
            key: state.pageKey,
            child: child
        ),
        routes: [
          // 🏛️ Admin/Manager Only Routes
          GoRoute(path: '/dashboard', builder: (context, state) => const StockDashboardView()),
          GoRoute(path: '/manage_user', builder: (context, state) => const UserManagementPage()),
          GoRoute(path: '/inventory', builder: (context, state) => const InventoryPage()),
          GoRoute(path: '/stock_plus', builder: (context, state) => const StockPlusTransactionView()),

          // 💼 Staff & Admin Accessible Routes
          GoRoute(path: '/sales_bill', builder: (context, state) => const SalesBillingView()),

          // ✅ NEW: My Reports Route (Staff can see their own reports)
          GoRoute(path: '/my_reports', builder: (context, state) => const MyReportsView()),
        ],
      ),
    ],
  );
}