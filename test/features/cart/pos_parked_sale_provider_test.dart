import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/cart/data/models/pos_parked_sale_dtos.dart';
import 'package:nytroz_pos/features/cart/domain/repositories/pos_parked_sale_repository.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_parked_sale_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_api_exception.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';

void main() {
  test(
      'create uses backend reference, omits expiry, and clears cart only on success',
      () async {
    final repo = _FakeRepository();
    final container = _container(repo);
    addTearDown(container.dispose);
    container.read(posNewSaleCartProvider.notifier).addToCart(_product);
    await container.read(posParkedSaleProvider.future);
    final cart = container.read(posNewSaleCartProvider);
    final sale = await container
        .read(posParkedSaleProvider.notifier)
        .saveCurrentCart(cart,
            referenceDetails: const PosParkedSaleReference(
                referenceName: 'Walk in', note: '  keep  '));
    expect(sale?.reference, 'PS-2026-00001');
    expect(repo.created.single.toJson(), isNot(contains('expiresAt')));
    expect(repo.created.single.reason, 'keep');
    expect(container.read(posNewSaleCartProvider).hasItems, isFalse);
  });

  test('timeout preserves cart and unchanged retry reuses idempotency key',
      () async {
    final repo = _FakeRepository(failCreates: 1);
    final container = _container(repo);
    addTearDown(container.dispose);
    container.read(posNewSaleCartProvider.notifier).addToCart(_product);
    await container.read(posParkedSaleProvider.future);
    final notifier = container.read(posParkedSaleProvider.notifier);
    await expectLater(
        notifier.saveCurrentCart(container.read(posNewSaleCartProvider)),
        throwsA(isA<PosCheckoutApiException>()));
    expect(container.read(posNewSaleCartProvider).hasItems, isTrue);
    await notifier.saveCurrentCart(container.read(posNewSaleCartProvider));
    expect(repo.created[0].idempotencyKey, repo.created[1].idempotencyKey);
  });

  test('missing canonical permission blocks before repository call', () async {
    final repo = _FakeRepository();
    final container = _container(repo,
        permissions: {PosPermissionCodes.viewBackendParkedSales});
    addTearDown(container.dispose);
    await container.read(posParkedSaleProvider.future);
    await expectLater(
        container.read(posParkedSaleProvider.notifier).saveCurrentCart(_cart),
        throwsA(predicate(
            (e) => e is PosCheckoutApiException && e.statusCode == 403)));
    expect(repo.created, isEmpty);
  });

  test('double submit invokes create once', () async {
    final repo = _FakeRepository();
    final container = _container(repo);
    addTearDown(container.dispose);
    container.read(posNewSaleCartProvider.notifier).addToCart(_product);
    await container.read(posParkedSaleProvider.future);
    final notifier = container.read(posParkedSaleProvider.notifier);
    final first =
        notifier.saveCurrentCart(container.read(posNewSaleCartProvider));
    final second =
        await notifier.saveCurrentCart(container.read(posNewSaleCartProvider));
    expect(second, isNull);
    await first;
    expect(repo.created, hasLength(1));
  });

  test('changed note after failure rotates idempotency key', () async {
    final repo = _FakeRepository(failCreates: 1);
    final container = _container(repo);
    addTearDown(container.dispose);
    container.read(posNewSaleCartProvider.notifier).addToCart(_product);
    await container.read(posParkedSaleProvider.future);
    final notifier = container.read(posParkedSaleProvider.notifier);
    await expectLater(
        notifier.saveCurrentCart(container.read(posNewSaleCartProvider),
            referenceDetails: const PosParkedSaleReference(
                referenceName: 'Walk in', note: 'first')),
        throwsA(isA<PosCheckoutApiException>()));
    await notifier.saveCurrentCart(container.read(posNewSaleCartProvider),
        referenceDetails: const PosParkedSaleReference(
            referenceName: 'Walk in', note: 'changed'));
    expect(
        repo.created[0].idempotencyKey, isNot(repo.created[1].idempotencyKey));
  });

  test('legacy local records are not merged into backend list', () async {
    final repo = _FakeRepository();
    final container = _container(repo);
    addTearDown(container.dispose);
    expect(await container.read(posParkedSaleProvider.future), isEmpty);
  });

  test('recall preserves the parked product image in the restored cart', () {
    final parked = PosParkedSale.fromBackend(_holdWithImage);
    final recalled = parked.toRecalledCart(_recalledHold);

    expect(
      recalled.itemList.single.product.imageUrl,
      'https://cdn.example.test/general-admission.png',
    );
  });

  test('list sends the trusted deviceId as a query parameter', () async {
    final repo = _FakeRepository();
    final container = _container(repo);
    addTearDown(container.dispose);
    await container.read(posParkedSaleProvider.future);
    expect(repo.listedDeviceIds, ['11111111-1111-1111-1111-111111111111']);
  });

  test('list defaults to today and exposes authoritative aggregate metadata',
      () async {
    final repo = _FakeRepository(
      listResult: const PosHoldListDto(
        [],
        8,
        totalValue: 58300,
        currency: 'LKR',
        page: 1,
        pageSize: 25,
      ),
    );
    final container = _container(repo);
    addTearDown(container.dispose);
    await container.read(posParkedSaleProvider.future);
    final notifier = container.read(posParkedSaleProvider.notifier);
    expect(repo.listedScopes, ['today']);
    expect(repo.listedPages, [1]);
    expect(repo.listedPageSizes, [25]);
    expect(notifier.totalCount, 8);
    expect(notifier.totalValue, 58300);
    expect(notifier.currency, 'LKR');
  });

  test('selecting This Shift resets page and requests current-shift scope',
      () async {
    final repo = _FakeRepository();
    final container = _container(repo);
    addTearDown(container.dispose);
    await container.read(posParkedSaleProvider.future);
    await container
        .read(posParkedSaleProvider.notifier)
        .selectScope(PosParkedSaleScope.currentShift);
    expect(repo.listedScopes, ['today', 'current-shift']);
    expect(repo.listedPages, [1, 1]);
  });

  group('itemPreview', () {
    test('single named line shows that name only', () {
      final sale = _saleWithNames(['General Admission']);
      expect(sale.itemPreview, 'General Admission');
    });

    test('two named lines are joined with a comma', () {
      final sale = _saleWithNames(['General Admission', 'VIP Pass']);
      expect(sale.itemPreview, 'General Admission, VIP Pass');
    });

    test(
        'more than two lines show the first two plus a remainder count '
        'based on total line count, not quantity', () {
      final sale = _saleWithNames(
        ['General Admission', 'VIP Pass', 'Parking', 'Merch Bundle'],
        quantities: [5, 1, 1, 1],
      );
      expect(sale.itemPreview, 'General Admission, VIP Pass +2 more');
    });

    test('preserves backend line order', () {
      final sale = _saleWithNames(['Zeta', 'Alpha', 'Mid']);
      expect(sale.itemPreview, 'Zeta, Alpha +1 more');
    });

    test('skips null/empty names but still counts total lines toward N', () {
      final sale = _saleWithNames(['', 'General Admission', '  ', 'VIP Pass']);
      // 4 total lines, first two non-empty names taken, remainder = 4 - 2.
      expect(sale.itemPreview, 'General Admission, VIP Pass +2 more');
    });

    test('all-empty names fall back to unavailable text', () {
      final sale = _saleWithNames(['', '   ']);
      expect(sale.itemPreview, 'Items unavailable');
    });
  });
}

