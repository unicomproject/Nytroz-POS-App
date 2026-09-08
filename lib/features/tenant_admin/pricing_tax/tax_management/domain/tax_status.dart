enum TaxStatus {
  active,
  inactive;

  String get apiValue {
    switch (this) {
      case TaxStatus.active:
        return 'ACTIVE';
      case TaxStatus.inactive:
        return 'INACTIVE';
    }
  }

  String get label {
    switch (this) {
      case TaxStatus.active:
        return 'Active';
      case TaxStatus.inactive:
        return 'Inactive';
    }
  }

  bool get isActive => this == TaxStatus.active;

  static TaxStatus parse(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'INACTIVE':
        return TaxStatus.inactive;
      case 'ACTIVE':
      default:
        return TaxStatus.active;
    }
  }
}

enum TaxRateHistoryState {
  historical,
  current,
  scheduled;

  String get apiValue {
    switch (this) {
      case TaxRateHistoryState.historical:
        return 'HISTORICAL';
      case TaxRateHistoryState.current:
        return 'CURRENT';
      case TaxRateHistoryState.scheduled:
        return 'SCHEDULED';
    }
  }

  String get label {
    switch (this) {
      case TaxRateHistoryState.historical:
        return 'Historical';
      case TaxRateHistoryState.current:
        return 'Current';
      case TaxRateHistoryState.scheduled:
        return 'Scheduled';
    }
  }

  static TaxRateHistoryState parse(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'HISTORICAL':
        return TaxRateHistoryState.historical;
      case 'SCHEDULED':
        return TaxRateHistoryState.scheduled;
      case 'CURRENT':
      default:
        return TaxRateHistoryState.current;
    }
  }
}

enum TaxPriceMode {
  inclusive,
  exclusive;

  String get apiValue {
    switch (this) {
      case TaxPriceMode.inclusive:
        return 'INCLUSIVE';
      case TaxPriceMode.exclusive:
        return 'EXCLUSIVE';
    }
  }

  String get label {
    switch (this) {
      case TaxPriceMode.inclusive:
        return 'Inclusive';
      case TaxPriceMode.exclusive:
        return 'Exclusive';
    }
  }

  static TaxPriceMode parse(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'EXCLUSIVE':
        return TaxPriceMode.exclusive;
      case 'INCLUSIVE':
      default:
        return TaxPriceMode.inclusive;
    }
  }
}
