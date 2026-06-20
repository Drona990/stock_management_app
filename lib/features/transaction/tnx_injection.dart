import 'package:get_it/get_it.dart';
import 'package:stock_management/features/transaction/presentation/pages/cash_transaction_page.dart';
import 'package:stock_management/features/transaction/presentation/pages/credit_debit_note_terminal_view.dart';
import 'package:stock_management/features/transaction/presentation/pages/dc_terminal_view.dart';
import 'package:stock_management/features/transaction/presentation/pages/journal_entry_page.py.dart';
import 'package:stock_management/features/transaction/presentation/pages/stock_dashboard_view.dart';
import 'package:stock_management/features/transaction/presentation/pages/transaction_entry_screen.dart';

Future<void> initTnxInjection(GetIt sl) async {

  sl.registerLazySingleton(() => TransactionRepository());
  sl.registerFactory(() => TransactionBloc(sl<TransactionRepository>()));

  sl.registerLazySingleton(() =>  CashTransactionRepository());
  sl.registerFactory(() => CashTransactionBloc(sl<CashTransactionRepository>()));

  sl.registerLazySingleton(() =>  JournalRepository());
  sl.registerFactory(() => JournalBloc(sl<JournalRepository>()));

  // Dependency mappings for unified screen executions
  sl.registerLazySingleton<UnifiedTransactionRepository>(() => UnifiedTransactionRepository());
  sl.registerFactory(() => UnifiedTxBloc(sl<UnifiedTransactionRepository>()));

  sl.registerLazySingleton<FinancialNoteRepository>(() => FinancialNoteRepository());
  sl.registerFactory(() => NoteTxBloc(sl<FinancialNoteRepository>()));

}