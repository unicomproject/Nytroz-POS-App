import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/mappers/wizard_product_create_mapper.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/step5_barcode_dtos.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/step5_barcode_sku_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/utils/step_5_barcode_type.dart';

void main() {
  group('resolveBarcodeType', () {
    test('blank barcode does not require a type', () {
      expect(resolveBarcodeType(barcode: '', existingType: 'CODE128'), isNull);
      expect(resolveBarcodeType(barcode: null, existingType: null), isNull);
    });

    test('infers CODE128 when SIMPLE type is hidden and value is not a GTIN',
        () {
      expect(
        resolveBarcodeType(barcode: 't01-scan', existingType: null),
        kBarcodeTypeCode128,
      );
    });

    test('keeps an existing type that still matches the value', () {
      expect(
        resolveBarcodeType(
          barcode: 'HELLO-128',
          existingType: kBarcodeTypeCode128,
        ),
        kBarcodeTypeCode128,
      );
    });
  });

  test('validateBarcodeFormat requires type only when barcode is present', () {
    expect(validateBarcodeFormat(null, null), isNull);
    expect(validateBarcodeFormat('', null), isNull);
    expect(
      validateBarcodeFormat('ABC', null),
      'Barcode type is required when a barcode is provided.',
    );
    expect(validateBarcodeFormat('ABC', kBarcodeTypeCode128), isNull);
  });

  test('wizard-create payload includes inferred type for SIMPLE barcode', () {
    const state = AddProductWizardState(
      productName: 't-shirt',
      internalCode: 't01',
      productStructure: 'SIMPLE',
      step5State: Step5BarcodeSkuState(
        baseSku: 't01',
        parentProductBarcode: 't01-barcode',
      ),
    );

    final json = WizardProductCreateMapper.toWizardCreateJson(state);
    final config = json['barcodeSkuConfiguration'] as Map;
    final assignment = (config['assignments'] as List).first as Map;
    expect(assignment['barcode'], 't01-barcode');
    expect(assignment['barcodeType'], kBarcodeTypeCode128);
  });

  test(
      'wizard-create infers type from SIMPLE assignment when parent type is missing',
      () {
    const state = AddProductWizardState(
      productName: 't-shirt',
      internalCode: 't01',
      productStructure: 'SIMPLE',
      step5State: Step5BarcodeSkuState(
        baseSku: 't01',
        assignments: [
          BarcodeSkuAssignmentDto(
            clientCombinationKey: 'SIMPLE_DEFAULT',
            sku: 't01',
            barcode: 'scan-me',
          ),
        ],
      ),
    );

    final json = WizardProductCreateMapper.toWizardCreateJson(state);
    final assignment =
        ((json['barcodeSkuConfiguration'] as Map)['assignments'] as List)
            .first as Map;
    expect(assignment['barcode'], 'scan-me');
    expect(assignment['barcodeType'], kBarcodeTypeCode128);
  });
}
