import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/role_list_item.dart';
import '../../domain/entities/role_list_query.dart';
import 'role_permissions_providers.dart';

final rolesListQueryProvider = StateProvider.autoDispose<RoleListQuery>((ref) {
  return const RoleListQuery();
});

final rolesListProvider = FutureProvider.autoDispose<PaginatedRoleList>((ref) async {
  ref.watch(authHeaderSyncProvider);
  final query = ref.watch(rolesListQueryProvider);
  final repository = ref.watch(rolePermissionRepositoryProvider);
  return repository.getRoles(query);
});

final selectedRoleIdProvider = StateProvider.autoDispose<String?>((ref) => null);
