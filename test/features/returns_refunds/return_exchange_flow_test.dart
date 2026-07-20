import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/exchange_difference_result.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_exchange.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_resolution_type.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/navigation/returns_route_guard.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_exchange_flow_provider.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_flow_provider.dart';

void main() {
  group('Strict exchange permissions', () {
    test('canProcessExchange requires exact exchanges.create', () {
      expect(
        PosPermissionAccess.canProcessExchange({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
          PosPermissionCodes.createExchange,
        }),
        isTrue,
      );
      expect(
        PosPermissionAccess.canProcessExchange({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
        }),
        isFalse,
      );
      expect(
        PosPermissionAccess.canProcessExchange({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
          PosPermissionCodes.createRefund,
        }),
        isFalse,
      );
      expect(
        PosPermissionAccess.canProcessExchange({
          PosPermissionCodes.viewExchanges,
          PosPermissionCodes.createExchange,
        }),
        isFalse,
      );
    });

    test('returns.create alias alone does not unlock exchange', () {
      expect(
        PosPermissionAccess.canCreateExchange({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
        }),
        isTrue,
      );
      expect(
        PosPermissionAccess.canProcessExchange({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
        }),
        isFalse,
      );
    });
  });

  group('Exchange review context', () {
    test('requires persisted EXCHANGE resolution and replacement preview', () {
      const flow = ReturnFlowState(
        resolutionPersisted: true,
        selectedResolution: ReturnResolutionType.exchange,
      );

      expect(
        ReturnsRouteGuard.hasExchangeBranchContext(flow),
        isTrue,
      );
      expect(
        ReturnsRouteGuard.hasExchangeReviewContext(
          flow: flow,
          replacementPersisted: false,
          previewLoaded: false,
        ),
        isFalse,
      );
      expect(
        ReturnsRouteGuard.hasExchangeReviewContext(
          flow: flow,
          replacementPersisted: true,
          previewLoaded: true,
        ),
        isTrue,
      );
    });

    test('refund resolution blocks exchange review context', () {
      const flow = ReturnFlowState(
        resolutionPersisted: true,
        selectedResolution: ReturnResolutionType.refund,
      );

      expect(
        ReturnsRouteGuard.hasExchangeReviewContext(
          flow: flow,
          replacementPersisted: true,
          previewLoaded: true,
        ),
        isFalse,
      );
    });
  });

  group('Backend exchange preview mapping', () {
    test('maps customer pays direction', () {
      final presentation = exchangeDifferenceFromPreview(
        differenceDirection: 'CUSTOMER_PAYS',
        differenceAmount: 125.5,
        currencyCode: 'LKR',
      );

      expect(presentation.type, ExchangeDifferenceType.customerPays);
      expect(presentation.amount, 125.5);
      expect(presentation.currencyCode, 'LKR');
    });

    test('maps customer receives direction', () {
      final presentation = exchangeDifferenceFromPreview(
        differenceDirection: 'CUSTOMER_RECEIVES',
        differenceAmount: 40,
        currencyCode: 'LKR',
      );

      expect(presentation.type, ExchangeDifferenceType.customerRefund);
      expect(presentation.amount, 40);
    });

    test('maps even exchange direction', () {
      final presentation = exchangeDifferenceFromPreview(
        differenceDirection: 'EVEN_EXCHANGE',
        differenceAmount: 0,
        currencyCode: 'LKR',
      );

      expect(presentation.type, ExchangeDifferenceType.evenExchange);
      expect(presentation.amount, 0);
    });
  });

  group('Return exchange flow continue gating', () {
    test('continue disabled without persisted replacement or preview', () {
      const state = ReturnExchangeFlowState();
      expect(state.canContinue, isFalse);
    });

    test('continue enabled with persisted replacement and valid preview', () {
      final state = ReturnExchangeFlowState(
        replacementPersisted: true,
        savedReplacement: ReturnExchangeReplacementResponse(
          saleId: 'sale-1',
          selectedAt: DateTime.utc(2026, 7, 16),
          version: 3,
          items: const [
            ReturnExchangeReplacementItem(
              returnedSaleLineId: 'line-1',
              replacementProductId: 'prod-1',
              replacementVariantId: 'var-1',
              productName: 'Product',
              sku: 'SKU-1',
              quantity: 1,
              unitPrice: 200,
              lineTotal: 200,
              currencyCode: 'LKR',
              stockStatus: 'InStock',
            ),
          ],
        ),
        preview: const ReturnExchangePreview(
          saleId: 'sale-1',
          currencyCode: 'LKR',
          returnedItemCount: 1,
          returnItemValue: 100,
          replacementItemValue: 200,
          taxAdjustment: 0,
          discountAdjustment: 0,
          differenceAmount: 100,
          differenceDirection: 'CUSTOMER_PAYS',
          canProceed: true,
          requiresApproval: false,
          policyMessages: [],
          replacementItems: [],
        ),
      );

      expect(state.canContinue, isTrue);
    });
    test('continue disabled when preview cannot proceed', () {
      final state = ReturnExchangeFlowState(
        replacementPersisted: true,
        savedReplacement: ReturnExchangeReplacementResponse(
          saleId: 'sale-1',
          selectedAt: DateTime.utc(2026, 7, 16),
          version: 3,
          items: const [
            ReturnExchangeReplacementItem(
              returnedSaleLineId: 'line-1',
              replacementProductId: 'prod-1',
              replacementVariantId: 'var-1',
              productName: 'Product',
              sku: 'SKU-1',
              quantity: 2,
              unitPrice: 200,
              lineTotal: 400,
              currencyCode: 'LKR',
              stockStatus: 'InStock',
              availableQuantity: 5,
            ),
          ],
        ),
        preview: const ReturnExchangePreview(
          saleId: 'sale-1',
          currencyCode: 'LKR',
          returnedItemCount: 1,
          returnItemValue: 100,
          replacementItemValue: 400,
          taxAdjustment: 10,
          discountAdjustment: 5,
          differenceAmount: 300,
          differenceDirection: 'CUSTOMER_PAYS',
          canProceed: false,
          requiresApproval: true,
          policyMessages: ['Manager approval is required.'],
          replacementItems: [],
        ),
      );

      expect(state.canContinue, isFalse);
    });

    test('settlement code follows difference direction', () {
      expect(
        settlementCodeForExchangeDirection('CUSTOMER_PAYS'),
        'CASH_PAYMENT',
      );
      expect(
        settlementCodeForExchangeDirection('CUSTOMER_RECEIVES'),
        'CASH_REFUND',
      );
      expect(
        settlementCodeForExchangeDirection('EVEN_EXCHANGE'),
        'NO_SETTLEMENT',
      );
    });
  });

  group('Exchange product model', () {
    test('parses backend product search payload', () {
      final product = ReturnExchangeProduct.fromJson({
        'productId': 'prod-1',
        'variantId': 'var-1',
        'name': 'Replacement Product',
        'sku': 'SKU-1',
        'stockStatus': 'InStock',
        'availableQuantity': 5,
        'sellingPrice': 199.99,
        'currencyCode': 'LKR',
        'hasVariants': false,
        'enabled': true,
      });

      expect(product.productId, 'prod-1');
      expect(product.sellingPrice, 199.99);
      expect(product.isOutOfStock, isFalse);
      expect(product.selectionKey, 'prod-1::var-1');
    });
  });
}
