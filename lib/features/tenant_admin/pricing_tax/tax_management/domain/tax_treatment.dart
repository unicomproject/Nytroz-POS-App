enum TaxTreatment {
  taxable,
  zeroRated,
  exempt;

  String get apiValue {
    switch (this) {
      case TaxTreatment.taxable:
        return 'TAXABLE';
      case TaxTreatment.zeroRated:
        return 'ZERO_RATED';
      case TaxTreatment.exempt:
        return 'EXEMPT';
    }
  }

  String get label {
    switch (this) {
      case TaxTreatment.taxable:
        return 'Taxable';
      case TaxTreatment.zeroRated:
        return 'Zero Rated';
      case TaxTreatment.exempt:
        return 'Exempt';
    }
  }

  String get description {
    switch (this) {
      case TaxTreatment.taxable:
        return 'Percentage tax is applied to products using this setup.';
      case TaxTreatment.zeroRated:
        return 'Rate is always 0%. Products remain classified as zero rated.';
      case TaxTreatment.exempt:
        return 'No tax calculation. Products remain classified as exempt.';
    }
  }

  static TaxTreatment parse(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'ZERO_RATED':
      case 'ZERORATED':
        return TaxTreatment.zeroRated;
      case 'EXEMPT':
        return TaxTreatment.exempt;
      case 'TAXABLE':
      default:
        return TaxTreatment.taxable;
    }
  }
}
