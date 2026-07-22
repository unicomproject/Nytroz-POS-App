import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_barcode_scan_controller.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_barcode_scan_feedback.dart';

void main() {
  test('success feedback includes item metadata and quantity per scan', () {
    final added = barcodeFeedbackPresentation(const PosBarcodeScanFeedbackEvent(
      id: 1,
      outcome: PosBarcodeScanOutcome.added,
      barcode: '82111001003',
      productName: 'Team Jersey',
      variantName: 'Medium / Blue',
      requestedQuantity: 2,
    ));
    final increased = barcodeFeedbackPresentation(
      const PosBarcodeScanFeedbackEvent(
        id: 2,
        outcome: PosBarcodeScanOutcome.quantityIncreased,
        barcode: '82111001003',
        productName: 'Team Jersey',
        variantName: 'Medium / Blue',
        requestedQuantity: 2,
      ),
    );

    expect(added.isSuccess, isTrue);
    expect(added.message, '2 × Team Jersey — Medium / Blue added');
    expect(increased.isSuccess, isTrue);
    expect(increased.message,
        'Team Jersey — Medium / Blue quantity increased by 2');
  });

  test('all failure outcomes map to safe cashier-facing messages', () {
    const expected = <PosBarcodeScanOutcome, String>{
      PosBarcodeScanOutcome.barcodeNotFound:
          'Product not found for barcode 82111001003',
      PosBarcodeScanOutcome.barcodeAmbiguous:
          'Multiple products use this barcode',
      PosBarcodeScanOutcome.invalidBarcode: 'Invalid barcode',
      PosBarcodeScanOutcome.invalidDevice:
          'POS device is not activated or trusted',
      PosBarcodeScanOutcome.authenticationRequired:
          'Session expired. Sign in again.',
      PosBarcodeScanOutcome.permissionDenied:
          'You do not have permission to scan products',
      PosBarcodeScanOutcome.productUnavailable: 'Product is unavailable',
      PosBarcodeScanOutcome.variantUnavailable:
          'Selected variant is unavailable',
      PosBarcodeScanOutcome.priceUnavailable: 'Product price is unavailable',
      PosBarcodeScanOutcome.outOfStock: 'Selected variant is out of stock',
      PosBarcodeScanOutcome.insufficientStock:
          'Not enough stock for this quantity',
      PosBarcodeScanOutcome.networkFailure:
          'Unable to verify barcode. Check the connection.',
      PosBarcodeScanOutcome.unexpectedFailure: 'Unable to process barcode',
      PosBarcodeScanOutcome.cancelled: 'Unable to process barcode',
    };

    for (final entry in expected.entries) {
      final feedback = barcodeFeedbackPresentation(PosBarcodeScanFeedbackEvent(
        id: entry.key.index + 1,
        outcome: entry.key,
        barcode: '82111001003',
      ));
      expect(feedback.isSuccess, isFalse, reason: entry.key.name);
      expect(feedback.message, entry.value, reason: entry.key.name);
      expect(feedback.message, isNot(contains('Exception')));
    }
  });
}
