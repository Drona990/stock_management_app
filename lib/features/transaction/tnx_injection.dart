import 'package:get_it/get_it.dart';
import 'package:stock_management/features/transaction/presentation/pages/stock_dashboard_view.dart';

Future<void> initTnxInjection(GetIt sl) async {
  sl.registerLazySingleton(() => DashboardRepository());
  sl.registerFactory(() => DashboardBloc(sl<DashboardRepository>()));


}