import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/step_3/units_pack_conversion.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/tenant_product_repository.dart';
class FakeTenantProductRepository implements TenantProductRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeTenantProductRepository mockRepo;
  late AddProductWizardController controller;

  const mockOptions = TenantProductCreateOptions(
    categories: [
      ProductCategoryOption(id: 'cat-1', name: 'Beverages', code: 'BEV'),
    ],
    subCategories: [],
    brands: [],
    units: [
      ProductUnitOption(
        id: 'uom-piece',
        code: 'PCS',
        name: 'Piece',
        unitType: 'COUNT',
        symbol: 'pc',
        recommendedAllowDecimalQuantity: false,
      ),
      ProductUnitOption(
        id: 'uom-pack',
        code: 'PACK',
        name: 'Pack',
        unitType: 'COUNT',
        symbol: 'pk',
        recommendedAllowDecimalQuantity: false,
      ),
      ProductUnitOption(
        id: 'uom-carton',
        code: 'CTN',
        name: 'Carton',
        unitType: 'COUNT',
        symbol: 'ctn',
        recommendedAllowDecimalQuantity: false,
      ),
    ],
    taxes: [],
    outlets: [],
    variantOptionTemplates: [],
  );

  setUp(() {
    mockRepo = FakeTenantProductRepository();
    controller = AddProductWizardController(mockRepo);
    controller.initializeOptions(mockOptions);
  });

  group('Step 3 — Units & Pack Conversion State & Controller', () {
    test('Initial state defaults to SINGLE_UNIT model', () {
      expect(controller.wizardState.unitModel, 'SINGLE_UNIT');
      expect(controller.wizardState.allowDecimalQuantity, false);
    });

    test('selectUnitModel updates unitModel state', () {
      controller.selectUnitModel('MULTIPLE_UNITS');
      expect(controller.wizardState.unitModel, 'MULTIPLE_UNITS');

      controller.selectUnitModel('SINGLE_UNIT');
      expect(controller.debugState.unitModel, 'SINGLE_UNIT');
    });

    test('setProductUnit updates productUnitId and baseUnitId', () {
      controller.setProductUnit('uom-piece');
      expect(controller.debugState.productUnitId, 'uom-piece');
      expect(controller.debugState.baseUnitId, 'uom-piece');
    });

    test('setBaseUnit sets baseUnitId and defaults sellingUnitId', () {
      controller.setBaseUnit('uom-piece');
      expect(controller.debugState.baseUnitId, 'uom-piece');
      expect(controller.debugState.sellingUnitId, 'uom-piece');
    });

    test('setPurchaseUnit and setItemsPerPurchaseUnit update factors', () {
      controller.setBaseUnit('uom-piece');
      controller.setPurchaseUnit('uom-pack');
      controller.setItemsPerPurchaseUnit(6);

      expect(controller.debugState.purchaseUnitId, 'uom-pack');
      expect(controller.debugState.itemsPerPurchaseUnit, 6);
    });

    test('validateStep3Continue validates Single Unit model', () {
      controller.selectUnitModel('SINGLE_UNIT');
      var errors = controller.validateStep3Continue();
      expect(errors.containsKey('productUnitId'), true);

      controller.setProductUnit('uom-piece');
      errors = controller.validateStep3Continue();
      expect(errors.isEmpty, true);
    });

    test('validateStep3Continue validates Multiple Units model required fields',
        () {
      controller.selectUnitModel('MULTIPLE_UNITS');
      var errors = controller.validateStep3Continue();
      expect(errors.containsKey('baseUnitId'), true);
      expect(errors.containsKey('sellingUnitId'), true);
      expect(errors.containsKey('purchaseUnitId'), true);

      controller.setBaseUnit('uom-piece');
      controller.setPurchaseUnit('uom-pack');
      controller.setItemsPerPurchaseUnit(6);
      controller.setSellingUnit('uom-piece');

      errors = controller.validateStep3Continue();
      expect(errors.isEmpty, true);
    });

    test('validateStep3Continue rejects duplicate Base and Purchase unit', () {
      controller.selectUnitModel('MULTIPLE_UNITS');
      controller.setBaseUnit('uom-piece');
      controller.setPurchaseUnit('uom-piece');
      controller.setItemsPerPurchaseUnit(6);

      final errors = controller.validateStep3Continue();
      expect(errors.containsKey('purchaseUnitId'), true);
    });

    test('validateStep3Continue rejects Selling Unit not matching active tiers',
        () {
      controller.selectUnitModel('MULTIPLE_UNITS');
      controller.setBaseUnit('uom-piece');
      controller.setPurchaseUnit('uom-pack');
      controller.setItemsPerPurchaseUnit(6);
      controller.setSellingUnit('uom-carton'); // uom-carton is unconfigured!

      final errors = controller.validateStep3Continue();
      expect(errors.containsKey('sellingUnitId'), true);
    });

    test(
        'validateStep3Continue rejects fractional conversion when allowDecimalQuantity is false',
        () {
      controller.selectUnitModel('MULTIPLE_UNITS');
      controller.setBaseUnit('uom-piece');
      controller.setPurchaseUnit('uom-pack');
      controller.setItemsPerPurchaseUnit(6.5);
      controller.setSellingUnit('uom-piece');
      controller.setAllowDecimalQuantity(false);

      final errors = controller.validateStep3Continue();
      expect(errors.containsKey('allowDecimalQuantity'), true);
    });
  });

  group('UnitsPackConversionForm Widget UI', () {
    Widget buildTestableWidget(AddProductWizardState state) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: UnitsPackConversionForm(
                state: state,
                controller: controller,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders Single Unit model form elements',
        (WidgetTester tester) async {
      final state = AddProductWizardState(
        currentStep: 3,
        unitModel: 'SINGLE_UNIT',
        createOptions: mockOptions,
      );

      await tester.pumpWidget(buildTestableWidget(state));

      expect(find.text('Units & Pack Conversion'), findsOneWidget);
      expect(find.text('Single Unit Only'), findsOneWidget);
      expect(find.text('Multiple Units & Pack Conversion'), findsOneWidget);
      expect(find.text('Product Unit *'), findsOneWidget);
      expect(find.text('Allow Decimal Quantity'), findsOneWidget);
      expect(
        find.textContaining(
            'Select a Product Unit to configure basic unit settings'),
        findsOneWidget,
      );
    });

    testWidgets('renders Multiple Units form elements, preview, and table',
        (WidgetTester tester) async {
      final state = AddProductWizardState(
        currentStep: 3,
        unitModel: 'MULTIPLE_UNITS',
        baseUnitId: 'uom-piece',
        purchaseUnitId: 'uom-pack',
        outerPackUnitId: 'uom-carton',
        sellingUnitId: 'uom-piece',
        itemsPerPurchaseUnit: 6,
        purchaseUnitsPerOuterPack: 12,
        createOptions: mockOptions,
      );

      await tester.pumpWidget(buildTestableWidget(state));

      expect(find.text('Base Unit *'), findsOneWidget);
      expect(find.text('Purchase Unit *'), findsOneWidget);
      expect(find.text('Outer Pack Unit'), findsOneWidget);
      expect(find.text('Selling Unit *'), findsOneWidget);
      expect(find.text('Items per Purchase Unit *'), findsOneWidget);
      expect(find.text('Purchase Units per Outer Pack'), findsOneWidget);

      // Conversion Summary
      expect(find.text('Conversion Summary'), findsOneWidget);
      expect(find.text('1 Pack = 6 Pieces'), findsAtLeastNWidgets(1));
      expect(find.text('1 Carton = 12 Packs'), findsOneWidget);
      expect(find.text('1 Carton = 72 Pieces'), findsOneWidget);

      // Conversion Table
      expect(find.text('Units & Pack Conversion Table'), findsOneWidget);
      expect(find.text('Piece (Selling & Base Unit)'), findsOneWidget);
      expect(find.text('Assigned in Step 5'), findsNWidgets(3));
    });
  });
}
