enum ReturnsExchangeStep {
  searchSale,
  saleSummary,
  selectItems,
  checkEligibility,
  returnReason,
  inspectItems,
  chooseOption,
  branchAction,
  reviewAndConfirm,
  receiptSuccess,
}

/// Implemented return flow states. Some visual milestones are future branch
/// states and can be displayed before they have separate routable screens.
abstract final class ReturnFlowSteps {
  static const labels = [
    'Search Sale',
    'Sale Summary',
    'Eligibility & Select Items',
    'Return Reason',
    'Create Credit',
    'Settlement',
    'Receipt',
  ];

  static const searchSale = ReturnsExchangeStep.searchSale;
  static const saleSummary = ReturnsExchangeStep.saleSummary;
  static const selectItems = ReturnsExchangeStep.selectItems;
  static const checkEligibility = ReturnsExchangeStep.checkEligibility;
  static const eligibilityAndItems = ReturnsExchangeStep.selectItems;
  static const returnReason = ReturnsExchangeStep.returnReason;
  static const inspectItems = ReturnsExchangeStep.inspectItems;
  static const chooseOption = ReturnsExchangeStep.chooseOption;
  static const branchAction = ReturnsExchangeStep.branchAction;
  static const refundFlow = ReturnsExchangeStep.branchAction;
  static const exchangeFlow = ReturnsExchangeStep.branchAction;
  static const createCredit = ReturnsExchangeStep.branchAction;
  static const settlement = ReturnsExchangeStep.reviewAndConfirm;
  static const receipt = ReturnsExchangeStep.receiptSuccess;
}

enum ReturnSearchTab {
  invoice,
  mobile,
  customer,
  recent,
}

extension ReturnSearchTabX on ReturnSearchTab {
  String get apiValue {
    switch (this) {
      case ReturnSearchTab.invoice:
        return 'invoice';
      case ReturnSearchTab.mobile:
        return 'mobile';
      case ReturnSearchTab.customer:
        return 'customer';
      case ReturnSearchTab.recent:
        return 'recent';
    }
  }

  String get label {
    switch (this) {
      case ReturnSearchTab.invoice:
        return 'Invoice';
      case ReturnSearchTab.mobile:
        return 'Mobile';
      case ReturnSearchTab.customer:
        return 'Customer';
      case ReturnSearchTab.recent:
        return 'Recent';
    }
  }
}
