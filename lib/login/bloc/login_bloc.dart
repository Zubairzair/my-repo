import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/constants.dart';
import '../../config/session_manager.dart';
import '../repository/login_repository.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginRepository repository;
  bool isFetching = false;

  LoginBloc({
    required this.repository,
  }) : super(const LoginState()) {
    on<LoginEmailChanged>(_onEmailChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onSubmitted);
    on<LoginSignUpRequested>(_onSignUpRequested);
  }

  void _onEmailChanged(
    LoginEmailChanged event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(
      email: event.email,
      status: FormzStatus.pure,
    ));
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(
      password: event.password,
      status: FormzStatus.pure,
    ));
  }

  void _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (state.email.isEmpty || state.password.isEmpty) {
      emit(state.copyWith(
        status: FormzStatus.submissionFailure,
        message: 'Please fill in all fields',
      ));
      return;
    }

    emit(state.copyWith(status: FormzStatus.submissionInProgress));
    
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: state.email.trim(),
        password: state.password,
      );

      if (credential.user != null) {
        await SessionManager().setLOGIN("true");
        await SessionManager().setFirstName(
          credential.user!.displayName ?? state.email.split('@')[0]
        );
        await SessionManager().setEmail(state.email.trim());
        
        emit(state.copyWith(status: FormzStatus.submissionSuccess));
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many failed attempts. Please try again later.';
      }
      emit(state.copyWith(
        status: FormzStatus.submissionFailure,
        message: message,
      ));
    } on SocketException {
      emit(state.copyWith(
        status: FormzStatus.submissionFailure,
        message: AppConstants.connectionError,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FormzStatus.submissionFailure,
        message: AppConstants.serverError,
      ));
    }
  }

  void _onSignUpRequested(
    LoginSignUpRequested event,
    Emitter<LoginState> emit,
  ) async {
    if (state.email.isEmpty || state.password.isEmpty) {
      emit(state.copyWith(
        status: FormzStatus.submissionFailure,
        message: 'Please fill in all fields',
      ));
      return;
    }

    if (state.password.length < 6) {
      emit(state.copyWith(
        status: FormzStatus.submissionFailure,
        message: 'Password must be at least 6 characters',
      ));
      return;
    }

    emit(state.copyWith(status: FormzStatus.submissionInProgress));
    
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: state.email.trim(),
        password: state.password,
      );

      if (credential.user != null) {
        await SessionManager().setLOGIN("true");
        await SessionManager().setFirstName(state.email.split('@')[0]);
        await SessionManager().setEmail(state.email.trim());
        
        emit(state.copyWith(status: FormzStatus.submissionSuccess));
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Sign up failed';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address.';
      }
      emit(state.copyWith(
        status: FormzStatus.submissionFailure,
        message: message,
      ));
    } on SocketException {
      emit(state.copyWith(
        status: FormzStatus.submissionFailure,
        message: AppConstants.connectionError,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: FormzStatus.submissionFailure,
        message: AppConstants.serverError,
      ));
    }
  }
}