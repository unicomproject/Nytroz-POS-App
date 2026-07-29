import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_sale_eligibility.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_eligibility_provider.dart';

ReturnSaleLineEligibility _line({
  required String id,
  required String name,
  required String sku,
  String? barcode,
  String variantId = 'variant-guid',
  bool isReturnable = true,
  double available = 2,
  double unitPrice = 100,
  String? reason,
}) {
  return ReturnSaleLineEligibility(
    saleLineId: id,
    variantId: variantId,
    name: name,
    sku: sku,
    barcode: barcode,
    soldQty: available + 1,
    returnedQty: 1,
    availableReturnQty: available,
    unitPrice: unitPrice,
    lineTotal: unitPrice * (available + 1),
    isReturnable: isReturnable,
    eligibilityStatus: isReturnable ? 'ELIGIBLE' : 'WINDOW_EXPIRED',
    ineligibilityReason: reason,
  );
}

void main() {
  group('filterReturnEligibilityItems', () {
    final items = [
      _line(id: '1', name: 'Match Shorts', sku: 'MER-003', barcode: '8901001'),
      _line(
        id: '2',
        name: 'Jersey',
        sku: 'MER-001',
        barcode: null,
        variantId: 'cccc0005-0003-4000-8000-000000000001',
        isReturnable: false,
        available: 1,
        reason: 'Return window expired',
      ),
    ];

    test('matches product name and SKU', () {
      expect(
        filterReturnEligibilityItems(items,
            query: 'shorts', returnableOnly: false),
        hasLength(1),
      );
      expect(
        filterReturnEligibilityItems(items,
                query: 'mer-001', returnableOnly: false)
            .single
            .sku,
        'MER-001',
      );
    });

    test('matches barcode and never treats variantId as barcode', () {
      expect(
        filterReturnEligibilityItems(items,
            query: '8901001', returnableOnly: false),
        hasLength(1),
      );
      expect(
        filterReturnEligibilityItems(
          items,
          query: 'cccc0005-0003-4000-8000-000000000001',
          returnableOnly: false,
        ),
        isEmpty,
      );
    });

    test('returnable-only filter excludes non-selectable lines', () {
      expect(
        filterReturnEligibilityItems(items, query: '', returnableOnly: true),
        hasLength(1),
      );
    });
  });

  group('ReturnSaleLineEligibility.isSelectable', () {
    test('requires isReturnable and positive remaining qty', () {
      expect(
        _line(id: 'a', name: 'A', sku: 'A', isReturnable: false, available: 2)
            .isSelectable,
        isFalse,
      );
      expect(
        _line(id: 'b', name: 'B', sku: 'B', isReturnable: true, available: 0)
            .isSelectable,
        isFalse,
      );
      expect(
        _line(id: 'c', name: 'C', sku: 'C', isReturnable: true, available: 1)
            .isSelectable,
        isTrue,
      );
    });
  });

  group('ReturnEligibilityState selection math', () {
    test('excludes non-returnable and zero-qty lines from count and estimate',
        () {
      final eligible =
          _line(id: '1', name: 'A', sku: 'A', available: 2, unitPrice: 50);
      final blocked = _line(
        id: '2',
        name: 'B',
        sku: 'B',
        isReturnable: false,
        available: 3,
        unitPrice: 80,
      );
      final state = ReturnEligibilityState(
        eligibility: ReturnSaleEligibility(
          saleId: 'sale',
          invoiceNo: 'INV',
          customerName: 'Cust',
          paymentMethod: 'Cash',
          maskedCard: '',
          currency: 'LKR',
          items: [eligible, blocked],
          policyChecks: const [],
        ),
        selections: {
          '1': const ReturnLineSelection(
            saleLineId: '1',
            isSelected: true,
            returnQty: 2,
          ),
          '2': const ReturnLineSelection(
            saleLineId: '2',
            isSelected: true,
            returnQty: 1,
          ),
        },
      );

      expect(state.selectedItemCount, 1);
      expect(state.estimatedReturnValue, 100);
      expect(state.selectedItems.single.saleLineId, '1');
    });

    test(
        'header selection state covers none/partial/all for visible eligible lines',
        () {
      final a = _line(id: '1', name: 'A', sku: 'A');
      final b = _line(id: '2', name: 'B', sku: 'B');
      final blocked = _line(id: '3', name: 'C', sku: 'C', isReturnable: false);
      final base = ReturnEligibilityState(
        eligibility: ReturnSaleEligibility(
          saleId: 'sale',
          invoiceNo: 'INV',
          customerName: 'Cust',
          paymentMethod: 'Cash',
          maskedCard: '',
          currency: 'LKR',
          items: [a, b, blocked],
          policyChecks: const [],
        ),
        selections: {
          '1': const ReturnLineSelection(
            saleLineId: '1',
            isSelected: false,
            returnQty: 0,
          ),
          '2': const ReturnLineSelection(
            saleLineId: '2',
            isSelected: false,
            returnQty: 0,
          ),
          '3': const ReturnLineSelection(
            saleLineId: '3',
            isSelected: false,
            returnQty: 0,
          ),
        },
      );

      expect(
        base.headerSelectionStateFor([a, b, blocked]),
        HeaderSelectionState.none,
      );

      final partial = base.copyWith(
        selections: {
          ...base.selections,
          '1': const ReturnLineSelection(
            saleLineId: '1',
            isSelected: true,
            returnQty: 1,
          ),
        },
      );
      expect(
        partial.headerSelectionStateFor([a, b, blocked]),
        HeaderSelectionState.partial,
      );

      final all = base.copyWith(
        selections: {
          '1': const ReturnLineSelection(
            saleLineId: '1',
            isSelected: true,
            returnQty: 1,
          ),
          '2': const ReturnLineSelection(
            saleLineId: '2',
            isSelected: true,
            returnQty: 1,
          ),
          '3': const ReturnLineSelection(
            saleLineId: '3',
            isSelected: false,
            returnQty: 0,
          ),
        },
      );
      expect(
        all.headerSelectionStateFor([a, b, blocked]),
        HeaderSelectionState.all,
      );
    });
  });

  group('ReturnSaleEligibility barcode parsing', () {
    test('fromJson maps barcode', () {
      final line = ReturnSaleLineEligibility.fromJson({
        'saleLineId': '1306a674-82af-4d1e-a481-ee03b8999e1a',
        'variantId': 'cccc0005-0003-4000-8000-000000000001',
        'name': 'Match Shorts',
        'sku': 'MER-003-S',
        'barcode': '8901001',
        'soldQty': 1,
        'returnedQty': 0,
        'availableReturnQty': 1,
        'unitPrice': 2800,
        'lineTotal': 2800,
        'isReturnable': true,
        'eligibilityStatus': 'ELIGIBLE',
      });
      expect(line.barcode, '8901001');
      expect(line.isSelectable, isTrue);
    });
  });
}
