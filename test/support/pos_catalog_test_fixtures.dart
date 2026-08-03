import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_catalog_provider.dart';

const testTicketsCategoryId = 'cat-tickets';
const testServicesCategoryId = 'cat-services';
const testRetailCategoryId = 'cat-retail';
const testFoodCategoryId = 'cat-food';
const testMembershipsCategoryId = 'cat-memberships';
const testVariableProductId = 'variable-jersey';

const testVariableProductSummary = PosCatalogProductSummary(
  productId: testVariableProductId,
  categoryId: testRetailCategoryId,
  name: 'Pro Team Jersey',
  categoryName: 'Retail',
  basePrice: 10000,
  hasVariants: true,
  stockStatus: 'InStock',
  stockLabel: 'From LKR 10,000.00',
);

const testVariableProductDetail = PosCatalogProductDetail(
  summary: testVariableProductSummary,
  variantGroups: [
    PosCatalogVariantGroup(
      name: 'Size',
      options: ['Small', 'Medium'],
      optionId: 'option-size',
      values: [
        PosCatalogOptionValue(
            optionValueId: 'size-small', code: 'S', displayName: 'Small'),
        PosCatalogOptionValue(
            optionValueId: 'size-medium', code: 'M', displayName: 'Medium'),
      ],
    ),
    PosCatalogVariantGroup(
      name: 'Color',
      options: ['Blue', 'Red'],
      optionId: 'option-color',
      values: [
        PosCatalogOptionValue(
            optionValueId: 'color-blue',
            code: 'BLU',
            displayName: 'Blue',
            colorHex: '#2563EB'),
        PosCatalogOptionValue(
            optionValueId: 'color-red',
            code: 'RED',
            displayName: 'Red',
            colorHex: '#DC2626'),
      ],
    ),
  ],
  variants: [
    PosCatalogVariant(
      variantId: 'variant-small-blue',
      sku: 'JER-S-BLU',
      price: 10000,
      stockStatus: 'InStock',
      stockQty: 20,
      attributes: {'Size': 'Small', 'Color': 'Blue'},
      selectedOptionValueIds: ['size-small', 'color-blue'],
      salesUomId: 'uom-each',
      authoritativePrice: 10000,
      currency: 'LKR',
    ),
    PosCatalogVariant(
      variantId: 'variant-medium-blue',
      sku: 'JER-M-BLU',
      price: 12000,
      stockStatus: 'InStock',
      stockQty: 15,
      attributes: {'Size': 'Medium', 'Color': 'Blue'},
      selectedOptionValueIds: ['size-medium', 'color-blue'],
      salesUomId: 'uom-each',
      authoritativePrice: 12000,
      currency: 'LKR',
    ),
    PosCatalogVariant(
      variantId: 'variant-small-red',
      sku: 'JER-S-RED',
      price: 10000,
      stockStatus: 'OutOfStock',
      stockQty: 0,
      attributes: {'Size': 'Small', 'Color': 'Red'},
      selectedOptionValueIds: ['size-small', 'color-red'],
      salesUomId: 'uom-each',
      authoritativePrice: 10000,
      currency: 'LKR',
    ),
  ],
);

const testPosCatalogCategories = <PosCatalogCategoryOption>[
  PosCatalogCategoryOption(name: 'All'),
  PosCatalogCategoryOption(id: testTicketsCategoryId, name: 'Tickets'),
  PosCatalogCategoryOption(id: testServicesCategoryId, name: 'Services'),
  PosCatalogCategoryOption(id: testRetailCategoryId, name: 'Retail'),
  PosCatalogCategoryOption(id: testFoodCategoryId, name: 'Food'),
  PosCatalogCategoryOption(id: testMembershipsCategoryId, name: 'Memberships'),
];

