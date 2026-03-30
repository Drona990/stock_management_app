import 'package:get_it/get_it.dart';
import 'package:stock_management/features/masters/presentation/pages/customer_master_screen.dart';
import 'package:stock_management/features/masters/presentation/pages/supplier_master_screen.dart';
import 'package:stock_management/features/masters/presentation/pages/uom_master_screen.dart';

Future<void> mastersInjection(GetIt sl) async {

  sl.registerLazySingleton<CustomerRepository>(() => CustomerRepository());
  sl.registerFactory(() => CustomerBloc(sl<CustomerRepository>()));

  sl.registerLazySingleton<SupplierRepository>(() =>   SupplierRepository());
  sl.registerFactory(() => SupplierBloc(sl<SupplierRepository>()));

  sl.registerLazySingleton<UomRepository>(() => UomRepository());
  sl.registerFactory(() => UomBloc(sl<UomRepository>()));


}