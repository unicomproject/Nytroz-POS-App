import 'pos_barcode_scan_controller.dart';

class PosBarcodeFeedbackPresentation {
  const PosBarcodeFeedbackPresentation({
    required this.message,
    required this.isSuccess,
  });

  final String message;
  final bool isSuccess;
}

PosBarcodeFeedbackPresentation barcodeFeedbackPresentation(
  PosBarcodeScanFeedbackEvent event,
) {
  final product = [event.productName, event.variantName]
      .whereType<String>()
      .where((value) => value.trim().isNotEmpty)
      .join(' — ');
  return switch (event.outcome) {
    PosBarcodeScanOutcome.added => PosBarcodeFeedbackPresentation(
        message: event.requestedQuantity != null && event.requestedQuantity! > 1
            ? '${event.requestedQuantity} × $product added'
            : '$product added',
        isSuccess: true,
      ),
    PosBarcodeScanOutcome.quantityIncreased => PosBarcodeFeedbackPresentation(
        message: event.requestedQuantity != null && event.requestedQuantity! > 1
            ? '$product quantity increased by ${event.requestedQuantity}'
            : '$product quantity increased',
        isSuccess: true,
      ),
    PosBarcodeScanOutcome.barcodeNotFound => PosBarcodeFeedbackPresentation(
        message: 'Product not found for barcode ${event.barcode}',
        isSuccess: false,
      ),
    PosBarcodeScanOutcome.barcodeAmbiguous =>
      const PosBarcodeFeedbackPresentation(
          message: 'Multiple products use this barcode', isSuccess: false),
    PosBarcodeScanOutcome.invalidBarcode =>
      const PosBarcodeFeedbackPresentation(
          message: 'Invalid barcode', isSuccess: false),
    PosBarcodeScanOutcome.invalidDevice => const PosBarcodeFeedbackPresentation(
        message: 'POS device is not activated or trusted', isSuccess: false),
    PosBarcodeScanOutcome.authenticationRequired =>
      const PosBarcodeFeedbackPresentation(
          message: 'Session expired. Sign in again.', isSuccess: false),
    PosBarcodeScanOutcome.permissionDenied =>
      const PosBarcodeFeedbackPresentation(
          message: 'You do not have permission to scan products',
          isSuccess: false),
    PosBarcodeScanOutcome.productUnavailable =>
      const PosBarcodeFeedbackPresentation(
          message: 'Product is unavailable', isSuccess: false),
    PosBarcodeScanOutcome.variantUnavailable =>
      const PosBarcodeFeedbackPresentation(
          message: 'Selected variant is unavailable', isSuccess: false),
    PosBarcodeScanOutcome.priceUnavailable =>
      const PosBarcodeFeedbackPresentation(
          message: 'Product price is unavailable', isSuccess: false),
    PosBarcodeScanOutcome.outOfStock => const PosBarcodeFeedbackPresentation(
        message: 'Selected variant is out of stock', isSuccess: false),
    PosBarcodeScanOutcome.insufficientStock =>
      const PosBarcodeFeedbackPresentation(
          message: 'Not enough stock for this quantity', isSuccess: false),
    PosBarcodeScanOutcome.networkFailure =>
      const PosBarcodeFeedbackPresentation(
          message: 'Unable to verify barcode. Check the connection.',
          isSuccess: false),
    PosBarcodeScanOutcome.unexpectedFailure =>
      const PosBarcodeFeedbackPresentation(
          message: 'Unable to process barcode', isSuccess: false),
    PosBarcodeScanOutcome.cancelled => const PosBarcodeFeedbackPresentation(
        message: 'Unable to process barcode', isSuccess: false),
  };
}
