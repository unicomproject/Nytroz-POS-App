import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';

void main() {
  group('PosCatalogProductDetail', () {
    const detail = PosCatalogProductDetail(
      summary: PosCatalogProductSummary(
        productId: 'variable-jersey',
        name: 'Pro Team Jersey',
        categoryName: 'Retail',
        basePrice: 10000,
        hasVariants: true,
      ),
      variantGroups: [
        PosCatalogVariantGroup(
          name: 'Size',
          options: ['Small', 'Medium'],
        ),
        PosCatalogVariantGroup(
          name: 'Color',
          options: ['Blue', 'Red'],
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
        ),
        PosCatalogVariant(
          variantId: 'variant-medium-blue',
          sku: 'JER-M-BLU',
          price: 12000,
          stockStatus: 'InStock',
          stockQty: 15,
          attributes: {'Size': 'Medium', 'Color': 'Blue'},
        ),
        PosCatalogVariant(
          variantId: 'variant-small-red',
          sku: 'JER-S-RED',
          price: 10000,
          stockStatus: 'OutOfStock',
          stockQty: 0,
          attributes: {'Size': 'Small', 'Color': 'Red'},
        ),
      ],
    );

    test('matchVariant resolves the selected combination', () {
      final matched = detail.matchVariant({
        'Size': 'Medium',
        'Color': 'Blue',
      });

      expect(matched?.variantId, 'variant-medium-blue');
      expect(matched?.price, 12000);
    });

    test('matchVariant returns null for incomplete selection', () {
      expect(
        detail.matchVariant({'Size': 'Small'}),
        isNull,
      );
    });

    test('matchVariant returns null for non-existent combination', () {
      expect(
        detail.matchVariant({'Size': 'Medium', 'Color': 'Red'}),
        isNull,
      );
    });

    test('toCartProduct uses variant price and separate cart keys', () {
      final smallBlue = detail.matchVariant({
        'Size': 'Small',
        'Color': 'Blue',
      });
      final mediumBlue = detail.matchVariant({
        'Size': 'Medium',
        'Color': 'Blue',
      });

      final smallLine = toCartProduct(
        summary: detail.summary,
        variant: smallBlue,
        quantity: 1,
      );
      final mediumLine = toCartProduct(
        summary: detail.summary,
        variant: mediumBlue,
        quantity: 1,
      );

      expect(smallLine.id, 'variant-small-blue');
      expect(mediumLine.id, 'variant-medium-blue');
      expect(smallLine.price, 10000);
      expect(mediumLine.price, 12000);
      expect(smallLine.selectedAttributes, {'Size': 'Small', 'Color': 'Blue'});
      expect(
          mediumLine.selectedAttributes, {'Size': 'Medium', 'Color': 'Blue'});
    });

    test(
        'out-of-stock variant cannot be added through cart product max quantity',
        () {
      final outOfStock = detail.matchVariant({
        'Size': 'Small',
        'Color': 'Red',
      });

      expect(outOfStock?.isOutOfStock, isTrue);
      expect(
        toCartProduct(
          summary: detail.summary,
          variant: outOfStock,
          quantity: 1,
        ).maxQuantity,
        0,
      );
    });
  });

  group('stockStatusFromApi', () {
    test('normalizes backend stock status values', () {
      expect(stockStatusFromApi('in_stock'), 'InStock');
      expect(stockStatusFromApi('out_of_stock'), 'OutOfStock');
      expect(stockStatusFromApi('low_stock'), 'LowStock');
      expect(stockStatusFromApi(null), 'InStock');
    });
  });
}
