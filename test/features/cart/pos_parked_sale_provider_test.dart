import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_cart_discount.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_parked_sale_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_customer.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('saves current cart as a persisted parked sale', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final sale = await container
        .read(posParkedSaleProvider.notifier)
        .saveCurrentCart(_cart);

    expect(sale, isNotNull);
    expect(sale!.reference, 'Parked Sale #1');
    expect(sale.itemCount, 2);
    expect(sale.total, 3000);
    expect(sale.customer?.displayName, 'Maya Silva');
    expect(sale.customerId, 'customer-1');
    expect(sale.customerName, 'Maya Silva');
    expect(sale.customerPhone, '0711111111');
    expect(sale.identityLine, 'Maya Silva • 0711111111');
    expect(sale.itemPreview, 'General Admission');

    final persistedContainer = ProviderContainer();
    addTearDown(persistedContainer.dispose);

    final persisted =
        await persistedContainer.read(posParkedSaleProvider.future);
    expect(persisted, hasLength(1));
    expect(persisted.single.items.single.product.name, 'General Admission');
    expect(persisted.single.items.single.quantity, 2);
    expect(persisted.single.identityLine, 'Maya Silva • 0711111111');
  });

  test('saves reference details for walk-in parked sales', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final sale =
        await container.read(posParkedSaleProvider.notifier).saveCurrentCart(
              _cart.copyWith(selectedCustomerSet: true),
              referenceDetails: const PosParkedSaleReference(
                referenceName: 'Token 12',
                referencePhone: '0771234567',
                note: 'Black cap customer',
              ),
            );

    expect(sale, isNotNull);
    expect(sale!.customerId, isNull);
    expect(sale.referenceName, 'Token 12');
    expect(sale.referencePhone, '0771234567');
    expect(sale.note, 'Black cap customer');
    expect(sale.identityLine, 'Token 12 • 0771234567');
  });

  test('recalls a parked sale and removes it from storage', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final saved = await container
        .read(posParkedSaleProvider.notifier)
        .saveCurrentCart(_cart);

    final recalled =
        await container.read(posParkedSaleProvider.notifier).recall(saved!.id);

    expect(recalled, isNotNull);
    final restoredCart = recalled!.toCartState();
    expect(restoredCart.hasItems, isTrue);
    expect(restoredCart.itemList.single.quantity, 2);
    expect(restoredCart.selectedCustomer?.customerId, 'customer-1');

    final remaining = await container.read(posParkedSaleProvider.future);
    expect(remaining, isEmpty);
  });

  test('deletes one parked sale without clearing other parked sales', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final first = await container
        .read(posParkedSaleProvider.notifier)
        .saveCurrentCart(_cart);
    final second = await container
        .read(posParkedSaleProvider.notifier)
        .saveCurrentCart(_cart.copyWith(selectedCustomerSet: true));

    await container.read(posParkedSaleProvider.notifier).delete(first!.id);

    final remaining = await container.read(posParkedSaleProvider.future);
    expect(remaining, hasLength(1));
    expect(remaining.single.id, second!.id);
  });

  test('preserves cart and item discounts when parked sale is recalled',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    const discountedCart = PosNewSaleCartState(
      items: {
        'general-admission': PosNewSaleCartItem(
          product: _product,
          quantity: 2,
          discount: PosCartDiscount(
            valueType: PosDiscountValueType.fixedAmount,
            value: 250,
          ),
        ),
      },
      selectedCustomer: _customer,
      cartDiscount: PosCartDiscount(
        valueType: PosDiscountValueType.percentage,
        value: 10,
      ),
    );

    final saved = await container
        .read(posParkedSaleProvider.notifier)
        .saveCurrentCart(discountedCart);
    final restored = saved!.toCartState();

    expect(saved.discount, 550);
    expect(restored.cartDiscount?.value, 10);
    expect(restored.itemList.single.discount?.value, 250);
    expect(restored.discount, 550);
    expect(restored.total, 2450);
  });
}

const _product = PosNewSaleProduct(
  id: 'general-admission',
  productId: 'general-admission',
  name: 'General Admission',
  category: 'Tickets',
  price: 1500,
);

const _customer = PosCustomer(
  customerId: 'customer-1',
  fullName: 'Maya Silva',
  phone: '0711111111',
);

const _cart = PosNewSaleCartState(
  items: {
    'general-admission': PosNewSaleCartItem(
      product: _product,
      quantity: 2,
    ),
  },
  selectedCustomer: _customer,
);
