class AppConstants {
  // Sample Images (Temporary placeholders)
  static const String sampleJobImage = 'https://picsum.photos/800/400';
  static const String sampleProviderImage = 'https://picsum.photos/500/500';
  static const String sampleCoverImage =
      'https://images.unsplash.com/photo-1581578731548-c64695cc6952?ixlib=rb-4.0.3';

  // Login Security
  static const int maxLoginAttempts =
      5; // Maximum failed login attempts allowed
  static const Duration loginLockoutDuration =
      Duration(minutes: 15); // Lockout duration after max attempts
  static const Duration passwordResetCodeExpiry =
      Duration(minutes: 10); // Password reset code expiry time

  // Password Requirements
  static const int minPasswordLength = 8;
  static const bool requireSpecialChar = true;
  static const bool requireNumber = true;
  static const bool requireUpperCase = true;
  static const bool requireLowerCase = true;
}
