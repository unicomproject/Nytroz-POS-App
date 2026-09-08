import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/mappers/wizard_product_create_mapper.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/step5_barcode_dtos.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/step6_pricing_tax_dtos.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/step4_variant_configuration_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/step5_barcode_sku_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/utils/step_6_variant_pricing.dart';

GeneratedVariantRow _v({
  required String key,
  required String label,
  String? id,
  bool included = true,
}) {
  return GeneratedVariantRow(
    clientCombinationKey: key,
    productVariantId: id,
    combinationLabel: label,
    displayLabel: label,
    isIncluded: included,
  );
}

BarcodeSkuAssignmentDto _sku(String key, String sku) {
  return BarcodeSkuAssignmentDto(
    clientCombinationKey: key,
    sku: sku,
    isAssigned: true,
  );
}

AddProductWizardState _variantState({
  required List<GeneratedVariantRow> variants,
  List<VariantPriceDto> prices = const [],
  List<BarcodeSkuAssignmentDto> assignments = const [],
  String? taxId = 'tax-1',
  bool taxExclusive = true,
}) {
  return AddProductWizardState(
    productStructure: 'VARIANT',
    productName: 'AquaFlow Classic Water Bottle',
    taxId: taxId,
    taxExclusive: taxExclusive,
    variantPrices: prices,
    step4State: Step4VariantConfigurationState(generatedVariants: variants),
    step5State: Step5BarcodeSkuState(assignments: assignments),
  );
}

