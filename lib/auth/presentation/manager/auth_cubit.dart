import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../service_locator.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository = getIt<AuthRepository>();

  AuthCubit() : super(AuthInitial());

  Future<void> signIn(String email, String password) async {
    try {
      emit(AuthLoading());
      print('Attempting to sign in with email: $email');
      final user = await authRepository.signIn(email, password);
      if (user != null) {
        if (user.isBlocked) {
          print('User is blocked');
          emit(AuthError('User is blocked'));
          await authRepository.signOut();
        } else {
          print('User authenticated');
          emit(Authenticated(user));
        }
      } else {
        print('User not found in Firestore');
        emit(AuthError('User not found'));
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during sign-in.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password provided.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Network error, please try again.';
      }
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      emit(AuthError(errorMessage));
    } catch (e) {
      print('Unknown error: $e');
      emit(AuthError('An unknown error occurred.'));
    }
  }

  Future<void> signUp(String email, String password, String username) async {
    try {
      emit(AuthLoading());
      final user = await authRepository.signUp(email, password, username);
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(AuthError('Sign Up Failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    await authRepository.signOut();
    emit(Unauthenticated());
  }
}
