import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/offline/offline_connectivity_monitor.dart';
import 'package:nytroz_pos/features/discount/data/datasources/local/pos_pending_sale_recovery_store.dart';
import 'package:nytroz_pos/features/discount/domain/entities/pos_cart_discount.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/discount/presentation/widgets/discount_sync_conflict_panel.dart';

void main() {
  group('OfflineConnectivityMonitor', () {
    test('debounces flapping and wakes once after stable online', () async {
      final monitor = OfflineConnectivityMonitor(
        stableOnlineWindow: const Duration(milliseconds: 40),
      );
      var wakes = 0;
      monitor.addListener(() async {
        wakes += 1;
      });

      monitor.reportOffline();
      monitor.reportOnline();
      monitor.reportOffline();
      monitor.reportOnline();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(wakes, 0);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(wakes, 1);

      // Already stably online — no duplicate wake.
      monitor.reportOnline();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(wakes, 1);
      monitor.dispose();
    });
  });

  group('PosPendingSaleRecoveryStore', () {
    test('restores cart, pending discount and same ownership context',
        () async {
      final storage = _MemorySecureStorage();
      final store = PosPendingSaleRecoveryStore(storage);
      const discount = PosCartDiscount(
        valueType: PosDiscountValueType.percentage,
        value: 8,
        applicationId: 'local:op-1',
        status: 'pending_sync',
        discountAmount: 224,
        totalAfterDiscount: 2576,
        scope: 'ORDER',
      );
      final cart = PosNewSaleCartState(
        items: {
          'variant-1||': PosNewSaleCartItem(
            product: const PosNewSaleProduct(
              id: 'p1',
              productId: 'p1',
              name: 'Match Shorts',
              category: 'Apparel',
              price: 2800,
              variantId: 'variant-1',
            ),
            quantity: 1,
          ),
        },
        cartDiscount: discount,
      );

      await store.save(
        tenantId: 'tenant-a',
        userId: 'user-a',
        deviceId: 'device-a',
        outletId: 'outlet-a',
        tillId: 'till-a',
        cart: cart,
        idempotencyKey: 'stable-key-1',
        localDiscountOperationId: 'op-1',
      );

      final restored = await store.loadMatching(
        tenantId: 'tenant-a',
        userId: 'user-a',
        deviceId: 'device-a',
      );
      expect(restored, isNotNull);
      expect(restored!.idempotencyKey, 'stable-key-1');
      expect(restored.localDiscountOperationId, 'op-1');
      expect(restored.cart.subtotal, 2800);
      expect(restored.cart.cartDiscount?.value, 8);
      expect(restored.cart.cartDiscount?.status, 'pending_sync');
      expect(restored.cart.total, 2576);

      expect(
        await store.loadMatching(
          tenantId: 'other-tenant',
          userId: 'user-a',
          deviceId: 'device-a',
        ),
        isNull,
      );
    });
  });

  group('DiscountSyncConflictPanel', () {
    test('maps safe cashier messages for known conflict codes', () {
      expect(
        DiscountSyncConflictPanel.messageForCode(
          'pos_discounts.permission_denied',
        ),
        'You no longer have permission to apply this Discount.',
      );
      expect(
        DiscountSyncConflictPanel.messageForCode(
          'pos_discounts.authority_exceeded',
        ),
        'Discount authority has changed.',
      );
      expect(
        DiscountSyncConflictPanel.messageForCode(
          'pos_discounts.cart_changed',
        ),
        'The discounted item/cart has changed.',
      );
      expect(
        DiscountSyncConflictPanel.messageForCode(
          'pos_discounts.active_discount_exists',
        ),
        'Another Discount already exists.',
      );
    });
  });
}

class _MemorySecureStorage implements OfflineStringStore {
  final Map<String, String> _values = {};

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;
}
