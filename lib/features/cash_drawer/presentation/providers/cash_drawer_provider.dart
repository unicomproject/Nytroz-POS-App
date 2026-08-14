import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../../data/datasources/cash_drawer_remote_datasource.dart';
import '../../data/repositories/cash_drawer_repository_impl.dart';
import '../../domain/entities/cash_drawer_summary.dart';
import '../../domain/entities/cash_movement.dart';
import '../../domain/repositories/cash_drawer_repository.dart';

/// Backend-authoritative cash drawer financial state.
class CashDrawerState {
  const CashDrawerState({
    this.summary,
    this.movements = const [],
    this.isSubmitting = false,
    this.isLoading = false,
    this.errorMessage,
    this.closeTillMessage,
  });

  final CashDrawerSummary? summary;
  final List<CashMovement> movements;
  final bool isSubmitting;
  final bool isLoading;
  final String? errorMessage;
  final String? closeTillMessage;

  bool get hasOpenTill => summary?.isOpen == true;

  CashDrawerState copyWith({
    CashDrawerSummary? summary,
    List<CashMovement>? movements,
    bool? isSubmitting,
    bool? isLoading,
    String? errorMessage,
    String? closeTillMessage,
    bool clearError = false,
    bool clearCloseTillMessage = false,
    bool clearSummary = false,
  }) {
    return CashDrawerState(
      summary: clearSummary ? null : summary ?? this.summary,
      movements: movements ?? this.movements,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      closeTillMessage: clearCloseTillMessage
          ? null
          : closeTillMessage ?? this.closeTillMessage,
    );
  }
}

final cashDrawerRepositoryProvider = Provider<CashDrawerRepository>((ref) {
  return CashDrawerRepositoryImpl(
    CashDrawerRemoteDatasource(ref.watch(appDioProvider)),
  );
});

class CashDrawerController extends StateNotifier<CashDrawerState> {
  CashDrawerController(this._ref) : super(const CashDrawerState()) {
    _ref.listen(tillProvider, (_, __) {
      refresh();
    });
    refresh();
  }

  final Ref _ref;

  Future<void> refresh() async {
    final device = _ref.read(deviceActivationProvider).deviceContext;
    final deviceId = device?.deviceId.trim() ?? '';
    if (deviceId.isEmpty) {
      state = state.copyWith(
        clearSummary: true,
        movements: const [],
        clearError: true,
        isLoading: false,
      );
      return;
    }

    final session = _ref.read(authSessionProvider);
    if (session == null || session.accessToken.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Sign in is required to load the cash drawer.',
        isLoading: false,
      );
      return;
    }

