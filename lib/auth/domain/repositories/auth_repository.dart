// lib/domain/repositories/auth_repository.dart
import 'package:file_picker/file_picker.dart';

import '../entities/user.dart';

abstract class AuthRepository {
  Future<UserModel?> signIn(String email, String password);
  Future<UserModel?> signUp(String email, String password, String username);
  Future<void> signOut();
  Future<String> uploadProfilePhoto(PlatformFile file, String userId);
  Future<void> updateIsPrimary(String userId, bool isPrimary);
  Future<void> updateSubscriptionDates(
      String userId, DateTime startDate, DateTime endDate);
  Future<UserModel?> getUserById(String userId); // Add this method
}
