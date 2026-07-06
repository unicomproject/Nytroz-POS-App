import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../domain/entities/return_sale_eligibility.dart';
import 'return_search_provider.dart';

class ReturnEligibilityState {
  const ReturnEligibilityState({
    this.eligibility,
    this.selections = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  final ReturnSaleEligibility? eligibility;
  final Map<String, ReturnLineSelection> selections;
  final bool isLoading;
  final String? errorMessage;

  ReturnLineSelection? selectionFor(String saleLineId) => selections[saleLineId];

  List<ReturnSaleLineEligibility> get selectedItems {
    final data = eligibility;
    if (data == null) {
      return const [];
    }

    return data.items.where((item) {
      final selection = selections[item.saleLineId];
      return selection?.isSelected == true && selection!.returnQty > 0;
    }).toList(growable: false);
  }

  double get estimatedReturnValue {
    final data = eligibility;
    if (data == null) {
      return 0;
    }

    var total = 0.0;
    for (final item in data.items) {
      final selection = selections[item.saleLineId];
      if (selection?.isSelected != true || selection!.returnQty <= 0) {
        continue;
      }
      total += item.unitPrice * selection.returnQty;
    }
    return total;
  }

  int get eligibleItemCount =>
      eligibility?.items.where((item) => item.isReturnable).length ?? 0;

  int get ineligibleItemCount =>
      eligibility?.items.where((item) => !item.isReturnable).length ?? 0;

  int get selectedItemCount => selectedItems.length;

  bool get canContinue => selectedItems.isNotEmpty;

  ReturnEligibilityState copyWith({
    ReturnSaleEligibility? eligibility,
    Map<String, ReturnLineSelection>? selections,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearData = false,
  }) {
    return ReturnEligibilityState(
      eligibility: clearData ? null : eligibility ?? this.eligibility,
      selections: clearData ? const {} : selections ?? this.selections,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ReturnEligibilityController extends StateNotifier<ReturnEligibilityState> {
  ReturnEligibilityController(this._ref) : super(const ReturnEligibilityState());

  final Ref _ref;

  Future<void> load(String saleId) async {
    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;

    if (session == null || !session.isAuthenticated || deviceContext == null) {
      state = state.copyWith(
        isLoading: false,
        clearData: true,
        errorMessage: 'Device context is required to load sale eligibility.',
      );
      return;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    state = state.copyWith(isLoading: true, clearError: true, clearData: true);

    try {
      final eligibility =
          await _ref.read(returnsRefundRemoteDatasourceProvider).getSaleEligibility(
                deviceId: deviceContext.deviceId,
                saleId: saleId,
              );

      final selections = {
        for (final item in eligibility.items)
          item.saleLineId: ReturnLineSelection(
            saleLineId: item.saleLineId,
            isSelected: false,
            returnQty: 0,
          ),
      };

      state = state.copyWith(
        isLoading: false,
        eligibility: eligibility,
        selections: selections,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        clearData: true,
        errorMessage: _readApiError(error) ??
            'Unable to load sale eligibility. Please try again.',
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        clearData: true,
        errorMessage: 'Unable to load sale eligibility. Please try again.',
      );
    }
  }

  void toggleItemSelection(String saleLineId, {required bool isReturnable}) {
    if (!isReturnable) {
      return;
    }

    final current = state.selections[saleLineId];
    if (current == null) {
      return;
    }

    final item = _findItem(saleLineId);
    if (item == null) {
      return;
    }

    final nextSelected = !current.isSelected;
    final updated = Map<String, ReturnLineSelection>.from(state.selections);
    updated[saleLineId] = current.copyWith(
      isSelected: nextSelected,
      returnQty: nextSelected ? (current.returnQty > 0 ? current.returnQty : 1) : 0,
    );

    state = state.copyWith(selections: updated);
  }

  void incrementReturnQty(String saleLineId) {
    _updateReturnQty(saleLineId, 1);
  }

  void decrementReturnQty(String saleLineId) {
    _updateReturnQty(saleLineId, -1);
  }

  void _updateReturnQty(String saleLineId, int delta) {
    final current = state.selections[saleLineId];
    final item = _findItem(saleLineId);

    if (current == null || item == null || !item.isReturnable) {
      return;
    }

    final nextQty = (current.returnQty + delta).clamp(0, item.maxReturnQty);
    final updated = Map<String, ReturnLineSelection>.from(state.selections);
    updated[saleLineId] = current.copyWith(
      isSelected: nextQty > 0,
      returnQty: nextQty,
    );
    state = state.copyWith(selections: updated);
  }

  ReturnSaleLineEligibility? _findItem(String saleLineId) {
    final items = state.eligibility?.items;
    if (items == null) {
      return null;
    }

    for (final item in items) {
      if (item.saleLineId == saleLineId) {
        return item;
      }
    }
    return null;
  }
}

final returnEligibilityProvider =
    StateNotifierProvider.autoDispose<ReturnEligibilityController, ReturnEligibilityState>(
  (ref) => ReturnEligibilityController(ref),
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

String formatReturnEligibilityAmount({
  required String currency,
  required double amount,
}) {
  final prefix = currency.trim().isEmpty ? 'LKR' : currency.trim();
  return '$prefix ${amount.toStringAsFixed(2)}';
}
