import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/usecases/set_password.dart';
import 'payment_provider.dart';

final setPasswordProvider = Provider<SetPassword>((ref) {
  return SetPassword(ref.watch(authRepositoryProvider));
});
