import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../sale/data/datasources/pos_customer_remote_datasource.dart';
import '../../../sale/domain/entities/pos_customer.dart';
import '../../../sale/domain/entities/pos_customer_page.dart';

final posCustomerRemoteDatasourceProvider =
    Provider<PosCustomerRemoteDatasource>((ref) {
  return PosCustomerRemoteDatasource(ref.watch(appDioProvider));
});

enum CustomerStatusFilter {
  all,
  active,
  inactive,
}

enum CustomerSourceFilter {
  all,
  pos,
  manual,
  ecommerce,
  import,
}

class CustomersState {
  const CustomersState({
    this.query = '',
    this.statusFilter = CustomerStatusFilter.all,
    this.sourceFilter = CustomerSourceFilter.all,
    this.page = 1,
    this.pageSize = 8,
    this.items = const [],
    this.totalCount = 0,
    this.totalPages = 0,
    this.selectedCustomerId,
    this.selectedCustomerDetail,
    this.recentOrders = const [],
    this.isLoading = false,
    this.isLoadingDetail = false,
    this.isAttaching = false,
    this.errorMessage,
    this.detailErrorMessage,
    this.attachMessage,
    this.isForbidden = false,
  });

  final String query;
  final CustomerStatusFilter statusFilter;
  final CustomerSourceFilter sourceFilter;
  final int page;
  final int pageSize;
  final List<PosCustomer> items;
  final int totalCount;
  final int totalPages;
  final String? selectedCustomerId;
  final PosCustomer? selectedCustomerDetail;
  final List<PosCustomerOrder> recentOrders;
  final bool isLoading;
  final bool isLoadingDetail;
  final bool isAttaching;
  final String? errorMessage;
  final String? detailErrorMessage;
  final String? attachMessage;
  final bool isForbidden;

  PosCustomer? get selectedCustomer {
    final detail = selectedCustomerDetail;
    if (detail != null && detail.customerId == selectedCustomerId) {
      return detail;
    }
    final id = selectedCustomerId?.trim();
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final customer in items) {
      if (customer.customerId == id) {
        return customer;
      }
    }
    return null;
  }

  List<PosCustomer> get visibleItems => items;

  int get rangeStart {
    if (totalCount == 0 || items.isEmpty) {
      return 0;
    }
    return ((page - 1) * pageSize) + 1;
  }

  int get rangeEnd {
    if (totalCount == 0) {
      return 0;
    }
    final end = page * pageSize;
    return end > totalCount ? totalCount : end;
  }

  String? get apiStatus {
    switch (statusFilter) {
      case CustomerStatusFilter.all:
        return 'ALL';
      case CustomerStatusFilter.active:
        return 'ACTIVE';
      case CustomerStatusFilter.inactive:
        return 'INACTIVE';
    }
  }

  String? get apiSource {
    switch (sourceFilter) {
      case CustomerSourceFilter.all:
        return 'ALL';
      case CustomerSourceFilter.pos:
        return 'POS';
      case CustomerSourceFilter.manual:
        return 'MANUAL';
      case CustomerSourceFilter.ecommerce:
        return 'ECOMMERCE';
      case CustomerSourceFilter.import:
        return 'IMPORT';
    }
  }

  CustomersState copyWith({
    String? query,
    CustomerStatusFilter? statusFilter,
    CustomerSourceFilter? sourceFilter,
    int? page,
    int? pageSize,
    List<PosCustomer>? items,
    int? totalCount,
    int? totalPages,
    String? selectedCustomerId,
    bool clearSelectedCustomer = false,
    PosCustomer? selectedCustomerDetail,
    bool clearSelectedCustomerDetail = false,
    List<PosCustomerOrder>? recentOrders,
    bool? isLoading,
    bool? isLoadingDetail,
    bool? isAttaching,
    String? errorMessage,
    bool clearError = false,
    String? detailErrorMessage,
    bool clearDetailError = false,
    String? attachMessage,
    bool clearAttachMessage = false,
    bool? isForbidden,
  }) {
    return CustomersState(
      query: query ?? this.query,
      statusFilter: statusFilter ?? this.statusFilter,
      sourceFilter: sourceFilter ?? this.sourceFilter,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      totalPages: totalPages ?? this.totalPages,
      selectedCustomerId: clearSelectedCustomer
          ? null
          : selectedCustomerId ?? this.selectedCustomerId,
      selectedCustomerDetail: clearSelectedCustomerDetail
          ? null
          : selectedCustomerDetail ?? this.selectedCustomerDetail,
      recentOrders: recentOrders ?? this.recentOrders,
      isLoading: isLoading ?? this.isLoading,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      isAttaching: isAttaching ?? this.isAttaching,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      detailErrorMessage: clearDetailError
          ? null
          : detailErrorMessage ?? this.detailErrorMessage,
      attachMessage:
          clearAttachMessage ? null : attachMessage ?? this.attachMessage,
      isForbidden: isForbidden ?? this.isForbidden,
    );
  }
}

