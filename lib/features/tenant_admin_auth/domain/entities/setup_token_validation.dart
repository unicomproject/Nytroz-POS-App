class SetupTokenValidation {
  const SetupTokenValidation({
    required this.setupToken,
    required this.valid,
    required this.expired,
    this.email,
    this.message,
  });

  final String setupToken;
  final bool valid;
  final bool expired;
  final String? email;
  final String? message;
}
