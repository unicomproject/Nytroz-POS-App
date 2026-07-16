import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/providers/tenant_admin_context_provider.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../data/constants/report_api_paths.dart';
import '../../data/datasources/report_remote_datasource.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../domain/entities/report_models.dart';
import '../../domain/entities/report_query.dart';
import '../../domain/repositories/report_repository.dart';

enum ReportScope { dashboard, sales, stock, outlets }

final reportRemoteDatasourceProvider = Provider<ReportRemoteDatasource>((ref) {
  return ReportRemoteDatasource(ref.watch(appDioProvider));
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepositoryImpl(ref.watch(reportRemoteDatasourceProvider));
});

final reportBusinessDateProvider = Provider<DateTime>((ref) {
  final contextDate =
      ref.watch(tenantAdminContextProvider).asData?.value.currentBusinessDate;
  if (contextDate != null) {
    return DateTime(contextDate.year, contextDate.month, contextDate.day);
  }

  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final reportQueryProvider =
    StateNotifierProvider.family<ReportQueryNotifier, ReportQuery, ReportScope>(
        (ref, scope) {
  return ReportQueryNotifier(
    _initialQuery(scope, ref.watch(reportBusinessDateProvider)),
  );
});

ReportQuery _initialQuery(ReportScope scope, DateTime businessDate) {
  final dateOnly = DateTime(
    businessDate.year,
    businessDate.month,
    businessDate.day,
  );
  return ReportQuery(
    from: DateTime(dateOnly.year, dateOnly.month),
    to: dateOnly,
    section: switch (scope) {
      ReportScope.dashboard => ReportSections.dashboard,
      ReportScope.sales => ReportSections.salesSummary,
      ReportScope.stock => ReportSections.currentStock,
      ReportScope.outlets => ReportSections.outletPerformance,
    },
  );
}

class ReportQueryNotifier extends StateNotifier<ReportQuery> {
  ReportQueryNotifier(super.state);

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(
      from: from,
      to: to,
      clearFrom: from == null,
      clearTo: to == null,
      page: 1,
    );
  }

  void setOutlet(String? outletId) {
    state = state.copyWith(
      outletId: outletId,
      clearOutlet: outletId == null,
      clearTill: true,
      page: 1,
    );
  }

  void setSection(String section) {
    state = state.copyWith(section: section, page: 1);
  }

  void setSearch(String value) {
    state = state.copyWith(
      search: value.trim(),
      clearSearch: value.trim().isEmpty,
      page: 1,
    );
  }

  void setPage(int page) => state = state.copyWith(page: page);

  void setPageSize(int pageSize) {
    state = state.copyWith(pageSize: pageSize, page: 1);
  }

  void setSort(String? sortBy, String direction) {
    state = state.copyWith(
      sortBy: sortBy,
      clearSort: sortBy == null,
      sortDirection: direction,
      page: 1,
    );
  }

  void setNamedFilter(String key, String? value) {
    final clear = value == null || value.trim().isEmpty;
    state = switch (key) {
      'tillId' => state.copyWith(
          tillId: value,
          clearTill: clear,
          page: 1,
        ),
      'cashierId' => state.copyWith(
          cashierId: value,
          clearCashier: clear,
          page: 1,
        ),
      'customerId' => state.copyWith(
          customerId: value,
          clearCustomer: clear,
          page: 1,
        ),
      'departmentId' => state.copyWith(
          departmentId: value,
          clearDepartment: clear,
          clearCategory: true,
          clearSubcategory: true,
          page: 1,
        ),
      'categoryId' => state.copyWith(
          categoryId: value,
          clearCategory: clear,
          clearSubcategory: true,
          page: 1,
        ),
      'subcategoryId' => state.copyWith(
          subcategoryId: value,
          clearSubcategory: clear,
          page: 1,
        ),
      'brandId' => state.copyWith(
          brandId: value,
          clearBrand: clear,
          page: 1,
        ),
      'productId' => state.copyWith(
          productId: value,
          clearProduct: clear,
          clearVariant: true,
          page: 1,
        ),
      'productVariantId' => state.copyWith(
          productVariantId: value,
          clearVariant: clear,
          page: 1,
        ),
      'salesChannelId' => state.copyWith(
          salesChannelId: value,
          clearSalesChannel: clear,
          page: 1,
        ),
      'paymentMethodId' => state.copyWith(
          paymentMethodId: value,
          clearPaymentMethod: clear,
          page: 1,
        ),
      'orderStatus' => state.copyWith(
          orderStatus: value,
          clearOrderStatus: clear,
          page: 1,
        ),
      'paymentStatus' => state.copyWith(
          paymentStatus: value,
          clearPaymentStatus: clear,
          page: 1,
        ),
      'stockStatus' => state.copyWith(
          stockStatus: value,
          clearStockStatus: clear,
          page: 1,
        ),
      'expiryStatus' => state.copyWith(
          expiryStatus: value,
          clearExpiryStatus: clear,
          page: 1,
        ),
      'movementType' => state.copyWith(
          movementType: value,
          clearMovementType: clear,
          page: 1,
        ),
      'batchNumber' => state.copyWith(
          batchNumber: value,
          clearBatchNumber: clear,
          page: 1,
        ),
      _ => state,
    };
  }

  void clearFilters() => state = state.clearFilters();

  void clearOptionalFilters() {
    state = state.copyWith(
      clearTill: true,
      clearCashier: true,
      clearCustomer: true,
      clearDepartment: true,
      clearCategory: true,
      clearSubcategory: true,
      clearBrand: true,
      clearProduct: true,
      clearVariant: true,
      clearSalesChannel: true,
      clearPaymentMethod: true,
      clearOrderStatus: true,
      clearPaymentStatus: true,
      clearStockStatus: true,
      clearExpiryStatus: true,
      clearMovementType: true,
      clearBatchNumber: true,
      clearSearch: true,
      page: 1,
    );
  }
}

final reportFilterOptionsProvider = FutureProvider.autoDispose
    .family<ReportFilterOptions, ReportScope>((ref, scope) async {
  final query = ref.watch(reportQueryProvider(scope));
  return ref.watch(reportRepositoryProvider).getFilterOptions(query);
});

final reportsDashboardProvider =
    FutureProvider.autoDispose<ReportResult>((ref) async {
  final query = ref.watch(reportQueryProvider(ReportScope.dashboard));
  _validateQuery(query, datesRequired: true);
  return ref.watch(reportRepositoryProvider).getDashboard(query);
});

final salesReportProvider =
    FutureProvider.autoDispose<ReportResult>((ref) async {
  final query = ref.watch(reportQueryProvider(ReportScope.sales));
  _validateQuery(query, datesRequired: true);
  return ref.watch(reportRepositoryProvider).getSales(query);
});

final stockReportProvider =
    FutureProvider.autoDispose<ReportResult>((ref) async {
  final query = ref.watch(reportQueryProvider(ReportScope.stock));
  _validateQuery(query, datesRequired: false);
  return ref.watch(reportRepositoryProvider).getStock(query);
});

final outletReportProvider =
    FutureProvider.autoDispose<ReportResult>((ref) async {
  final query = ref.watch(reportQueryProvider(ReportScope.outlets));
  _validateQuery(query, datesRequired: true);
  return ref.watch(reportRepositoryProvider).getOutlets(query);
});

final salesTransactionDetailProvider = FutureProvider.autoDispose
    .family<SalesTransactionDetail, String>((ref, orderId) async {
  if (orderId.trim().isEmpty) {
    throw const ReportValidationException('Order ID is required.');
  }
  return ref.watch(reportRepositoryProvider).getSalesDetail(orderId.trim());
});

final reportPermissionProvider =
    FutureProvider<ReportPermissionSnapshot>((ref) async {
  final access = await ref.watch(tenantAdminAccessCheckerProvider.future);
  return ReportPermissionSnapshot.fromAccess(access);
});

final reportExportControllerProvider = StateNotifierProvider.autoDispose<
    ReportExportController, AsyncValue<ReportExport?>>((ref) {
  return ReportExportController(ref.watch(reportRepositoryProvider));
});

class ReportExportController extends StateNotifier<AsyncValue<ReportExport?>> {
  ReportExportController(this._repository) : super(const AsyncData(null));

  final ReportRepository _repository;

  Future<ReportExport> request({
    required String reportType,
    required String format,
    required ReportQuery query,
  }) async {
    if (state.isLoading) {
      throw const ReportValidationException(
        'An export request is already in progress.',
      );
    }
    final validation = query.validate(datesRequired: reportType != 'stock');
    if (validation != null) {
      throw ReportValidationException(validation);
    }

    state = const AsyncLoading();
    late ReportExport result;
    state = await AsyncValue.guard(() async {
      result = await _repository.requestExport(
        ReportExportRequest(
          reportType: reportType,
          section: query.section,
          format: format,
          query: query,
        ),
      );
      return result;
    });
    if (state.hasError) {
      throw state.error!;
    }
    return result;
  }
}

void _validateQuery(ReportQuery query, {required bool datesRequired}) {
  final message = query.validate(datesRequired: datesRequired);
  if (message != null) {
    throw ReportValidationException(message);
  }
}

class ReportValidationException implements Exception {
  const ReportValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReportPermissionSnapshot {
  const ReportPermissionSnapshot({
    required this.module,
    required this.dashboard,
    required this.sales,
    required this.transactions,
    required this.products,
    required this.categories,
    required this.payments,
    required this.tax,
    required this.discounts,
    required this.returnsAndRefunds,
    required this.cashiers,
    required this.dailySales,
    required this.stock,
    required this.batchExpiry,
    required this.stockMovements,
    required this.inventoryValuation,
    required this.outlets,
    required this.tillSummary,
    required this.export,
    required this.customerPii,
  });

  factory ReportPermissionSnapshot.fromAccess(TenantAdminAccessChecker access) {
    return ReportPermissionSnapshot(
      module: access.canAccessReportsModule(),
      dashboard: access.canViewReportsDashboard(),
      sales: access.canViewSalesReport(),
      transactions: access.canViewSalesTransactions(),
      products: access.canViewProductSalesReport(),
      categories: access.canViewCategorySalesReport(),
      payments: access.canViewPaymentReport(),
      tax: access.canViewTaxReport(),
      discounts: access.canViewDiscountReport(),
      returnsAndRefunds: access.canViewReturnRefundReport(),
      cashiers: access.canViewCashierPerformance(),
      dailySales: access.canViewDailySalesReport(),
      stock: access.canViewStockReport(),
      batchExpiry: access.canViewBatchExpiryReport(),
      stockMovements: access.canViewStockMovements(),
      inventoryValuation: access.canViewInventoryValuation(),
      outlets: access.canViewOutletReport(),
      tillSummary: access.canViewTillSummary(),
      export: access.canExportReports(),
      customerPii: access.canViewCustomerPii(),
    );
  }

  final bool module;
  final bool dashboard;
  final bool sales;
  final bool transactions;
  final bool products;
  final bool categories;
  final bool payments;
  final bool tax;
  final bool discounts;
  final bool returnsAndRefunds;
  final bool cashiers;
  final bool dailySales;
  final bool stock;
  final bool batchExpiry;
  final bool stockMovements;
  final bool inventoryValuation;
  final bool outlets;
  final bool tillSummary;
  final bool export;
  final bool customerPii;
}
