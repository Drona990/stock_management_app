import 'package:get_it/get_it.dart';
import 'package:stock_management/features/reports/presentation/bloc/salse_purchase_legder_report_bloc.dart';

Future<void> reportInjection(GetIt sl) async {

  sl.registerLazySingleton<LedgerRepository>(() => LedgerRepository());
  sl.registerFactory(() => LedgerBloc(sl<LedgerRepository>()));



}