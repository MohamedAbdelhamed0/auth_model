// lib/domain/entities/user.dart
class UserModel {
  final String id;
  final String email;
  final String username;
  final bool isBlocked;
  final DateTime signUpDate;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.isBlocked,
    required this.signUpDate,
  });
}
