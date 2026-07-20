import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/exchange_difference_result.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/exchange_replacement_selection.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_flow_steps.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_resolution_type.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_flow_provider.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/return_stepper.dart';

void main() {
  group('Exchange difference logic', () {
    test('positive difference shows customer pays', () {
      final result = calculateExchangeDifference(
        returnItemValue: 100,
        newItemValue: 250,
        currencyCode: 'CUR',
      );

      expect(result.type, ExchangeDifferenceType.customerPays);
      expect(result.amount, 150);
    });

    test('negative difference shows customer refund', () {
      final result = calculateExchangeDifference(
        returnItemValue: 250,
        newItemValue: 100,
        currencyCode: 'CUR',
      );

      expect(result.type, ExchangeDifferenceType.customerRefund);
      expect(result.amount, 150);
    });

    test('zero difference shows even exchange', () {
      final result = calculateExchangeDifference(
        returnItemValue: 200,
        newItemValue: 200,
        currencyCode: 'CUR',
      );

      expect(result.type, ExchangeDifferenceType.evenExchange);
      expect(result.amount, 0);
    });
  });

  group('Exchange replacement selection', () {
    test('selection key uses product and variant ids', () {
      const selection = ExchangeReplacementSelection(
        productId: 'prod-1',
        productVariantId: 'var-1',
        productName: 'Product',
        variantDisplayName: 'Variant',
        quantity: 1,
        unitPrice: 100,
        currencyCode: 'CUR',
      );

      expect(selection.selectionKey, 'prod-1::var-1');
      expect(selection.lineTotal, 100);
    });

    test('quantity greater than one updates line total', () {
      const selection = ExchangeReplacementSelection(
        productId: 'prod-1',
        productVariantId: 'var-1',
        productName: 'Product',
        variantDisplayName: 'Variant',
        quantity: 3,
        unitPrice: 100,
        currencyCode: 'CUR',
        availableQty: 5,
      );

      expect(selection.quantity, 3);
      expect(selection.lineTotal, 300);
      expect(selection.copyWith(quantity: 2).quantity, 2);
    });

    test('out of stock selection is not selectable', () {
      const selection = ExchangeReplacementSelection(
        productId: 'prod-1',
        productVariantId: 'var-1',
        productName: 'Product',
        variantDisplayName: 'Variant',
        quantity: 1,
        unitPrice: 100,
        currencyCode: 'CUR',
        stockStatus: 'OutOfStock',
      );

      expect(selection.isSelectable, isFalse);
    });
  });

  group('Return flow branch clearing', () {
    test('switching to refund clears exchange replacement', () {
      final controller = ReturnFlowController();
      controller.setSelectedResolution(ReturnResolutionType.exchange);
      controller.setSelectedReplacement(
        const ExchangeReplacementSelection(
          productId: 'prod-1',
          productVariantId: 'var-1',
          productName: 'Product',
          variantDisplayName: 'Variant',
          quantity: 1,
          unitPrice: 100,
          currencyCode: 'CUR',
        ),
      );

      controller.setSelectedResolution(ReturnResolutionType.refund);

      expect(controller.state.selectedReplacement, isNull);
      expect(controller.state.selectedResolution, ReturnResolutionType.refund);
    });
  });

  group('Stepper exchange label', () {
    test('step 8 label is Exchange on exchange branch', () {
      expect(
        ReturnStepper.branchStepLabel(ReturnResolutionType.exchange),
        'Exchange',
      );
    });

    test('branch step is single numbered step', () {
      expect(ReturnFlowSteps.branchAction, ReturnsExchangeStep.branchAction);
      expect(ReturnFlowSteps.exchangeFlow, ReturnFlowSteps.branchAction);
    });
  });

  group('Catalog product stock', () {
    test('out of stock product is not selectable in list logic', () {
      const product = PosCatalogProductSummary(
        productId: 'prod-1',
        name: 'Product',
        categoryName: 'General',
        basePrice: 100,
        hasVariants: false,
        stockStatus: 'OutOfStock',
      );

      expect(product.isOutOfStock, isTrue);
    });
  });
}
