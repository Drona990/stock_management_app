import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stock_management/features/auth/presentation/pages/login_page.dart';
import 'package:stock_management/features/inventory/presentation/pages/inventory_page.dart';
import 'package:stock_management/features/transaction/presentation/pages/purchase_master_view.dart';
import 'package:stock_management/features/transaction/presentation/pages/stock_dashboard_view.dart';
import 'package:stock_management/features/transaction/presentation/pages/stock_log_view.dart';
import '../../features/main/presentation/pages/bar&resturant/user_management_page.dart';
import '../../features/transaction/presentation/pages/salse_master_view.dart';
import '../../features/transaction/presentation/pages/supplier_management_view.dart';
import '../../core/utils/routes_name.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/main/presentation/pages/bar&resturant/main_dashboard.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',

    // ✅ AUTH LOGIC: This is the ONLY place that should check for tokens
    redirect: (context, state) async {
      if (!GetIt.I.isRegistered<FlutterSecureStorage>()) {
        return null;
      }
      final storage = GetIt.I<FlutterSecureStorage>();
      final String? token = await storage.read(key: 'access_token');

      final bool isLoggingIn = state.uri.path == '/login';
      final bool isOnSplash = state.uri.path == '/splash';

      // 1. If no token, force login
      if (token == null || token.isEmpty) {
        if (isLoggingIn || isOnSplash) return null;
        return '/login';
      }

      // 2. If logged in and hitting Splash/Login, send to Dashboard
      if (isLoggingIn || isOnSplash) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
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
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        // ✅ The pageKey prevents the Shell from rebuilding/flickering black
        builder: (context, state, child) => MainDashboard(
            key: state.pageKey,
            child: child
        ),
        routes: [
          GoRoute(
              path: '/dashboard',
              builder: (context, state) => const StockDashboardView()
          ),
          GoRoute(path: '/manage_user', builder: (context, state) => const UserManagementPage()),
          GoRoute(path: '/inventory', builder: (context, state) => const InventoryPage()),
          GoRoute(path: '/transaction', builder: (context, state) => const SupplierManagementView()),
          GoRoute(path: '/purchase', builder: (context, state) => const PurchaseMasterView()),
          GoRoute(path: '/sale', builder: (context, state) => const SalesMasterView()),
          GoRoute(path: '/stock-ledger', builder: (context, state) => const StockLedgerView()),
        ],
      ),
    ],
  );
}