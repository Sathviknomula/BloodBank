enum UserRole {
  customer,
  hospitalManager,
  admin,
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer / Recipient';
      case UserRole.hospitalManager:
        return 'Blood Bank Manager';
      case UserRole.admin:
        return 'Developer / Admin';
    }
  }
}
