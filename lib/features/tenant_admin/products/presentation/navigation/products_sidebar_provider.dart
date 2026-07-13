import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/tenant_admin_access_provider.dart';
import 'products_sidebar_routes.dart';
import 'products_sidebar_visibility.dart';

final tenantAdminCurrentPathProvider = StateProvider<String>((ref) {
  return '/tenant-admin/dashboard';
});

final productsSidebarVisibilityProvider =
    Provider<AsyncValue<ProductsSidebarVisibility>>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (accessChecker) => AsyncData(
      ProductsSidebarVisibility.resolve(access: accessChecker),
    ),
  );
});

final productsSidebarManualExpandedProvider = StateProvider<bool?>((ref) => null);

final productsSidebarExpandedProvider = Provider<bool>((ref) {
  final currentPath = ref.watch(tenantAdminCurrentPathProvider);
  final manual = ref.watch(productsSidebarManualExpandedProvider);

  if (manual != null) {
    return manual;
  }

  return ProductsSidebarRoutes.isProductsArea(currentPath);
});

void toggleProductsSidebarExpanded(WidgetRef ref) {
  final current = ref.read(productsSidebarExpandedProvider);
  ref.read(productsSidebarManualExpandedProvider.notifier).state = !current;
}

void syncProductsSidebarPath(WidgetRef ref, String path) {
  ref.read(tenantAdminCurrentPathProvider.notifier).state = path;

  if (!ProductsSidebarRoutes.isProductsArea(path)) {
    ref.read(productsSidebarManualExpandedProvider.notifier).state = null;
  }
}
