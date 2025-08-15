part of 'login_bloc.dart';

class LoginState extends Equatable {
  const LoginState({
    this.status = FormzStatus.pure,
    this.email = '',
    this.password = '',
    this.message = '',
  });

  final FormzStatus status;
  final String email;
  final String password;
  final String message;

  LoginState copyWith({
    FormzStatus? status,
    String? email,
    String? password,
    String? message,
  }) {
    return LoginState(
      status: status ?? this.status,
      email: email ?? this.email,
      password: password ?? this.password,
      message: message ?? this.message,
    );
  }

  @override
  List<Object> get props => [status, email, password, message];
}

class UnAuthorizedState extends LoginState {
  final String message;

  const UnAuthorizedState({
    required this.message,
  });
}