import 'package:get_it/get_it.dart';
import 'package:stock_management/features/transaction/presentation/pages/stock_dashboard_view.dart';
import 'package:stock_management/features/transaction/presentation/pages/transaction_entry_screen.dart';

Future<void> initTnxInjection(GetIt sl) async {
  sl.registerLazySingleton(() => DashboardRepository());
  sl.registerFactory(() => DashboardBloc(sl<DashboardRepository>()));

  sl.registerLazySingleton(() => TransactionRepository());
  sl.registerFactory(() => TransactionBloc(sl<TransactionRepository>()));


}