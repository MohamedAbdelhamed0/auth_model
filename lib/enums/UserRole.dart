enum UserRole {
  trial, // For users in trial period
  primary, // For primary users
  moderator, // For users with moderator privileges
}

String userRoleToString(UserRole role) => role.toString().split('.').last;

UserRole userRoleFromString(String roleString) {
  switch (roleString) {
    case 'trial':
      return UserRole.trial;
    case 'primary':
      return UserRole.primary;
    case 'moderator':
      return UserRole.moderator;
    default:
      throw Exception('Unknown role: $roleString');
  }
}
