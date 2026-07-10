import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_catalog_provider.dart';

const testTicketsCategoryId = 'cat-tickets';
const testServicesCategoryId = 'cat-services';
const testRetailCategoryId = 'cat-retail';
const testFoodCategoryId = 'cat-food';
const testMembershipsCategoryId = 'cat-memberships';

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
      stockLabel: '24 in stock',
    ),
    PosCatalogProductSummary(
      productId: 'vip-entry',
      categoryId: testTicketsCategoryId,
      name: 'VIP Entry',
      categoryName: 'Tickets',
      basePrice: 4500,
      hasVariants: false,
      stockLabel: '12 in stock',
    ),
    PosCatalogProductSummary(
      productId: 'guided-tour',
      categoryId: testServicesCategoryId,
      name: 'Guided Tour',
      categoryName: 'Services',
      basePrice: 2000,
      hasVariants: false,
      stockLabel: 'Available',
    ),
    PosCatalogProductSummary(
      productId: 'event-t-shirt',
      categoryId: testRetailCategoryId,
      name: 'Event T-Shirt',
      categoryName: 'Retail',
      basePrice: 2750,
      hasVariants: false,
      stockLabel: '18 in stock',
    ),
    PosCatalogProductSummary(
      productId: 'snack-combo',
      categoryId: testFoodCategoryId,
      name: 'Snack Combo',
      categoryName: 'Food',
      basePrice: 950,
      hasVariants: false,
      stockLabel: '32 in stock',
    ),
    PosCatalogProductSummary(
      productId: 'annual-pass',
      categoryId: testMembershipsCategoryId,
      name: 'Annual Pass',
      categoryName: 'Memberships',
      basePrice: 12000,
      hasVariants: false,
      stockLabel: 'Available',
    ),
    PosCatalogProductSummary(
      productId: 'family-pack',
      categoryId: testTicketsCategoryId,
      name: 'Family Pack',
      categoryName: 'Tickets',
      basePrice: 5200,
      hasVariants: false,
      stockLabel: '16 in stock',
    ),
    PosCatalogProductSummary(
      productId: 'photo-print',
      categoryId: testRetailCategoryId,
      name: 'Photo Print',
      categoryName: 'Retail',
      basePrice: 1250,
      hasVariants: false,
      stockLabel: '40 in stock',
    ),
    PosCatalogProductSummary(
      productId: 'locker-rental',
      categoryId: testServicesCategoryId,
      name: 'Locker Rental',
      categoryName: 'Services',
      basePrice: 700,
      hasVariants: false,
      stockLabel: 'Available',
    ),
    PosCatalogProductSummary(
      productId: 'coffee-voucher',
      categoryId: testFoodCategoryId,
      name: 'Coffee Voucher',
      categoryName: 'Food',
      basePrice: 650,
      hasVariants: false,
      stockLabel: '50 in stock',
    ),
    PosCatalogProductSummary(
      productId: 'student-entry',
      categoryId: testTicketsCategoryId,
      name: 'Student Entry',
      categoryName: 'Tickets',
      basePrice: 900,
      hasVariants: false,
      stockLabel: '28 in stock',
    ),
    PosCatalogProductSummary(
      productId: 'premium-pass',
      categoryId: testMembershipsCategoryId,
      name: 'Premium Pass',
      categoryName: 'Memberships',
      basePrice: 18000,
      hasVariants: false,
      stockLabel: 'Available',
    ),
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
