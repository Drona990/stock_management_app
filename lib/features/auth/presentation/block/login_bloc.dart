import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

// Events
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

// States
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

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository repository;

  LoginBloc(this.repository) : super(LoginInitial()) {
    on<LoginSubmitted>((event, emit) async {
      emit(LoginLoading());
      final result = await repository.loginWithCredentials(event.login, event.password);
      result.fold(
            (failure) => emit(LoginFailure(failure.message)),
            (auth) => emit(LoginSuccess(auth)),
      );
    });

    on<LoginWithQRSubmitted>((event, emit) async {
      emit(LoginLoading());

      String token = event.rawQrCode;
      try {
        final parsed = jsonDecode(event.rawQrCode);
        if (parsed is Map && parsed.containsKey('qr_token')) {
          token = parsed['qr_token'];
        }
      } catch (_) {}

      final result = await repository.loginWithQR(token);
      result.fold(
            (failure) => emit(LoginFailure(failure.message)),
            (auth) => emit(LoginSuccess(auth)),
      );
    });
  }
}