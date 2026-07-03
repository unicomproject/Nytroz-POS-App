class ApiEndpoints {
  const ApiEndpoints._();

  static const activateDevice = '/api/v1/devices/activate';
  static const currentDevice = '/api/v1/devices/current';
  static const openTill = '/api/v1/tills/open';
  static const tenantLogin = '/api/v1/auth/tenant-login';

  static const tenantAdminOutlets = '/api/v1/tenant-admin/outlets';
  static String tenantAdminOutlet(String id) => '/api/v1/tenant-admin/outlets/$id';
  static String tenantAdminOutletStatus(String id) =>
      '/api/v1/tenant-admin/outlets/$id/status';
  static const tenantAdminTills = '/api/v1/tenant-admin/tills';
  static String tenantAdminTill(String id) => '/api/v1/tenant-admin/tills/$id';
  static const tenantAdminStaffManagers =
      '/api/v1/tenant-admin/staff/managers';

  static const currentTillSession = '/api/v1/tills/current-session';
  static const posHome = '/api/v1/pos/home';
  static const posProducts = '/api/v1/pos/products';
  static const posCatalogCategories = '/api/v1/pos/catalog/categories';
  static const posCheckoutSummary = '/api/v1/pos/checkout/summary';
  static const posCheckoutStartPayment = '/api/v1/pos/checkout/start-payment';
  static const posCustomers = '/api/v1/customers';

  static String posReceipt(String saleId) => '/api/v1/pos/receipts/$saleId';

  static String posReceiptPrint(String saleId) =>
      '/api/v1/pos/receipts/$saleId/print';

  static String posProductDetail(String productId) =>
      '/api/v1/pos/products/$productId';

  static String posProductVariants(String productId) =>
      '/api/v1/pos/products/$productId/variants';
}