ProviderContainer _container(_FakeRepository repo,
        {Set<String>? permissions}) =>
    ProviderContainer(overrides: [
      posParkedSaleRepositoryProvider.overrideWithValue(repo),
      posParkedSaleAccessContextProvider
          .overrideWithValue(PosParkedSaleAccessContext(
              authenticated: true,
              trustedDevice: true,
              deviceId: '11111111-1111-1111-1111-111111111111',
              permissions: permissions ??
                  {
                    PosPermissionCodes.createParkedSale,
                    PosPermissionCodes.viewBackendParkedSales,
                    PosPermissionCodes.recallBackendParkedSale
                  })),
    ]);

class _FakeRepository implements PosParkedSaleRepository {
  _FakeRepository({this.failCreates = 0, this.listResult});
  int failCreates;
  final PosHoldListDto? listResult;
  final created = <PosCreateHoldRequestDto>[];
  final listedDeviceIds = <String>[];
  final listedScopes = <String>[];
  final listedPages = <int>[];
  final listedPageSizes = <int>[];
  @override
  Future<PosHoldDto> create(PosCreateHoldRequestDto request) async {
    created.add(request);
    if (failCreates-- > 0) {
      throw PosCheckoutApiException(
          message: 'timeout', isNetworkUnavailable: true);
    }
    return _hold;
  }

