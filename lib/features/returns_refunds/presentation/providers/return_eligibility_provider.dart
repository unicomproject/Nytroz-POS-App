import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../domain/entities/return_sale_eligibility.dart';
import 'return_search_provider.dart';

enum HeaderSelectionState { none, partial, all }

class ReturnEligibilityState {
  const ReturnEligibilityState({
    this.eligibility,
    this.checkResult,
    this.selections = const {},
    this.isLoading = false,
    this.isChecking = false,
    this.errorMessage,
    this.checkErrorMessage,
    this.checkPermissionDenied = false,
  });

  final ReturnSaleEligibility? eligibility;
  final ReturnSaleEligibility? checkResult;
  final Map<String, ReturnLineSelection> selections;
  final bool isLoading;
  final bool isChecking;
  final String? errorMessage;
  final String? checkErrorMessage;
  final bool checkPermissionDenied;

  ReturnLineSelection? selectionFor(String saleLineId) =>
      selections[saleLineId];

  List<ReturnSaleLineEligibility> get selectedItems {
    final data = eligibility;
    if (data == null) {
      return const [];
    }

    return data.items.where((item) {
      if (!item.isSelectable) {
        return false;
      }
      final selection = selections[item.saleLineId];
      return selection?.isSelected == true && selection!.returnQty > 0;
    }).toList(growable: false);
  }

  /// Estimated selected return value for Step 3 display only.
  /// Final refundable amounts are calculated by later backend credit/refund preview.
  double get estimatedReturnValue {
    final data = eligibility;
    if (data == null) {
      return 0;
    }

    var total = 0.0;
    for (final item in data.items) {
      if (!item.isSelectable) {
        continue;
      }
      final selection = selections[item.saleLineId];
      if (selection?.isSelected != true || selection!.returnQty <= 0) {
        continue;
      }
      total += item.unitPrice * selection.returnQty;
    }
    return total;
  }

  int get eligibleItemCount =>
      eligibility?.items.where((item) => item.isSelectable).length ?? 0;

  int get ineligibleItemCount =>
      eligibility?.items.where((item) => !item.isSelectable).length ?? 0;

  int get selectedItemCount => selectedItems.length;

  bool get canContinueSelection => selectedItems.isNotEmpty;

  bool get canContinueFromCheck => checkResult?.canContinue == true;

  HeaderSelectionState headerSelectionStateFor(
    List<ReturnSaleLineEligibility> visibleItems,
  ) {
    final eligibleVisible =
        visibleItems.where((item) => item.isSelectable).toList(growable: false);
    if (eligibleVisible.isEmpty) {
      return HeaderSelectionState.none;
    }

    var selectedCount = 0;
    for (final item in eligibleVisible) {
      final selection = selections[item.saleLineId];
      if (selection?.isSelected == true && selection!.returnQty > 0) {
        selectedCount += 1;
      }
    }

    if (selectedCount == 0) {
      return HeaderSelectionState.none;
    }
    if (selectedCount == eligibleVisible.length) {
      return HeaderSelectionState.all;
    }
    return HeaderSelectionState.partial;
  }

  ReturnEligibilityState copyWith({
    ReturnSaleEligibility? eligibility,
    ReturnSaleEligibility? checkResult,
    Map<String, ReturnLineSelection>? selections,
    bool? isLoading,
    bool? isChecking,
    String? errorMessage,
    String? checkErrorMessage,
    bool? checkPermissionDenied,
    bool clearError = false,
    bool clearCheckError = false,
    bool clearData = false,
    bool clearCheckResult = false,
  }) {
    return ReturnEligibilityState(
      eligibility: clearData ? null : eligibility ?? this.eligibility,
      checkResult: clearCheckResult ? null : checkResult ?? this.checkResult,
      selections: clearData ? const {} : selections ?? this.selections,
      isLoading: isLoading ?? this.isLoading,
      isChecking: isChecking ?? this.isChecking,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      checkErrorMessage:
          clearCheckError ? null : checkErrorMessage ?? this.checkErrorMessage,
      checkPermissionDenied: clearCheckError || clearCheckResult
          ? (checkPermissionDenied ?? false)
          : checkPermissionDenied ?? this.checkPermissionDenied,
    );
  }
}

