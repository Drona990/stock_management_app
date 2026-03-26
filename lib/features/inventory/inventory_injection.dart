import 'package:get_it/get_it.dart';
import 'package:stock_management/features/inventory/presentation/bloc/inventory_category.dart';
import 'package:stock_management/features/inventory/presentation/bloc/inventory_group_subgroup_bloc.dart';
import 'package:stock_management/features/inventory/presentation/bloc/item_location_bloc.dart';
import 'package:stock_management/features/inventory/presentation/bloc/location_bloc.dart';
import 'package:stock_management/features/transaction/presentation/pages/salse_bill_screen.dart';
import 'package:stock_management/features/transaction/presentation/pages/stock_plus_screen.dart';

import '../transaction/presentation/pages/rreturn_exchange_screen.dart';



Future<void> initInventoryInjection(GetIt sl) async {
  sl.registerLazySingleton<InventoryCategoryRepository>(
        () => InventoryCategoryRepository(),
  );

  sl.registerFactory<InventoryCategoryBloc>(
        () => InventoryCategoryBloc(sl<InventoryCategoryRepository>()),
  );

// Location Registration
  sl.registerLazySingleton<LocationRepository>(() => LocationRepository());
  sl.registerFactory(() => LocationBloc(sl()));

  sl.registerLazySingleton<ItemLocationRepository>(() => ItemLocationRepository());
  sl.registerFactory(() => ItemLocationBloc(sl()));

  sl.registerLazySingleton<ProductGroupRepository>(() => ProductGroupRepository());
  sl.registerFactory(() => ProductGroupBloc(sl()));

  sl.registerLazySingleton<ProductSubGroupRepository>(() => ProductSubGroupRepository());
  sl.registerFactory(() => ProductSubGroupBloc(sl()));

  sl.registerLazySingleton<StockTransactionRepository>(() => StockTransactionRepository());
  sl.registerFactory(() => StockEntryBloc(sl<StockTransactionRepository>()));

  sl.registerLazySingleton<SalesRepository>(() => SalesRepository());
  sl.registerFactory(() => SalesBloc(sl<SalesRepository>()));

  sl.registerLazySingleton<ReturnRepository>(() => ReturnRepository());
  sl.registerFactory(() => ReturnBloc(sl<ReturnRepository>()));



}




