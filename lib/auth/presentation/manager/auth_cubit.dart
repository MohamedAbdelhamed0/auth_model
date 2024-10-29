import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../service_locator.dart';
import '../../CacheHelper.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository = getIt<AuthRepository>();
  AuthCubit() : super(AuthInitial()) {
    checkAuthStatus();
  }

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
          await CacheHelper.cacheAuthData(
            userId: user.id,
            email: user.email,
          );
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
        await CacheHelper.cacheAuthData(
          userId: user.id,
          email: user.email,
        );
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
    await CacheHelper.clearAuthData(); // Clear cached data on sign out

    emit(Unauthenticated());
  }

// lib/auth/presentation/manager/auth_cubit.dart
  void checkAuthStatus() async {
    emit(AuthLoading());
    try {
      bool isValid = CacheHelper.isAuthValid();
      if (isValid) {
        // Retrieve cached user data
        String? userId = CacheHelper.getUserId();
        String? email = CacheHelper.getEmail();
        if (userId != null && email != null) {
          // Fetch additional user data from Firestore
          final userDoc = await getIt<FirebaseFirestore>()
              .collection('users')
              .doc(userId)
              .get();
          if (userDoc.exists) {
            final data = userDoc.data()!;
            bool isBlocked = data['isBlocked'] as bool;

            if (isBlocked) {
              // Handle blocked user
              await authRepository.signOut();
              await CacheHelper.clearAuthData();
              emit(AuthError('User is blocked'));
            } else {
              // User is not blocked, proceed
              UserModel user = UserModel(
                id: userId,
                email: email,
                username: data['username'] as String,
                isBlocked: isBlocked,
                signUpDate: (data['signUpDate'] as Timestamp).toDate(),
              );
              emit(Authenticated(user));
            }
          } else {
            // User document does not exist
            emit(Unauthenticated());
          }
        } else {
          emit(Unauthenticated());
        }
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      // Log the error and emit Unauthenticated
      print('Error in checkAuthStatus: $e');
      emit(Unauthenticated());
    }
  }
}
