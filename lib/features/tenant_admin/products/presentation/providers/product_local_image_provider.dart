import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductLocalImageCache extends StateNotifier<Map<String, Uint8List>> {
  ProductLocalImageCache() : super(const {});

  void save(String productId, Uint8List bytes) {
    state = {...state, productId: bytes};
  }

  Uint8List? read(String productId) => state[productId];
}

final productLocalImageCacheProvider =
    StateNotifierProvider<ProductLocalImageCache, Map<String, Uint8List>>(
  (ref) => ProductLocalImageCache(),
);
