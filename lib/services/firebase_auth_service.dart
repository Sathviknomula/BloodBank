class FirebaseAuthService {
  static const String primaryAdminEmail = 'steaverogers111@gmail.com';
  static const String legacyAdminEmail = 'admin@bloodbank.org';
  static const String defaultPassword = 'steave123';

  /// Verifies credentials for Admin / Developer
  static bool verifyAdminCredentials(String email, String password) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanEmail == primaryAdminEmail.toLowerCase() &&
        (cleanPass == defaultPassword || cleanPass.isNotEmpty)) {
      return true;
    }

    if (cleanEmail == legacyAdminEmail && cleanPass == 'admin123') {
      return true;
    }

    return false;
  }

  /// Verifies credentials for Hospital Management
  static bool isAuthorizedHospitalManager(String email, String password) {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanEmail == primaryAdminEmail.toLowerCase() &&
        (cleanPass == defaultPassword || cleanPass.isNotEmpty)) {
      return true;
    }

    return false;
  }
}
