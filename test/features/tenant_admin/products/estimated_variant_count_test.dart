import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/product_draft_response_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/step4_variant_configuration_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/repositories/tenant_product_repository.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/utils/variant_estimated_count_calculator.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/step_4/estimated_variant_count_card.dart';

void main() {
  Step4VariantConfigurationState buildColourCapacityState({
    int colourCount = 3,
    int capacityCount = 2,
  }) {
    final colours = List.generate(
      colourCount,
      (i) => SelectedOptionValue(valueId: 'c$i', valueName: 'Colour$i'),
    );
    final capacities = List.generate(
      capacityCount,
      (i) => SelectedOptionValue(valueId: 'p$i', valueName: 'Cap$i'),
    );

    return Step4VariantConfigurationState(
      attributeRows: [
        AttributeConfigRow(
          templateId: 'colour-template',
          templateName: 'Colour',
          selectedValues: colours,
        ),
        AttributeConfigRow(
          templateId: 'capacity-template',
          templateName: 'Capacity',
          selectedValues: capacities,
        ),
      ],
    );
  }

  group('EstimatedVariantCountCard widget', () {
    testWidgets('shows 6 variants and formula summary', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EstimatedVariantCountCard(
              step4State: buildColourCapacityState(),
            ),
          ),
        ),
      );

      expect(find.text('Estimated Variant Count'), findsOneWidget);
      expect(find.text('6 variants'), findsOneWidget);
      expect(find.text('will be created'), findsOneWidget);
      expect(
        find.text('Colour (3) × Capacity (2) = 6 variants'),
        findsOneWidget,
      );
    });

    testWidgets('shows max limit validation at 110 combinations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EstimatedVariantCountCard(
              step4State: buildColourCapacityState(
                colourCount: 10,
                capacityCount: 11,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Maximum of 100'), findsOneWidget);
    });

    testWidgets('1024x768 card wraps long attribute names without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final longName =
          'Extra Long Attribute Name For Responsive Layout Validation';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1024,
              child: SingleChildScrollView(
                child: EstimatedVariantCountCard(
                  step4State: Step4VariantConfigurationState(
                    attributeRows: [
                      AttributeConfigRow(
                        templateId: 'a',
                        templateName: longName,
                        selectedValues: const [
                          SelectedOptionValue(valueId: '1', valueName: 'One'),
                          SelectedOptionValue(valueId: '2', valueName: 'Two'),
                          SelectedOptionValue(valueId: '3', valueName: 'Three'),
                        ],
                      ),
                      AttributeConfigRow(
                        templateId: 'b',
                        templateName: 'Capacity',
                        selectedValues: const [
                          SelectedOptionValue(valueId: '4', valueName: '128GB'),
                          SelectedOptionValue(valueId: '5', valueName: '256GB'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Estimated Variant Count'), findsOneWidget);
      expect(find.text('6 variants'), findsOneWidget);
    });
  });

  group('Draft reopen estimated count', () {
    late _SetupRepo repo;
    late AddProductWizardController controller;

    setUp(() {
      repo = _SetupRepo();
      controller = AddProductWizardController(repo);
    });

    tearDown(() {
      if (controller.mounted) {
        controller.dispose();
      }
    });

    test('GET /setup hydration recalculates 6 variants without backend count',
        () async {
      await controller.initWizard(resumeProductId: 'prod-1');

      final estimate = controller.wizardState.step4State.estimatedCountResult;
      expect(estimate.count, 6);
      expect(estimate.isComplete, isTrue);
      expect(
        VariantEstimatedCountCalculator.formatFormulaSummary(estimate),
        'Colour (3) × Capacity (2) = 6 variants',
      );
    });

    test('editing restored configuration updates estimate immediately', () async {
      await controller.initWizard(resumeProductId: 'prod-1');
      controller.selectValues(0, ['c0', 'c1']);

      final estimate = controller.wizardState.step4State.estimatedCountResult;
      expect(estimate.count, 4);
    });

    test('validateStep4Continue blocks when estimate exceeds 100', () async {
      await controller.initWizard();
      controller.setProductStructure('VARIANT');
      controller.addAttributeRow();
      controller.updateAttributeName(0, 'A');
      controller.selectValues(0, List.generate(10, (i) => 'a$i'));
      controller.addAttributeRow();
      controller.updateAttributeName(1, 'B');
      controller.selectValues(1, List.generate(11, (i) => 'b$i'));

      final errors = controller.validateStep4Continue();
      expect(errors.containsKey('variantEstimatedCount'), isTrue);
    });

    test('generateVariants blocks when estimate exceeds 100', () async {
      await controller.initWizard();
      controller.setProductStructure('VARIANT');
      controller.addAttributeRow();
      controller.updateAttributeName(0, 'A');
      controller.selectValues(0, List.generate(10, (i) => 'a$i'));
      controller.addAttributeRow();
      controller.updateAttributeName(1, 'B');
      controller.selectValues(1, List.generate(11, (i) => 'b$i'));

      await controller.generateVariants();
      expect(
        controller.wizardState.pageError,
        contains('100'),
      );
    });
  });
}

class _SetupRepo implements TenantProductRepository {
  @override
  Future<TenantProductCreateOptions> getCreateOptions() async {
    return const TenantProductCreateOptions(
      categories: [
        ProductCategoryOption(id: 'cat-1', code: 'CAT1', name: 'Apparel'),
      ],
      subCategories: [],
      brands: [],
      units: [
        ProductUnitOption(id: 'unit-1', code: 'PCS', name: 'Piece'),
      ],
      taxes: [
        ProductTaxOption(id: 'tax-1', code: 'TAX15', name: 'VAT 15%'),
      ],
      outlets: [],
      variantOptionTemplates: [
        ProductVariantOptionTemplate(
          id: 'colour-template',
          code: 'COLOR',
          name: 'Colour',
          optionType: 'SWATCH',
        ),
        ProductVariantOptionTemplate(
          id: 'capacity-template',
          code: 'CAPACITY',
          name: 'Capacity',
          optionType: 'SELECT',
        ),
      ],
    );
  }

  @override
  Future<ProductDraftResponseDto> getSetup(String productId) async {
    return ProductDraftResponseDto.fromJson({
      'productId': productId,
      'productName': 'Phone',
      'productCode': 'PHONE-001',
      'status': 'DRAFT',
      'currentSetupStep': 4,
      'rowVersion': 1,
      'productStructure': 'VARIANT',
      'variantConfiguration': {
        'options': [
          {
            'sourceOptionTemplateId': 'colour-template',
            'optionCode': 'COLOR',
            'optionName': 'Colour',
            'values': [
              {
                'sourceOptionTemplateValueId': 'c0',
                'valueCode': 'RED',
                'valueName': 'Red',
              },
              {
                'sourceOptionTemplateValueId': 'c1',
                'valueCode': 'BLUE',
                'valueName': 'Blue',
              },
              {
                'sourceOptionTemplateValueId': 'c2',
                'valueCode': 'BLACK',
                'valueName': 'Black',
              },
            ],
          },
          {
            'sourceOptionTemplateId': 'capacity-template',
            'optionCode': 'CAPACITY',
            'optionName': 'Capacity',
            'values': [
              {
                'sourceOptionTemplateValueId': 'p0',
                'valueCode': '128',
                'valueName': '128GB',
              },
              {
                'sourceOptionTemplateValueId': 'p1',
                'valueCode': '256',
                'valueName': '256GB',
              },
            ],
          },
        ],
        'variants': [],
        'excludedCombinationHashes': [],
      },
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
