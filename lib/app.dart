import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:stock_management/features/masters/presentation/pages/customer_master_screen.dart';
import 'package:stock_management/features/masters/presentation/pages/ledger_entry_screen.dart';
import 'package:stock_management/features/masters/presentation/pages/supplier_master_screen.dart';
import 'package:stock_management/features/reports/presentation/bloc/salse_purchase_legder_report_bloc.dart';
import 'package:stock_management/features/transaction/presentation/pages/dc_terminal_view.dart';
import 'package:stock_management/features/transaction/presentation/pages/purchase_order_transaction_page.dart';
import 'package:stock_management/features/transaction/presentation/pages/transaction_entry_screen.dart';
import '../../core/utils/app_routes.dart';
import 'core/theme/app_color.dart';
import 'features/auth/presentation/block/login_bloc.dart';
import 'features/masters/presentation/pages/uom_master_screen.dart';
import 'features/transaction/presentation/pages/cash_transaction_page.dart';
import 'features/transaction/presentation/pages/credit_debit_note_terminal_view.dart';
import 'features/transaction/presentation/pages/journal_entry_page.py.dart';
import 'injection.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  // 🌟 ENGINE: Start or reset inactivity tracking loop
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 5), _handleAutoLogout);
  }

  // 🌟 TRIGGER: Core action when timer reaches explicit limit (5 min)
  Future<void> _handleAutoLogout() async {
    if (!GetIt.I.isRegistered<FlutterSecureStorage>()) return;
    final storage = GetIt.I<FlutterSecureStorage>();

    // Clear dynamic auth tokens safely
    final String? token = await storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      await storage.delete(key: 'access_token');
      await storage.delete(key: 'user_role');

      // Kick user instantly to Login page via public root navigation key channel
      final context = AppRouter.rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Session expired. Re-Login again."),
            backgroundColor: Colors.redAccent,
          ),
        );
        AppRouter.router.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(create: (context) => sl<LoginBloc>()),
        BlocProvider(create: (_) => sl<CustomerBloc>()),
        BlocProvider(create: (_) => sl<SupplierBloc>()),
        BlocProvider(create: (_) => sl<UomBloc>()),
        BlocProvider(create: (_) => sl<TransactionBloc>()),
        BlocProvider(create: (_) => sl<LedgerBloc>()),
        BlocProvider(create: (_) => sl<LedgerMasterBloc>()),
        BlocProvider(create: (_) => sl<CashTransactionBloc>()),
        BlocProvider(create: (_) => sl<JournalBloc>()),
        BlocProvider(create: (_) => sl<UnifiedTxBloc>()),
        BlocProvider(create: (_) => sl<NoteTxBloc>()),
        //BlocProvider(create: (_) => sl<PurchaseOrderBloc>()),

      ],
      child: GestureDetector(
        // 🌟 CAPTURE EVERY USER TOUCH MATRIX -> Reset dynamic timer pulse on interaction
        behavior: HitTestBehavior.translucent,
        onTap: _startInactivityTimer,
        onPanDown: (_) => _startInactivityTimer(),
        onScaleStart: (_) => _startInactivityTimer(),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: AppRouter.router,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.backgroundGrey,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primaryCyan,
              primary: AppColors.primaryCyan,
              onPrimary: AppColors.pureWhite,
              surface: AppColors.pureWhite,
              onSurface: AppColors.deepBlack,
            ),
            textTheme: const TextTheme(
              displayLarge: TextStyle(color: AppColors.deepBlack, fontWeight: FontWeight.bold),
              bodyLarge: TextStyle(color: AppColors.deepBlack),
              bodyMedium: TextStyle(color: AppColors.textGrey),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.pureWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryCyan, width: 2),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryCyan,
                foregroundColor: AppColors.pureWhite,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}