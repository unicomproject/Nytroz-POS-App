import os
import re

file_path = 'test/features/tenant_admin/products/add_product_wizard_chunk3_simple_test.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace goToStep5Simple definition
old_goto = """  Future<void> goToStep5Simple({bool trackInventory = true}) async {
    await controller.initWizard();
    controller.skipScanStepForTesting();
    controller.updateProductName('Simple Widget');
    controller.updateCategory('cat-1');
    controller.updateInternalCode('SW-001');
    await controller.saveAndContinue();
    controller.setProductStructure('SIMPLE');
    controller.setTrackInventory(trackInventory);
    await controller.saveAndContinue();
    if (trackInventory) {
      expect(controller.wizardState.currentStep, 4);
      controller.selectUnitModel('SINGLE_UNIT');
      controller.setProductUnit('unit-1');
      await controller.saveAndContinue();
    }
    expect(controller.wizardState.currentStep, 5);
  }"""

new_goto = """  Future<void> goToStep3Configuration() async {
    await controller.initWizard();
    controller.skipScanStepForTesting();
    controller.updateProductName('Simple Widget');
    controller.updateCategory('cat-1');
    controller.updateInternalCode('SW-001');
    await controller.saveAndContinue();
    controller.setProductStructure('SIMPLE');
    controller.selectUnitModel('SINGLE_UNIT');
    controller.setProductUnit('unit-1');
  }

  Future<void> goToStep4Pricing() async {
    await goToStep3Configuration();
    controller.updateSimpleBaseSku('TEST-SIMPLE-001');
    await controller.saveAndContinue();
    expect(controller.wizardState.currentStep, 4);
  }

  Future<void> goToStep5Tracking() async {
    await goToStep4Pricing();
    controller.updateCostPrice(100);
    controller.updateStandardSellingPrice(150);
    controller.updateTaxId('tax-1', taxRate: 15, taxName: 'VAT 15%');
    await controller.saveAndContinue();
    expect(controller.wizardState.currentStep, 5);
  }"""

content = content.replace(old_goto, new_goto)