class ReturnEligibilityController
    extends StateNotifier<ReturnEligibilityState> {
  ReturnEligibilityController(this._ref)
      : super(const ReturnEligibilityState());

  final Ref _ref;
  int _loadSequence = 0;
  int _checkSequence = 0;
  CancelToken? _loadCancelToken;
  CancelToken? _checkCancelToken;
  bool _disposed = false;

  bool get canMutateSelection {
    final session = _ref.read(authSessionProvider);
    if (session == null || !session.isAuthenticated) {
      return false;
    }
    final granted = session.permissionCodes.toSet();
    return PosPermissionAccess.canViewReturns(granted) &&
        PosPermissionAccess.canCreateReturn(granted);
  }

  Future<void> load(String saleId) async {
    final requestId = ++_loadSequence;
    _loadCancelToken?.cancel('Superseded by a newer eligibility load.');
    final cancelToken = CancelToken();
    _loadCancelToken = cancelToken;

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;

    if (session == null || !session.isAuthenticated || deviceContext == null) {
      if (!_canApplyLoad(requestId)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        clearData: true,
        errorMessage: 'Device context is required to load sale eligibility.',
      );
      return;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    if (!_canApplyLoad(requestId)) {
      return;
    }
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearData: true,
      clearCheckResult: true,
      clearCheckError: true,
    );

    try {
      final eligibility = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .getSaleEligibility(
            deviceId: deviceContext.deviceId,
            saleId: saleId,
            cancelToken: cancelToken,
          );

      if (!_canApplyLoad(requestId)) {
        return;
      }

      final selections = _buildSelections(eligibility.items);
      state = state.copyWith(
        isLoading: false,
        eligibility: eligibility,
        selections: selections,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) || !_canApplyLoad(requestId)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        clearData: true,
        errorMessage: _readApiError(error) ??
            'Unable to load sale eligibility. Please try again.',
      );
    } catch (_) {
      if (!_canApplyLoad(requestId)) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        clearData: true,
        errorMessage: 'Unable to load sale eligibility. Please try again.',
      );
    }
  }

  Future<void> validateSelectedLines({
    required String saleId,
    required List<ReturnLineSelection> lines,
  }) async {
    if (state.isChecking) {
      return;
    }

    final requestId = ++_checkSequence;
    _checkCancelToken?.cancel('Superseded by a newer eligibility check.');
    final cancelToken = CancelToken();
    _checkCancelToken = cancelToken;

    final session = _ref.read(authSessionProvider);
    final deviceContext = _ref.read(deviceActivationProvider).deviceContext;

    if (session == null || !session.isAuthenticated || deviceContext == null) {
      if (!_canApplyCheck(requestId)) {
        return;
      }
      state = state.copyWith(
        isChecking: false,
        clearCheckResult: true,
        checkErrorMessage:
            'Device context is required to validate return eligibility.',
      );
      return;
    }

    final validLines = lines
        .where((line) => line.isSelected && line.returnQty > 0)
        .toList(growable: false);
    if (validLines.isEmpty) {
      if (!_canApplyCheck(requestId)) {
        return;
      }
      state = state.copyWith(
        isChecking: false,
        clearCheckResult: true,
        checkErrorMessage:
            'Select at least one sale line before checking eligibility.',
      );
      return;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session);
    if (!_canApplyCheck(requestId)) {
      return;
    }
    state = state.copyWith(
      isChecking: true,
      clearCheckError: true,
      clearCheckResult: true,
    );

    try {
      final result = await _ref
          .read(returnsRefundRemoteDatasourceProvider)
          .checkSelectedSaleEligibility(
            deviceId: deviceContext.deviceId,
            saleId: saleId,
            lines: [
              for (final line in validLines)
                {
                  'saleLineId': line.saleLineId,
                  'returnQty': line.returnQty,
                },
            ],
            cancelToken: cancelToken,
          );

      if (!_canApplyCheck(requestId)) {
        return;
      }

      state = state.copyWith(
        isChecking: false,
        checkResult: result,
        checkPermissionDenied: false,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error) || !_canApplyCheck(requestId)) {
        return;
      }
      state = state.copyWith(
        isChecking: false,
        clearCheckResult: true,
        checkPermissionDenied: error.response?.statusCode == 403,
        checkErrorMessage: _readApiError(error) ??
            'Unable to validate return eligibility. Please try again.',
      );
    } catch (_) {
      if (!_canApplyCheck(requestId)) {
        return;
      }
      state = state.copyWith(
        isChecking: false,
        clearCheckResult: true,
        checkPermissionDenied: false,
        checkErrorMessage:
            'Unable to validate return eligibility. Please try again.',
      );
    }
  }

  void toggleItemSelection(String saleLineId) {
    if (!_canMutateNow()) {
      return;
    }

    final current = state.selections[saleLineId];
    if (current == null) {
      return;
    }

    final item = _findItem(saleLineId);
    if (item == null || !item.isSelectable) {
      return;
    }

    final nextSelected = !current.isSelected;
    final updated = Map<String, ReturnLineSelection>.from(state.selections);
    updated[saleLineId] = current.copyWith(
      isSelected: nextSelected,
      returnQty:
          nextSelected ? (current.returnQty > 0 ? current.returnQty : 1) : 0,
    );

    state = state.copyWith(selections: updated);
  }

  /// Select/unselect all currently visible eligible lines (filtered list).
  void toggleSelectAllVisible(List<ReturnSaleLineEligibility> visibleItems) {
    if (!_canMutateNow()) {
      return;
    }

    final eligibleVisible =
        visibleItems.where((item) => item.isSelectable).toList(growable: false);
    if (eligibleVisible.isEmpty) {
      return;
    }

    final headerState = state.headerSelectionStateFor(eligibleVisible);
    final shouldSelect = headerState != HeaderSelectionState.all;
    final updated = Map<String, ReturnLineSelection>.from(state.selections);

    for (final item in eligibleVisible) {
      final current = updated[item.saleLineId] ??
          ReturnLineSelection(
            saleLineId: item.saleLineId,
            isSelected: false,
            returnQty: 0,
          );
      updated[item.saleLineId] = current.copyWith(
        isSelected: shouldSelect,
        returnQty:
            shouldSelect ? (current.returnQty > 0 ? current.returnQty : 1) : 0,
      );
    }

    state = state.copyWith(selections: updated);
  }

  void incrementReturnQty(String saleLineId) {
    _updateReturnQty(saleLineId, 1);
  }

  void decrementReturnQty(String saleLineId) {
    _updateReturnQty(saleLineId, -1);
  }

  void _updateReturnQty(String saleLineId, int delta) {
    if (!_canMutateNow()) {
      return;
    }

    final current = state.selections[saleLineId];
    final item = _findItem(saleLineId);

    if (current == null || item == null || !item.isSelectable) {
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

  Map<String, ReturnLineSelection> _buildSelections(
    List<ReturnSaleLineEligibility> items,
  ) {
    return {
      for (final item in items)
        item.saleLineId: ReturnLineSelection(
          saleLineId: item.saleLineId,
          isSelected: false,
          returnQty: 0,
        ),
    };
  }

  bool _canMutateNow() =>
      canMutateSelection && !state.isLoading && !state.isChecking;

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

  bool _canApplyLoad(int requestId) => !_disposed && requestId == _loadSequence;

  bool _canApplyCheck(int requestId) =>
      !_disposed && requestId == _checkSequence;

  @override
  void dispose() {
    _disposed = true;
    _loadSequence++;
    _checkSequence++;
    _loadCancelToken?.cancel('Return eligibility provider disposed.');
    _checkCancelToken?.cancel('Return eligibility provider disposed.');
    super.dispose();
  }
}

final returnEligibilityProvider = StateNotifierProvider.autoDispose<
    ReturnEligibilityController, ReturnEligibilityState>(
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

/// Local Step 3 item filter. Matches name, SKU, and barcode — never variant UUID.
List<ReturnSaleLineEligibility> filterReturnEligibilityItems(
  List<ReturnSaleLineEligibility> items, {
  required String query,
  required bool returnableOnly,
}) {
  final normalized = query.trim().toLowerCase();
  return items.where((item) {
    if (returnableOnly && !item.isSelectable) {
      return false;
    }
    if (normalized.isEmpty) {
      return true;
    }
    final barcode = (item.barcode ?? '').trim().toLowerCase();
    return item.name.toLowerCase().contains(normalized) ||
        item.sku.toLowerCase().contains(normalized) ||
        (barcode.isNotEmpty && barcode.contains(normalized));
  }).toList(growable: false);
}
