// import 'dart:io';
//
// import 'package:bloc/bloc.dart';
// import 'package:equatable/equatable.dart';
// import 'package:formz/formz.dart';
//
// import '../../config/constants.dart';
// import '../repository/login_repository.dart';
//
// part 'login_event.dart';
// part 'login_state.dart';
//
// class LoginBloc extends Bloc<LoginEvent, LoginState> {
//   final LoginRepository repository;
//   bool isFetching = false;
//
//   LoginBloc({
//     required this.repository,
//   }) : super(LoginState()) {
//     on<LoginPhoneChanged>(_onPhoneChanged);
//     on<LoginSubmitted>(_onSubmitted);
//   }
//
//   void _onPhoneChanged(
//     LoginPhoneChanged event,
//     Emitter<LoginState> emit,
//   ) {}
//
//   void _onSubmitted(
//     LoginSubmitted event,
//     Emitter<LoginState> emit,
//   ) async {
//     emit(state.copyWith(status: FormzStatus.submissionInProgress));
//     try {
//       // Simple success for demo
//       emit(state.copyWith(status: FormzStatus.submissionSuccess));
//     } on SocketException {
//       emit(state.copyWith(
//           status: FormzStatus.submissionFailure,
//           message: AppConstants.connectionError));
//     } catch (e) {
//       print(e.toString());
//       emit(state.copyWith(
//           status: FormzStatus.submissionFailure,
//           message: AppConstants.serverError));
//     }
//   }
// }