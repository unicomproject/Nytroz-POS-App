import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';

/// Isolated offline fallback used only when the catalog API is unavailable.
const posCatalogFallbackSummaries = <PosCatalogProductSummary>[
  PosCatalogProductSummary(
    productId: '53000000-0000-0000-0000-000000000001',
    name: 'Team Jersey',
    description: 'Official team jersey',
    categoryName: 'Apparel',
    basePrice: 12000,
    hasVariants: true,
  ),
  PosCatalogProductSummary(
    productId: '53000000-0000-0000-0000-000000000002',
    name: 'Hoodie',
    description: 'Comfortable team hoodie',
    categoryName: 'Apparel',
    basePrice: 8500,
    hasVariants: true,
  ),
  PosCatalogProductSummary(
    productId: '53000000-0000-0000-0000-000000000003',
    name: 'Sports Cap',
    description: 'Adjustable sports cap',
    categoryName: 'Accessories',
    basePrice: 2500,
    hasVariants: true,
  ),
  PosCatalogProductSummary(
    productId: '53000000-0000-0000-0000-000000000004',
    name: 'Running Shoes',
    description: 'Lightweight running shoes',
    categoryName: 'Accessories',
    basePrice: 18500,
    hasVariants: true,
  ),
  PosCatalogProductSummary(
    productId: '53000000-0000-0000-0000-000000000005',
    name: 'Event Ticket',
    description: 'Single day event admission',
    categoryName: 'Tickets',
    basePrice: 3500,
    hasVariants: true,
  ),
  PosCatalogProductSummary(
    productId: '53000000-0000-0000-0000-000000000006',
    name: 'Burger Combo',
    description: 'Burger meal combo',
    categoryName: 'Food',
    basePrice: 1950,
    hasVariants: true,
  ),
  PosCatalogProductSummary(
    productId: '53000000-0000-0000-0000-000000000007',
    name: 'Coffee',
    description: 'Fresh brewed coffee',
    categoryName: 'Drinks',
    basePrice: 650,
    hasVariants: true,
  ),
  PosCatalogProductSummary(
    productId: '53000000-0000-0000-0000-000000000008',
    name: 'Gym Membership',
    description: 'Flexible gym membership',
    categoryName: 'Memberships',
    basePrice: 15000,
    hasVariants: true,
  ),
  PosCatalogProductSummary(
    productId: '53000000-0000-0000-0000-000000000009',
    name: 'Printing Service',
    description: 'Document printing service',
    categoryName: 'Services',
    basePrice: 500,
    hasVariants: true,
  ),
  PosCatalogProductSummary(
    productId: '53000000-0000-0000-0000-000000000010',
    name: 'Gift Box',
    description: 'Curated gift box',
    categoryName: 'Retail',
    basePrice: 4500,
    hasVariants: true,
  ),
];

PosCatalogProductDetail posCatalogFallbackDetail(String productId) {
  final summary = posCatalogFallbackSummaries.firstWhere(
    (item) => item.productId == productId,
    orElse: () => posCatalogFallbackSummaries.first,
  );

  if (summary.productId == '53000000-0000-0000-0000-000000000001') {
    return const PosCatalogProductDetail(
      summary: PosCatalogProductSummary(
        productId: '53000000-0000-0000-0000-000000000001',
        name: 'Team Jersey',
        description: 'Official team jersey',
        categoryName: 'Apparel',
        basePrice: 12000,
        hasVariants: true,
      ),
      variantGroups: [
        PosCatalogVariantGroup(name: 'Size', options: ['S', 'M', 'L', 'XL']),
        PosCatalogVariantGroup(name: 'Colour', options: ['Blue', 'Black', 'Navy', 'Red']),
        PosCatalogVariantGroup(name: 'Style', options: ['Men', 'Women']),
        PosCatalogVariantGroup(name: 'Material', options: ['Cotton', 'Polyester']),
      ],
      variants: [
        PosCatalogVariant(
          variantId: '55000000-0000-0000-0000-000001000001',
          sku: 'JER-S-BLU-MEN-COT',
          price: 12000,
          stockStatus: 'InStock',
          stockQty: 10,
          attributes: {
            'Size': 'S',
            'Colour': 'Blue',
            'Style': 'Men',
            'Material': 'Cotton',
          },
        ),
        PosCatalogVariant(
          variantId: '55000000-0000-0000-0000-000001000004',
          sku: 'JER-XL-RED-MEN-COT',
          price: 12000,
          stockStatus: 'OutOfStock',
          stockQty: 0,
          attributes: {
            'Size': 'XL',
            'Colour': 'Red',
            'Style': 'Men',
            'Material': 'Cotton',
          },
        ),
      ],
    );
  }

  return PosCatalogProductDetail(
    summary: summary,
    variantGroups: const [
      PosCatalogVariantGroup(name: 'Option', options: ['Default']),
    ],
    variants: const [
      PosCatalogVariant(
        variantId: 'fallback-variant',
        sku: 'FALLBACK',
        price: 1000,
        stockStatus: 'InStock',
        stockQty: 99,
        attributes: {'Option': 'Default'},
      ),
    ],
  );
}
