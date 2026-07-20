class ApiEndpoints {
  const ApiEndpoints._();

  static const activateDevice = '/api/v1/devices/activate';
  static const currentDevice = '/api/v1/devices/current';
  static const openTill = '/api/v1/tills/open';
  static const closeTill = '/api/v1/tills/close';
  static const tenantLogin = '/api/v1/tenant-auth/login';
  static const tenantRefresh = '/api/v1/tenant-auth/refresh';
  static const tenantLogout = '/api/v1/tenant-auth/logout';

  static const tenantAdminOutlets = '/api/v1/tenant-admin/outlets';
  static const tenantAdminOutletOptions =
      '/api/v1/tenant-admin/outlets/options';
  static String tenantAdminOutlet(String id) =>
      '/api/v1/tenant-admin/outlets/$id';
  static String tenantAdminOutletStatus(String id) =>
      '/api/v1/tenant-admin/outlets/$id/status';
  static const tenantAdminTills = '/api/v1/tenant-admin/tills';
  static String tenantAdminTill(String id) => '/api/v1/tenant-admin/tills/$id';
  static const tenantAdminStaffManagers = '/api/v1/tenant-admin/staff/managers';

  static const currentTillSession = '/api/v1/tills/current-session';
  static const posHome = '/api/v1/pos/home';
  static const posProducts = '/api/v1/pos/products';
  static const posCatalogCategories = '/api/v1/pos/catalog/categories';
  static const posCheckoutSummary = '/api/v1/pos/checkout/summary';
  static const posCheckoutStartPayment = '/api/v1/pos/checkout/start-payment';
  static const posCustomers = '/api/v1/customers';
  static const posCustomersSummary = '/api/v1/customers/summary';
  static String posCustomer(String customerId) => '/api/v1/customers/$customerId';
  static String posCustomerOrders(String customerId) =>
      '/api/v1/customers/$customerId/orders';
  static String posCustomerAttachToSale(String customerId) =>
      '/api/v1/customers/$customerId/attach-to-sale';
  static const posDiscounts = '/api/v1/pos/discounts';
  static const posDiscountValidate = '/api/v1/pos/discounts/validate';
  static const posDiscountApply = '/api/v1/pos/discounts/apply';
  static String posDiscountApprove(String applicationId) =>
      '/api/v1/pos/discounts/$applicationId/approve';

  static const posReturnSaleSearch = '/api/v1/pos/returns/sales/search';
  static const posReturnReasons = '/api/v1/pos/returns/reasons';
  static String posReturnSaleReasonsValidate(String saleId) =>
      '/api/v1/pos/returns/sales/$saleId/reasons/validate';
  static const posReturnInspectionConditions =
      '/api/v1/pos/returns/inspection/conditions';

  static String posReturnSaleInspectionValidate(String saleId) =>
      '/api/v1/pos/returns/sales/$saleId/inspection/validate';

  static String posReturnSaleInspectionDraft(String saleId) =>
      '/api/v1/pos/returns/sales/$saleId/inspection/draft';

  static String posReturnSaleInspectionMedia(String saleId) =>
      '/api/v1/pos/returns/sales/$saleId/inspection/media';

  static String posReturnInspectionMedia(String mediaId) =>
      '/api/v1/pos/returns/inspection/media/$mediaId';

  static String posReturnSaleEligibility(String saleId) =>
      '/api/v1/pos/returns/sales/$saleId/eligibility';

  static String posReturnSaleEligibilityCheck(String saleId) =>
      '/api/v1/pos/returns/sales/$saleId/eligibility-check';

  static String posReturnSaleCreditPreview(String saleId) =>
      '/api/v1/pos/returns/sales/$saleId/credit-preview';

  static String posReturnSaleComplete(String saleId) =>
      '/api/v1/pos/returns/sales/$saleId/complete';

  static String posReturnCompletion(String returnId) =>
      '/api/v1/pos/returns/completions/$returnId';

  static String posReturnSaleResolution(String saleId) =>
      '/api/v1/pos/returns/sales/$saleId/resolution';

  static String posReturnSaleRefundMethods(String saleId) =>
      '/api/v1/pos/returns/sales/$saleId/refund-methods';

  static String posReturnSaleRefundMethod(String saleId) =>
      '/api/v1/pos/returns/sales/$saleId/refund-method';

  static String posReturnSaleExchangeProducts(String saleId) =>
      '/api/v1/pos/returns/sales/$saleId/exchange/products';

  static String posReturnSaleExchangeReplacement(String saleId) =>
      '/api/v1/pos/returns/sales/$saleId/exchange/replacement';

  static String posReturnSaleExchangePreview(String saleId) =>
      '/api/v1/pos/returns/sales/$saleId/exchange-preview';

  static String posReceipt(String saleId) => '/api/v1/pos/receipts/$saleId';

  static String posReceiptPrint(String saleId) =>
      '/api/v1/pos/receipts/$saleId/print';

  static String posProductDetail(String productId) =>
      '/api/v1/pos/products/$productId';

  static String posProductVariants(String productId) =>
      '/api/v1/pos/products/$productId/variants';
}
