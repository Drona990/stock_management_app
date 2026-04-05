import 'package:get_it/get_it.dart';
import 'package:stock_management/features/transaction/presentation/pages/cash_transaction_page.dart';
import 'package:stock_management/features/transaction/presentation/pages/journal_entry_page.py.dart';
import 'package:stock_management/features/transaction/presentation/pages/stock_dashboard_view.dart';
import 'package:stock_management/features/transaction/presentation/pages/transaction_entry_screen.dart';

Future<void> initTnxInjection(GetIt sl) async {
  sl.registerLazySingleton(() => DashboardRepository());
  sl.registerFactory(() => DashboardBloc(sl<DashboardRepository>()));

  sl.registerLazySingleton(() => TransactionRepository());
  sl.registerFactory(() => TransactionBloc(sl<TransactionRepository>()));

  sl.registerLazySingleton(() =>  CashTransactionRepository());
  sl.registerFactory(() => CashTransactionBloc(sl<CashTransactionRepository>()));

  sl.registerLazySingleton(() =>  JournalRepository());
  sl.registerFactory(() => JournalBloc(sl<JournalRepository>()));

}