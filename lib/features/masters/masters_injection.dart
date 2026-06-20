import 'package:get_it/get_it.dart';
import 'package:stock_management/features/masters/presentation/pages/customer_master_screen.dart';
import 'package:stock_management/features/masters/presentation/pages/ledger_entry_screen.dart';
import 'package:stock_management/features/masters/presentation/pages/material_master_entry_page.dart';
import 'package:stock_management/features/masters/presentation/pages/material_type_master_page.dart';
import 'package:stock_management/features/masters/presentation/pages/supplier_master_screen.dart';
import 'package:stock_management/features/masters/presentation/pages/uom_master_screen.dart';

import 'presentation/pages/bom_entry_page.dart';

Future<void> mastersInjection(GetIt sl) async {

  sl.registerLazySingleton<CustomerRepository>(() => CustomerRepository());
  sl.registerFactory(() => CustomerBloc(sl<CustomerRepository>()));

  sl.registerLazySingleton<SupplierRepository>(() =>   SupplierRepository());
  sl.registerFactory(() => SupplierBloc(sl<SupplierRepository>()));

  sl.registerLazySingleton<UomRepository>(() => UomRepository());
  sl.registerFactory(() => UomBloc(sl<UomRepository>()));

  sl.registerLazySingleton<MaterialTypeRepository>(() => MaterialTypeRepository());
  sl.registerFactory(() => MaterialTypeBloc(sl<MaterialTypeRepository>()));

  sl.registerLazySingleton<MaterialMasterRepository>(() => MaterialMasterRepository());
  sl.registerFactory(() => MaterialMasterBloc(sl<MaterialMasterRepository>()));

  sl.registerLazySingleton<ProjectBomRepository>(() => ProjectBomRepository());
  sl.registerFactory(() => ProjectBomBloc(sl<ProjectBomRepository>()));

  sl.registerLazySingleton<LedgerMasterRepository>(() => LedgerMasterRepository());
  sl.registerFactory(() => LedgerMasterBloc(sl<LedgerMasterRepository>()));


}