# We will apply a set of regular expression replacements to cleanly fix the test bodies
replacements = [
    (r"test\('1\. SIMPLE Track ON → Step 4', \(\) async \{\s+await controller\.initWizard\(\);\s+controller\.skipScanStepForTesting\(\);\s+controller\.updateProductName\('A'\);\s+controller\.updateCategory\('cat-1'\);\s+controller\.updateInternalCode\('code-1'\);\s+await controller\.saveAndContinue\(\);\s+controller\.setProductStructure\('SIMPLE'\);\s+controller\.setTrackInventory\(true\);\s+await controller\.saveAndContinue\(\);\s+expect\(controller\.wizardState\.currentStep, 4\);\s+\}\);",
     "test('1. SIMPLE Track ON → Step 4', () async {\n      await controller.initWizard();\n      controller.skipScanStepForTesting();\n      controller.updateProductName('A');\n      controller.updateCategory('cat-1');\n      controller.updateInternalCode('code-1');\n      await controller.saveAndContinue();\n      controller.setProductStructure('SIMPLE');\n      controller.selectUnitModel('SINGLE_UNIT');\n      controller.setProductUnit('unit-1');\n      await controller.saveAndContinue();\n      expect(controller.wizardState.currentStep, 4);\n    });"),

    (r"test\('2\. SIMPLE Track OFF → Step 5', \(\) async \{\s+await controller\.initWizard\(\);\s+controller\.skipScanStepForTesting\(\);\s+controller\.updateProductName\('A'\);\s+controller\.updateCategory\('cat-1'\);\s+controller\.updateInternalCode\('code-2'\);\s+await controller\.saveAndContinue\(\);\s+controller\.setProductStructure\('SIMPLE'\);\s+controller\.setTrackInventory\(false\);\s+await controller\.saveAndContinue\(\);\s+expect\(controller\.wizardState\.currentStep, 5\);\s+\}\);",
     "test('2. SIMPLE Track OFF → Step 4', () async {\n      await controller.initWizard();\n      controller.skipScanStepForTesting();\n      controller.updateProductName('A');\n      controller.updateCategory('cat-1');\n      controller.updateInternalCode('code-2');\n      await controller.saveAndContinue();\n      controller.setProductStructure('SIMPLE');\n      controller.selectUnitModel('SINGLE_UNIT');\n      controller.setProductUnit('unit-1');\n      await controller.saveAndContinue();\n      expect(controller.wizardState.currentStep, 4);\n    });"),

    (r"test\('3\. Step 3 → Step 5 \(skips Step 4\)', \(\) async \{\s+await goToStep5Simple\(trackInventory: false\);\s+expect\(controller\.isStepApplicable\(4\), isFalse\);\s+expect\(controller\.wizardState\.currentStep, 5\);\s+\}\);",
     "test('3. Step 3 → Step 4', () async {\n      await goToStep3Configuration();\n      controller.updateSimpleBaseSku('TEST-SIMPLE-001');\n      await controller.saveAndContinue();\n      expect(controller.wizardState.currentStep, 4);\n    });"),

    (r"test\('5\. SIMPLE Step 5 does not require ProductVariantId', \(\) async \{\s+await goToStep5Simple\(\);\s+controller\.updateSimpleBaseSku\('TEST-SIMPLE-001'\);\s+controller\.updateSimpleParentBarcode\('8901234567890'\);\s+await controller\.saveAndContinue\(\);\s+final assignment = controller\.wizardState\.step5State\.assignments\.first;\s+expect\(assignment\.productVariantId, isNull\);\s+expect\(assignment\.sku, 'TEST-SIMPLE-001'\);\s+expect\(controller\.wizardState\.productId, isNull\);\s+\}\);",
     "test('5. SIMPLE Step 3 does not require ProductVariantId', () async {\n      await goToStep3Configuration();\n      controller.updateSimpleBaseSku('TEST-SIMPLE-001');\n      controller.updateSimpleParentBarcode('8901234567890');\n      await controller.saveAndContinue();\n      final assignment = controller.wizardState.step5State.assignments.first;\n      expect(assignment.productVariantId, isNull);\n      expect(assignment.sku, 'TEST-SIMPLE-001');\n      expect(controller.wizardState.productId, isNull);\n    });"),

    (r"test\('6\. Step 5 Save & Continue â†’ Step 6', \(\) async \{\s+await goToStep5Simple\(\);\s+controller\.updateSimpleBaseSku\('TEST-SIMPLE-001'\);\s+expect\(await controller\.saveAndContinue\(\), isTrue\);\s+expect\(controller\.wizardState\.currentStep, 6\);\s+\}\);",
     "test('6. Step 3 Save & Continue → Step 4', () async {\n      await goToStep3Configuration();\n      controller.updateSimpleBaseSku('TEST-SIMPLE-001');\n      expect(await controller.saveAndContinue(), isTrue);\n      expect(controller.wizardState.currentStep, 4);\n    });"),

    (r"test\('7\. Step 5 Back → Step 4', \(\) async \{\s+await goToStep5Simple\(\);\s+controller\.goToPreviousApplicableStep\(\);\s+expect\(controller\.wizardState\.currentStep, 4\);\s+\}\);",
     "test('7. Step 3 Back → Step 2', () async {\n      await goToStep3Configuration();\n      controller.goToPreviousApplicableStep();\n      expect(controller.wizardState.currentStep, 2);\n    });"),

    (r"test\('8\. Step 5 values survive Back/Forward', \(\) async \{\s+await goToStep5Simple\(\);\s+controller\.updateSimpleBaseSku\('TEST-SIMPLE-001'\);\s+controller\.updateSimpleParentBarcode\('8901234567890'\);\s+controller\.goToPreviousApplicableStep\(\); // → 4\s+expect\(controller\.wizardState\.productUnitId, 'unit-1'\);\s+expect\(await controller\.saveAndContinue\(\), isTrue\); // â†’ 5\s+expect\(controller\.wizardState\.step5State\.baseSku, 'TEST-SIMPLE-001'\);\s+expect\(\s+controller\.wizardState\.step5State\.parentProductBarcode, '8901234567890'\);\s+\}\);",
     "test('8. Step 3 values survive Back/Forward', () async {\n      await goToStep3Configuration();\n      controller.updateSimpleBaseSku('TEST-SIMPLE-001');\n      controller.updateSimpleParentBarcode('8901234567890');\n      controller.goToPreviousApplicableStep(); // → 2\n      expect(await controller.saveAndContinue(), isTrue); // → 3\n      expect(controller.wizardState.step5State.baseSku, 'TEST-SIMPLE-001');\n      expect(\n          controller.wizardState.step5State.parentProductBarcode, '8901234567890');\n    });"),

    (r"test\('10\. Tax selection populates rate and name', \(\) async \{\s+await goToStep5Simple\(\);\s+controller\.updateSimpleBaseSku\('SKU-1'\);\s+await controller\.saveAndContinue\(\);\s+controller\.updateTaxId\('tax-1', taxRate: 15, taxName: 'VAT 15%'\);\s+expect\(controller\.wizardState\.taxId, 'tax-1'\);\s+expect\(controller\.wizardState\.taxRate, 15\);\s+expect\(controller\.wizardState\.taxName, 'VAT 15%'\);\s+\}\);",
     "test('10. Tax selection populates rate and name', () async {\n      await goToStep4Pricing();\n      controller.updateTaxId('tax-1', taxRate: 15, taxName: 'VAT 15%');\n      expect(controller.wizardState.taxId, 'tax-1');\n      expect(controller.wizardState.taxRate, 15);\n      expect(controller.wizardState.taxName, 'VAT 15%');\n    });"),

    (r"test\('11\. Step 6 Save & Continue â†’ Step 7', \(\) async \{\s+await goToStep5Simple\(\);\s+controller\.updateSimpleBaseSku\('TEST-SIMPLE-001'\);\s+await controller\.saveAndContinue\(\);\s+controller\.updateCostPrice\(100\);\s+controller\.updateStandardSellingPrice\(150\);\s+controller\.updateDiscountPrice\(140\);\s+controller\.updateTaxId\('tax-1', taxRate: 15, taxName: 'VAT 15%'\);\s+expect\(await controller\.saveAndContinue\(\), isTrue\);\s+expect\(controller\.wizardState\.currentStep, 7\);\s+\}\);",
     "test('11. Step 4 Save & Continue → Step 5', () async {\n      await goToStep4Pricing();\n      controller.updateCostPrice(100);\n      controller.updateStandardSellingPrice(150);\n      controller.updateDiscountPrice(140);\n      controller.updateTaxId('tax-1', taxRate: 15, taxName: 'VAT 15%');\n      expect(await controller.saveAndContinue(), isTrue);\n      expect(controller.wizardState.currentStep, 5);\n    });"),

    (r"test\('12\. Step 6 values survive Back/Forward', \(\) async \{\s+await goToStep5Simple\(\);\s+controller\.updateSimpleBaseSku\('TEST-SIMPLE-001'\);\s+await controller\.saveAndContinue\(\);\s+controller\.updateCostPrice\(100\);\s+controller\.updateStandardSellingPrice\(150\);\s+controller\.updateDiscountPrice\(140\);\s+controller\.updateTaxId\('tax-1', taxRate: 15, taxName: 'VAT 15%'\);\s+controller\.goToPreviousApplicableStep\(\); // â†’ 5\s+expect\(await controller\.saveAndContinue\(\), isTrue\); // â†’ 6\s+expect\(controller\.wizardState\.costPrice, 100\);\s+expect\(controller\.wizardState\.standardSellingPrice, 150\);\s+expect\(controller\.wizardState\.discountPrice, 140\);\s+expect\(controller\.wizardState\.taxId, 'tax-1'\);\s+expect\(controller\.wizardState\.taxRate, 15\);\s+\}\);",
     "test('12. Step 4 values survive Back/Forward', () async {\n      await goToStep4Pricing();\n      controller.updateCostPrice(100);\n      controller.updateStandardSellingPrice(150);\n      controller.updateDiscountPrice(140);\n      controller.updateTaxId('tax-1', taxRate: 15, taxName: 'VAT 15%');\n      controller.goToPreviousApplicableStep(); // → 3\n      expect(await controller.saveAndContinue(), isTrue); // → 4\n      expect(controller.wizardState.costPrice, 100);\n      expect(controller.wizardState.standardSellingPrice, 150);\n      expect(controller.wizardState.discountPrice, 140);\n      expect(controller.wizardState.taxId, 'tax-1');\n      expect(controller.wizardState.taxRate, 15);\n    });"),

    (r"test\('14\. Save & Continue across Step 3/5/6 triggers zero Product mutations',\s+\(\) async \{\s+await goToStep5Simple\(\);\s+controller\.updateSimpleBaseSku\('TEST-SIMPLE-001'\);\s+await controller\.saveAndContinue\(\);\s+controller\.updateCostPrice\(100\);\s+controller\.updateStandardSellingPrice\(150\);\s+controller\.updateTaxId\('tax-1', taxRate: 15, taxName: 'VAT 15%'\);\s+await controller\.saveAndContinue\(\);\s+expect\(repo\.saveDraftCallCount, 0\);\s+expect\(repo\.updateDraftCallCount, 0\);\s+expect\(repo\.createProductCallCount, 0\);\s+expect\(repo\.updateProductCallCount, 0\);\s+expect\(controller\.wizardState\.productId, isNull\);\s+\}\);",
     "test('14. Save & Continue across Step 3/4/5 triggers zero Product mutations',\n        () async {\n      await goToStep5Tracking();\n      expect(repo.saveDraftCallCount, 0);\n      expect(repo.updateDraftCallCount, 0);\n      expect(repo.createProductCallCount, 0);\n      expect(repo.updateProductCallCount, 0);\n      expect(controller.wizardState.productId, isNull);\n    });"),

    (r"test\('15\. VARIANT routing regression still passes', \(\) async \{\s+await controller\.initWizard\(\);\s+controller\.skipScanStepForTesting\(\);\s+controller\.updateProductName\('Variant Item'\);\s+controller\.updateCategory\('cat-1'\);\s+controller\.updateInternalCode\('V-001'\);\s+await controller\.saveAndContinue\(\);\s+controller\.setProductStructure\('VARIANT'\);\s+await controller\.saveAndContinue\(\);\s+expect\(controller\.wizardState\.currentStep, 5\);\s+controller\.addAttributeRow\(\);\s+controller\.updateAttributeName\(0, 'Color'\);\s+controller\.selectValues\(0, \['Red'\]\);\s+await controller\.generateVariants\(\);\s+for \(final assignment in controller\.wizardState\.step5State\.assignments\) \{\s+await controller\.assignBarcodeSkuAndSave\(\s+assignment\.copyWith\(sku: 'SKU-\$\{assignment\.clientCombinationKey\}'\),\s+\);\s+\}\s+await controller\.saveAndContinue\(\);\s+expect\(controller\.wizardState\.currentStep, 6\);\s+\}\);",
     "test('15. VARIANT routing regression still passes', () async {\n      await controller.initWizard();\n      controller.skipScanStepForTesting();\n      controller.updateProductName('Variant Item');\n      controller.updateCategory('cat-1');\n      controller.updateInternalCode('V-001');\n      await controller.saveAndContinue();\n      controller.setProductStructure('VARIANT');\n      controller.addAttributeRow();\n      controller.updateAttributeName(0, 'Color');\n      controller.selectValues(0, ['Red']);\n      await controller.generateVariants();\n      for (final assignment in controller.wizardState.step5State.assignments) {\n        await controller.assignBarcodeSkuAndSave(\n          assignment.copyWith(sku: 'SKU-${assignment.clientCombinationKey}'),\n        );\n      }\n      await controller.saveAndContinue();\n      expect(controller.wizardState.currentStep, 4);\n    });"),

    (r"test\('SIMPLE multiple units survive Back to Step 4', \(\) async \{\s+await controller\.initWizard\(\);\s+controller\.skipScanStepForTesting\(\);\s+controller\.updateProductName\('Multi Unit'\);\s+controller\.updateCategory\('cat-1'\);\s+controller\.updateInternalCode\('MU-001'\);\s+await controller\.saveAndContinue\(\);\s+controller\.setProductStructure\('SIMPLE'\);\s+controller\.setTrackInventory\(true\);\s+await controller\.saveAndContinue\(\);\s+controller\.selectUnitModel\('MULTIPLE_UNITS'\);\s+controller\.setBaseUnit\('unit-1'\);\s+controller\.setSellingUnit\('unit-1'\);\s+controller\.setPurchaseUnit\('unit-2'\);\s+controller\.setItemsPerPurchaseUnit\(12\);\s+await controller\.saveAndContinue\(\);\s+expect\(controller\.wizardState\.currentStep, 5\);\s+controller\.goToPreviousApplicableStep\(\);\s+expect\(controller\.wizardState\.currentStep, 4\);\s+expect\(controller\.wizardState\.unitModel, 'MULTIPLE_UNITS'\);\s+expect\(controller\.wizardState\.baseUnitId, 'unit-1'\);\s+expect\(controller\.wizardState\.purchaseUnitId, 'unit-2'\);\s+expect\(controller\.wizardState\.itemsPerPurchaseUnit, 12\);\s+\}\);",
     "test('SIMPLE multiple units survive Back to Step 3', () async {\n      await controller.initWizard();\n      controller.skipScanStepForTesting();\n      controller.updateProductName('Multi Unit');\n      controller.updateCategory('cat-1');\n      controller.updateInternalCode('MU-001');\n      await controller.saveAndContinue();\n      controller.setProductStructure('SIMPLE');\n      controller.selectUnitModel('MULTIPLE_UNITS');\n      controller.setBaseUnit('unit-1');\n      controller.setSellingUnit('unit-1');\n      controller.setPurchaseUnit('unit-2');\n      controller.setItemsPerPurchaseUnit(12);\n      controller.updateSimpleBaseSku('MU-SKU-1');\n      await controller.saveAndContinue();\n      expect(controller.wizardState.currentStep, 4);\n      controller.goToPreviousApplicableStep();\n      expect(controller.wizardState.currentStep, 3);\n      expect(controller.wizardState.unitModel, 'MULTIPLE_UNITS');\n      expect(controller.wizardState.baseUnitId, 'unit-1');\n      expect(controller.wizardState.purchaseUnitId, 'unit-2');\n      expect(controller.wizardState.itemsPerPurchaseUnit, 12);\n    });"),

    (r"testWidgets\('4\. SIMPLE Step 5 does not show Variant selector',\s+\(tester\) async \{\s+await goToStep5Simple\(\);\s+await tester\.pumpWidget\(\s+ProviderScope\(\s+overrides: \[\s+addProductWizardControllerProvider\.overrideWith\(\(ref\) \{\s+return controller;\s+\}\),\s+\],\s+child: const MaterialApp\(\s+home: Scaffold\(body: Step5BarcodeSkuForm\(\)\),\s+\),\s+\),\s+\);\s+await tester\.pumpAndSettle\(\);\s+expect\(find\.text\('Variant \*'\), findsNothing\);\s+expect\(find\.text\('Select variant'\), findsNothing\);\s+expect\(find\.text\('Base SKU \*'\), findsOneWidget\);\s+expect\(find\.text\('Parent Product Barcode'\), findsOneWidget\);\s+expect\(find\.text\('Apply'\), findsOneWidget\);\s+expect\(find\.text\('Product'\), findsWidgets\);\s+\}\);",
     "testWidgets('4. SIMPLE Step 3 does not show Variant selector',\n        (tester) async {\n      await goToStep3Configuration();\n      await tester.pumpWidget(\n        ProviderScope(\n          overrides: [\n            addProductWizardControllerProvider.overrideWith((ref) {\n              return controller;\n            }),\n          ],\n          child: const MaterialApp(\n            home: Scaffold(body: Step5BarcodeSkuForm()),\n          ),\n        ),\n      );\n      await tester.pumpAndSettle();\n\n      expect(find.text('Variant *'), findsNothing);\n      expect(find.text('Select variant'), findsNothing);\n      expect(find.text('Base SKU *'), findsOneWidget);\n      expect(find.text('Parent Product Barcode'), findsOneWidget);\n      expect(find.text('Apply'), findsOneWidget);\n      expect(find.text('Product'), findsWidgets);\n    });"),

    (r"testWidgets\('13\. Step 7 SIMPLE review has no Variant Configuration section',\s+\(tester\) async \{\s+await goToStep5Simple\(\);\s+controller\.updateSimpleBaseSku\('TEST-SIMPLE-001'\);\s+controller\.updateSimpleParentBarcode\('8901234567890'\);\s+await controller\.saveAndContinue\(\);\s+controller\.updateCostPrice\(100\);\s+controller\.updateStandardSellingPrice\(150\);\s+controller\.updateTaxId\('tax-1', taxRate: 15, taxName: 'VAT 15%'\);\s+await controller\.saveAndContinue\(\);\s+await tester\.pumpWidget\(\s+MaterialApp\(\s+home: Scaffold\(\s+body: Step7ReviewCreate\(state: controller\.wizardState\),\s+\),\s+\),\s+\);\s+await tester\.pumpAndSettle\(\);\s+expect\(find\.text\('Variant Configuration'\), findsNothing\);\s+expect\(find\.text\('Product Configuration'\), findsNothing\);\s+expect\(find\.text\('Basic Details'\), findsOneWidget\);\s+expect\(find\.text\('Product Type & Tracking'\), findsOneWidget\);\s+expect\(find\.text\('Units & Pack Conversion'\), findsOneWidget\);\s+expect\(find\.text\('Barcode & SKU'\), findsOneWidget\);\s+expect\(find\.text\('SKU'\), findsWidgets\);\s+expect\(find\.text\('TEST-SIMPLE-001'\), findsWidgets\);\s+expect\(find\.text\('Pricing & Tax'\), findsOneWidget\);\s+expect\(find\.text\('VAT 15%'\), findsOneWidget\);\s+expect\(find\.text\('Simple Product'\), findsWidgets\);\s+expect\(find\.text\('Variant Product'\), findsNothing\);\s+await tester\.pump\(const Duration\(seconds: 1\)\);\s+\}\);",
     "testWidgets('13. Step 6 SIMPLE review has no Variant Configuration section',\n        (tester) async {\n      await goToStep5Tracking();\n      controller.updateSimpleParentBarcode('8901234567890');\n      await controller.saveAndContinue();\n\n      await tester.pumpWidget(\n        MaterialApp(\n          home: Scaffold(\n            body: Step7ReviewCreate(state: controller.wizardState),\n          ),\n        ),\n      );\n      await tester.pumpAndSettle();\n\n      expect(find.text('Variant Configuration'), findsNothing);\n      expect(find.text('Product Configuration'), findsNothing);\n      expect(find.text('Basic Details'), findsOneWidget);\n      expect(find.text('Product Type & Tracking'), findsOneWidget);\n      expect(find.text('Units & Pack Conversion'), findsOneWidget);\n      expect(find.text('Barcode & SKU'), findsOneWidget);\n      expect(find.text('SKU'), findsWidgets);\n      expect(find.text('TEST-SIMPLE-001'), findsWidgets);\n      expect(find.text('Pricing & Tax'), findsOneWidget);\n      expect(find.text('VAT 15%'), findsOneWidget);\n      expect(find.text('Simple Product'), findsWidgets);\n      expect(find.text('Variant Product'), findsNothing);\n      \n      await tester.pump(const Duration(seconds: 1));\n    });")
]

for pattern, replacement in replacements:
    content = re.sub(pattern, replacement, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
