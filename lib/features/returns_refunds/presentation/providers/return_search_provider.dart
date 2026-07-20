import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../data/datasources/returns_refund_remote_datasource.dart';
import '../../domain/entities/return_flow_steps.dart';
import '../../domain/entities/return_sale_summary.dart';

final returnsRefundRemoteDatasourceProvider =
    Provider<ReturnsRefundRemoteDatasource>((ref) {
  return ReturnsRefundRemoteDatasource(ref.watch(appDioProvider));
});

class ReturnSearchFilters {
  const ReturnSearchFilters({
    this.fromDate,
    this.toDate,
    this.paymentMethodCode,
    this.minAmount,
    this.maxAmount,
  });

  final DateTime? fromDate;
  final DateTime? toDate;
  final String? paymentMethodCode;
  final double? minAmount;
  final double? maxAmount;

  int get activeCount => [
        fromDate,
        toDate,
        paymentMethodCode?.trim().isNotEmpty == true
            ? paymentMethodCode
            : null,
        minAmount,
        maxAmount,
      ].where((value) => value != null).length;

  @override
  bool operator ==(Object other) {
    return other is ReturnSearchFilters &&
        other.fromDate == fromDate &&
        other.toDate == toDate &&
        other.paymentMethodCode == paymentMethodCode &&
        other.minAmount == minAmount &&
        other.maxAmount == maxAmount;
  }

  @override
  int get hashCode => Object.hash(
        fromDate,
        toDate,
        paymentMethodCode,
        minAmount,
        maxAmount,
      );
}

class ReturnSearchState {
  const ReturnSearchState({
    this.query = '',
    this.tab = ReturnSearchTab.recent,
    this.results = const [],
    this.selectedSaleId,
    this.isLoading = false,
    this.errorMessage,
    this.recentSearches = const [],
    this.showFilters = false,
    this.filters = const ReturnSearchFilters(),
    this.page = 1,
    this.pageSize = 20,
    this.totalCount = 0,
    this.paymentMethods = const [],
    this.isForbidden = false,
  });

  final String query;
  final ReturnSearchTab tab;
  final List<ReturnSaleSummary> results;
  final String? selectedSaleId;
  final bool isLoading;
  final String? errorMessage;
  final List<String> recentSearches;
  final bool showFilters;
  final ReturnSearchFilters filters;
  final int page;
  final int pageSize;
  final int totalCount;
  final List<ReturnPaymentMethodFilterOption> paymentMethods;
  final bool isForbidden;

  ReturnSaleSummary? get selectedSale {
    if (selectedSaleId == null) {
      return null;
    }

    for (final sale in results) {
      if (sale.saleId == selectedSaleId) {
        return sale;
      }
    }
    return null;
  }

  bool get hasValidSelection =>
      selectedSale != null && selectedSale!.saleId.trim().isNotEmpty;
  int get totalPages =>
      totalCount == 0 ? 0 : (totalCount / pageSize).ceil();
  bool get hasPreviousPage => page > 1;
  bool get hasNextPage => page < totalPages;
  int get rangeStart =>
      totalCount == 0 || results.isEmpty ? 0 : ((page - 1) * pageSize) + 1;
  int get rangeEnd {
    if (totalCount == 0) {
      return 0;
    }
    final end = page * pageSize;
    return end > totalCount ? totalCount : end;
  }

  ReturnSearchState copyWith({
    String? query,
    ReturnSearchTab? tab,
    List<ReturnSaleSummary>? results,
    String? selectedSaleId,
    bool? isLoading,
    String? errorMessage,
    List<String>? recentSearches,
    bool? showFilters,
    ReturnSearchFilters? filters,
    int? page,
    int? pageSize,
    int? totalCount,
    List<ReturnPaymentMethodFilterOption>? paymentMethods,
    bool? isForbidden,
    bool clearError = false,
    bool clearSelection = false,
  }) {
    return ReturnSearchState(
      query: query ?? this.query,
      tab: tab ?? this.tab,
      results: results ?? this.results,
      selectedSaleId:
          clearSelection ? null : selectedSaleId ?? this.selectedSaleId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      recentSearches: recentSearches ?? this.recentSearches,
      showFilters: showFilters ?? this.showFilters,
      filters: filters ?? this.filters,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalCount: totalCount ?? this.totalCount,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      isForbidden: isForbidden ?? this.isForbidden,
    );
  }
}

