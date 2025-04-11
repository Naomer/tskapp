class PasswordResetState {
  final String email;
  String? verificationCode;
  String? newPassword;

  PasswordResetState({
    required this.email,
    this.verificationCode,
    this.newPassword,
  });
}
