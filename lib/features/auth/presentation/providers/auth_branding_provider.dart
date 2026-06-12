import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_branding.dart';
import '../../application/usecases/get_auth_branding.dart';
import 'payment_provider.dart';

final getAuthBrandingProvider = Provider<GetAuthBranding>((ref) {
  return GetAuthBranding(
    ref.watch(authRepositoryProvider),
  );
});

final authBrandingProvider = FutureProvider<AuthBranding>((ref) async {
  return ref.watch(getAuthBrandingProvider).call();
});
