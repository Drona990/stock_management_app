import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthEntity>> loginWithCredentials(String username, String password);
  Future<Either<Failure, AuthEntity>> loginWithQR(String qrToken);
  Future<Either<Failure, Map<String, dynamic>>> getEmployeeDashboardData();
  Future<void> updateFCMToken();
  Future<void> logout();
}