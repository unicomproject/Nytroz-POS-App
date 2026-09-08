import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/setup_token_validation.dart';
import '../../application/usecases/validate_setup_token.dart';
import 'payment_provider.dart';

final validateSetupTokenProvider = Provider<ValidateSetupToken>((ref) {
  return ValidateSetupToken(ref.watch(authRepositoryProvider));
});

final setupTokenValidationProvider = FutureProvider.autoDispose
    .family<SetupTokenValidation, String>((ref, setupToken) {
  if (setupToken.trim().isEmpty) {
    return const SetupTokenValidation(
      setupToken: '',
      valid: false,
      expired: false,
      message: 'Open the invitation link sent by your administrator.',
    );
  }
  return ref.watch(validateSetupTokenProvider).call(setupToken);
});
