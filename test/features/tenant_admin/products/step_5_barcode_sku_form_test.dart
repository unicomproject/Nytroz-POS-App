import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/step_5/step_5_barcode_sku_form.dart';

void main() {
  testWidgets('Step 5 form renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Step5BarcodeSkuForm(),
          ),
        ),
      ),
    );

    // Verify UI components exist
    expect(find.text('Barcode & SKU'), findsOneWidget);
    expect(find.text('Base SKU *'), findsOneWidget);
    expect(find.text('Auto Generate'), findsOneWidget);
    expect(find.text('Parent Product Barcode (Optional)'), findsOneWidget);
    expect(find.text('Additional Barcodes'), findsOneWidget);
    expect(find.text('Add Additional Barcode'), findsOneWidget);
  });
}
