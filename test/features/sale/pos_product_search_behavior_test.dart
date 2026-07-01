import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';

void main() {
  group('POS product search behavior', () {
    test('product name only returns matching product', () {
      expect(_hoodie.matches('hoodie'), isTrue);
      expect(_sportsCap.matches('hoodie'), isFalse);
    });

    test('product name plus colour variant returns matching product', () {
      expect(_hoodie.matches('hoodie black'), isTrue);
      expect(_sportsCap.matches('hoodie black'), isFalse);
    });

    test('product name plus size variant returns matching product', () {
      expect(_hoodie.matches('hoodie small'), isTrue);
      expect(_sportsCap.matches('hoodie small'), isFalse);
    });

    test('variant-only size does not return products', () {
      expect(_hoodie.matches('small'), isFalse);
      expect(_sportsCap.matches('small'), isFalse);
    });

    test('variant-only colour does not return products', () {
      expect(_hoodie.matches('black'), isFalse);
      expect(_sportsCap.matches('black'), isFalse);
    });

    test('product name containing variant-like word can match that word', () {
      expect(_blackHoodie.matches('black'), isTrue);
    });

    test('exact SKU or barcode search still returns a product', () {
      expect(_hoodie.matches('HOD-S-BLK'), isTrue);
      expect(_hoodie.matches('9300000000012'), isTrue);
    });

    test('product name plus variant selects matching variant attributes', () {
      final attributes = _hoodieDetail.matchingVariantAttributesForSearchQuery(
        'hoodie black',
      );

      expect(attributes, {'Size': 'Small', 'Colour': 'Black'});
    });

    test('variant-only query does not select variant attributes', () {
      final attributes = _hoodieDetail.matchingVariantAttributesForSearchQuery(
        'black',
      );

      expect(attributes, isEmpty);
    });
  });
}

const _hoodie = PosCatalogProductSummary(
  productId: 'hoodie',
  name: 'Hoodie',
  categoryName: 'Apparel',
  basePrice: 8500,
  hasVariants: true,
  variantSearchTerms: ['Small', 'Medium', 'Black', 'Grey'],
  directSearchTerms: ['HOD-S-BLK', '9300000000012'],
);

const _blackHoodie = PosCatalogProductSummary(
  productId: 'black-hoodie',
  name: 'Black Hoodie',
  categoryName: 'Apparel',
  basePrice: 8500,
  hasVariants: true,
  variantSearchTerms: ['Small', 'Medium'],
  directSearchTerms: ['BLK-HOD-S'],
);

const _sportsCap = PosCatalogProductSummary(
  productId: 'sports-cap',
  name: 'Sports Cap',
  categoryName: 'Accessories',
  basePrice: 2500,
  hasVariants: true,
  variantSearchTerms: ['Small', 'Black'],
  directSearchTerms: ['CAP-S-BLK'],
);

const _hoodieDetail = PosCatalogProductDetail(
  summary: _hoodie,
  variantGroups: [
    PosCatalogVariantGroup(name: 'Size', options: ['Small', 'Medium']),
    PosCatalogVariantGroup(name: 'Colour', options: ['Black', 'Grey']),
  ],
  variants: [
    PosCatalogVariant(
      variantId: 'hoodie-small-black',
      sku: 'HOD-S-BLK',
      price: 8500,
      stockStatus: 'InStock',
      attributes: {
        'Size': 'Small',
        'Colour': 'Black',
      },
    ),
    PosCatalogVariant(
      variantId: 'hoodie-medium-grey',
      sku: 'HOD-M-GRY',
      price: 8500,
      stockStatus: 'InStock',
      attributes: {
        'Size': 'Medium',
        'Colour': 'Grey',
      },
    ),
  ],
);
