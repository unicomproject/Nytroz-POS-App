import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../domain/entities/till.dart';
import 'till_providers.dart';

final tillListVisibilityProvider =
    Provider<AsyncValue<TillListVisibility>>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (accessChecker) => AsyncData(
      TillListVisibility.resolve(access: accessChecker),
    ),
  );
});

final tillListProvider = FutureProvider<TillListResult?>((ref) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canFetchTillList()) {
    return null;
  }

  final query = ref.watch(tillListQueryProvider);
  return ref.watch(getTillsProvider).call(query: query);
});
