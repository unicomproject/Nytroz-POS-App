import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';

final currentStockVisibilityProvider =
    Provider<AsyncValue<CurrentStockVisibility>>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (accessChecker) => AsyncData(
      CurrentStockVisibility.resolve(access: accessChecker),
    ),
  );
});

final stockInVisibilityProvider =
    Provider<AsyncValue<StockInVisibility>>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (accessChecker) => AsyncData(
      StockInVisibility.resolve(access: accessChecker),
    ),
  );
});
