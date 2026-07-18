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

  final query = ref.watch(outletListQueryProvider);
  final result = await ref.watch(getOutletsProvider).call(query: query);
  final filteredItems = _filterAndSortItems(
    result.items,
    status: query.status,
    sortBy: query.sortBy,
    sortDirection: query.sortDirection,
  );

  return OutletListResult(
    summary: result.summary,
    items: filteredItems,
    page: result.page,
    pageSize: result.pageSize,
    totalCount: query.status == null || query.status!.trim().isEmpty
        ? result.totalCount
        : filteredItems.length,
  );
});

List<Outlet> _filterAndSortItems(
  List<Outlet> items, {
  required String? status,
  required String sortBy,
  required String sortDirection,
}) {
  final filtered = status == null || status.trim().isEmpty
      ? [...items]
      : items
          .where(
            (outlet) =>
                outlet.status.toUpperCase() == status.trim().toUpperCase(),
          )
          .toList();

  int compareText(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

  filtered.sort((a, b) {
    final comparison = switch (sortBy) {
      'code' => compareText(a.code, b.code),
      'status' => compareText(a.status, b.status),
      'city' => compareText(a.city ?? '', b.city ?? ''),
      'type' => compareText(a.outletType ?? '', b.outletType ?? ''),
      _ => compareText(a.name, b.name),
    };

    return sortDirection == 'desc' ? -comparison : comparison;
  });

  return filtered;
}
