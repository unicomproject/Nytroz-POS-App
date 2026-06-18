class ApiEndpoints {
  const ApiEndpoints._();

  static const activateDevice = '/api/v1/devices/activate';
  static const currentDevice = '/api/v1/devices/current';
  static const openTill = '/api/v1/tills/open';

  static const currentTillSession = '/api/v1/tills/current-session';
  static const posHome = '/api/v1/pos/home';
  static const posProducts = '/api/v1/pos/products';
  static const posCatalogCategories = '/api/v1/pos/catalog/categories';

  static String posProductDetail(String productId) =>
      '/api/v1/pos/products/$productId';

  static String posProductVariants(String productId) =>
      '/api/v1/pos/products/$productId/variants';
}
