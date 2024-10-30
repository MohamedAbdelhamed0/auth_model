// lib/auth/presentation/manager/auth_cubit.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../Log.dart';
import '../../../enums/UserRole.dart';
import '../../../service_locator.dart';
import '../../CacheHelper.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository = getIt<AuthRepository>();
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  AuthCubit() : super(AuthInitial()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    try {
      bool isValid = CacheHelper.isAuthValid();
      if (isValid) {
        String? userId = CacheHelper.getUserId();
        String? email = CacheHelper.getEmail();
        if (userId != null && email != null) {
          _subscribeToUser(userId, email);
        } else {
          emit(Unauthenticated());
        }
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      Log.error('Error in checkAuthStatus: $e');
      emit(Unauthenticated());
    }
  }

  void _subscribeToUser(String userId, String email) {
    _userSubscription?.cancel();
    _userSubscription = getIt<FirebaseFirestore>()
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen(
      (userDoc) {
        if (userDoc.exists) {
          final data = userDoc.data()!;
          _handleUserDocument(data, userId, email);
        } else {
          emit(Unauthenticated());
        }
      },
      onError: (error) {
        Log.error('Error in user subscription: $error');
        emit(Unauthenticated());
      },
    );
  }

  void _handleUserDocument(
      Map<String, dynamic> data, String userId, String email) {
    bool isBlocked = data['isBlocked'] as bool? ?? false;

    if (isBlocked) {
      signOut();
      emit(AuthError('User is blocked'));
    } else {
      // Parse the role from the data, using a helper function
      UserRole role = userRoleFromString(data['role'] as String? ?? 'trial');

      UserModel user = UserModel(
        id: userId,
        email: email,
        username: data['username'] as String,
        isBlocked: isBlocked,
        signUpDate:
            (data['signUpDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isPrimary: (data['isPrimary'] as bool?) ?? false,
        profilePhotoUrl: data['profilePhotoUrl'] as String?,
        subscriptionStartDate:
            (data['subscriptionStartDate'] as Timestamp?)?.toDate(),
        subscriptionEndDate:
            (data['subscriptionEndDate'] as Timestamp?)?.toDate(),
        // Additional fields
        phoneNumber: data['phoneNumber'] as String?,
        address: data['address'] as String?,
        bio: data['bio'] as String?,
        website: data['website'] as String?,
        role: role, // Role from Firestore data
        status: data['status'] as String? ?? "offline",
        accountType: data['accountType'] as String? ?? "free",
        language: data['language'] as String? ?? "en",
        themePreference: data['themePreference'] as String? ?? "system",
        notificationSettings:
            Map<String, bool>.from(data['notificationSettings'] ?? {}),
        lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt:
            (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

      emit(Authenticated(user));
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signIn(email, password);
      if (user != null && !user.isBlocked) {
        await CacheHelper.cacheAuthData(userId: user.id, email: user.email);
        _subscribeToUser(user.id, user.email);
      } else {
        await _handleSignInError(user);
      }
    } catch (e) {
      _handleAuthException(e, 'sign-in');
    }
  }

  Future<void> _handleSignInError(UserModel? user) async {
    if (user == null) {
      Log.warning('User not found');
      emit(AuthError('User not found'));
    } else {
      Log.warning('User is blocked');
      emit(AuthError('User is blocked'));
      await authRepository.signOut();
    }
  }

  Future<void> signUp(String email, String password, String username) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signUp(email, password, username);
      if (user != null) {
        await CacheHelper.cacheAuthData(userId: user.id, email: user.email);
        _subscribeToUser(user.id, user.email);
      } else {
        emit(AuthError('Sign Up Failed'));
      }
    } catch (e) {
      Log.error('Sign-up error: $e');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    await authRepository.signOut();
    await CacheHelper.clearAuthData();
    _userSubscription?.cancel();
    emit(Unauthenticated());
  }

  Future<void> updateIsPrimary(bool isPrimary) async {
    if (state is Authenticated) {
      try {
        UserModel user = (state as Authenticated).user;
        await authRepository.updateIsPrimary(user.id, isPrimary);
        Log.success('Primary status updated successfully');
      } catch (e) {
        Log.error('Error updating isPrimary: $e');
        emit(AuthError('Failed to update primary status.'));
      }
    }
  }

  Future<void> updateSubscriptionDates(
      DateTime startDate, DateTime endDate) async {
    if (state is Authenticated) {
      try {
        UserModel user = (state as Authenticated).user;
        await authRepository.updateSubscriptionDates(
            user.id, startDate, endDate);
        Log.success('Subscription dates updated successfully');
      } catch (e) {
        Log.error('Error updating subscription dates: $e');
        emit(AuthError('Failed to update subscription dates.'));
      }
    }
  }

  Future<void> updateProfilePhoto(PlatformFile file) async {
    if (state is Authenticated) {
      try {
        UserModel user = (state as Authenticated).user;
        Log.info('User is authenticated with userId: ${user.id}');
        String downloadUrl =
            await authRepository.uploadProfilePhoto(file, user.id);
        Log.success('Profile photo uploaded successfully: $downloadUrl');
        emit(AuthSuccess('Profile photo updated successfully'));
      } catch (e) {
        Log.error('Error uploading profile photo: $e');
        emit(AuthError('Failed to upload profile photo.'));
      }
    } else {
      Log.warning('User is not authenticated');
      emit(AuthError('User is not authenticated.'));
    }
  }

  void _handleAuthException(dynamic e, String operation) {
    String errorMessage = 'An error occurred during $operation.';
    if (e is fb_auth.FirebaseAuthException) {
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password provided.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Network error, please try again.';
      }
    }
    Log.error('FirebaseAuthException: ${e.code} - ${e.message}');
    emit(AuthError(errorMessage));
  }
}