void main() {
  group('reconcile + derived status', () {
    test('UI-03/04 included only; excluded omitted', () {
      final state = _variantState(
        variants: [
          _v(key: 'a', label: 'Blue / 500ml'),
          _v(key: 'b', label: 'Blue / 1L'),
          _v(key: 'c', label: 'Black / 500ml', included: false),
        ],
        prices: const [
          VariantPriceDto(clientCombinationKey: 'a', sellingPrice: 750),
          VariantPriceDto(clientCombinationKey: 'c', sellingPrice: 999),
        ],
      );
      final rows = buildVariantPricingRows(state: state);
      expect(rows.length, 2);
      expect(rows.map((r) => r.clientCombinationKey), ['a', 'b']);
      expect(rows.any((r) => r.clientCombinationKey == 'c'), isFalse);
    });

    test('UI-05 SKU from Step 5', () {
      final state = _variantState(
        variants: [_v(key: 'a', label: 'Blue / 500ml')],
        assignments: [_sku('a', '741853595-500B')],
      );
      final rows = buildVariantPricingRows(state: state);
      expect(rows.single.sku, '741853595-500B');
    });

    test('UI-06/07 independent prices', () {
      final state = _variantState(
        variants: [
          _v(key: 'a', label: 'A'),
          _v(key: 'b', label: 'B'),
        ],
        prices: const [
          VariantPriceDto(clientCombinationKey: 'a', sellingPrice: 750),
          VariantPriceDto(clientCombinationKey: 'b', sellingPrice: 620),
        ],
      );
      final rows = buildVariantPricingRows(state: state);
      expect(rows[0].sellingPrice, 750);
      expect(rows[1].sellingPrice, 620);
    });

    test('UI-10..14 derived priced/pending/range', () {
      final empty = deriveVariantPricingStatus(
        buildVariantPricingRows(
          state: _variantState(
            variants: [
              _v(key: 'a', label: 'A'),
              _v(key: 'b', label: 'B'),
            ],
          ),
        ),
      );
      expect(empty.priced, 0);
      expect(empty.pending, 2);
      expect(empty.priceRangeLabel('LKR'), '—');

      final one = deriveVariantPricingStatus(
        buildVariantPricingRows(
          state: _variantState(
            variants: [
              _v(key: 'a', label: 'A'),
              _v(key: 'b', label: 'B'),
            ],
            prices: const [
              VariantPriceDto(clientCombinationKey: 'a', sellingPrice: 650),
            ],
          ),
        ),
      );
      expect(one.priced, 1);
      expect(one.pending, 1);
      expect(one.priceRangeLabel('LKR'), 'LKR 650.00');

      final range = deriveVariantPricingStatus(
        buildVariantPricingRows(
          state: _variantState(
            variants: [
              _v(key: 'a', label: 'A'),
              _v(key: 'b', label: 'B'),
              _v(key: 'c', label: 'C'),
              _v(key: 'd', label: 'D'),
              _v(key: 'e', label: 'E'),
              _v(key: 'f', label: 'F'),
            ],
            prices: const [
              VariantPriceDto(clientCombinationKey: 'a', sellingPrice: 750),
              VariantPriceDto(clientCombinationKey: 'b', sellingPrice: 650),
              VariantPriceDto(clientCombinationKey: 'c', sellingPrice: 620),
              VariantPriceDto(clientCombinationKey: 'd', sellingPrice: 680),
            ],
          ),
        ),
      );
      expect(range.priced, 4);
      expect(range.pending, 2);
      expect(range.priceRangeLabel('LKR'), 'LKR 620.00 – LKR 750.00');
    });

    test('REC-UI preserve by identity; new pending; exclude removed', () {
      final existing = const [
        VariantPriceDto(
          productVariantId: 'id-a',
          clientCombinationKey: 'a',
          sellingPrice: 750,
        ),
        VariantPriceDto(
          productVariantId: 'id-b',
          clientCombinationKey: 'b',
          sellingPrice: 650,
        ),
        VariantPriceDto(
          productVariantId: 'id-c',
          clientCombinationKey: 'c',
          sellingPrice: 700,
        ),
      ];
      final after = reconcileVariantPricesWithIncluded(
        includedVariants: [
          _v(key: 'a', label: 'Blue / 500ml', id: 'id-a'),
          _v(key: 'b', label: 'Renamed Only', id: 'id-b'),
          _v(key: 'd', label: 'New', id: 'id-d'),
        ],
        existingPrices: existing,
      );
      expect(after.length, 3);
      expect(
        after.firstWhere((p) => p.clientCombinationKey == 'a').sellingPrice,
        750,
      );
      expect(
        after.firstWhere((p) => p.clientCombinationKey == 'b').sellingPrice,
        650,
      );
      expect(
        after.firstWhere((p) => p.clientCombinationKey == 'd').sellingPrice,
        isNull,
      );
      expect(after.any((p) => p.clientCombinationKey == 'c'), isFalse);
    });

    test('maps variantPrices[n] server error to submitted identity', () {
      final snapshot = const [
        VariantPriceDto(
          productVariantId: 'id-a',
          clientCombinationKey: 'a',
          sellingPrice: 750,
        ),
        VariantPriceDto(clientCombinationKey: 'b', sellingPrice: null),
      ];
      final mapped = mapVariantPriceServerFieldErrors(
        submittedSnapshot: snapshot,
        errorBody: {
          'details': [
            {
              'field': 'pricingTax.variantPrices[1].sellingPrice',
              'message': 'Selling price is required.',
            },
          ],
        },
      );
      expect(mapped['variantPrice:key:b'], 'Selling price is required.');
    });

    test('REH-02 response order does not shuffle by identity', () {
      final state = _variantState(
        variants: [
          _v(key: 'a', label: 'A', id: 'id-a'),
          _v(key: 'b', label: 'B', id: 'id-b'),
          _v(key: 'c', label: 'C', id: 'id-c'),
        ],
        prices: const [
          VariantPriceDto(
            productVariantId: 'id-c',
            clientCombinationKey: 'c',
            sellingPrice: null,
          ),
          VariantPriceDto(
            productVariantId: 'id-a',
            clientCombinationKey: 'a',
            sellingPrice: 750,
          ),
          VariantPriceDto(
            productVariantId: 'id-b',
            clientCombinationKey: 'b',
            sellingPrice: 650,
          ),
        ],
      );
      final rows = buildVariantPricingRows(state: state);
      expect(rows[0].sellingPrice, 750);
      expect(rows[1].sellingPrice, 650);
      expect(rows[2].sellingPrice, isNull);
      expect(rows[2].isPriced, isFalse);
    });
  });

  group('serialization', () {
    test('SER-01..03 full snapshot keeps null sellingPrice', () {
      final state = _variantState(
        variants: [
          _v(key: 'a', label: 'A', id: 'id-a'),
          _v(key: 'b', label: 'B'),
        ],
        prices: const [
          VariantPriceDto(
            productVariantId: 'id-a',
            clientCombinationKey: 'a',
            sellingPrice: 750,
          ),
          VariantPriceDto(clientCombinationKey: 'b', sellingPrice: null),
        ],
      );
      final snapshot = buildVariantPriceSnapshot(state);
      expect(snapshot.length, 2);
      final json = snapshot.map((e) => e.toSnapshotJson()).toList();
      expect(json[0]['sellingPrice'], 750);
      expect(json[0]['productVariantId'], 'id-a');
      expect(json[1].containsKey('sellingPrice'), isTrue);
      expect(json[1]['sellingPrice'], isNull);
      expect(json[1]['clientCombinationKey'], 'b');
    });

    test('SER-04 SIMPLE omits variantPrices', () {
      final dto = WizardProductCreateMapper.toWizardCreateJson(
        const AddProductWizardState(
          productStructure: 'SIMPLE',
          productName: 'Simple',
          categoryId: '00000000-0000-0000-0000-000000000001',
          baseUnitId: '00000000-0000-0000-0000-000000000002',
          standardSellingPrice: 100,
          taxId: 'tax-1',
        ),
      );
      final pricing = dto['pricingTax'] as Map<String, dynamic>;
      expect(pricing.containsKey('variantPrices'), isFalse);
      expect(pricing['standardSellingPrice'], 100);
    });

    test('SER-05..08 VARIANT snapshot; no helper default; no scalar authority',
        () {
      final state = _variantState(
        variants: [
          _v(key: 'a', label: 'A'),
          _v(key: 'b', label: 'B'),
        ],
        prices: const [
          VariantPriceDto(clientCombinationKey: 'a', sellingPrice: 650),
          VariantPriceDto(clientCombinationKey: 'b', sellingPrice: null),
        ],
      ).copyWith(
        productName: 'AquaFlow',
        categoryId: '00000000-0000-0000-0000-000000000001',
        standardSellingPrice: 999, // must not become VARIANT authority
      );
      final dto = WizardProductCreateMapper.toWizardCreateJson(state);
      final pricing = dto['pricingTax'] as Map<String, dynamic>;
      expect(pricing.containsKey('standardSellingPrice'), isFalse);
      expect(pricing.containsKey('defaultVariantSellingPrice'), isFalse);
      expect(pricing.containsKey('bulkSellingPrice'), isFalse);
      expect(pricing.containsKey('setSamePriceForAll'), isFalse);
      expect(pricing.containsKey('applyToAll'), isFalse);
      final variants = pricing['variantPrices'] as List;
      expect(variants.length, 2);
      expect(variants[1]['sellingPrice'], isNull);
      expect((variants[1] as Map).containsKey('sellingPrice'), isTrue);
    });
  });
}
