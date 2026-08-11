import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';

final posNewSaleSearchCancellationProvider =
    StateProvider.autoDispose<int>((ref) => 0);

final posNewSaleSearchCoordinatorProvider =
    Provider<PosNewSaleSearchCoordinator>(PosNewSaleSearchCoordinator.new);

class PosNewSaleSearchCoordinator {
  const PosNewSaleSearchCoordinator(this.ref);

  final Ref ref;

  void clearForScanner() {
    ref.read(posNewSaleSearchQueryProvider.notifier).state = '';
    final cancellation = ref.read(posNewSaleSearchCancellationProvider);
    ref.read(posNewSaleSearchCancellationProvider.notifier).state =
        cancellation + 1;
  }
}
