import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stock_management/features/auth/presentation/block/login_bloc.dart';
import 'data/data_source/auth_remote_data_source.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/auth_repository_imp.dart';

Future<void> initAuthInjection(GetIt sl) async {
  // --- 1. Data Sources ---
  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSource(sl()),
  );

  // --- 2. Repositories ---
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      storage: sl<FlutterSecureStorage>(),
    ),
  );

  // --- 3. Blocs ---
  sl.registerFactory<LoginBloc>(
        () => LoginBloc(sl<AuthRepository>()),
  );

}