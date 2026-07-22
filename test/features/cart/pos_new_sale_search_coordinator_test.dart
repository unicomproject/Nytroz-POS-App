import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_search_coordinator.dart';

void main() {
  test('scanner cleanup clears query and invalidates pending debounce', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(posNewSaleSearchCancellationProvider, (_, __) {},
        fireImmediately: true);

    container.read(posNewSaleSearchQueryProvider.notifier).state =
        '82111001003';
    final before = container.read(posNewSaleSearchCancellationProvider);

    container.read(posNewSaleSearchCoordinatorProvider).clearForScanner();

    expect(container.read(posNewSaleSearchQueryProvider), isEmpty);
    expect(container.read(posNewSaleSearchCancellationProvider), before + 1);
  });

  test('manual query remains unchanged without scanner completion', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(posNewSaleSearchQueryProvider.notifier).state = 'jersey';

    expect(container.read(posNewSaleSearchQueryProvider), 'jersey');
    expect(container.read(posNewSaleSearchCancellationProvider), 0);
  });
}
