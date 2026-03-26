
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_management/features/transaction/presentation/pages/rreturn_exchange_screen.dart';
import 'package:stock_management/features/transaction/presentation/pages/salse_bill_screen.dart';
import 'package:stock_management/features/transaction/presentation/pages/stock_dashboard_view.dart';
import 'package:stock_management/features/transaction/presentation/pages/stock_plus_screen.dart';
import '../../core/utils/app_routes.dart';
import 'core/theme/app_color.dart';
import 'features/auth/presentation/block/login_bloc.dart';
import 'features/inventory/presentation/bloc/inventory_group_subgroup_bloc.dart';
import 'features/inventory/presentation/bloc/item_location_bloc.dart';
import 'features/inventory/presentation/bloc/location_bloc.dart';
import 'injection.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(create: (context) => sl<LoginBloc>()),
        BlocProvider(create: (context) => sl<StockEntryBloc>()),
        BlocProvider(create: (_) => sl<ProductGroupBloc>()),
        BlocProvider(create: (_) => sl<ProductSubGroupBloc>()),
        BlocProvider(create: (_) => sl<StockEntryBloc>()),
        BlocProvider(create: (_) => sl<SalesBloc>()),
        BlocProvider(create: (_) => sl<DashboardBloc>()),
        BlocProvider(create: (_) => sl<LocationBloc>()),
        BlocProvider(create: (_) => sl<ReturnBloc>()),
        BlocProvider(create: (_) => sl<ItemLocationBloc>()),

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