import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';

enum PosDiscountScope { order, item }

enum PosDiscountCalculationMethod { percentage, fixedAmount }

class PosDiscountPreview {
  const PosDiscountPreview({
    required this.subtotal,
    required this.eligibleSubtotal,
    required this.currencyCode,
    this.discountAmount,
    this.totalAfterDiscount,
    this.validationMessages = const [],
  });

  final int subtotal;
  final int eligibleSubtotal;
  final String currencyCode;
  final int? discountAmount;
  final int? totalAfterDiscount;
  final List<String> validationMessages;
}

class PosDiscountPresentationState {
  const PosDiscountPresentationState({
    required this.scope,
    required this.calculationMethod,
    required this.currencyCode,
    required this.currentSubtotal,
    required this.currentItemCount,
    required this.preview,
    this.selectedCartLineKey,
    this.selectedVariantId,
    this.requestedValueText = '',
    this.reasonText = '',
    this.valueError,
    this.errorMessage,
    this.isLoading = false,
    this.isSubmitting = false,
    this.maxPercentage,
    this.maxFixedAmount,
    this.isAuthoritativelyValid = false,
    this.isOfflineProvisional = false,
  });

  factory PosDiscountPresentationState.initial({
    required String currencyCode,
    required int subtotal,
    required int itemCount,
  }) {
    return PosDiscountPresentationState(
      scope: PosDiscountScope.order,
      calculationMethod: PosDiscountCalculationMethod.percentage,
      currencyCode: currencyCode,
      currentSubtotal: subtotal,
      currentItemCount: itemCount,
      preview: PosDiscountPreview(
        subtotal: subtotal,
        eligibleSubtotal: subtotal,
        currencyCode: currencyCode,
        totalAfterDiscount: subtotal,
      ),
    );
  }

  final PosDiscountScope scope;
  final PosDiscountCalculationMethod calculationMethod;
  final String? selectedCartLineKey;
  final String? selectedVariantId;
  final String requestedValueText;
  final String reasonText;
  final String currencyCode;
  final int currentSubtotal;
  final int currentItemCount;
  final PosDiscountPreview preview;
  final String? valueError;
  final String? errorMessage;
  final bool isLoading;
  final bool isSubmitting;
  final double? maxPercentage;
  final double? maxFixedAmount;
  final bool isAuthoritativelyValid;
  final bool isOfflineProvisional;

  double? get parsedRequestedValue =>
      double.tryParse(requestedValueText.trim());

  bool get isValueValid {
    final value = parsedRequestedValue;
    if (value == null || value <= 0) return false;
    if (calculationMethod == PosDiscountCalculationMethod.percentage &&
        value > 100) {
      return false;
    }
    return true;
  }

  bool get isLocallyValid =>
      !isLoading &&
      !isSubmitting &&
      currentItemCount > 0 &&
      isValueValid &&
      (scope == PosDiscountScope.order || selectedCartLineKey != null) &&
      !(scope == PosDiscountScope.item &&
          calculationMethod == PosDiscountCalculationMethod.fixedAmount);

  bool get canApply =>
      isLocallyValid && (isAuthoritativelyValid || isOfflineProvisional);

  PosNewSaleCartItem? selectedItem(PosNewSaleCartState cart) =>
      selectedCartLineKey == null ? null : cart.items[selectedCartLineKey];

  PosDiscountPresentationState copyWith({
    PosDiscountScope? scope,
    PosDiscountCalculationMethod? calculationMethod,
    String? selectedCartLineKey,
    String? selectedVariantId,
    bool clearSelectedCartLine = false,
    String? requestedValueText,
    String? reasonText,
    PosDiscountPreview? preview,
    String? valueError,
    bool clearValueError = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isLoading,
    bool? isSubmitting,
    double? maxPercentage,
    double? maxFixedAmount,
    bool? isAuthoritativelyValid,
    bool? isOfflineProvisional,
  }) {
    return PosDiscountPresentationState(
      scope: scope ?? this.scope,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      selectedCartLineKey: clearSelectedCartLine
          ? null
          : selectedCartLineKey ?? this.selectedCartLineKey,
      selectedVariantId: clearSelectedCartLine
          ? null
          : selectedVariantId ?? this.selectedVariantId,
      requestedValueText: requestedValueText ?? this.requestedValueText,
      reasonText: reasonText ?? this.reasonText,
      currencyCode: currencyCode,
      currentSubtotal: currentSubtotal,
      currentItemCount: currentItemCount,
      preview: preview ?? this.preview,
      valueError: clearValueError ? null : valueError ?? this.valueError,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      maxPercentage: maxPercentage ?? this.maxPercentage,
      maxFixedAmount: maxFixedAmount ?? this.maxFixedAmount,
      isAuthoritativelyValid:
          isAuthoritativelyValid ?? this.isAuthoritativelyValid,
      isOfflineProvisional: isOfflineProvisional ?? this.isOfflineProvisional,
    );
  }
}
