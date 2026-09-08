class SetupTokenValidation {
  const SetupTokenValidation({
    required this.setupToken,
    required this.valid,
    required this.expired,
    this.email,
    this.message,
    this.code,
  });

  final String setupToken;
  final bool valid;
  final bool expired;
  final String? email;
  final String? message;
  final String? code;

  SetupTokenStatus get status => expired
      ? SetupTokenStatus.expired
      : code == 'INVITE_USED'
          ? SetupTokenStatus.alreadyUsed
          : valid
              ? SetupTokenStatus.valid
              : SetupTokenStatus.invalid;
}

enum SetupTokenStatus { valid, invalid, expired, alreadyUsed }
