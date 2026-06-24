class PosFeatureCodes {
  const PosFeatureCodes._();

  static const sales = 'pos.sales';
  static const customers = 'pos.customers';
  static const discounts = 'pos.discounts';
  static const returns = 'pos.returns';
  static const exchanges = 'pos.exchanges';
  static const onlineOrders = 'pos.online_orders';
  static const till = 'pos.till';
  static const hardware = 'pos.hardware';
}

class PosPermissionCodes {
  const PosPermissionCodes._();

  static const startSale = 'pos.sale.start';
  static const viewDashboard = 'pos.dashboard.view';
  static const viewNewSale = 'pos.new_sale.view';
  static const createSale = 'sales.create';
  static const viewSales = 'sales.view';
  static const viewProducts = 'products.view';
  static const searchProducts = 'products.search';
  static const manageCart = 'sales.cart.manage';
  static const addCartItem = 'sales.cart.add_item';
  static const updateCartItem = 'sales.cart.update_item';
  static const removeCartItem = 'sales.cart.remove_item';
  static const clearCart = 'sales.cart.clear';
  static const viewNewSaleCustomers = 'customers.view';
  static const createNewSaleCustomer = 'customers.create';
  static const applySaleDiscount = 'sales.discount.apply';
  static const createParkedSale = 'sales.park.create';
  static const checkoutSale = 'sales.checkout';
  static const acceptCashPayment = 'payments.cash.accept';
  static const acceptCardPayment = 'payments.card.accept';
  static const acceptQrPayment = 'payments.qr.accept';
  static const acceptSplitPayment = 'payments.split.accept';
  static const viewReceipts = 'receipts.view';
  static const printReceipts = 'receipts.print';
  static const viewOrders = 'orders.view';
  static const viewReturns = 'returns.view';
  static const viewRefunds = 'refunds.view';
  static const createRefund = 'refunds.create';
  static const viewCashDrawer = 'cash_drawer.view';
  static const manageCashDrawer = 'cash_drawer.manage';
  static const createCashDrawerMovement = 'cash_drawer.movement.create';
  static const viewTillSession = 'till.session.view';
  static const viewNotifications = 'notifications.view';
  static const parkSale = 'pos.sale.park';
  static const recallSale = 'pos.sale.recall';
  static const viewParkedSales = 'pos.sale.park.view';
  static const viewCustomers = 'pos.customers.view';
  static const createCustomer = 'pos.customers.create';
  static const applyDiscount = 'pos.discount.apply';
  static const processRefund = 'pos.refund.process';
  static const processExchange = 'pos.exchange.process';
  static const manageOnlineOrders = 'pos.online_orders.manage';
  static const openTill = 'pos.till.open';
  static const viewTill = 'pos.till.view';
  static const viewHome = 'pos.home.view';
  static const cashMovement = 'pos.till.cash_movement';
  static const closeTill = 'pos.till.close';
  static const hardwareSettings = 'pos.hardware.settings';
}
