/// Six-step return and refund workflow labels.
abstract final class ReturnFlowSteps {
  static const labels = [
    'Search Sale',
    'Eligibility & Select Items',
    'Return Reason',
    'Create Credit',
    'Settlement',
    'Receipt',
  ];

  static const searchSale = 0;
  static const eligibilityAndItems = 1;
  static const returnReason = 2;
  static const createCredit = 3;
  static const settlement = 4;
  static const receipt = 5;
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
