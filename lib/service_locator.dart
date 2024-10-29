// lib/service_locator.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:get_it/get_it.dart';

import 'auth/data/repositories/auth_repository_impl.dart';
import 'auth/domain/repositories/auth_repository.dart';

final GetIt getIt = GetIt.instance;

// lib/service_locator.dart
void setupLocator() {
  // FirebaseAuth instance
  getIt.registerLazySingleton(() => fb_auth.FirebaseAuth.instance);

  // Firestore instance
  getIt.registerLazySingleton(() => FirebaseFirestore.instance);

  // AuthRepository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      firebaseAuth: getIt<fb_auth.FirebaseAuth>(),
      firestore: getIt<FirebaseFirestore>(),
    ),
  );
}