class CustomersSummaryState {
  const CustomersSummaryState({
    this.totalCustomers,
    this.activeCustomers,
    this.customersWithOrders,
    this.newCustomersThisMonth,
    this.isLoading = false,
    this.errorMessage,
    this.customersWithOrdersAvailable = true,
    this.newCustomersThisMonthAvailable = true,
  });

  final int? totalCustomers;
  final int? activeCustomers;
  final int? customersWithOrders;
  final int? newCustomersThisMonth;
  final bool isLoading;
  final String? errorMessage;
  final bool customersWithOrdersAvailable;
  final bool newCustomersThisMonthAvailable;

  CustomersSummaryState copyWith({
    int? totalCustomers,
    int? activeCustomers,
    int? customersWithOrders,
    int? newCustomersThisMonth,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? customersWithOrdersAvailable,
    bool? newCustomersThisMonthAvailable,
  }) {
    return CustomersSummaryState(
      totalCustomers: totalCustomers ?? this.totalCustomers,
      activeCustomers: activeCustomers ?? this.activeCustomers,
      customersWithOrders: customersWithOrders ?? this.customersWithOrders,
      newCustomersThisMonth:
          newCustomersThisMonth ?? this.newCustomersThisMonth,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      customersWithOrdersAvailable:
          customersWithOrdersAvailable ?? this.customersWithOrdersAvailable,
      newCustomersThisMonthAvailable:
          newCustomersThisMonthAvailable ?? this.newCustomersThisMonthAvailable,
    );
  }
}

final customersProvider = NotifierProvider<CustomersController, CustomersState>(
  CustomersController.new,
);

final customersSummaryProvider =
    NotifierProvider<CustomersSummaryController, CustomersSummaryState>(
  CustomersSummaryController.new,
);

class CustomersController extends Notifier<CustomersState> {
  int _requestSeq = 0;
  int _detailSeq = 0;
  int _historySeq = 0;
  CancelToken? _listCancelToken;
  CancelToken? _detailCancelToken;
  CancelToken? _historyCancelToken;

  @override
  CustomersState build() {
    ref.onDispose(() {
      _listCancelToken?.cancel('disposed');
      _detailCancelToken?.cancel('disposed');
      _historyCancelToken?.cancel('disposed');
    });
    return const CustomersState();
  }

  Future<void> load({bool resetPage = false}) async {
    final requestId = ++_requestSeq;
    final nextPage = resetPage ? 1 : state.page;

    _listCancelToken?.cancel('superseded');
    final cancelToken = CancelToken();
    _listCancelToken = cancelToken;

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearAttachMessage: true,
      page: nextPage,
      isForbidden: false,
    );

