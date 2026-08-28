import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
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

  AuthRepositoryImpl({required this.remoteDataSource, required this.storage});

  @override
  Future<Either<Failure, AuthEntity>> loginWithCredentials(String username, String password) async {
    try {
      final response = await remoteDataSource.apiClient.post(
        '/api/auth/login/',
        data: {'email': username, 'password': password},
      );
      final model = AuthModel.fromJson(response.data);
      return _processAuthSuccess(model);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data['error'] ?? e.response?.data['detail'] ?? "Login Failed"));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthEntity>> loginWithQR(String qrToken) async {
    try {
      final response = await remoteDataSource.apiClient.post(
        '/api/hrms/auth/qr-login/',
        data: {'qr_token': qrToken},
      );
      final model = AuthModel.fromJson(response.data);
      return _processAuthSuccess(model);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data['error'] ?? "Invalid or expired QR Token"));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, AuthEntity>> _processAuthSuccess(AuthModel model) async {
    if (model.access == null || model.access!.isEmpty) {
      return Left(ServerFailure("Security Token Missing"));
    }

    final entity = model.toEntity();

    await storage.write(key: 'access_token', value: entity.accessToken);
    await storage.write(key: 'refresh_token', value: entity.refreshToken);
    await storage.write(key: 'user_id', value: entity.userId);
    await storage.write(key: 'employee_id', value: entity.employeeId);
    await storage.write(key: 'emp_code', value: entity.empCode);
    await storage.write(key: 'full_name', value: entity.fullName);

    // 🌟 Profile photo storage write
    if (entity.profilePhoto != null && entity.profilePhoto!.isNotEmpty) {
      await storage.write(key: 'profile_photo', value: entity.profilePhoto);
    } else {
      await storage.delete(key: 'profile_photo');
    }

    await storage.write(key: 'department', value: entity.department);
    await storage.write(key: 'designation', value: entity.designation);
    await storage.write(key: 'shift_code', value: entity.shiftCode);
    await storage.write(key: 'shift_name', value: entity.shiftName);
    await storage.write(key: 'shift_start', value: entity.shiftStart);
    await storage.write(key: 'shift_end', value: entity.shiftEnd);

    _updateDI(entity.accessToken, entity.refreshToken);
    return Right(entity);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getEmployeeDashboardData() async {
    try {
      final response = await remoteDataSource.apiClient.get('/api/employee/dashboard/');
      return Right(response.data['data'] ?? {});
    } catch (e) {
      return Left(ServerFailure("Failed to sync dashboard metrics"));
    }
  }

  @override
  Future<void> updateFCMToken() async {}

  @override
  Future<void> logout() async {
    await storage.deleteAll();
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