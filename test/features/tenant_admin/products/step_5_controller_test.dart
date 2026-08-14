import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/providers/tenant_product_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/step5_barcode_dtos.dart';

void main() {
  group('AddProductWizardController Step 5 Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('updateBaseSku updates state and marks dirty', () {
      final controller = container.read(addProductWizardControllerProvider.notifier);
      controller.updateBaseSku('NEW-SKU-123');

      final state = container.read(addProductWizardControllerProvider);
      expect(state.step5State.baseSku, 'NEW-SKU-123');
      expect(state.isDirty, true);
    });

    test('autoGenerateSku generates a SKU', () {
      final controller = container.read(addProductWizardControllerProvider.notifier);
      controller.updateInternalCode('TESTCODE');
      controller.autoGenerateSku();

      final state = container.read(addProductWizardControllerProvider);
      expect(state.step5State.baseSku, 'TESTCODE');
    });

    test('updateParentProductBarcode updates state', () {
      final controller = container.read(addProductWizardControllerProvider.notifier);
      controller.updateParentProductBarcode('1234567890');

      final state = container.read(addProductWizardControllerProvider);
      expect(state.step5State.parentProductBarcode, '1234567890');
      expect(state.isDirty, true);
    });

    test('addAdditionalBarcode adds barcode and handles primary', () {
      final controller = container.read(addProductWizardControllerProvider.notifier);
      
      controller.addAdditionalBarcode(
        const Step5AdditionalBarcodeDto(barcode: '111', barcodeType: 'EAN13', quantityPerScan: 1, isPrimary: true, status: 'ACTIVE')
      );
      
      var state = container.read(addProductWizardControllerProvider);
      expect(state.step5State.additionalBarcodes.length, 1);
      expect(state.step5State.additionalBarcodes[0].barcode, '111');
      expect(state.step5State.additionalBarcodes[0].isPrimary, true);

      // Add another primary, first should be demoted
      controller.addAdditionalBarcode(
        const Step5AdditionalBarcodeDto(barcode: '222', barcodeType: 'EAN13', quantityPerScan: 1, isPrimary: true, status: 'ACTIVE')
      );

      state = container.read(addProductWizardControllerProvider);
      expect(state.step5State.additionalBarcodes.length, 2);
      expect(state.step5State.additionalBarcodes[0].isPrimary, false);
      expect(state.step5State.additionalBarcodes[1].isPrimary, true);
    });

    test('removeAdditionalBarcode removes barcode', () {
      final controller = container.read(addProductWizardControllerProvider.notifier);
      
      controller.addAdditionalBarcode(
        const Step5AdditionalBarcodeDto(barcode: '111', barcodeType: 'EAN13', quantityPerScan: 1, isPrimary: false, status: 'ACTIVE')
      );
      controller.addAdditionalBarcode(
        const Step5AdditionalBarcodeDto(barcode: '222', barcodeType: 'EAN13', quantityPerScan: 1, isPrimary: false, status: 'ACTIVE')
      );

      controller.removeAdditionalBarcode(0);

      final state = container.read(addProductWizardControllerProvider);
      expect(state.step5State.additionalBarcodes.length, 1);
      expect(state.step5State.additionalBarcodes[0].barcode, '222');
    });

    test('updateVariantIdentifier updates existing or adds new', () {
      final controller = container.read(addProductWizardControllerProvider.notifier);
      
      controller.updateVariantIdentifier(
        const Step5VariantIdentifierDto(productVariantId: 'v1', sku: 'S1', barcode: 'B1')
      );

      var state = container.read(addProductWizardControllerProvider);
      expect(state.step5State.variantIdentifiers.length, 1);

      controller.updateVariantIdentifier(
        const Step5VariantIdentifierDto(productVariantId: 'v1', sku: 'S1-MOD', barcode: 'B1')
      );

      state = container.read(addProductWizardControllerProvider);
      expect(state.step5State.variantIdentifiers.length, 1);
      expect(state.step5State.variantIdentifiers[0].sku, 'S1-MOD');
    });
  });
}
