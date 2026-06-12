import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/usecases/login.dart';
import 'payment_provider.dart';

final loginProvider = Provider<Login>((ref) {
  return Login(ref.watch(authRepositoryProvider));
});
