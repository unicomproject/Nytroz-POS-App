import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/pos_cart_discount.dart';
import '../../domain/entities/pos_discount_api_models.dart';
import '../providers/pos_discount_provider.dart';
import 'discount_state.dart';

class PosDiscountController
    extends StateNotifier<PosDiscountPresentationState> {
  PosDiscountController({
    required String currencyCode,
    required int subtotal,
    required int itemCount,
    this.validateOnline,
  }) : super(PosDiscountPresentationState.initial(
          currencyCode: currencyCode,
          subtotal: subtotal,
          itemCount: itemCount,
        ));

  final Future<PosDiscountValidationResult> Function(
      PosDiscountPresentationState state)? validateOnline;
  Timer? _debounce;
  int _validationSequence = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void selectScope(PosDiscountScope scope) {
    if (scope == state.scope) return;
    state = state.copyWith(
      scope: scope,
      calculationMethod: scope == PosDiscountScope.item
          ? PosDiscountCalculationMethod.percentage
          : state.calculationMethod,
      clearSelectedCartLine: true,
      clearValueError: true,
      clearErrorMessage: true,
      preview: _neutralPreview(eligibleSubtotal: state.currentSubtotal),
      isAuthoritativelyValid: false,
      isOfflineProvisional: false,
    );
    validateValue();
    scheduleValidation();
  }

  void selectCalculationMethod(PosDiscountCalculationMethod method) {
    if (state.scope == PosDiscountScope.item &&
        method == PosDiscountCalculationMethod.fixedAmount) {
      return;
    }
    state = state.copyWith(
      calculationMethod: method,
      clearValueError: true,
      clearErrorMessage: true,
      isAuthoritativelyValid: false,
      isOfflineProvisional: false,
    );
    validateValue();
    scheduleValidation();
  }

  void selectCartLine(String cartLineKey, String? variantId, int lineTotal) {
    state = state.copyWith(
      selectedCartLineKey: cartLineKey,
      selectedVariantId: variantId,
      clearErrorMessage: true,
      preview: _neutralPreview(eligibleSubtotal: lineTotal),
      isAuthoritativelyValid: false,
      isOfflineProvisional: false,
    );
    scheduleValidation();
  }

  void updateValue(String value) {
    state = state.copyWith(
      requestedValueText: value,
      clearValueError: true,
      clearErrorMessage: true,
      isAuthoritativelyValid: false,
      isOfflineProvisional: false,
    );
    validateValue();
    scheduleValidation();
  }

  void updateReason(String reason) {
    state = state.copyWith(reasonText: reason, clearErrorMessage: true);
    scheduleValidation();
  }

  void validateValue() {
    final text = state.requestedValueText.trim();
    String? error;
    if (text.isNotEmpty) {
      final value = double.tryParse(text);
      if (value == null) {
        error = 'Enter a valid number.';
      } else if (value <= 0) {
        error = 'Discount must be greater than 0.';
      } else if (state.calculationMethod ==
              PosDiscountCalculationMethod.percentage &&
          value > 100) {
        error = 'Percentage cannot exceed 100%.';
      }
    }
    state = state.copyWith(
      valueError: error,
      clearValueError: error == null,
    );
  }

  void markIntegrationPending() {
    state = state.copyWith(
      errorMessage:
          'Discount validation and application will be connected in Chunk 2.',
    );
  }

  void setAuthority(PosDiscountAuthority authority) {
    state = state.copyWith(
      maxPercentage: authority.maxPercentage,
      maxFixedAmount: authority.maxFixedAmount,
    );
  }

  void scheduleValidation() {
    _debounce?.cancel();
    final validator = validateOnline;
    if (validator == null || !state.isLocallyValid) {
      state = state.copyWith(
        isLoading: false,
        isAuthoritativelyValid: false,
        isOfflineProvisional: false,
      );
      return;
    }
    final sequence = ++_validationSequence;
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      state = state.copyWith(
        isLoading: true,
        clearErrorMessage: true,
        isAuthoritativelyValid: false,
      );
      try {
        final result = await validator(state);
        if (sequence != _validationSequence || !mounted) return;
        state = state.copyWith(
          isLoading: false,
          isAuthoritativelyValid:
              result.isValid && result.outcome.toLowerCase() == 'direct_apply',
          isOfflineProvisional: result.isValid &&
              result.outcome.toLowerCase() == 'offline_provisional',
          preview: PosDiscountPreview(
            subtotal: result.subtotal,
            eligibleSubtotal: result.eligibleSubtotal,
            discountAmount: result.discountAmount,
            totalAfterDiscount: result.totalAfterDiscount,
            currencyCode: result.currencyCode,
            validationMessages: result.validationMessages,
          ),
          errorMessage: result.isValid
              ? null
              : _safeValidationMessage(result.validationMessages),
          clearErrorMessage: result.isValid,
        );
      } catch (error) {
        if (sequence != _validationSequence || !mounted) return;
        state = state.copyWith(
          isLoading: false,
          isAuthoritativelyValid: false,
          isOfflineProvisional: false,
          errorMessage: safePosDiscountErrorMessage(error),
        );
      }
    });
  }

  void setSubmitting(bool value) {
    state = state.copyWith(isSubmitting: value);
  }

  void setError(Object error) {
    state = state.copyWith(
      isSubmitting: false,
      errorMessage: safePosDiscountErrorMessage(error),
    );
  }

  static String _safeValidationMessage(List<String> messages) =>
      messages.isEmpty ? 'Discount validation failed.' : messages.join(' ');

  PosDiscountPreview _neutralPreview({required int eligibleSubtotal}) {
    return PosDiscountPreview(
      subtotal: state.currentSubtotal,
      eligibleSubtotal: eligibleSubtotal,
      currencyCode: state.currencyCode,
      totalAfterDiscount: eligibleSubtotal,
    );
  }
}

final posDiscountControllerProvider = StateNotifierProvider.autoDispose.family<
    PosDiscountController,
    PosDiscountPresentationState,
    PosDiscountControllerArgs>((ref, args) {
  return PosDiscountController(
    currencyCode: args.currencyCode,
    subtotal: args.subtotal,
    itemCount: args.itemCount,
    validateOnline: (state) => validatePosDiscount(
      ref: ref,
      valueType:
          state.calculationMethod == PosDiscountCalculationMethod.percentage
              ? PosDiscountValueType.percentage
              : PosDiscountValueType.fixedAmount,
      value: state.parsedRequestedValue!,
      isLineDiscount: state.scope == PosDiscountScope.item,
      targetVariantId: state.selectedVariantId,
      reason: state.reasonText,
    ),
  );
});

class PosDiscountControllerArgs {
  const PosDiscountControllerArgs({
    required this.currencyCode,
    required this.subtotal,
    required this.itemCount,
  });

  final String currencyCode;
  final int subtotal;
  final int itemCount;

  @override
  bool operator ==(Object other) =>
      other is PosDiscountControllerArgs &&
      other.currencyCode == currencyCode &&
      other.subtotal == subtotal &&
      other.itemCount == itemCount;

  @override
  int get hashCode => Object.hash(currencyCode, subtotal, itemCount);
}
