import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/step5_barcode_dtos.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/step_5/edit_variant_identifier_drawer.dart';

void main() {
  const variant = Step5VariantIdentifierDto(
    productVariantId: 'v1',
    sku: '741853595',
    barcode: '2000002222203333',
    barcodeType: 'EAN13',
  );

  Widget wrapDrawer({
    Step5VariantIdentifierDto dto = variant,
    Set<String> existingBarcodes = const {},
    Set<String> existingSkus = const {},
    ValueChanged<Step5VariantIdentifierDto>? onUpdate,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 440,
          height: 900,
          child: EditVariantIdentifierDrawer(
            variantDto: dto,
            displayLabel: 'AquaFlow Classic Water Bottle — Blue / 1L',
            existingBarcodes: existingBarcodes,
            existingSkus: existingSkus,
            onUpdate: onUpdate ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('edit drawer matches SKU & barcode layout', (tester) async {
    await tester.pumpWidget(wrapDrawer());

    expect(find.text('Edit Variant SKU & Barcode'), findsOneWidget);
    expect(
      find.text(
        'Update the SKU or barcode for this variant. Ensure the barcode is unique across all variants.',
      ),
      findsOneWidget,
    );
    expect(find.text('Variant (Read-only)'), findsOneWidget);
    expect(find.text('SKU'), findsOneWidget);
    expect(find.text('Barcode'), findsOneWidget);
    expect(find.text('Scan to Replace Barcode'), findsOneWidget);
    expect(find.text('Barcode is valid and unique.'), findsOneWidget);
    expect(
      find.text('This barcode is not used by any other variant.'),
      findsOneWidget,
    );
    expect(find.text('Barcode Type'), findsNothing);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
  });

  testWidgets('duplicate barcode shows error and disables Update',
      (tester) async {
    await tester.pumpWidget(wrapDrawer(
      existingBarcodes: const {'2000002222203333'},
    ));

    expect(find.text('Barcode is already in use.'), findsOneWidget);
    expect(
      find.text(
        'This barcode is assigned to another variant. Enter a unique barcode.',
      ),
      findsOneWidget,
    );

    final updateButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Update'),
    );
    expect(updateButton.onPressed, isNull);
  });

  testWidgets('Update saves edited SKU and barcode', (tester) async {
    Step5VariantIdentifierDto? updated;
    await tester.pumpWidget(wrapDrawer(
      onUpdate: (value) => updated = value,
    ));

    await tester.enterText(find.byType(TextFormField).at(1), 'SKU-NEW');
    await tester.enterText(find.byType(TextFormField).at(2), '999000111');
    await tester.pump();

    expect(find.text('Barcode is valid and unique.'), findsOneWidget);

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(updated, isNotNull);
    expect(updated!.sku, 'SKU-NEW');
    expect(updated!.barcode, '999000111');
  });
}
