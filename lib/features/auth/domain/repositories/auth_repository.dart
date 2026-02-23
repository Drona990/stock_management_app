import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthEntity>> login(String login, String password);

  Future<Either<Failure, Map<String, String>>> getUserProfile();

  Future<void> updateFCMToken();
}