import 'package:get_it/get_it.dart';
import 'package:stock_management/features/transaction/presentation/bloc/purchase_bloc.dart';
import 'package:stock_management/features/transaction/presentation/bloc/salse_bloc.dart';
import 'package:stock_management/features/transaction/presentation/bloc/stock_bloc.dart';
import 'package:stock_management/features/transaction/presentation/bloc/stock_dashboard_bloc.dart';
import 'package:stock_management/features/transaction/presentation/bloc/suppier_bloc.dart';
import 'domain/repository/dashboard_stock_summary_reposotory.dart';
import 'domain/repository/purchase_repository.dart';
import 'domain/repository/salse_repository.dart';
import 'domain/repository/stock_repository.dart';
import 'domain/repository/supplier_repository.dart';

Future<void> initTnxInjection(GetIt sl) async {

  sl.registerFactory(() => SupplierBloc(sl()));
  sl.registerLazySingleton(() => SupplierRepository());

  sl.registerFactory(() => PurchaseBloc(sl()));
  sl.registerLazySingleton(() => PurchaseRepository());

  sl.registerFactory(() => SaleBloc(sl()));
  sl.registerLazySingleton(() => SaleRepository());

  sl.registerLazySingleton(() => DashboardStockSummaryRepository());
  sl.registerFactory(() => DashboardStockBloc(sl()));

  sl.registerFactory(() => StockBloc(sl()));
  sl.registerLazySingleton(() => StockRepository());

}