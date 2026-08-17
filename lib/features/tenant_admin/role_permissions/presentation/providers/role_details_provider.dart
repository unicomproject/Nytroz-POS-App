import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/role_details.dart';
import 'role_permissions_providers.dart';

final roleDetailsProvider = FutureProvider.autoDispose.family<RoleDetails, String>((ref, roleId) async {
  ref.watch(authHeaderSyncProvider);
  final repository = ref.watch(rolePermissionRepositoryProvider);
  return repository.getRoleById(roleId);
});
