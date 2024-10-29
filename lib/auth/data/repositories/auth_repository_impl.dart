// lib/data/repositories/auth_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final fb_auth.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRepositoryImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  @override
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final fb_auth.UserCredential result =
          await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch additional user data from Firestore
      final doc =
          await firestore.collection('users').doc(result.user!.uid).get();

      if (!doc.exists) return null;

      final data = doc.data()!;

      return UserModel(
        id: result.user!.uid,
        email: email,
        username: data['username'] as String,
        isBlocked: data['isBlocked'] as bool,
        signUpDate: (data['signUpDate'] as Timestamp).toDate(),
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      // Rethrow to be caught by AuthCubit
      throw e;
    } catch (e) {
      // Rethrow other exceptions
      throw e;
    }
  }

  @override
  Future<UserModel?> signUp(
      String email, String password, String username) async {
    try {
      final fb_auth.UserCredential result =
          await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save additional user data to Firestore
      await firestore.collection('users').doc(result.user!.uid).set({
        'username': username,
        'isBlocked': false,
        'signUpDate': FieldValue.serverTimestamp(),
      });

      // Fetch the signUpDate from Firestore after saving
      final doc =
          await firestore.collection('users').doc(result.user!.uid).get();
      final data = doc.data()!;

      return UserModel(
        id: result.user!.uid,
        email: email,
        username: username,
        isBlocked: false,
        signUpDate: (data['signUpDate'] as Timestamp).toDate(),
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }
}
