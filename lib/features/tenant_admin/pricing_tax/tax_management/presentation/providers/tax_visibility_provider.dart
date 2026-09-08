import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/services/tenant_admin_access_checker.dart';
import '../../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../application/tax_management_controller.dart';
import '../../domain/tax_aggregate.dart';

final taxListVisibilityProvider =
    Provider<AsyncValue<TaxSetupListVisibility>>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (accessChecker) => AsyncData(
      TaxSetupListVisibility.resolve(access: accessChecker),
    ),
  );
});

final taxListScreenProvider =
    FutureProvider.autoDispose<TaxSetupListResult?>((ref) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canViewTaxSetup()) {
    return null;
  }

  return ref.watch(taxListProvider.future);
});
