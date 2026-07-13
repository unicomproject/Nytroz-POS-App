import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/close_till_mismatch_reason.dart';
import 'cash_drawer_provider.dart';

enum CloseTillClosingStatus {
  balanced,
  varianceReasonRequired,
  short,
  over,
}

class CloseTillFormState {
  const CloseTillFormState({
    this.countedCashText = '',
    this.mismatchReason,
    this.notes = '',
    this.hasDraft = false,
  });

  final String countedCashText;
  final String? mismatchReason;
  final String notes;
  final bool hasDraft;

  double? get parsedCountedCash {
    final raw = countedCashText.trim();
    if (raw.isEmpty) {
      return null;
    }
    return double.tryParse(raw);
  }

  bool get hasValidCountedCash =>
      parsedCountedCash != null && parsedCountedCash! >= 0;

  double? differenceFor(double expectedCash) {
    final counted = parsedCountedCash;
    if (counted == null) {
      return null;
    }
    return counted - expectedCash;
  }

  CloseTillClosingStatus closingStatusFor(double expectedCash) {
    final difference = differenceFor(expectedCash);
    if (difference == null) {
      return CloseTillClosingStatus.varianceReasonRequired;
    }
    if (difference == 0) {
      return CloseTillClosingStatus.balanced;
    }
    if (difference < 0) {
      return CloseTillClosingStatus.short;
    }
    return CloseTillClosingStatus.over;
  }

  String summaryClosingStatusLabel(double expectedCash) {
    final difference = differenceFor(expectedCash);
    if (difference == null || difference == 0) {
      return 'Balanced';
    }
    return 'Variance Reason Required';
  }

  CloseTillFormState copyWith({
    String? countedCashText,
    String? mismatchReason,
    String? notes,
    bool? hasDraft,
    bool clearMismatchReason = false,
  }) {
    return CloseTillFormState(
      countedCashText: countedCashText ?? this.countedCashText,
      mismatchReason:
          clearMismatchReason ? null : mismatchReason ?? this.mismatchReason,
      notes: notes ?? this.notes,
      hasDraft: hasDraft ?? this.hasDraft,
    );
  }
}

class CloseTillFormController extends StateNotifier<CloseTillFormState> {
  CloseTillFormController() : super(const CloseTillFormState());

  CloseTillFormState? _draftSnapshot;

  void reset() {
    state = const CloseTillFormState();
    _draftSnapshot = null;
  }

  void restoreDraftIfAvailable() {
    final draft = _draftSnapshot;
    if (draft == null) {
      return;
    }
    state = draft.copyWith(hasDraft: true);
  }

  void setCountedCashText(String value) {
    state = state.copyWith(countedCashText: value);
  }

  void setMismatchReason(String? value) {
    state = state.copyWith(mismatchReason: value);
  }

  void setNotes(String value) {
    state = state.copyWith(notes: value);
  }

  void saveDraft() {
    _draftSnapshot = state.copyWith(hasDraft: true);
    state = state.copyWith(hasDraft: true);
  }

  void applyDefaultCountedCash(double expectedCash) {
    if (state.hasDraft || state.hasValidCountedCash || expectedCash < 0) {
      return;
    }

    state = state.copyWith(
      countedCashText: formatCloseTillCountedCashDefault(expectedCash),
    );
  }
}

final closeTillFormProvider =
    StateNotifierProvider.autoDispose<CloseTillFormController, CloseTillFormState>(
  (ref) => CloseTillFormController(),
);

String formatCloseTillCountedCashDefault(double expectedCash) {
  return expectedCash.toStringAsFixed(2);
}

String formatCloseTillDifferenceLabel(double difference) {
  if (difference == 0) {
    return '${formatCashDrawerAmount(0)} Balanced';
  }

  final amount = formatCashDrawerAmount(difference.abs());
  if (difference < 0) {
    return '- $amount Short';
  }
  return '+ $amount Over';
}

CloseTillColorPair closeTillDifferenceColors(double difference) {
  if (difference == 0) {
    return const CloseTillColorPair(
      foreground: TenantAdminColors.success,
      background: Color(0xFFEFFAF3),
      border: Color(0xFFBBF7D0),
    );
  }
  if (difference < 0) {
    return const CloseTillColorPair(
      foreground: TenantAdminColors.danger,
      background: Color(0xFFFEF2F2),
      border: Color(0xFFFECACA),
    );
  }
  return const CloseTillColorPair(
    foreground: TenantAdminColors.success,
    background: Color(0xFFEFFAF3),
    border: Color(0xFFBBF7D0),
  );
}

CloseTillColorPair closeTillClosingStatusColors(String statusLabel) {
  switch (statusLabel) {
    case 'Balanced':
      return const CloseTillColorPair(
        foreground: TenantAdminColors.success,
        background: Color(0xFFEFFAF3),
        border: Color(0xFFBBF7D0),
      );
    case 'Short':
      return const CloseTillColorPair(
        foreground: TenantAdminColors.danger,
        background: Color(0xFFFEF2F2),
        border: Color(0xFFFECACA),
      );
    case 'Over':
      return const CloseTillColorPair(
        foreground: TenantAdminColors.success,
        background: Color(0xFFEFFAF3),
        border: Color(0xFFBBF7D0),
      );
    case 'Variance Reason Required':
    default:
      return const CloseTillColorPair(
        foreground: TenantAdminColors.warning,
        background: Color(0xFFFFF7ED),
        border: Color(0xFFFED7AA),
      );
  }
}

class CloseTillColorPair {
  const CloseTillColorPair({
    required this.foreground,
    required this.background,
    required this.border,
  });

  final Color foreground;
  final Color background;
  final Color border;
}

String? validateCloseTillCountedCash(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) {
    return 'Counted cash is required';
  }

  final amount = double.tryParse(raw);
  if (amount == null || amount < 0) {
    return 'Enter a valid counted amount';
  }

  return null;
}

String? validateCloseTillMismatchReason(String? value, {required bool required}) {
  if (!required) {
    return null;
  }

  if (value == null || value.trim().isEmpty) {
    return 'Mismatch reason is required';
  }

  if (!CloseTillMismatchReason.options.contains(value)) {
    return 'Select a valid mismatch reason';
  }

  return null;
}
