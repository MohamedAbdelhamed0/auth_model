// lib/auth/data/repositories/auth_repository_impl.dart
import 'dart:html' as html;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../Log.dart'; // Ensure the correct path to the Log class
import '../../../enums/UserRole.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final fb_auth.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final FirebaseStorage firebaseStorage;

  AuthRepositoryImpl({
    required this.firebaseStorage,
    required this.firebaseAuth,
    required this.firestore,
  });

  // Helper function to map Firestore data to UserModel
  UserModel _mapFirestoreUserData(String userId, Map<String, dynamic> data) {
    return UserModel(
      id: userId,
      email: data['email'] as String,
      username: data['username'] as String,
      isBlocked: data['isBlocked'] as bool,
      signUpDate:
          (data['signUpDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      profilePhotoUrl: data['profilePhotoUrl'] as String?,
      isPrimary: data['isPrimary'] as bool? ?? false,
      subscriptionStartDate:
          (data['subscriptionStartDate'] as Timestamp?)?.toDate(),
      subscriptionEndDate:
          (data['subscriptionEndDate'] as Timestamp?)?.toDate(),
      // Additional fields
      phoneNumber: data['phoneNumber'] as String?,
      address: data['address'] as String?,
      bio: data['bio'] as String?,
      website: data['website'] as String?,
      role: userRoleFromString(data['role'] as String? ?? 'trial'),
      status: data['status'] as String? ?? 'offline',
      accountType: data['accountType'] as String? ?? 'free',
      language: data['language'] as String? ?? 'en',
      themePreference: data['themePreference'] as String? ?? 'system',
      notificationSettings:
          Map<String, bool>.from(data['notificationSettings'] ?? {}),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final fb_auth.UserCredential result =
          await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      // await firestore.collection('users').doc(result.user!.uid).update({
      //   'lastLogin': FieldValue.serverTimestamp(),
      //   'updatedAt': FieldValue.serverTimestamp(),
      // });

      final doc =
          await firestore.collection('users').doc(result.user!.uid).get();

      if (!doc.exists) {
        Log.warning('User document does not exist in Firestore.');
        return null;
      }

      final data = doc.data()!;
      Log.success('User signed in successfully with email: $email');

      return _mapFirestoreUserData(result.user!.uid, data);
    } on fb_auth.FirebaseAuthException catch (e) {
      Log.error(
          'FirebaseAuthException during sign-in: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      Log.error('Exception during sign-in: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        Log.warning('No user found with ID: $userId');
        return null;
      }

      final data = doc.data()!;
      Log.info('Fetched user data for ID: $userId');

      return _mapFirestoreUserData(userId, data);
    } catch (e) {
      Log.error('Error fetching user by ID: $e');
      rethrow;
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
        'email': email,
        'username': username,
        'isBlocked': false,
        'signUpDate': FieldValue.serverTimestamp(),
        'profilePhotoUrl': null,
        'isPrimary': false,
        'subscriptionStartDate': null,
        'subscriptionEndDate': null,
        // Default values for additional fields
        'phoneNumber': null,
        'address': null,
        'bio': null,
        'website': null,
        'role': 'trial',
        'status': 'offline',
        'accountType': 'free',
        'language': 'en',
        'themePreference': 'system',
        'notificationSettings': {
          'email': true,
          'sms': false,
          'push': true,
        },
        'lastLogin': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final doc =
          await firestore.collection('users').doc(result.user!.uid).get();
      final data = doc.data()!;
      Log.success('User signed up successfully with email: $email');

      return _mapFirestoreUserData(result.user!.uid, data);
    } catch (e) {
      Log.error('Error during user sign-up: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await firebaseAuth.signOut();
    Log.info('User signed out successfully');
  }

  @override
  Future<String> uploadProfilePhoto(PlatformFile file, String userId) async {
    try {
      Log.info('Starting upload of profile photo for userId: $userId');
      Reference storageRef =
          firebaseStorage.ref().child('profile_photos/$userId.jpg');
      UploadTask uploadTask;

      if (kIsWeb) {
        Log.info('Uploading profile photo using putBlob (Web)');
        final blob = html.Blob([file.bytes!]);
        uploadTask = storageRef.putBlob(blob);
      } else {
        Log.info('Uploading profile photo from file path (Mobile)');
        File imageFile = File(file.path!);
        uploadTask = storageRef.putFile(imageFile);
      }

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        Log.info('Task state: ${snapshot.state}');
        Log.info(
            'Progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100} %');
      }, onError: (e) {
        Log.error('Upload error: $e');
      });

      TaskSnapshot snapshot = await uploadTask.whenComplete(() {
        Log.success('Upload task completed');
      });

      String downloadUrl = await snapshot.ref.getDownloadURL();
      Log.success('Download URL obtained: $downloadUrl');

      await firestore.collection('users').doc(userId).update({
        'profilePhotoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Log.success('Firestore updated with new profilePhotoUrl');

      return downloadUrl;
    } catch (e) {
      Log.error('Exception in uploadProfilePhoto: $e');
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  @override
  Future<void> updateIsPrimary(String userId, bool isPrimary) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'isPrimary': isPrimary,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Log.success('User primary status updated successfully');
    } catch (e) {
      Log.error('Failed to update isPrimary: $e');
      throw Exception('Failed to update isPrimary: $e');
    }
  }

  @override
  Future<void> updateSubscriptionDates(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'subscriptionStartDate': Timestamp.fromDate(startDate),
        'subscriptionEndDate': Timestamp.fromDate(endDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Log.success('Subscription dates updated successfully');
    } catch (e) {
      Log.error('Failed to update subscription dates: $e');
      throw Exception('Failed to update subscription dates: $e');
    }
  }
}
