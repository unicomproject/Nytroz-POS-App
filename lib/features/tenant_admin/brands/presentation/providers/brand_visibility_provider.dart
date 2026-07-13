import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../domain/entities/brand.dart';
import 'brand_providers.dart';

final brandListVisibilityProvider =
    Provider<AsyncValue<BrandListVisibility>>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (accessChecker) => AsyncData(
      BrandListVisibility.resolve(access: accessChecker),
    ),
  );
});

final brandListScreenProvider = FutureProvider.autoDispose<BrandListResult?>((ref) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canFetchBrandList()) {
    return null;
  }

  final query = ref.watch(brandListQueryProvider);
  return ref.watch(brandRepositoryProvider).listBrands(query: query);
});