class ReturnSearchController extends StateNotifier<ReturnSearchState> {
  ReturnSearchController(this._ref) : super(const ReturnSearchState());

  final Ref _ref;
  int _requestSequence = 0;
  CancelToken? _cancelToken;
  bool _disposed = false;

  void setQuery(String value) {
    if (value == state.query) {
      return;
    }
    state = state.copyWith(
      query: value,
      page: 1,
      clearError: true,
      clearSelection: true,
    );
  }

  void setTab(ReturnSearchTab tab) {
    if (tab == state.tab) {
      return;
    }
    state = state.copyWith(
      tab: tab,
      page: 1,
      clearError: true,
      clearSelection: true,
    );
  }

  void toggleFilters() {
    state = state.copyWith(showFilters: !state.showFilters);
  }

  void selectSale(String saleId) {
    final normalized = saleId.trim();
    if (normalized.isEmpty ||
        !state.results.any((sale) => sale.saleId == normalized)) {
      return;
    }
    state = state.copyWith(selectedSaleId: normalized);
  }

  Future<void> applyFilters(ReturnSearchFilters filters) async {
    state = state.copyWith(
      filters: filters,
      page: 1,
      clearError: true,
      clearSelection: true,
    );
    await search(page: 1);
  }

  Future<void> clearFilters() async {
    state = state.copyWith(
      filters: const ReturnSearchFilters(),
      page: 1,
      clearError: true,
      clearSelection: true,
    );
    await search(page: 1);
  }

  Future<void> goToPage(int page) async {
    final totalPages = state.totalPages;
    if (state.isLoading ||
        page < 1 ||
        (totalPages > 0 && page > totalPages) ||
        page == state.page) {
      return;
    }
    await search(page: page);
  }

  void addRecentSearch(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final updated = [
      trimmed,
      ...state.recentSearches.where((item) => item != trimmed),
    ].take(8).toList(growable: false);

    state = state.copyWith(recentSearches: updated);
  }

  void removeRecentSearch(String value) {
    state = state.copyWith(
      recentSearches:
          state.recentSearches.where((item) => item != value).toList(),
    );
  }

  void clearRecentSearches() {
    state = state.copyWith(recentSearches: const []);
  }

