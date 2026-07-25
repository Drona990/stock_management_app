import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stock_management/features/auth/presentation/pages/create_superuser.dart';
import 'package:stock_management/features/auth/presentation/pages/login_page.dart';
import 'package:stock_management/features/main/presentation/pages/bar&resturant/user_permissions_page.dart';
import 'package:stock_management/features/managment/presentation/pages/session_management_page.dart';
import 'package:stock_management/features/masters/presentation/pages/material_type_master_page.dart';
import 'package:stock_management/features/masters/presentation/pages/uom_master_screen.dart';
import 'package:stock_management/features/reports/presentation/pages/bom_project_history_page.dart';
import 'package:stock_management/features/reports/presentation/pages/dc_challan_history.dart';
import 'package:stock_management/features/reports/presentation/pages/finalcial_note_reports_screen.dart';
import 'package:stock_management/features/reports/presentation/pages/ledger_transacton_report_screen.dart';
import 'package:stock_management/features/transaction/presentation/pages/dc_terminal_view.dart';
import 'package:stock_management/features/transaction/presentation/pages/journal_entry_page.py.dart';
import 'package:stock_management/features/transaction/presentation/pages/quotation_page.dart';
import 'package:stock_management/features/transaction/presentation/pages/stock_dashboard_view.dart';
import '../../features/main/presentation/pages/bar&resturant/user_management_page.dart';
import '../../features/masters/presentation/pages/customer_master_screen.dart';
import '../../features/masters/presentation/pages/ledger_entry_screen.dart';
import '../../features/masters/presentation/pages/material_master_entry_page.dart';
import '../../features/masters/presentation/pages/supplier_master_screen.dart';
import '../../features/reports/presentation/pages/purchase_ledger_report_page.dart';
import '../../features/reports/presentation/pages/sales_ledger_report_page.dart';
import '../../features/masters/presentation/pages/bom_entry_page.dart';
import '../../features/transaction/presentation/pages/bom_project_final_config_page.dart';
import '../../features/transaction/presentation/pages/cash_transaction_page.dart';
import '../../features/transaction/presentation/pages/credit_debit_note_terminal_view.dart';
import '../../features/transaction/presentation/pages/purchase_order_transaction_page.dart';
import '../../features/transaction/presentation/pages/transaction_entry_screen.dart';
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
          GoRoute(path: '/customer_master', builder: (context, state) => const CustomerMasterScreen()),
          GoRoute(path: '/supplier_master', builder: (context, state) => const SupplierMasterScreen()),
          GoRoute(path: '/uom_master', builder: (context, state) => const UomView()),
          GoRoute(path: '/material_type_master', builder: (context, state) => const MaterialTypeMasterPage()),
          GoRoute(path: '/material_master', builder: (context, state) => const MaterialMasterPage()),
          GoRoute(path: '/bom_entry', builder: (context, state) => const ProjectBomPage()),
          GoRoute(path: '/project_bom', builder: (context, state) => const ProjectFinalConfigPage()),
          GoRoute(path: '/bom_history', builder: (context, state) => const BomProjectHistoryPage()),
          GoRoute(path: '/sales_transaction', builder: (context, state) => const TransactionTerminalScreen(isSales: true)),
          GoRoute(path: '/purchase_transaction', builder: (context, state) => const TransactionTerminalScreen(isSales: false)),
          GoRoute(path: '/purchase_order', builder: (context, state) => const PurchaseOrderTerminalScreen
            ()),
          GoRoute(path: '/adjustment_return', builder: (context, state) => const CreditDebitNoteTerminalScreen()),
          GoRoute(path: '/financial_note_summary', builder: (context, state) => const FinancialNoteReportScreen()),
          GoRoute(
            path: '/dc_summary',
            parentNavigatorKey: _shellNavigatorKey, // Enforces rendering tightly inside dashboard shell body
            builder: (context, state) {
              // 🌟 THE LIFECYCLE FIX ENGINE: Forcefully allocations brand new Bloc instance on every single route entry
              return BlocProvider<UnifiedTxBloc>(
                create: (context) => sl<UnifiedTxBloc>(),
                child: const DcChallanHistory(),
              );
            },
          ),
          GoRoute(path: '/sales_ledger_report', builder: (context, state) => const SalesLedgerReportPage()),
          GoRoute(path: '/purchase_ledger_report', builder: (context, state) => const PurchaseLedgerReportPage()),
          GoRoute(path: '/ledger_screen', builder: (context, state) => const LedgerMasterPage()),
          GoRoute(path: '/ledger_summary', builder: (context, state) => const LedgerReportScreen()),
          GoRoute(path: '/cash_transaction', builder: (context, state) => const CashTransactionPage()),
          GoRoute(path: '/journal_entry', builder: (context, state) => const JournalEntryPage()),

          GoRoute(path: '/dashboard', builder: (context, state) => const StockDashboardView()),
          GoRoute(path: '/manage_user', builder: (context, state) => const UserManagementPage()),
          GoRoute(path: '/manage_session', builder: (context, state) => const SessionManagementPage()),
          GoRoute(path: '/manage_permission', builder: (context, state) => const UserPermissionsScreen()),
          GoRoute(path: '/dc_terminal', builder: (context, state) => const DynamicTerminalScreen()),
          GoRoute(path: '/quotation_entry', builder: (context, state) => const QuotationTerminalScreen()),

        ],
      ),
    ],
  );
}