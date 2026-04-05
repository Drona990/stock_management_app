import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stock_management/features/inventory/inventory_injection.dart';
import 'package:stock_management/features/masters/masters_injection.dart';
import 'package:stock_management/features/transaction/tnx_injection.dart';
import 'core/network/api_client.dart';
import 'core/network/network_info.dart';
import 'core/utils/websocket/websocket_service.dart';
import 'features/auth/auth_injection.dart';
import 'features/reports/report_injection.dart';

final sl = GetIt.instance;

Future<void> init() async {
  sl.registerLazySingleton(() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
    ),
  ));

  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton<FlutterSecureStorage>(
          () => const FlutterSecureStorage());
  // Core
  sl.registerLazySingleton<NetworkInfo>(
        () => NetworkInfoImpl(sl()),
  );

  sl.registerLazySingleton<ApiClient>(
        () => ApiClient(sl()),
  );
  sl.registerLazySingleton<WebSocketService>(() => WebSocketService());

  // Features
  await initAuthInjection(sl);
  await initInventoryInjection(sl);
  await initTnxInjection(sl);
  await mastersInjection(sl);
  await reportInjection(sl);


}
