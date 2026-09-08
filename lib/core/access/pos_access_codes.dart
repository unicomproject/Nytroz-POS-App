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
  static const viewNewSaleCustomers = 'pos.customers.management.view';
  static const createNewSaleCustomer = 'pos.customers.management.create';
  static const updateNewSaleCustomer = 'pos.customers.management.update';
  static const applySaleDiscount = 'sales.discount.apply';
  static const approveSaleDiscount = 'sales.discount.approve';
  static const createParkedSale = 'sales.park.create';
  static const viewBackendParkedSales = 'sales.park.view';
  static const recallBackendParkedSale = 'sales.park.recall';

  /// Canonical held-sales codes (Chunk 2). Prefer these over legacy park aliases.
  static const heldSalesCreate = 'pos.sales.held_sales.create';
  static const heldSalesView = 'pos.sales.held_sales.view';
  static const heldSalesRecall = 'pos.sales.held_sales.recall';
  static const heldSalesCancel = 'pos.sales.held_sales.cancel';

  static const checkoutSale = 'pos.sales.checkout.execute';
  static const acceptCashPayment = 'pos.payments.cash.accept';
  static const acceptCardPayment = 'pos.payments.card.accept';
  static const acceptQrPayment = 'pos.payments.qr.accept';
  static const acceptSplitPayment = 'pos.payments.split.accept';

  /// Chunk 2 checkout / payment-method chrome (catalog mirrors only).
  static const checkoutMethodsContainer = 'pos.checkout.methods.container';
  static const checkoutMethodsCashTile = 'pos.checkout.methods.cash_tile';
  static const checkoutMethodsCardTile = 'pos.checkout.methods.card_tile';
  static const checkoutMethodsQrTile = 'pos.checkout.methods.qr_tile';
  static const checkoutMethodsSplitTile = 'pos.checkout.methods.split_tile';
  static const checkoutCustomerSummary = 'pos.checkout.customer.summary';
  static const checkoutSummaryPayment = 'pos.checkout.summary.payment';
  static const checkoutSummaryItems = 'pos.checkout.summary.items';
  static const checkoutSummaryQuantity = 'pos.checkout.summary.quantity';
  static const checkoutSummaryPrice = 'pos.checkout.summary.price';
  static const checkoutSummaryLineTotal = 'pos.checkout.summary.line_total';
  static const checkoutSummarySubtotal = 'pos.checkout.summary.subtotal';
  static const checkoutSummaryDiscount = 'pos.checkout.summary.discount';
  static const checkoutSummaryTax = 'pos.checkout.summary.tax';
  static const checkoutSummaryTotal = 'pos.checkout.summary.total';

  /// Chunk 2 cash payment children (catalog mirrors only).
  static const cashPaymentSummaryOrder = 'pos.cash_payment.summary.order';
  static const cashPaymentLineItem = 'pos.cash_payment.line.item';
  static const cashPaymentLineQuantity = 'pos.cash_payment.line.quantity';
  static const cashPaymentLinePrice = 'pos.cash_payment.line.price';
  static const cashPaymentLineItemTotal = 'pos.cash_payment.line.item_total';
  static const cashPaymentSummarySubtotal = 'pos.cash_payment.summary.subtotal';
  static const cashPaymentSummaryDiscount = 'pos.cash_payment.summary.discount';
  static const cashPaymentSummaryTax = 'pos.cash_payment.summary.tax';
  static const cashPaymentSummaryTotalDue = 'pos.cash_payment.summary.total_due';
  static const cashPaymentTenderAmountReceivedView =
      'pos.cash_payment.tender.amount_received_view';
  static const cashPaymentTenderAmountReceivedEntry =
      'pos.cash_payment.tender.amount_received_entry';
  static const cashPaymentTenderDueAmount = 'pos.cash_payment.tender.due_amount';
  static const cashPaymentTenderExact = 'pos.cash_payment.tender.exact';
  static const cashPaymentTenderChangeDue = 'pos.cash_payment.tender.change_due';
  static const cashPaymentQuickAmountsContainer =
      'pos.cash_payment.quick_amounts.container';
  static const cashPaymentQuickAmountsSlot1 =
      'pos.cash_payment.quick_amounts.slot_1';
  static const cashPaymentQuickAmountsSlot2 =
      'pos.cash_payment.quick_amounts.slot_2';
  static const cashPaymentQuickAmountsSlot3 =
      'pos.cash_payment.quick_amounts.slot_3';
  static const cashPaymentNumpadContainer = 'pos.cash_payment.numpad.container';
  static const cashPaymentNumpadDigit0 = 'pos.cash_payment.numpad.digit_0';
  static const cashPaymentNumpadDigit1 = 'pos.cash_payment.numpad.digit_1';
  static const cashPaymentNumpadDigit2 = 'pos.cash_payment.numpad.digit_2';
  static const cashPaymentNumpadDigit3 = 'pos.cash_payment.numpad.digit_3';
  static const cashPaymentNumpadDigit4 = 'pos.cash_payment.numpad.digit_4';
  static const cashPaymentNumpadDigit5 = 'pos.cash_payment.numpad.digit_5';
  static const cashPaymentNumpadDigit6 = 'pos.cash_payment.numpad.digit_6';
  static const cashPaymentNumpadDigit7 = 'pos.cash_payment.numpad.digit_7';
  static const cashPaymentNumpadDigit8 = 'pos.cash_payment.numpad.digit_8';
  static const cashPaymentNumpadDigit9 = 'pos.cash_payment.numpad.digit_9';
  static const cashPaymentNumpadDigit00 = 'pos.cash_payment.numpad.digit_00';
  static const cashPaymentNumpadDecimal = 'pos.cash_payment.numpad.decimal';
  static const cashPaymentControlsBackspace =
      'pos.cash_payment.controls.backspace';
  static const cashPaymentControlsClear = 'pos.cash_payment.controls.clear';
  static const cashPaymentCompletionExecute =
      'pos.cash_payment.completion.execute';

  /// Chunk 2 sale-complete / receipt presentation (catalog mirrors only).
  static const saleCompleteMessageSuccess = 'pos.sale_complete.message.success';
  static const saleCompleteDetailsReceiptNumber =
      'pos.sale_complete.details.receipt_number';
  static const saleCompleteDetailsPaymentMethod =
      'pos.sale_complete.details.payment_method';
  static const saleCompleteDetailsDatetime =
      'pos.sale_complete.details.datetime';
  static const saleCompleteDetailsCashier = 'pos.sale_complete.details.cashier';
  static const saleCompleteDetailsCustomer =
      'pos.sale_complete.details.customer';
  static const saleCompleteDetailsCashReceived =
      'pos.sale_complete.details.cash_received';
  static const saleCompleteDetailsChangeDue =
      'pos.sale_complete.details.change_due';
  static const saleCompleteDetailsTotalPaid =
      'pos.sale_complete.details.total_paid';

  static const receiptsPhysicalPrint = 'pos.receipts.physical.print';
  static const receiptsHistoryReprint = 'pos.receipts.history.reprint';
  static const receiptsDetailsStore = 'pos.receipts.details.store';
  static const receiptsDetailsReceiptNumber =
      'pos.receipts.details.receipt_number';
  static const receiptsDetailsDatetime = 'pos.receipts.details.datetime';
  static const receiptsDetailsCashier = 'pos.receipts.details.cashier';
  static const receiptsDetailsCustomer = 'pos.receipts.details.customer';
  static const receiptsDetailsTerminal = 'pos.receipts.details.terminal';
  static const receiptsDetailsPaymentMethod =
      'pos.receipts.details.payment_method';
  static const receiptsDetailsItems = 'pos.receipts.details.items';
  static const receiptsDetailsItemQuantity =
      'pos.receipts.details.item_quantity';
  static const receiptsDetailsItemValue = 'pos.receipts.details.item_value';
  static const receiptsDetailsItemRate = 'pos.receipts.details.item_rate';
  static const receiptsDetailsSubtotal = 'pos.receipts.details.subtotal';
  static const receiptsDetailsDiscount = 'pos.receipts.details.discount';
  static const receiptsDetailsTotal = 'pos.receipts.details.total';
  static const receiptsDetailsPaidAmount = 'pos.receipts.details.paid_amount';
  static const receiptsDetailsChangeDue = 'pos.receipts.details.change_due';

  /// Canonical cash-drawer movement splits (Chunk 2 definitions only).
  static const cashDrawerCashIn = 'pos.cash_drawer.movements.cash_in';
  static const cashDrawerCashOut = 'pos.cash_drawer.movements.cash_out';
  static const cashDrawerCashDrop = 'pos.cash_drawer.movements.cash_drop';
  static const customersAttachSale = 'pos.customers.management.attach_sale';
  static const customersDeactivate = 'pos.customers.management.deactivate';

  /// Chunk 2 customer list / detail / history mirrors (catalog codes only).
  static const customersListSearch = 'pos.customers.list.search';
  static const customersListFilters = 'pos.customers.list.filters';
  static const customersListId = 'pos.customers.list.id';
  static const customersListName = 'pos.customers.list.name';
  static const customersListPhone = 'pos.customers.list.phone';
  static const customersListEmail = 'pos.customers.list.email';
  static const customersListSource = 'pos.customers.list.source';
  static const customersListStatus = 'pos.customers.list.status';
  static const customersListOrderCount = 'pos.customers.list.order_count';
  static const customersListTotalSpend = 'pos.customers.list.total_spend';
  static const customersListPagination = 'pos.customers.list.pagination';
  static const customersDetailsJoinedDate = 'pos.customers.details.joined_date';
  static const customersDetailsAverageOrderValue =
      'pos.customers.details.average_order_value';
  static const customersHistoryRecentPurchases =
      'pos.customers.history.recent_purchases';
  static const customersHistoryPurchaseAmounts =
      'pos.customers.history.purchase_amounts';
  static const customersHistoryPurchaseHistory =
      'pos.customers.history.purchase_history';

  static const returnsWorkflowCreate = 'pos.returns.workflow.create';
  static const shellNavigationSettings = 'pos.shell.navigation.settings';
  static const shellNavigationOfflineBanner =
      'pos.shell.navigation.offline_banner';

  /// Chunk 2 shell top-bar / bottom-nav mirrors (catalog codes only).
  static const shellTopbarContainer = 'pos.shell.topbar.container';
  static const shellTopbarBrand = 'pos.shell.topbar.brand';
  static const shellTopbarSessionStatus = 'pos.shell.topbar.session_status';
  static const shellTopbarOutlet = 'pos.shell.topbar.outlet';
  static const shellTopbarTill = 'pos.shell.topbar.till';
  static const shellTopbarConnectivity = 'pos.shell.topbar.connectivity';
  static const shellTopbarClock = 'pos.shell.topbar.clock';
  static const shellTopbarNotificationBell =
      'pos.shell.topbar.notification_bell';
  static const shellBottomNavContainer = 'pos.shell.bottom_nav.container';

  /// Chunk 2 destination REUSE mirrors (not shell aliases).
  static const salesDashboardView = 'pos.sales.dashboard.view';
  static const salesNewSaleView = 'pos.sales.new_sale.view';
  static const receiptsDigitalView = 'pos.receipts.digital.view';

  /// Chunk 2 notification child mirrors under alerts.view parent.
  static const notificationsPanelView = 'pos.notifications.panel.view';
  static const notificationsPanelUnreadCount =
      'pos.notifications.panel.unread_count';
  static const notificationsMessagesList = 'pos.notifications.messages.list';
  static const notificationsMessagesTitle = 'pos.notifications.messages.title';
  static const notificationsMessagesBody = 'pos.notifications.messages.body';
  static const notificationsMessagesTimestamp =
      'pos.notifications.messages.timestamp';
  static const notificationsMessagesOpen = 'pos.notifications.messages.open';
  static const notificationsMessagesMarkRead =
      'pos.notifications.messages.mark_read';
  static const notificationsMessagesDismiss =
      'pos.notifications.messages.dismiss';
  static const notificationsMessagesMarkAllRead =
      'pos.notifications.messages.mark_all_read';

  /// Chunk 2 Home / Sales / Catalog / Cart / Held mirrors (catalog codes only).
  static const homeProfileView = 'pos.home.profile.view';
  static const homeProfileAvatar = 'pos.home.profile.avatar';
  static const homeProfileName = 'pos.home.profile.name';
  static const homeProfileRole = 'pos.home.profile.role';
  static const homeSessionSummaryView = 'pos.home.session_summary.view';
  static const homeSessionSummaryTotalSales =
      'pos.home.session_summary.total_sales';
  static const homeSessionSummaryTransactionCount =
      'pos.home.session_summary.transaction_count';
  static const homeSessionSummaryReturns = 'pos.home.session_summary.returns';
  static const homeSessionSummaryDiscounts =
      'pos.home.session_summary.discounts';
  static const homeSessionSummaryNetSales =
      'pos.home.session_summary.net_sales';
  static const homeActionsOnlineOrdersEntry =
      'pos.home.actions.online_orders_entry';
  static const homeActionsReturnsEntry = 'pos.home.actions.returns_entry';

  static const cashDrawerPositionView = 'pos.cash_drawer.position.view';
  static const tillSessionClose = 'pos.till.session.close';
  static const returnsSearchSaleView = 'pos.returns.search_sale.view';

  static const salesCatalogView = 'pos.sales.catalog.view';
  static const salesCatalogSearch = 'pos.sales.catalog.search';
  static const catalogSearchBar = 'pos.catalog.search.bar';
  static const catalogSearchClear = 'pos.catalog.search.clear';
  static const catalogSearchResults = 'pos.catalog.search.results';
  static const catalogSearchEmptyState = 'pos.catalog.search.empty_state';
  static const catalogSearchScannerHint = 'pos.catalog.search.scanner_hint';
  static const catalogSectionsQuickProducts =
      'pos.catalog.sections.quick_products';
  static const catalogSectionsPopular = 'pos.catalog.sections.popular';
  static const catalogSectionsFrequentlySold =
      'pos.catalog.sections.frequently_sold';
  static const catalogSectionsOffers = 'pos.catalog.sections.offers';
  static const catalogSectionsSort = 'pos.catalog.sections.sort';

  static const catalogProductCardImage = 'pos.catalog.product_card.image';
  static const catalogProductCardName = 'pos.catalog.product_card.name';
  static const catalogProductCardRegularPrice =
      'pos.catalog.product_card.regular_price';
  static const catalogProductCardSalePrice =
      'pos.catalog.product_card.sale_price';
  static const catalogProductCardDiscountBadge =
      'pos.catalog.product_card.discount_badge';
  static const catalogProductCardOpenDetails =
      'pos.catalog.product_card.open_details';

  static const catalogProductDetailView = 'pos.catalog.product_detail.view';
  static const catalogProductDetailClose = 'pos.catalog.product_detail.close';
  static const catalogProductDetailImage = 'pos.catalog.product_detail.image';
  static const catalogProductDetailName = 'pos.catalog.product_detail.name';
  static const catalogProductDetailPrice = 'pos.catalog.product_detail.price';
  static const catalogProductDetailStock = 'pos.catalog.product_detail.stock';
  static const catalogProductDetailSku = 'pos.catalog.product_detail.sku';
  static const catalogProductDetailDescription =
      'pos.catalog.product_detail.description';
  static const catalogProductDetailVariants =
      'pos.catalog.product_detail.variants';
  static const catalogProductDetailVariantSelect =
      'pos.catalog.product_detail.variant_select';
  static const catalogProductDetailAvailableQty =
      'pos.catalog.product_detail.available_qty';
  static const catalogProductDetailQuantityDisplay =
      'pos.catalog.product_detail.quantity_display';
  static const catalogProductDetailNoteView =
      'pos.catalog.product_detail.note_view';
  static const catalogProductDetailNoteEntry =
      'pos.catalog.product_detail.note_entry';
  static const catalogProductDetailRecommendations =
      'pos.catalog.product_detail.recommendations';
  static const catalogProductDetailCancel =
      'pos.catalog.product_detail.cancel';

  static const salesCartManage = 'pos.sales.cart.manage';
  static const salesCartAddItem = 'pos.sales.cart.add_item';
  static const salesCartUpdateItem = 'pos.sales.cart.update_item';
  static const salesCartClear = 'pos.sales.cart.clear';
  static const salesManualDiscountApply = 'pos.sales.manual_discount.apply';
  static const salesCheckoutExecute = 'pos.sales.checkout.execute';
  static const salesNewSaleCreate = 'pos.sales.new_sale.create';

  static const cartSummaryView = 'pos.cart.summary.view';
  static const cartSummaryItemCount = 'pos.cart.summary.item_count';
  static const cartSummarySubtotal = 'pos.cart.summary.subtotal';
  static const cartSummaryDiscount = 'pos.cart.summary.discount';
  static const cartSummaryTax = 'pos.cart.summary.tax';
  static const cartSummaryTotal = 'pos.cart.summary.total';
  static const cartLinesList = 'pos.cart.lines.list';
  static const cartLinesName = 'pos.cart.lines.name';
  static const cartLinesQuantity = 'pos.cart.lines.quantity';
  static const cartLinesUnitPrice = 'pos.cart.lines.unit_price';
  static const cartLinesLineTotal = 'pos.cart.lines.line_total';
  static const cartLinesNote = 'pos.cart.lines.note';
  static const cartLinesImage = 'pos.cart.lines.image';

  static const newSaleChromeHeader = 'pos.new_sale.chrome.header';
  static const newSaleChromeParkAction = 'pos.new_sale.chrome.park_action';
  static const newSaleChromeCustomerChip = 'pos.new_sale.chrome.customer_chip';
  static const newSaleChromeEmptyCart = 'pos.new_sale.chrome.empty_cart';
  static const newSaleChromeCheckoutAction =
      'pos.new_sale.chrome.checkout_action';
  static const newSaleChromeHeldCount = 'pos.new_sale.chrome.held_count';
  static const newSaleChromeClearCartAction =
      'pos.new_sale.chrome.clear_cart_action';

  static const discountPanelView = 'pos.discount.panel.view';
  static const discountPanelAmountEntry = 'pos.discount.panel.amount_entry';
  static const discountPanelReasonEntry = 'pos.discount.panel.reason_entry';
  static const discountPanelApplyAction = 'pos.discount.panel.apply_action';
  static const discountPanelCancelAction = 'pos.discount.panel.cancel_action';

  static const heldSalesPopupView = 'pos.held_sales.popup.view';
  static const heldSalesPopupReference = 'pos.held_sales.popup.reference';
  static const heldSalesPopupNote = 'pos.held_sales.popup.note';
  static const heldSalesPopupExpiry = 'pos.held_sales.popup.expiry';
  static const heldSalesListFilters = 'pos.held_sales.list.filters';
  static const heldSalesListActiveCount = 'pos.held_sales.list.active_count';
  static const heldSalesListCustomer = 'pos.held_sales.list.customer';
  static const heldSalesListValue = 'pos.held_sales.list.value';
  static const heldSalesListItemCount = 'pos.held_sales.list.item_count';
  static const heldSalesListParkedTime = 'pos.held_sales.list.parked_time';
  static const heldSalesListExpiryTime = 'pos.held_sales.list.expiry_time';
  static const heldSalesListItems = 'pos.held_sales.list.items';
  static const heldSalesListPagination = 'pos.held_sales.list.pagination';
  static const heldSalesListSummary = 'pos.held_sales.list.summary';

  static const viewReceipts = 'receipts.view';
  static const printReceipts = 'receipts.print';
  static const reprintReceipts = 'receipts.reprint';
  static const viewOrders = 'orders.view';
  static const viewReturns = 'returns.view';
  static const createReturn = 'returns.create';
  static const viewRefunds = 'refunds.view';
  static const createRefund = 'refunds.create';
  static const viewExchanges = 'exchanges.view';
  static const createExchange = 'exchanges.create';
  static const approveRefund = 'pos.refund.approve';
  static const viewCashDrawer = 'cash_drawer.view';
  static const manageCashDrawer = 'cash_drawer.manage';
  static const createCashDrawerMovement = 'cash_drawer.movement.create';
  static const viewTillSession = 'till.session.view';
  static const viewNotifications = 'pos.notifications.alerts.view';

  /// Legacy alias — prefer [createParkedSale].
  static const parkSale = 'pos.sale.park';

  /// Legacy alias — prefer [recallBackendParkedSale].
  static const recallSale = 'pos.sale.recall';

  /// Legacy alias — prefer [viewBackendParkedSales].
  static const viewParkedSales = 'pos.sale.park.view';
  static const viewCustomers = 'pos.customers.management.view';
  static const createCustomer = 'pos.customers.management.create';

  /// Legacy alias — prefer [updateNewSaleCustomer].
  static const updateCustomer = 'pos.customers.management.update';
  static const applyDiscount = 'pos.discount.apply';

  /// Legacy alias — prefer [createRefund] / [approveRefund].
  static const processRefund = 'pos.refund.process';

  /// Legacy alias — prefer [createExchange].
  static const processExchange = 'pos.exchange.process';
  static const manageOnlineOrders = 'pos.online_orders.manage';
  static const accessOnlineOrders = 'commerce.online_order.orders.access';
  static const startOnlineOrderFulfillment =
      'commerce.online_order.fulfilment.start';
  static const viewOnlineOrderPicking = 'commerce.online_order.picking.view';
  static const pickOnlineOrderItem = 'commerce.online_order.picking.pick';
  static const scanOnlineOrderItem = 'commerce.online_order.picking.scan';
  static const manuallyEnterOnlineOrderItem =
      'commerce.online_order.picking.manual_entry';
  static const reportOnlineOrderPickingIssue =
      'commerce.online_order.picking.report_issue';
  static const addOnlineOrderPickingNote = 'commerce.online_order.picking.note';
  static const viewOnlineOrderPacking = 'commerce.online_order.packing.view';
  static const packOnlineOrder = 'commerce.online_order.packing.pack';
  static const markOnlineOrderReady =
      'commerce.online_order.collection.mark_ready';
  static const viewOnlineOrders = 'commerce.online_order.orders.view';
  static const openTill = 'pos.till.open';
  static const viewTill = 'pos.till.view';
  static const viewHome = 'pos.home.view';
  static const cashMovement = 'pos.till.cash_movement';
  static const closeTill = 'pos.till.close';
  static const hardwareSettings = 'pos.hardware.settings';

  // --- Chunk 13 Cash Drawer / Till (canonical mirrors) ---
  static const cashDrawerPhysicalManage = 'pos.cash_drawer.physical.manage';
  static const cashDrawerSummaryTill = 'pos.cash_drawer.summary.till';
  static const cashDrawerSummaryStatus = 'pos.cash_drawer.summary.status';
  static const cashDrawerSummaryOpeningCash =
      'pos.cash_drawer.summary.opening_cash';
  static const cashDrawerSummaryCashSales = 'pos.cash_drawer.summary.cash_sales';
  static const cashDrawerSummaryExpectedCash =
      'pos.cash_drawer.summary.expected_cash';
  static const cashDrawerMovementsList = 'pos.cash_drawer.movements.list';
  static const cashDrawerMovementsType = 'pos.cash_drawer.movements.type';
  static const cashDrawerMovementsDate = 'pos.cash_drawer.movements.date';
  static const cashDrawerMovementsTime = 'pos.cash_drawer.movements.time';
  static const cashDrawerMovementsCashier = 'pos.cash_drawer.movements.cashier';
  static const cashDrawerMovementsAmountView =
      'pos.cash_drawer.movements.amount_view';
  static const cashDrawerOpenPopupView = 'pos.cash_drawer.open_popup.view';
  static const cashDrawerOpenPopupCancel = 'pos.cash_drawer.open_popup.cancel';
  static const cashDrawerOpenPopupContinue =
      'pos.cash_drawer.open_popup.continue';
  static const cashDrawerOpenReasonProvideChange =
      'pos.cash_drawer.open_reason.provide_change';
  static const cashDrawerOpenReasonTillCheck =
      'pos.cash_drawer.open_reason.till_check';
  static const cashDrawerOpenReasonCashCount =
      'pos.cash_drawer.open_reason.cash_count';
  static const cashDrawerOpenReasonManagerOperation =
      'pos.cash_drawer.open_reason.manager_operation';
  static const cashDrawerOpenReasonOther = 'pos.cash_drawer.open_reason.other';

  static const cashMovementsCashInTill = 'pos.cash_movements.cash_in.till';
  static const cashMovementsCashInExpectedCash =
      'pos.cash_movements.cash_in.expected_cash';
  static const cashMovementsCashInAvailableCash =
      'pos.cash_movements.cash_in.available_cash';
  static const cashMovementsCashInAmountEntry =
      'pos.cash_movements.cash_in.amount_entry';
  static const cashMovementsCashInReason = 'pos.cash_movements.cash_in.reason';
  static const cashMovementsCashInNote = 'pos.cash_movements.cash_in.note';
  static const cashMovementsCashInManagerPin =
      'pos.cash_movements.cash_in.manager_pin';
  static const cashMovementsCashInSummary = 'pos.cash_movements.cash_in.summary';
  static const cashMovementsCashInResultingBalance =
      'pos.cash_movements.cash_in.resulting_balance';
  static const cashMovementsCashInValidationMessage =
      'pos.cash_movements.cash_in.validation_message';
  static const cashMovementsCashInConfirm = 'pos.cash_movements.cash_in.confirm';
  static const cashMovementsCashInCancel = 'pos.cash_movements.cash_in.cancel';

  static const cashMovementsCashOutTill = 'pos.cash_movements.cash_out.till';
  static const cashMovementsCashOutExpectedCash =
      'pos.cash_movements.cash_out.expected_cash';
  static const cashMovementsCashOutAvailableCash =
      'pos.cash_movements.cash_out.available_cash';
  static const cashMovementsCashOutAmountEntry =
      'pos.cash_movements.cash_out.amount_entry';
  static const cashMovementsCashOutReason = 'pos.cash_movements.cash_out.reason';
  static const cashMovementsCashOutNote = 'pos.cash_movements.cash_out.note';
  static const cashMovementsCashOutManagerPin =
      'pos.cash_movements.cash_out.manager_pin';
  static const cashMovementsCashOutSummary =
      'pos.cash_movements.cash_out.summary';
  static const cashMovementsCashOutResultingBalance =
      'pos.cash_movements.cash_out.resulting_balance';
  static const cashMovementsCashOutConfirm =
      'pos.cash_movements.cash_out.confirm';
  static const cashMovementsCashOutCancel = 'pos.cash_movements.cash_out.cancel';

  static const cashMovementsCashDropTill = 'pos.cash_movements.cash_drop.till';
  static const cashMovementsCashDropExpectedCash =
      'pos.cash_movements.cash_drop.expected_cash';
  static const cashMovementsCashDropAvailableCash =
      'pos.cash_movements.cash_drop.available_cash';
  static const cashMovementsCashDropAmountEntry =
      'pos.cash_movements.cash_drop.amount_entry';
  static const cashMovementsCashDropReason =
      'pos.cash_movements.cash_drop.reason';
  static const cashMovementsCashDropNote = 'pos.cash_movements.cash_drop.note';
  static const cashMovementsCashDropManagerPin =
      'pos.cash_movements.cash_drop.manager_pin';
  static const cashMovementsCashDropSummary =
      'pos.cash_movements.cash_drop.summary';
  static const cashMovementsCashDropResultingBalance =
      'pos.cash_movements.cash_drop.resulting_balance';
  static const cashMovementsCashDropConfirm =
      'pos.cash_movements.cash_drop.confirm';
  static const cashMovementsCashDropCancel =
      'pos.cash_movements.cash_drop.cancel';

  static const tillSessionOpen = 'pos.till.session.open';
  static const tillOpeningStartingCashView =
      'pos.till.opening.starting_cash_view';
  static const tillOpeningStartingCashEntry =
      'pos.till.opening.starting_cash_entry';
  static const tillOpeningValidationMessage =
      'pos.till.opening.validation_message';
  static const tillOpeningNoteView = 'pos.till.opening.note_view';
  static const tillOpeningNoteEntry = 'pos.till.opening.note_entry';
  static const tillOpeningQuickAmounts = 'pos.till.opening.quick_amounts';
  static const tillOpeningQuickSlot1 = 'pos.till.opening.quick_slot_1';
  static const tillOpeningQuickSlot2 = 'pos.till.opening.quick_slot_2';
  static const tillOpeningQuickSlot3 = 'pos.till.opening.quick_slot_3';
  static const tillOpeningNumpad = 'pos.till.opening.numpad';
  static const tillOpeningBackspace = 'pos.till.opening.backspace';
  static const tillOpeningClear = 'pos.till.opening.clear';
  static const tillOpeningConfirmMessage = 'pos.till.opening.confirm_message';
  static const tillOpeningKey0 = 'pos.till.opening.key_0';
  static const tillOpeningKey1 = 'pos.till.opening.key_1';
  static const tillOpeningKey2 = 'pos.till.opening.key_2';
  static const tillOpeningKey3 = 'pos.till.opening.key_3';
  static const tillOpeningKey4 = 'pos.till.opening.key_4';
  static const tillOpeningKey5 = 'pos.till.opening.key_5';
  static const tillOpeningKey6 = 'pos.till.opening.key_6';
  static const tillOpeningKey7 = 'pos.till.opening.key_7';
  static const tillOpeningKey8 = 'pos.till.opening.key_8';
  static const tillOpeningKey9 = 'pos.till.opening.key_9';
  static const tillOpeningKey00 = 'pos.till.opening.key_00';
  static const tillOpeningKeyDecimal = 'pos.till.opening.key_decimal';

  static const tillClosingBack = 'pos.till.closing.back';
  static const tillClosingTill = 'pos.till.closing.till';
  static const tillClosingOpenedBy = 'pos.till.closing.opened_by';
  static const tillClosingOpenedTime = 'pos.till.closing.opened_time';
  static const tillClosingExpectedCash = 'pos.till.closing.expected_cash';
  static const tillClosingCountedCashEntry =
      'pos.till.closing.counted_cash_entry';
  static const tillClosingDifference = 'pos.till.closing.difference';
  static const tillClosingBalanceStatus = 'pos.till.closing.balance_status';
  static const tillClosingMismatchReason = 'pos.till.closing.mismatch_reason';
  static const tillClosingNotes = 'pos.till.closing.notes';
  static const tillClosingSummary = 'pos.till.closing.summary';
  static const tillClosingExpectedCashSummary =
      'pos.till.closing.expected_cash_summary';
  static const tillClosingCountedCashSummary =
      'pos.till.closing.counted_cash_summary';
  static const tillClosingDifferenceSummary =
      'pos.till.closing.difference_summary';
  static const tillClosingStatusSummary = 'pos.till.closing.status_summary';
}