const testPosCatalogState = PosNewSaleCatalogState(
  products: [
    PosCatalogProductSummary(
      productId: 'general-admission',
      categoryId: testTicketsCategoryId,
      name: 'General Admission',
      categoryName: 'Tickets',
      basePrice: 1500,
      hasVariants: false,
      stockStatus: 'InStock',
      stockLabel: '24 in stock',
    ),
    PosCatalogProductSummary(
      productId: 'vip-entry',
      categoryId: testTicketsCategoryId,
      name: 'VIP Entry',
      categoryName: 'Tickets',
      basePrice: 4500,
      hasVariants: false,
      stockStatus: 'InStock',
      stockLabel: '12 in stock',
    ),
    PosCatalogProductSummary(
      productId: 'guided-tour',
      categoryId: testServicesCategoryId,
      name: 'Guided Tour',
      categoryName: 'Services',
      basePrice: 2000,
      hasVariants: false,
      stockStatus: 'InStock',
      stockLabel: 'Available',
    ),
    PosCatalogProductSummary(
      productId: 'event-t-shirt',
      categoryId: testRetailCategoryId,
      name: 'Event T-Shirt',
      categoryName: 'Retail',
      basePrice: 2750,
      hasVariants: false,
      stockStatus: 'InStock',
      stockLabel: '18 in stock',
    ),
    PosCatalogProductSummary(
      productId: 'snack-combo',
      categoryId: testFoodCategoryId,
      name: 'Snack Combo',
      categoryName: 'Food',
      basePrice: 950,
      hasVariants: false,
      stockStatus: 'InStock',
      stockLabel: '32 in stock',
    ),
    PosCatalogProductSummary(
      productId: 'annual-pass',
      categoryId: testMembershipsCategoryId,
      name: 'Annual Pass',
      categoryName: 'Memberships',
      basePrice: 12000,
      hasVariants: false,
      stockStatus: 'InStock',
      stockLabel: 'Available',
    ),
    PosCatalogProductSummary(
      productId: 'family-pack',
      categoryId: testTicketsCategoryId,
      name: 'Family Pack',
      categoryName: 'Tickets',
      basePrice: 5200,
      hasVariants: false,
      stockStatus: 'InStock',
      stockLabel: '16 in stock',
    ),
    PosCatalogProductSummary(
      productId: 'photo-print',
      categoryId: testRetailCategoryId,
      name: 'Photo Print',
      categoryName: 'Retail',
      basePrice: 1250,
      hasVariants: false,
      stockStatus: 'InStock',
      stockLabel: '40 in stock',
    ),
    PosCatalogProductSummary(
      productId: 'locker-rental',
      categoryId: testServicesCategoryId,
      name: 'Locker Rental',
      categoryName: 'Services',
      basePrice: 700,
      hasVariants: false,
      stockStatus: 'InStock',
      stockLabel: 'Available',
    ),
    PosCatalogProductSummary(
      productId: 'coffee-voucher',
      categoryId: testFoodCategoryId,
      name: 'Coffee Voucher',
      categoryName: 'Food',
      basePrice: 650,
      hasVariants: false,
      stockStatus: 'InStock',
      stockLabel: '50 in stock',
    ),
    PosCatalogProductSummary(
      productId: 'student-entry',
      categoryId: testTicketsCategoryId,
      name: 'Student Entry',
      categoryName: 'Tickets',
      basePrice: 900,
      hasVariants: false,
      stockStatus: 'InStock',
      stockLabel: '28 in stock',
    ),
    PosCatalogProductSummary(
      productId: 'premium-pass',
      categoryId: testMembershipsCategoryId,
      name: 'Premium Pass',
      categoryName: 'Memberships',
      basePrice: 18000,
      hasVariants: false,
      stockStatus: 'InStock',
      stockLabel: 'Available',
    ),
    testVariableProductSummary,
  ],
);

PosNewSaleCatalogState testPosCatalogStateForCategory(String? categoryId) {
  if (categoryId == null) {
    return testPosCatalogState;
  }

  return PosNewSaleCatalogState(
    products: testPosCatalogState.products
        .where((product) => product.categoryId == categoryId)
        .toList(growable: false),
  );
}