  @override
  Future<PosHoldListDto> list(
      {required String deviceId,
      required String scope,
      required int page,
      required int pageSize}) async {
    listedDeviceIds.add(deviceId);
    listedScopes.add(scope);
    listedPages.add(page);
    listedPageSizes.add(pageSize);
    return listResult ?? const PosHoldListDto([], 0);
  }

  @override
  Future<void> cancel(String holdId, {String? reason}) async {}
  @override
  Future<PosRecallHoldDto> recall(String holdId, String deviceId) =>
      throw UnimplementedError();
}

/// Builds a [PosParkedSale] with cart lines named (in backend line order) by
/// [names], optionally overriding per-line [quantities] to verify that
/// [PosParkedSale.itemPreview]'s "+N more" count is derived from the total
/// line count, never from summed quantity.
PosParkedSale _saleWithNames(List<String> names, {List<int>? quantities}) {
  final items = <PosNewSaleCartItem>[
    for (var i = 0; i < names.length; i++)
      PosNewSaleCartItem(
        product: PosNewSaleProduct(
          id: 'line-$i',
          productId: 'product-$i',
          name: names[i],
          category: 'General',
          price: 1000,
        ),
        quantity: quantities != null ? quantities[i] : 1,
      ),
  ];
  return PosParkedSale(
    id: 'hold-id',
    reference: 'PS-2026-00001',
    createdAt: DateTime.utc(2026, 8, 6),
    items: items,
    subtotal: 0,
    discount: 0,
    tax: 0,
    total: 0,
  );
}

final _hold = PosHoldDto(
    holdId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    holdNumber: 'PS-2026-00001',
    saleId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    saleNumber: 'SALE-1',
    status: 'Held',
    itemCount: 1,
    subtotal: 1500,
    discount: 0,
    tax: 0,
    total: 1500,
    currency: 'LKR',
    heldAt: DateTime.utc(2026, 8, 6),
    lines: const [
      PosHoldLineDto(
          lineId: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
          variantId: 'dddddddd-dddd-dddd-dddd-dddddddddddd',
          name: 'General Admission',
          qty: 1,
          unitPrice: 1500,
          lineTotal: 1500)
    ]);
final _holdWithImage = PosHoldDto(
    holdId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    holdNumber: 'PS-2026-00001',
    saleId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    saleNumber: 'SALE-1',
    status: 'Held',
    itemCount: 1,
    subtotal: 1500,
    discount: 0,
    tax: 0,
    total: 1500,
    currency: 'LKR',
    heldAt: DateTime.utc(2026, 8, 6),
    lines: const [
      PosHoldLineDto(
          lineId: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
          variantId: 'dddddddd-dddd-dddd-dddd-dddddddddddd',
          name: 'General Admission',
          imageUrl: 'https://cdn.example.test/general-admission.png',
          qty: 1,
          unitPrice: 1500,
          lineTotal: 1500)
    ]);
final _recalledHold = PosRecallHoldDto(
  holdId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  saleId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  holdNumber: 'PS-2026-00001',
  deviceId: '11111111-1111-1111-1111-111111111111',
  saleType: 'NewSale',
  recalledAt: DateTime.utc(2026, 8, 6),
  lines: const [
    PosCheckoutLineRequest(
      variantId: 'dddddddd-dddd-dddd-dddd-dddddddddddd',
      quantity: 1,
    ),
  ],
  checkoutSummary: PosCheckoutSummaryPayload(
    billingSummary: const PosCheckoutBillingSummaryPayload(
      itemCount: 1,
      subtotal: 1500,
      discount: 0,
      tax: 0,
      totalPayable: 1500,
      currency: 'LKR',
    ),
    saleDetails: PosCheckoutSaleDetailsPayload(
      saleType: 'NewSale',
      itemsInCart: 1,
      saleDate: DateTime.utc(2026, 8, 6),
      cashierName: 'Cashier',
    ),
    paymentMethods: const ['cash'],
    validationMessages: const [],
  ),
);
const _product = PosNewSaleProduct(
    id: 'p1',
    productId: 'p1',
    variantId: 'dddddddd-dddd-dddd-dddd-dddddddddddd',
    name: 'General Admission',
    category: 'Tickets',
    price: 1500);
const _cart =
    PosNewSaleCartState(items: {'x': PosNewSaleCartItem(product: _product)});
