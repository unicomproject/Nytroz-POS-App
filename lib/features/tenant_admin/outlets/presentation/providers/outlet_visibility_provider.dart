import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../domain/entities/outlet.dart';
import 'outlet_providers.dart';

final outletListVisibilityProvider =
    Provider<AsyncValue<OutletListVisibility>>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (accessChecker) => AsyncData(
      OutletListVisibility.resolve(access: accessChecker),
    ),
  );
});

final outletListProvider = FutureProvider<OutletListResult?>((ref) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canFetchOutletList()) {
    return null;
  }

  final search = ref.watch(outletSearchProvider);
  // TODO: request summary fields separately when backend supports field-level filtering.
  return ref.watch(getOutletsProvider).call(search: search);
});
