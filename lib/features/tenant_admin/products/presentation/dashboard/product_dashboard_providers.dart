import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../../outlets/domain/entities/outlet_list_query.dart';
import '../../../outlets/presentation/providers/outlet_providers.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../application/usecases/get_product_dashboard.dart';
import '../../data/datasources/product_dashboard_remote_datasource.dart';
import '../../data/repositories/product_dashboard_repository_impl.dart';
import '../../domain/entities/product_dashboard.dart';
import '../../domain/repositories/product_dashboard_repository.dart';
import 'product_dashboard_visibility.dart';

enum ProductDashboardDatePreset {
  today,
  yesterday,
  last7,
  last30,
  custom,
}

class ProductDashboardFilter {
  const ProductDashboardFilter({
    this.outletId,
    this.preset = ProductDashboardDatePreset.today,
    this.customFrom,
    this.customTo,
  });

  final String? outletId;
  final ProductDashboardDatePreset preset;
  final DateTime? customFrom;
  final DateTime? customTo;

  DateTime get dateFrom => _dateRange.$1;

  DateTime get dateTo => _dateRange.$2;

  (DateTime, DateTime) get _dateRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (preset) {
      case ProductDashboardDatePreset.today:
        return (today, today);
      case ProductDashboardDatePreset.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return (yesterday, yesterday);
      case ProductDashboardDatePreset.last7:
        return (today.subtract(const Duration(days: 6)), today);
      case ProductDashboardDatePreset.last30:
        return (today.subtract(const Duration(days: 29)), today);
      case ProductDashboardDatePreset.custom:
        final from = customFrom ?? today;
        final to = customTo ?? from;
        return (
          DateTime(from.year, from.month, from.day),
          DateTime(to.year, to.month, to.day),
        );
    }
  }

  ProductDashboardQuery toQuery({String? resolvedOutletId}) {
    return ProductDashboardQuery(
      outletId: resolvedOutletId ?? outletId,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  String get dateLabel {
    switch (preset) {
      case ProductDashboardDatePreset.today:
        return 'Today';
      case ProductDashboardDatePreset.yesterday:
        return 'Yesterday';
      case ProductDashboardDatePreset.last7:
        return 'Last 7 Days';
      case ProductDashboardDatePreset.last30:
        return 'Last 30 Days';
      case ProductDashboardDatePreset.custom:
        return '${_formatDate(dateFrom)} – ${_formatDate(dateTo)}';
    }
  }

  ProductDashboardFilter copyWith({
    String? outletId,
    bool clearOutletId = false,
    ProductDashboardDatePreset? preset,
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    return ProductDashboardFilter(
      outletId: clearOutletId ? null : outletId ?? this.outletId,
      preset: preset ?? this.preset,
      customFrom: customFrom ?? this.customFrom,
      customTo: customTo ?? this.customTo,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProductDashboardFilter &&
        other.outletId == outletId &&
        other.preset == preset &&
        _sameDay(other.customFrom, customFrom) &&
        _sameDay(other.customTo, customTo);
  }

  @override
  int get hashCode => Object.hash(
        outletId,
        preset,
        customFrom?.millisecondsSinceEpoch,
        customTo?.millisecondsSinceEpoch,
      );
}

bool _sameDay(DateTime? a, DateTime? b) {
  if (a == null && b == null) {
    return true;
  }

  if (a == null || b == null) {
    return false;
  }

  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _formatDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}

final productDashboardRemoteDatasourceProvider =
    Provider<ProductDashboardRemoteDatasource>((ref) {
  return ProductDashboardRemoteDatasource(ref.watch(appDioProvider));
});

final productDashboardRepositoryProvider =
    Provider<ProductDashboardRepository>((ref) {
  return ProductDashboardRepositoryImpl(
    ref.watch(productDashboardRemoteDatasourceProvider),
  );
});

final getProductDashboardProvider = Provider<GetProductDashboard>((ref) {
  return GetProductDashboard(ref.watch(productDashboardRepositoryProvider));
});

final productDashboardFilterProvider =
    StateProvider<ProductDashboardFilter>((ref) {
  return const ProductDashboardFilter();
});

final productDashboardOutletsProvider =
    FutureProvider.autoDispose<List<OutletOption>>((ref) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canViewProductDashboardOutletFilter()) {
    return const [];
  }

  final result = await ref.watch(getOutletsProvider).call(
        query: const OutletListQuery(
          page: 1,
          pageSize: 100,
        ),
      );

  return [
    for (final outlet in result.items)
      OutletOption(id: outlet.id, name: outlet.name),
  ];
});

class OutletOption {
  const OutletOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

final productDashboardVisibilityProvider =
    Provider<AsyncValue<ProductDashboardVisibility>>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);

  return accessState.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (accessChecker) => AsyncData(
      ProductDashboardVisibility.resolve(access: accessChecker),
    ),
  );
});

final productDashboardCacheProvider =
    StateProvider<ProductDashboard?>((ref) => null);

final productDashboardRefreshingProvider = StateProvider<bool>((ref) => false);

String? _resolvedOutletId(
  ProductDashboardFilter filter,
  dynamic accessChecker,
) {
  if (accessChecker.canViewProductDashboardOutletFilter()) {
    return filter.outletId;
  }

  final outlets = accessChecker.context.outletScope;
  if (outlets.isEmpty) {
    return filter.outletId;
  }

  if (outlets.length == 1) {
    return outlets.first.outletId;
  }

  for (final outlet in outlets) {
    if (outlet.isDefault) {
      return outlet.outletId;
    }
  }

  return outlets.first.outletId;
}

final productDashboardProvider =
    FutureProvider.autoDispose<ProductDashboard?>((ref) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canFetchProductDashboard()) {
    return null;
  }

  final filter = ref.watch(productDashboardFilterProvider);
  final capturedFilter = filter;
  final outletId = _resolvedOutletId(filter, accessChecker);

  final dashboard = await ref.watch(getProductDashboardProvider).call(
        query: capturedFilter.toQuery(resolvedOutletId: outletId),
      );

  if (ref.read(productDashboardFilterProvider) != capturedFilter) {
    throw const StaleProductDashboardRequest();
  }

  ref.read(productDashboardCacheProvider.notifier).state = dashboard;
  ref.read(productDashboardRefreshingProvider.notifier).state = false;

  return dashboard;
});

Future<void> refreshProductDashboard(WidgetRef ref) async {
  final cached = ref.read(productDashboardCacheProvider);
  if (cached != null) {
    ref.read(productDashboardRefreshingProvider.notifier).state = true;
  }

  ref.invalidate(productDashboardProvider);
  await ref.read(productDashboardProvider.future);
}

class StaleProductDashboardRequest implements Exception {
  const StaleProductDashboardRequest();
}
