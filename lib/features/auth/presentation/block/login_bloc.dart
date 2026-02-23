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

      final result = await repository.login(event.login, event.password);

      await result.fold(
            (failure) async {
          emit(LoginFailure(failure.message));
        },
            (auth) async {
          repository.updateFCMToken();

          final profileResult = await repository.getUserProfile();

          profileResult.fold(
                (failure) => emit(LoginFailure("Profile setup failed: ${failure.message}")),
                (profileMap) {
              emit(LoginSuccess(auth));
            },
          );
        },
      );
    });
  }
}