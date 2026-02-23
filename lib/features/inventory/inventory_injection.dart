import 'package:get_it/get_it.dart';
import 'package:stock_management/features/inventory/presentation/bloc/inventory_brand_block.dart';
import 'package:stock_management/features/inventory/presentation/bloc/inventory_category.dart';
import 'package:stock_management/features/inventory/presentation/bloc/inventory_product_management_bloc.dart';
import 'package:stock_management/features/inventory/presentation/widget/inventory_units_view.dart';
import 'package:stock_management/features/inventory/presentation/widget/tax_profile_view.dart';



Future<void> initInventoryInjection(GetIt sl) async {
  sl.registerLazySingleton<InventoryCategoryRepository>(
        () => InventoryCategoryRepository(),
  );

  sl.registerFactory<InventoryCategoryBloc>(
        () => InventoryCategoryBloc(sl<InventoryCategoryRepository>()),
  );

  // injection.dart mein init() ke andar
  sl.registerLazySingleton<InventoryBrandRepository>(() => InventoryBrandRepository());
  sl.registerFactory<InventoryBrandBloc>(() => InventoryBrandBloc(sl()));

  sl.registerLazySingleton<InventoryUnitRepository>(() => InventoryUnitRepository());
  sl.registerFactory<InventoryUnitBloc>(() => InventoryUnitBloc(sl()));


  sl.registerLazySingleton<TaxProfileRepository>(() => TaxProfileRepository());
  sl.registerFactory<TaxProfileBloc>(() => TaxProfileBloc(sl()));

  // injection.dart
  sl.registerLazySingleton<InventoryProductRepository>(() => InventoryProductRepository());
  sl.registerFactory<InventoryProductBloc>(() => InventoryProductBloc(sl()));

}