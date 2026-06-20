/*
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/error/failures.dart';
import '../../data/data_source/auth_remote_data_source.dart';
import '../../data/models/auth_model.dart';
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

      if (userData == null) {
        return Left(ServerFailure("User profile data missing"));
      }

      // 1. Extract Strings safely
      final String role = userData['role']?.toString() ?? "staff";
      final String name = userData['name']?.toString() ?? "User";
      final String userId = userData['user_id']?.toString() ?? "";

      // 2. ✅ Handle the Location Object correctly
      // Since backend sends {"id": 0, "name": "Default Location"}
      String locationName = "Default Location";
      String locationId = "0";

      if (userData['location'] != null && userData['location'] is Map) {
        locationName = userData['location']['name']?.toString() ?? "Default Location";
        locationId = userData['location']['id']?.toString() ?? "0";
      }

      debugPrint("✅ Parsed Role: $role, Name: $name, Location: $locationName");

      // 3. Save to Storage
      await storage.write(key: 'user_role', value: role);
      await storage.write(key: 'username', value: name);
      await storage.write(key: 'user_id', value: userId);
      await storage.write(key: 'location_name', value: locationName);
      await storage.write(key: 'location_id', value: locationId);

      // Returning the map for immediate UI use
      return Right({
        'role': role,
        'name': name,
        'location': locationName,
        'location_id': locationId,
      });

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

  @override
  Future<Either<Failure, AuthEntity>> switchUser(String targetUserId) async {
    try {
      final response = await remoteDataSource.apiClient.post(
        "/api/auth/silent-switch/",
        data: {"user_id": targetUserId},
      );

      if (response.data['success'] == true) {
        final model = AuthModel.fromJson(response.data['data']);

        // 1. Tokens overwrite karein
        await storage.write(key: 'access_token', value: model.access);
        await storage.write(key: 'refresh_token', value: model.refresh);

        // 2. DI update karein (Aapka existing method)
        _updateDI(model.access!, model.refresh!);

        // 3. 🔥 ZAROORI: Naye staff ka Profile (Role, Name, Location) Sync karein
        await getUserProfile();

        return Right(model.toEntity());
      }
      return Left(ServerFailure("Identity Switch Failed"));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
}*/


import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/error/failures.dart';
import '../../data/data_source/auth_remote_data_source.dart';
import '../../data/models/auth_model.dart';
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

      // 1. Response credentials metadata securely preserve karein
      await storage.write(key: 'access_token', value: accessToken);
      await storage.write(key: 'refresh_token', value: refreshToken);
      await storage.write(key: 'user_role', value: model.role ?? 'admin');
      await storage.write(key: 'username', value: model.fullName ?? username);
      await storage.write(key: 'user_id', value: model.userId ?? '');
      await storage.write(key: 'session_id', value: model.sessionId ?? '');

      _updateDI(accessToken, refreshToken);

      // User profile configuration metrics dynamically mapping pull karna
      final profileResult = await getUserProfile();

      return profileResult.fold(
            (failure) => Left(failure),
            (data) {
          debugPrint("✅ Session mapping metadata fully synced into Storage.");
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

      if (userData == null) {
        return Left(ServerFailure("User profile data missing"));
      }

      final String role = userData['role']?.toString() ?? "admin";
      final String name = userData['name']?.toString() ?? "User";
      final String userId = userData['user_id']?.toString() ?? "";

      String locationName = "Default Location";
      String locationId = "0";

      if (userData['location'] != null && userData['location'] is Map) {
        locationName = userData['location']['name']?.toString() ?? "Default Location";
        locationId = userData['location']['id']?.toString() ?? "0";
      }

      debugPrint("✅ Dynamic System Metrics Profile Sync Completed.");

      await storage.write(key: 'user_role', value: role);
      await storage.write(key: 'username', value: name);
      await storage.write(key: 'user_id', value: userId);
      await storage.write(key: 'location_name', value: locationName);
      await storage.write(key: 'location_id', value: locationId);

      return Right({
        'role': role,
        'name': name,
        'location': locationName,
        'location_id': locationId,
      });

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
      await remoteDataSource.updateFCMToken(fcmToken);
    } catch (e) {
      debugPrint("FCM Update Error: $e");
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> switchUser(String targetUserId) async {
    try {
      final response = await remoteDataSource.apiClient.post(
        "/api/auth/silent-switch/",
        data: {"user_id": targetUserId},
      );

      if (response.data['success'] == true) {
        final model = AuthModel.fromJson(response.data['data']);

        await storage.write(key: 'access_token', value: model.access);
        await storage.write(key: 'refresh_token', value: model.refresh);
        await storage.write(key: 'session_id', value: model.sessionId);

        _updateDI(model.access!, model.refresh!);
        await getUserProfile();

        return Right(model.toEntity());
      }
      return Left(ServerFailure("Identity Switch Failed"));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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