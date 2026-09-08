import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/step5_barcode_dtos.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/step4_variant_configuration_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/step5_barcode_sku_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/step_7/product_created_success.dart';

void main() {
  testWidgets('success screen shows create summary and actions', (tester) async {
    var viewed = false;
    var another = false;
    var back = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductCreatedSuccess(
            snapshot: ProductCreateSuccessSnapshot(
              productId: 'prod-1',
              productName: 'AquaFlow Classic Water Bottle',
              productCode: 'AQF-BTL',
              sku: 'AQF-BTL-001',
              status: 'ACTIVE',
              productStructure: 'VARIANT',
              totalSkus: 6,
              totalVariants: 6,
              createdAt: DateTime(2026, 9, 4, 16, 24),
            ),
            onViewProduct: () => viewed = true,
            onAddAnother: () => another = true,
            onBackToProducts: () => back = true,
          ),
        ),
      ),
    );

    expect(find.text('Product Created Successfully!'), findsOneWidget);
    expect(find.text('AquaFlow Classic Water Bottle'), findsWidgets);
    expect(find.text('Variant Product'), findsOneWidget);
    expect(find.text('Total Variants'), findsOneWidget);
    expect(find.text('View Product'), findsOneWidget);
    expect(find.text('Add Another Product'), findsOneWidget);
    expect(find.text('Back to Products'), findsOneWidget);
    expect(find.text('Product created successfully'), findsNothing);

    await tester.tap(find.text('View Product'));
    expect(viewed, isTrue);

    await tester.tap(find.text('Add Another Product'));
    expect(another, isTrue);

    await tester.ensureVisible(find.text('Back to Products'));
    await tester.tap(find.text('Back to Products'));
    expect(back, isTrue);
  });

  testWidgets('SIMPLE success hides Total Variants', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductCreatedSuccess(
            snapshot: ProductCreateSuccessSnapshot(
              productId: 'prod-2',
              productName: 'Plain Tee',
              productCode: 'TEE-1',
              sku: 'TEE-SKU',
              status: 'ACTIVE',
              productStructure: 'SIMPLE',
              totalSkus: 1,
              createdAt: DateTime(2026, 9, 4, 16, 24),
            ),
            onViewProduct: () {},
            onAddAnother: () {},
            onBackToProducts: () {},
          ),
        ),
      ),
    );

    expect(find.text('Simple Product'), findsOneWidget);
    expect(find.text('Total Variants'), findsNothing);
    expect(find.text('SKU'), findsOneWidget);
  });

  test('fromWizard maps VARIANT counts from wizard state', () {
    const variant = GeneratedVariantRow(
      clientCombinationKey: 'k1',
      combinationLabel: 'Blue / 500ml',
      isIncluded: true,
    );
    final state = AddProductWizardState(
      productId: 'prod-9',
      productName: 'Bottle',
      internalCode: 'AQF-BTL',
      productStructure: 'VARIANT',
      status: 'ACTIVE',
      step4State: const Step4VariantConfigurationState(
        generatedVariants: [variant],
      ),
      step5State: const Step5BarcodeSkuState(
        assignments: [
          BarcodeSkuAssignmentDto(
            clientCombinationKey: 'k1',
            sku: 'AQF-BTL-001',
            isAssigned: true,
          ),
        ],
      ),
    );

    final snap = ProductCreateSuccessSnapshot.fromWizard(state);
    expect(snap.productId, 'prod-9');
    expect(snap.isVariant, isTrue);
    expect(snap.totalVariants, 1);
    expect(snap.totalSkus, 1);
    expect(snap.productTypeLabel, 'Variant Product');
  });
}