  Future<void> search({int? page}) async {
    final requestId = ++_requestSequence;
    _cancelToken?.cancel('Superseded by a newer sale search.');
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    final targetPage = page ?? state.page;
    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;

    if (session == null || !session.isAuthenticated) {
      if (!_canApply(requestId)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign in required to search sales.',
        results: const [],
        totalCount: 0,
        clearSelection: true,
      );
      return;
    }

    final granted = session.permissionCodes.toSet();
    if (!PosPermissionAccess.canViewReturns(granted)) {
      if (!_canApply(requestId)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        isForbidden: true,
        errorMessage: 'Permission Denied',
        results: const [],
        totalCount: 0,
        clearSelection: true,
      );
      return;
    }

    if (deviceContext == null || deviceContext.deviceId.trim().isEmpty) {
      if (!_canApply(requestId)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Device context is required to search sales.',
        results: const [],
        totalCount: 0,
        clearSelection: true,
      );
      return;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);

    final query = state.query;
    final tab = state.tab;
    final filters = state.filters;
    state = state.copyWith(
      isLoading: true,
      page: targetPage,
      isForbidden: false,
      clearError: true,
    );

    try {
      final responsePage = await _ref.read(returnsRefundRemoteDatasourceProvider).searchOriginalSales(
            deviceId: deviceContext.deviceId,
            search: tab == ReturnSearchTab.recent ? null : query,
            searchType: tab.apiValue,
            fromDate: filters.fromDate,
            toDate: filters.toDate,
            paymentMethodCode: filters.paymentMethodCode,
            minAmount: filters.minAmount,
            maxAmount: filters.maxAmount,
            page: targetPage,
            pageSize: state.pageSize,
            cancelToken: cancelToken,
          );

      if (!_canApply(requestId)) {
        return;
      }
      final selectedStillVisible = responsePage.items.any(
        (sale) => sale.saleId == state.selectedSaleId,
      );

      state = state.copyWith(
        isLoading: false,
        results: responsePage.items,
        page: responsePage.page <= 0 ? targetPage : responsePage.page,
        pageSize:
            responsePage.pageSize <= 0 ? state.pageSize : responsePage.pageSize,
        totalCount: responsePage.totalCount,
        paymentMethods: responsePage.paymentMethods,
        selectedSaleId: selectedStillVisible ? state.selectedSaleId : null,
        clearSelection: !selectedStillVisible,
      );

      if (query.trim().isNotEmpty && tab != ReturnSearchTab.recent) {
        addRecentSearch(query.trim());
      }
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) || !_canApply(requestId)) {
        return;
      }
      final forbidden = error.response?.statusCode == 403;
      state = state.copyWith(
        isLoading: false,
        results: const [],
        totalCount: 0,
        clearSelection: true,
        isForbidden: forbidden,
        errorMessage: forbidden
            ? 'Permission Denied'
            : _readApiError(error) ??
                'Unable to search original sales. Please try again.',
      );
    } catch (_) {
      if (!_canApply(requestId)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        results: const [],
        totalCount: 0,
        clearSelection: true,
        errorMessage: 'Unable to search original sales. Please try again.',
      );
    }
  }

  void applyRecentSearch(String value) {
    state = state.copyWith(
      query: value,
      tab: _inferTabForRecentSearch(value),
      page: 1,
      clearError: true,
      clearSelection: true,
    );
  }

  bool _canApply(int requestId) =>
      !_disposed && requestId == _requestSequence;

  @override
  void dispose() {
    _disposed = true;
    _requestSequence++;
    _cancelToken?.cancel('Return sale search provider disposed.');
    super.dispose();
  }
}

final returnSearchProvider =
    StateNotifierProvider.autoDispose<ReturnSearchController, ReturnSearchState>(
  (ref) => ReturnSearchController(ref),
);

void _ensureAuthorizationHeader(Dio dio, AuthSession session) {
  final currentValue = dio.options.headers['Authorization'];
  if (currentValue is String && currentValue.trim().isNotEmpty) {
    return;
  }

  dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
}

String? _readApiError(DioException error) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
  }
  return null;
}

ReturnSearchTab _inferTabForRecentSearch(String value) {
  final trimmed = value.trim();
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (RegExp(r'^(inv|rcp|sale)[\s\-_]?', caseSensitive: false)
      .hasMatch(trimmed)) {
    return ReturnSearchTab.invoice;
  }
  if (digits.length >= 7 && digits.length >= trimmed.length / 2) {
    return ReturnSearchTab.mobile;
  }
  return ReturnSearchTab.customer;
}

String formatReturnSaleDateTime(DateTime? value) {
  if (value == null) {
    return '-';
  }

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

  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';

  return '${value.day} ${months[value.month - 1]} ${value.year}, '
      '$hour:$minute $period';
}

String formatReturnSaleAmount(ReturnSaleSummary sale) {
  final prefix = sale.currency.trim().isEmpty ? '—' : sale.currency.trim();
  return '$prefix ${sale.total.toStringAsFixed(2)}';
}
