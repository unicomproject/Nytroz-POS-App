import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';

void main() {
  test('stable option-value ids resolve exactly one variant', () {
    const detail = PosCatalogProductDetail(
      summary: PosCatalogProductSummary(
        productId: 'product-1',
        name: 'Jersey',
        categoryName: 'Apparel',
        basePrice: 10,
        hasVariants: true,
      ),
      variantGroups: [
        PosCatalogVariantGroup(
            name: 'Size',
            options: ['Small'],
            optionId: 'size',
            values: [
              PosCatalogOptionValue(
                  optionValueId: 'small', code: 'S', displayName: 'Small')
            ]),
      ],
      variants: [
        PosCatalogVariant(
            variantId: 'variant-small',
            sku: 'J-S',
            price: 10,
            stockStatus: 'InStock',
            attributes: {'Size': 'Small'},
            selectedOptionValueIds: ['small'],
            authoritativePrice: 10.125),
      ],
    );
    expect(detail.matchVariantIds({'small'})?.variantId, 'variant-small');
    expect(detail.variants.single.authoritativePrice, 10.125);
  });

  test('checkout line emits Chunk 2 optional fields and trims note', () {
    const line = PosCheckoutLineRequest(
      variantId: 'variant-1',
      quantity: 2,
      clientLineId: 'line-1',
      uomId: 'uom-1',
      lineNote: '  no onions  ',
      source: 'product_popup',
      recommendationParentProductId: 'product-1',
      recommendationRelationshipId: 'relationship-1',
    );
    expect(line.toJson(), containsPair('lineNote', 'no onions'));
    expect(line.toJson(), containsPair('uomId', 'uom-1'));
    expect(line.toJson(),
        containsPair('recommendationRelationshipId', 'relationship-1'));
  });

  test('same variant with different notes remains separate cart lines', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(posNewSaleCartProvider.notifier);
    notifier.addToCart(_product('Kitchen', 'no onions'));
    notifier.addToCart(_product('Kitchen', 'extra onions'));
    expect(container.read(posNewSaleCartProvider).items, hasLength(2));
  });

  test('same variant and normalized note merges quantity', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(posNewSaleCartProvider.notifier);
    notifier.addToCart(_product('Kitchen', ' no onions '));
    notifier.addToCart(_product('Kitchen', 'no onions'));
    expect(container.read(posNewSaleCartProvider).items, hasLength(1));
    expect(container.read(posNewSaleCartProvider).itemList.single.quantity, 2);
  });

  test('fractional variant metadata is preserved without integer submission',
      () {
    const variant = PosCatalogVariant(
      variantId: 'weighted',
      sku: 'W-1',
      price: 25,
      stockStatus: 'InStock',
      attributes: {},
      allowFractionalQuantity: true,
      authoritativePrice: 25.75,
    );
    expect(variant.allowFractionalQuantity, isTrue);
    expect(variant.authoritativePrice, 25.75);
  });
}

PosNewSaleProduct _product(String category, String note) => PosNewSaleProduct(
      id: 'variant-1',
      productId: 'product-1',
      variantId: 'variant-1',
      name: 'Burger',
      category: category,
      price: 100,
      stockStatus: 'InStock',
      lineNote: note,
      uomId: 'each',
    );
