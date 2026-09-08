import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/tax_aggregate.dart';
import '../../domain/tax_status.dart';

final taxSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final taxStatusFilterProvider =
    StateProvider.autoDispose<TaxStatus?>((ref) => null);

final taxPageProvider = StateProvider.autoDispose<int>((ref) => 1);

final taxListQueryProvider = Provider.autoDispose<TaxSetupListQuery>((ref) {
  return TaxSetupListQuery(
    search: ref.watch(taxSearchProvider),
    status: ref.watch(taxStatusFilterProvider),
    pageNumber: ref.watch(taxPageProvider),
    pageSize: TenantAdminContentTokens.defaultListPageSize,
  );
});

final taxProductsSearchProvider =
    StateProvider.autoDispose.family<String, String>((ref, taxId) => '');

final taxProductsPageProvider =
    StateProvider.autoDispose.family<int, String>((ref, taxId) => 1);

final taxProductsQueryProvider =
    Provider.autoDispose.family<TaxProductsQuery, String>((ref, taxId) {
  return TaxProductsQuery(
    search: ref.watch(taxProductsSearchProvider(taxId)),
    pageNumber: ref.watch(taxProductsPageProvider(taxId)),
    pageSize: TenantAdminContentTokens.defaultListPageSize,
  );
});

void resetTaxListFilters(WidgetRef ref) {
  ref.read(taxSearchProvider.notifier).state = '';
  ref.read(taxStatusFilterProvider.notifier).state = null;
  ref.read(taxPageProvider.notifier).state = 1;
}

bool taxListFiltersActive(WidgetRef ref) {
  return ref.watch(taxSearchProvider).trim().isNotEmpty ||
      ref.watch(taxStatusFilterProvider) != null;
}
