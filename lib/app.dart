
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_management/features/inventory/presentation/bloc/inventory_product_management_bloc.dart';
import 'package:stock_management/features/transaction/presentation/bloc/purchase_bloc.dart';
import 'package:stock_management/features/transaction/presentation/bloc/salse_bloc.dart';
import 'package:stock_management/features/transaction/presentation/bloc/stock_dashboard_bloc.dart';
import '../../core/utils/app_routes.dart';
import 'core/theme/app_color.dart';
import 'features/auth/presentation/block/login_bloc.dart';
import 'features/transaction/presentation/bloc/stock_bloc.dart';
import 'features/transaction/presentation/bloc/suppier_bloc.dart';
import 'injection.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(create: (context) => sl<LoginBloc>()),
        BlocProvider(create: (context) => sl<SupplierBloc>()),
        BlocProvider(create: (context) => sl<PurchaseBloc>()),
        BlocProvider(create: (context) => sl<InventoryProductBloc>()),
        BlocProvider(create: (context) => sl<SaleBloc>()),
        BlocProvider(create: (context) => sl<DashboardStockBloc>()),
        BlocProvider(create: (context) => sl<StockBloc>()),


      ],
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
    );
  }
}