import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  final String query;
  final ReturnSearchTab tab;
  final List<ReturnSaleSummary> results;
  final String? selectedSaleId;
  final bool isLoading;
  final String? errorMessage;
  final List<String> recentSearches;
  final bool showFilters;

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

  bool get canContinue => selectedSaleId != null;

  ReturnSearchState copyWith({
    String? query,
    ReturnSearchTab? tab,
    List<ReturnSaleSummary>? results,
    String? selectedSaleId,
    bool? isLoading,
    String? errorMessage,
    List<String>? recentSearches,
    bool? showFilters,
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
    );
  }
}

class ReturnSearchController extends StateNotifier<ReturnSearchState> {
  ReturnSearchController(this._ref) : super(const ReturnSearchState());

  final Ref _ref;

  void setQuery(String value) {
    state = state.copyWith(query: value, clearError: true);
  }

  void setTab(ReturnSearchTab tab) {
    state = state.copyWith(tab: tab, clearError: true, clearSelection: true);
  }

  void toggleFilters() {
    state = state.copyWith(showFilters: !state.showFilters);
  }

  void selectSale(String saleId) {
    state = state.copyWith(selectedSaleId: saleId);
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

  Future<void> search() async {
    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;

    if (session == null || !session.isAuthenticated || deviceContext == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Device context is required to search sales.',
        results: const [],
        clearSelection: true,
      );
      return;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final page = await _ref.read(returnsRefundRemoteDatasourceProvider).searchOriginalSales(
            deviceId: deviceContext.deviceId,
            search: state.tab == ReturnSearchTab.recent ? null : state.query,
            searchType: state.tab.apiValue,
          );

      final selectedStillVisible = page.items.any(
        (sale) => sale.saleId == state.selectedSaleId,
      );

      state = state.copyWith(
        isLoading: false,
        results: page.items,
        selectedSaleId: selectedStillVisible ? state.selectedSaleId : null,
        clearSelection: !selectedStillVisible,
      );

      if (state.query.trim().isNotEmpty &&
          state.tab != ReturnSearchTab.recent) {
        addRecentSearch(state.query.trim());
      }
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        results: const [],
        clearSelection: true,
        errorMessage: _readApiError(error) ??
            'Unable to search original sales. Please try again.',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        results: const [],
        clearSelection: true,
        errorMessage: 'Unable to search original sales. Please try again.',
      );
    }
  }

  void applyRecentSearch(String value) {
    state = state.copyWith(query: value, clearError: true, clearSelection: true);
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
  final prefix = sale.currency.trim().isEmpty ? 'LKR' : sale.currency.trim();
  return '$prefix ${sale.total.toStringAsFixed(2)}';
}