    _ensureAuthorizationHeader(_ref.read(appDioProvider), session.accessToken);
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = _ref.read(cashDrawerRepositoryProvider);
      final summary = await repository.getSummary(deviceId);
      final movements = await repository.getMovements(deviceId);
      state = state.copyWith(
        summary: summary,
        movements: movements,
        isLoading: false,
        clearError: true,
      );
    } on CashDrawerException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message,
        clearSummary: true,
        movements: const [],
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Cash drawer could not be loaded. $error',
        clearSummary: true,
        movements: const [],
      );
    }
  }

  Future<bool> recordCashIn({
    required double amount,
    String? reason,
    String? note,
  }) async {
    return _recordMovement(
      type: CashMovementType.cashIn,
      amount: amount,
      reason: reason,
      note: note,
    );
  }

  Future<bool> recordCashOut({
    required double amount,
    String? note,
  }) async {
    final expected = state.summary?.currentExpectedCash ?? 0;
    final currency = state.summary?.currencyCode ?? '';
    if (amount > expected) {
      state = state.copyWith(
        errorMessage:
            'Amount cannot exceed current expected cash (${formatCashDrawerAmount(expected, currencyCode: currency)}).',
      );
      return false;
    }

    return _recordMovement(
      type: CashMovementType.cashOut,
      amount: amount,
      note: note,
    );
  }

  Future<bool> recordCashDrop({
    required double amount,
    String? reason,
    String? note,
  }) async {
    final expected = state.summary?.currentExpectedCash ?? 0;
    final currency = state.summary?.currencyCode ?? '';
    if (amount > expected) {
      state = state.copyWith(
        errorMessage:
            'Amount cannot exceed available cash in drawer (${formatCashDrawerAmount(expected, currencyCode: currency)}).',
      );
      return false;
    }

    return _recordMovement(
      type: CashMovementType.cashDrop,
      amount: amount,
      reason: reason,
      note: note,
    );
  }

  Future<bool> submitCloseTill({
    required double countedCash,
    String? mismatchReason,
    String? note,
  }) async {
    final summary = state.summary;
    if (summary == null || !summary.isOpen) {
      state = state.copyWith(
        errorMessage: 'An open till session is required to close the till.',
      );
      return false;
    }

    if (countedCash < 0) {
      state = state.copyWith(
        errorMessage: 'Counted cash must be zero or greater.',
      );
      return false;
    }

    final device = _ref.read(deviceActivationProvider).deviceContext;
    if (device == null) {
      state = state.copyWith(
        errorMessage: 'Device context is required to close the till.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    final closedSession = await _ref.read(tillProvider.notifier).closeTill(
          deviceContext: device,
          countedCash: countedCash,
          expectedCash: summary.currentExpectedCash,
          mismatchReason: mismatchReason,
          closingNote: note,
        );

    if (closedSession == null) {
      final tillError = _ref.read(tillProvider).errorMessage;
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: tillError ?? 'Till could not be closed. Try again.',
      );
      return false;
    }

    final difference = closedSession.cashDifference;
    final currency = summary.currencyCode;
    final differenceLabel = difference == 0
        ? 'balanced'
        : difference > 0
            ? 'over by ${formatCashDrawerAmount(difference.abs(), currencyCode: currency)}'
            : 'short by ${formatCashDrawerAmount(difference.abs(), currencyCode: currency)}';

    await refresh();
    state = state.copyWith(
      isSubmitting: false,
      clearCloseTillMessage: true,
      closeTillMessage: 'Till closed successfully. Count was $differenceLabel.',
    );
    return true;
  }

  Future<bool> _recordMovement({
    required CashMovementType type,
    required double amount,
    String? reason,
    String? note,
  }) async {
    final summary = state.summary;
    if (summary == null || !summary.isOpen) {
      state = state.copyWith(
        errorMessage: 'An open till session is required for cash movements.',
      );
      return false;
    }

    if (amount <= 0) {
      state = state.copyWith(
        errorMessage: 'Amount must be greater than zero.',
      );
      return false;
    }

    final device = _ref.read(deviceActivationProvider).deviceContext;
    final deviceId = device?.deviceId.trim() ?? '';
    if (deviceId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Device context is required for cash movements.',
      );
      return false;
    }

    final authSession = _ref.read(authSessionProvider);
    if (authSession == null || authSession.accessToken.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'Sign in is required for cash movements.',
      );
      return false;
    }

    final effectiveReason = () {
      final primary = reason?.trim();
      if (primary != null && primary.isNotEmpty) return primary;
      final fallback = note?.trim();
      if (fallback != null && fallback.isNotEmpty) return fallback;
      return null;
    }();
    if (effectiveReason == null) {
      state = state.copyWith(
        errorMessage: 'A reason is required for cash movements.',
      );
      return false;
    }

    _ensureAuthorizationHeader(
        _ref.read(appDioProvider), authSession.accessToken);
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      await _ref.read(cashDrawerRepositoryProvider).createMovement(
            requestId: _newRequestId(),
            deviceId: deviceId,
            tillSessionId: summary.tillSessionId,
            type: type,
            amount: amount,
            reason: effectiveReason,
            referenceNumber: note?.trim().isEmpty == true ? null : note?.trim(),
          );
      await refresh();
      state = state.copyWith(isSubmitting: false, clearError: true);
      return true;
    } on CashDrawerException catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.message,
      );
      return false;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Cash movement could not be saved. $error',
      );
      return false;
    }
  }
}

void _ensureAuthorizationHeader(Dio dio, String accessToken) {
  dio.options.headers['Authorization'] = 'Bearer $accessToken';
}

String _newRequestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

final cashDrawerProvider =
    StateNotifierProvider<CashDrawerController, CashDrawerState>((ref) {
  return CashDrawerController(ref);
});

String formatCashDrawerAmount(double value, {String currencyCode = ''}) {
  final currency = currencyCode.trim().isEmpty ? '' : currencyCode.trim();
  final parts = value.toStringAsFixed(2).split('.');
  final whole = parts.first;
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    buffer.write(whole[i]);
    final remaining = whole.length - i;
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  final amount = '${buffer.toString()}.${parts.last}';
  return currency.isEmpty ? amount : '$currency $amount';
}

String formatCashDrawerDateTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
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
  return '${months[value.month - 1]} ${value.day}, ${value.year} • $hour:$minute $period';
}

String formatCashDrawerOpenedTime(DateTime? value) {
  if (value == null) {
    return '—';
  }

  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}
