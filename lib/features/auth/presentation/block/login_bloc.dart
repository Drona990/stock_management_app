import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// =============================================================================
// LOGIN EVENTS
// =============================================================================
abstract class LoginEvent {}

class LoginSubmitted extends LoginEvent {
  final String login;
  final String password;
  LoginSubmitted(this.login, this.password);
}

class LoginWithQRSubmitted extends LoginEvent {
  final String rawQrCode;
  LoginWithQRSubmitted(this.rawQrCode);
}

// =============================================================================
// LOGIN STATES
// =============================================================================
abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final AuthEntity auth;
  LoginSuccess(this.auth);
}

class LoginFailure extends LoginState {
  final String error;
  LoginFailure(this.error);
}

// =============================================================================
// LOGIN BLOC ENGINE
// =============================================================================
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository repository;

  LoginBloc(this.repository) : super(LoginInitial()) {
    // 1. Username/Email & Password Login
    on<LoginSubmitted>((event, emit) async {
      emit(LoginLoading());

      final result = await repository.loginWithCredentials(
        event.login.trim(),
        event.password,
      );

      await result.fold(
            (failure) async => emit(LoginFailure(failure.message)),
            (auth) async {
          await repository.updateFCMToken();
          emit(LoginSuccess(auth));
        },
      );
    });

    // 2. Instant QR Token Authentication
    on<LoginWithQRSubmitted>((event, emit) async {
      emit(LoginLoading());

      String token = event.rawQrCode.trim();

      // Agar camera pure JSON string ko scan kare to qr_token key extract karein
      if (token.startsWith('{') && token.endsWith('}')) {
        try {
          final Map<String, dynamic> parsed = jsonDecode(token);
          if (parsed.containsKey('qr_token')) {
            token = parsed['qr_token'].toString().trim();
          }
        } catch (_) {}
      }

      final result = await repository.loginWithQR(token);

      await result.fold(
            (failure) async => emit(LoginFailure(failure.message)),
            (auth) async {
          await repository.updateFCMToken();
          emit(LoginSuccess(auth));
        },
      );
    });
  }
}