    final session = ref.read(authSessionProvider);
    if (session == null || !session.isAuthenticated) {
      if (requestId != _requestSeq) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        items: const [],
        totalCount: 0,
        totalPages: 0,
        errorMessage: 'Sign in required to load customers.',
      );
      return;
    }

    final deviceContext = ref.read(deviceActivationProvider).deviceContext;
    if (deviceContext == null || deviceContext.deviceId.trim().isEmpty) {
      if (requestId != _requestSeq) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        items: const [],
        totalCount: 0,
        totalPages: 0,
        errorMessage: 'Device context is not available.',
      );
      return;
    }

    try {
      final page =
          await ref.read(posCustomerRemoteDatasourceProvider).listCustomers(
                deviceId: deviceContext.deviceId,
                search: state.query,
                status: state.apiStatus,
                source: state.apiSource,
                page: nextPage,
                pageSize: state.pageSize,
                cancelToken: cancelToken,
              );

      if (requestId != _requestSeq) {
        return;
      }

      final selectedStillValid = state.selectedCustomerId != null &&
          page.items.any((c) => c.customerId == state.selectedCustomerId);

      state = state.copyWith(
        isLoading: false,
        items: page.items,
        page: page.page,
        pageSize: page.pageSize,
        totalCount: page.totalCount,
        totalPages: page.totalPages,
        clearSelectedCustomer: !selectedStillValid,
        clearSelectedCustomerDetail: !selectedStillValid,
        recentOrders: !selectedStillValid ? const [] : null,
        clearError: true,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) || requestId != _requestSeq) {
        return;
      }
      final forbidden = error.response?.statusCode == 403;
      state = state.copyWith(
        isLoading: false,
        items: const [],
        totalCount: 0,
        totalPages: 0,
        isForbidden: forbidden,
        errorMessage: forbidden ? 'Permission Denied' : _mapError(error),
      );
    } catch (_) {
      if (requestId != _requestSeq) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        items: const [],
        totalCount: 0,
        totalPages: 0,
        errorMessage: 'Unable to load customers. Try again.',
      );
    }
  }

  Future<void> selectCustomer(String customerId) async {
    final id = customerId.trim();
    if (id.isEmpty) {
      return;
    }
    state = state.copyWith(
      selectedCustomerId: id,
      clearAttachMessage: true,
      clearDetailError: true,
    );
    await _loadSelectedCustomer(id);
  }

  Future<void> _loadSelectedCustomer(String customerId) async {
    final requestId = ++_detailSeq;
    final deviceContext = ref.read(deviceActivationProvider).deviceContext;
    if (deviceContext == null) {
      return;
    }

    _detailCancelToken?.cancel('superseded');
    final cancelToken = CancelToken();
    _detailCancelToken = cancelToken;

    state = state.copyWith(isLoadingDetail: true, clearDetailError: true);

    try {
      final datasource = ref.read(posCustomerRemoteDatasourceProvider);
      final detail = await datasource.getCustomer(
        deviceId: deviceContext.deviceId,
        customerId: customerId,
        cancelToken: cancelToken,
      );
      final orders = await datasource.getCustomerOrders(
        deviceId: deviceContext.deviceId,
        customerId: customerId,
        page: 1,
        pageSize: 5,
        cancelToken: cancelToken,
      );

      if (requestId != _detailSeq) {
        return;
      }

      state = state.copyWith(
        isLoadingDetail: false,
        selectedCustomerDetail: detail,
        recentOrders: orders,
        clearDetailError: true,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) || requestId != _detailSeq) {
        return;
      }
      state = state.copyWith(
        isLoadingDetail: false,
        recentOrders: const [],
        detailErrorMessage: error.response?.statusCode == 404
            ? 'Customer not found.'
            : error.response?.statusCode == 403
                ? 'Permission Denied'
                : _mapError(error),
      );
    } catch (_) {
      if (requestId != _detailSeq) {
        return;
      }
      state = state.copyWith(
        isLoadingDetail: false,
        recentOrders: const [],
        detailErrorMessage: 'Unable to load customer details.',
      );
    }
  }

  void setSearchQuery(String value) {
    final trimmed = value.trim();
    if (trimmed == state.query) {
      return;
    }
    state = state.copyWith(query: trimmed, page: 1);
    load(resetPage: true);
  }

  void setStatusFilter(CustomerStatusFilter filter) {
    if (filter == state.statusFilter) {
      return;
    }
    state = state.copyWith(statusFilter: filter, page: 1);
    load(resetPage: true);
  }

  void setSourceFilter(CustomerSourceFilter filter) {
    if (filter == state.sourceFilter) {
      return;
    }
    state = state.copyWith(sourceFilter: filter, page: 1);
    load(resetPage: true);
  }

  void clearFilters() {
    state = state.copyWith(
      query: '',
      statusFilter: CustomerStatusFilter.all,
      sourceFilter: CustomerSourceFilter.all,
      page: 1,
      clearAttachMessage: true,
    );
    load(resetPage: true);
  }

  Future<void> goToPage(int page) async {
    if (page < 1 || (state.totalPages > 0 && page > state.totalPages)) {
      return;
    }
    if (page == state.page || state.isLoading) {
      return;
    }
    state = state.copyWith(page: page);
    await load();
  }

  void clearSelection() {
    state = state.copyWith(
      clearSelectedCustomer: true,
      clearSelectedCustomerDetail: true,
      recentOrders: const [],
    );
  }

  Future<void> refreshAfterCreate(PosCustomer created) async {
    state = state.copyWith(selectedCustomerId: created.customerId);
    await load(resetPage: true);
    await selectCustomer(created.customerId);
    await ref.read(customersSummaryProvider.notifier).refresh();
  }

  Future<void> refreshAfterMutation() async {
    final selectedId = state.selectedCustomerId;
    await load();
    if (selectedId != null && selectedId.trim().isNotEmpty) {
      await _loadSelectedCustomer(selectedId);
    }
    await ref.read(customersSummaryProvider.notifier).refresh();
  }

  Future<PosCustomer?> updateCustomer({
    required String customerId,
    required String fullName,
    String? phone,
    String? email,
    required String status,
  }) async {
    final deviceContext = ref.read(deviceActivationProvider).deviceContext;
    if (deviceContext == null) {
      return null;
    }

    final updated =
        await ref.read(posCustomerRemoteDatasourceProvider).updateCustomer(
              deviceId: deviceContext.deviceId,
              customerId: customerId,
              fullName: fullName,
              phone: phone,
              email: email,
              status: status,
            );

    final items = state.items
        .map(
          (customer) =>
              customer.customerId == updated.customerId ? updated : customer,
        )
        .toList(growable: false);

    state = state.copyWith(
      items: items,
      selectedCustomerDetail: state.selectedCustomerId == updated.customerId
          ? updated
          : state.selectedCustomerDetail,
    );

    await ref.read(customersSummaryProvider.notifier).refresh();
    return updated;
  }

  Future<PosCustomerOrderPage?> loadPurchaseHistory({
    required String customerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final requestId = ++_historySeq;
    final deviceContext = ref.read(deviceActivationProvider).deviceContext;
    if (deviceContext == null) {
      return null;
    }

    _historyCancelToken?.cancel('superseded');
    final cancelToken = CancelToken();
    _historyCancelToken = cancelToken;

    try {
      final result = await ref
          .read(posCustomerRemoteDatasourceProvider)
          .getCustomerOrdersPage(
            deviceId: deviceContext.deviceId,
            customerId: customerId,
            page: page,
            pageSize: pageSize,
            cancelToken: cancelToken,
          );

      if (requestId != _historySeq) {
        return null;
      }
      return result;
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) || requestId != _historySeq) {
        return null;
      }
      rethrow;
    }
  }

  Future<PosCustomerAttachResult?> attachSelectedToSale() async {
    final selected = state.selectedCustomer;
    final deviceContext = ref.read(deviceActivationProvider).deviceContext;
    if (selected == null || deviceContext == null) {
      return null;
    }

    state = state.copyWith(isAttaching: true, clearAttachMessage: true);
    try {
      final result =
          await ref.read(posCustomerRemoteDatasourceProvider).attachToSale(
                deviceId: deviceContext.deviceId,
                customerId: selected.customerId,
              );
      state = state.copyWith(
        isAttaching: false,
        attachMessage: 'Customer attached to the active sale.',
      );
      return result;
    } on DioException catch (error) {
      state = state.copyWith(
        isAttaching: false,
        attachMessage: error.response?.statusCode == 403
            ? 'Permission Denied'
            : _mapError(error),
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isAttaching: false,
        attachMessage: 'Unable to attach customer to the sale.',
      );
      return null;
    }
  }

  void setAttaching(bool value) {
    state = state.copyWith(isAttaching: value);
  }

  void setAttachMessage(String? message) {
    state = state.copyWith(
      attachMessage: message,
      clearAttachMessage: message == null,
    );
  }

  String _mapError(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message']?.toString() ??
          data['Message']?.toString() ??
          data['title']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return 'Unable to load customers. Try again.';
  }
}

class CustomersSummaryController extends Notifier<CustomersSummaryState> {
  int _requestSeq = 0;

  @override
  CustomersSummaryState build() => const CustomersSummaryState();

  Future<void> refresh() async {
    final requestId = ++_requestSeq;
    state = state.copyWith(isLoading: true, clearError: true);

    final deviceContext = ref.read(deviceActivationProvider).deviceContext;
    if (deviceContext == null || deviceContext.deviceId.trim().isEmpty) {
      if (requestId != _requestSeq) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Device context is not available.',
      );
      return;
    }

    try {
      final summary = await ref
          .read(posCustomerRemoteDatasourceProvider)
          .getSummary(deviceId: deviceContext.deviceId);

      if (requestId != _requestSeq) {
        return;
      }

      state = CustomersSummaryState(
        totalCustomers: summary.totalCustomers,
        activeCustomers: summary.activeCustomers,
        customersWithOrders: summary.customersWithOrders,
        newCustomersThisMonth: summary.newCustomersThisMonth,
        isLoading: false,
        customersWithOrdersAvailable: true,
        newCustomersThisMonthAvailable: true,
      );
    } catch (_) {
      if (requestId != _requestSeq) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Customer summary is unavailable.',
      );
    }
  }
}
