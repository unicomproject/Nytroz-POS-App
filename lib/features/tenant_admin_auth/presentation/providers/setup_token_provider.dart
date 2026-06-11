import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/setup_token_validation.dart';
import '../../domain/usecases/validate_setup_token.dart';
import 'tenant_payment_provider.dart';

final validateSetupTokenProvider = Provider<ValidateSetupToken>((ref) {
  return ValidateSetupToken(ref.watch(tenantAdminAuthRepositoryProvider));
});

final setupTokenValidationProvider =
    FutureProvider.family<SetupTokenValidation, String>((ref, setupToken) {
  return ref.watch(validateSetupTokenProvider).call(setupToken);
});
