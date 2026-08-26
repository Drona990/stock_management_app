import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stock_management/features/auth/presentation/pages/create_superuser.dart';
import 'package:stock_management/features/auth/presentation/pages/login_page.dart';
import 'package:stock_management/features/main/presentation/pages/bar&resturant/dashboard_details_page.dart';
import 'package:stock_management/features/main/presentation/pages/bar&resturant/user_permissions_page.dart';
import 'package:stock_management/features/managment/presentation/pages/session_management_page.dart';
import '../../features/main/presentation/pages/attendance/attendance_master_page.dart';
import '../../features/main/presentation/pages/bar&resturant/user_management_page.dart';
import '../../features/main/presentation/pages/documentations/employment_documents.dart';
import '../../features/main/presentation/pages/staff/role_master_page.dart';
import '../../features/main/presentation/pages/staff/staff_create_page.dart';
import '../../features/main/presentation/pages/staff/staff_masster_page.dart';
import '../../features/managment/presentation/pages/company_profile_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/main/presentation/pages/bar&resturant/main_dashboard.dart';
import '../../injection.dart';

class AppRouter {
  // 🌟 UPDATED: Made public so the API interceptor can call global force logout routes
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
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
      final bool isCreatingSuperuser = state.uri.path == '/create/superuser';

      // 1. Token Protection Gateway
      if (token == null || token.isEmpty) {
        if (isLoggingIn || isOnSplash || isCreatingSuperuser) return null;
        return '/login';
      }

      // 2. Logged In Users Redirects
      if (isLoggingIn || isOnSplash || isCreatingSuperuser) {
        if (userRole == 'staff') {
          return '/dc_terminal';
        }
        return '/dashboard';
      }

      // 3. RBAC Security Parameters for Staff
      final restrictedPaths = ['/dashboard', '/manage_user', '/inventory'];
      if (userRole == 'staff' && restrictedPaths.contains(state.uri.path)) {
        return '/dc_terminal';
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
      GoRoute(
        path: '/create/superuser',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SuperuserCreateScreen(),
      ),

      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainDashboard(
            key: state.pageKey,
            child: child
        ),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) =>  DashboardScreen()),
          GoRoute(path: '/manage_user', builder: (context, state) => const UserManagementPage()),
          GoRoute(path: '/manage_session', builder: (context, state) => const SessionManagementPage()),
          GoRoute(path: '/manage_permission', builder: (context, state) => const UserPermissionsScreen()),
          GoRoute(
            path: '/company_profile',
            builder: (context, state) => const CompanyProfileScreen(),
          ),

          GoRoute(
            path: '/staff_create',
            builder: (context, state) => const StaffCreateScreen(),
          ),
          GoRoute(
            path: '/staff_master',
            builder: (context, state) => const StaffMasterScreen(),
          ),
          GoRoute(
            path: '/roles_master',
            builder: (context, state) => const RolesMasterScreen(),
          ),
          GoRoute(
            path: '/employment_documents',
            builder: (context, state) => const EmploymentDocumentScreen(),
          ),

          GoRoute(
            path: '/attendance_master',
            builder: (context, state) => const AttendanceLeaveMasterScreen(),
          ),
        ],
      ),
    ],
  );
}