import '../../../enums/UserRole.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final bool isBlocked;
  final DateTime signUpDate;
  final String? profilePhotoUrl;
  final bool isPrimary;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;

  // Additional fields
  final String? phoneNumber;
  final String? address;
  final String? bio;
  final String? website;
  final UserRole role; // Updated to use UserRole enum
  final String status;
  final String accountType;
  final String language;
  final String themePreference;
  final Map<String, bool> notificationSettings;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.isBlocked,
    required this.signUpDate,
    this.profilePhotoUrl,
    required this.isPrimary,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.phoneNumber,
    this.address,
    this.bio,
    this.website,
    this.role = UserRole.trial, // Default role set to 'trial'
    this.status = "offline",
    this.accountType = "free",
    this.language = "en",
    this.themePreference = "system",
    this.notificationSettings = const {},
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });
}
