import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/error/failures.dart';
import '../../data/data_source/auth_remote_data_source.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage storage;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storage,
  });


  @override
  Future<Either<Failure, AuthEntity>> login(String username, String password) async {
    try {
      final model = await remoteDataSource.login(username, password);
      final String accessToken = model.access ?? "";
      final String refreshToken = model.refresh ?? "";

      if (accessToken.isEmpty) {
        return Left(ServerFailure("Token missing"));
      }

      // 1. Tokens save karein
      await storage.write(key: 'access_token', value: accessToken);
      await storage.write(key: 'refresh_token', value: refreshToken);

      _updateDI(accessToken, refreshToken);

      final profileResult = await getUserProfile();

      return profileResult.fold(
            (failure) => Left(failure),
            (data) {
          debugPrint("✅ Profile Data Synced into Storage before navigation");
          return Right(model.toEntity());
        },
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }


  @override
  Future<Either<Failure, Map<String, String>>> getUserProfile() async {
    try {
      final response = await remoteDataSource.getUserDashboard();

      final responseBody = response.data;
      if (responseBody == null || responseBody['data'] == null) {
        return Left(ServerFailure("Server returned no data"));
      }

      final dataMap = responseBody['data'];
      final userData = dataMap['user'];

      print("data map $dataMap");

      if (userData == null) {
        return Left(ServerFailure("User profile data missing"));
      }

      final String role = userData['role']?.toString() ?? "Customer";
      final String name = userData['name']?.toString() ?? "Customer";
      final String userId = userData['user_id']?.toString() ?? "uuid";


      debugPrint("✅ Parsed Role: $role, Name: $name");

      await storage.write(key: 'user_role', value: role);
      await storage.write(key: 'username', value: name);
      await storage.write(key: 'user_id', value: userId);

      debugPrint("✅ Role saved in storage: $role");
      debugPrint("✅ name saved in storage: $name");
      debugPrint("✅ userId saved in storage: $userId");



      return Right({'role': role, 'name': name});
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data['message'] ?? "Profile Fetch Failed"));
    } catch (e) {
      debugPrint("Profile Parsing Error: $e");
      return Left(ServerFailure("Data Parsing Error"));
    }
  }

  @override
  Future<void> updateFCMToken() async {
    if (!kIsWeb && Platform.isWindows) {
      debugPrint("FCM Registration skipped on Windows Desktop");
      return;
    }

    try {
      String fcmToken = "Demo";
      if (fcmToken != null) {
        await remoteDataSource.updateFCMToken(fcmToken);
        debugPrint("FCM Token Updated Successfully: $fcmToken");
      }
    } catch (e) {
      debugPrint("FCM Update Error: $e");
    }
  }

  void _updateDI(String access, String refresh) {
    final sl = GetIt.I;
    if (sl.isRegistered<String>(instanceName: 'accessToken')) {
      sl.unregister<String>(instanceName: 'accessToken');
    }
    if (sl.isRegistered<String>(instanceName: 'refreshToken')) {
      sl.unregister<String>(instanceName: 'refreshToken');
    }
    sl.registerSingleton<String>(access, instanceName: 'accessToken');
    sl.registerSingleton<String>(refresh, instanceName: 'refreshToken');
  }
}