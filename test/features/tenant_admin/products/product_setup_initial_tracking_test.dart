import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/mappers/wizard_product_create_mapper.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state_codec.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/product_wizard_capabilities.dart';

void main() {
  test('Initial tracking fields survive copyWith and codec round-trip', () {
    final expiry = DateTime(2027, 6, 30);
    final state = AddProductWizardState(
      productName: 'Tea',
      initialBatchNumber: 'BAT-2026-0001',
      initialExpiryDate: expiry,
      initialSerialNumber: 'SN-1',
    );

    final copied = state.copyWith(initialBatchNumber: 'BAT-2');
    expect(copied.initialBatchNumber, 'BAT-2');
    expect(copied.initialExpiryDate, expiry);

    final json = AddProductWizardStateCodec.toJson(state);
    final restored = AddProductWizardStateCodec.fromJson(json);
    expect(restored.initialBatchNumber, 'BAT-2026-0001');
    expect(restored.initialSerialNumber, 'SN-1');
    expect(restored.initialExpiryDate?.year, 2027);
  });

  test('Step 2 serial tracking requires confirmation before clearing batch', () {
    final plan = InitialTrackingCompatibility.evaluate(
      productStructure: 'SIMPLE',
      trackInventory: true,
      batchTracking: false,
      expiryTracking: false,
      serialTracking: true,
      batch: 'BAT-1',
      expiry: DateTime(2027, 6, 30),
      serial: 'SN-1',
    );

    expect(plan.requiresConfirmation, isTrue);
    expect(plan.batchNumber, isNull);
    expect(plan.serialNumber, 'SN-1');
  });

  test('Wizard create mapper includes initial tracking and omits cost without permission', () {
    final state = AddProductWizardState(
      productName: 'Tea',
      categoryId: '11111111-1111-1111-1111-111111111111',
      initialBatchNumber: 'BAT-1',
      costPrice: 12,
      standardSellingPrice: 20,
      taxId: '22222222-2222-2222-2222-222222222222',
    );

    final json = WizardProductCreateMapper.toWizardCreateJson(
      state,
      capabilities: const ProductWizardCapabilities(
        canViewProduct: true,
        canCreateProduct: true,
        canUpdateProduct: true,
        canPublishProduct: true,
        canManageProductMedia: true,
        canManageProductChannels: true,
        canManageVariants: true,
        canManageBundleComponents: false,
        canManageBarcodes: true,
        canManagePricing: true,
        canViewProductCost: false,
        canLookupTaxClasses: true,
        canViewStock: false,
        canUseAdvancedInventoryTracking: true,
      ),
    );

    expect(json['initialBatchNumber'], 'BAT-1');
    expect((json['pricingTax'] as Map)['costPrice'], isNull);
  });
}
