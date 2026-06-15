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
