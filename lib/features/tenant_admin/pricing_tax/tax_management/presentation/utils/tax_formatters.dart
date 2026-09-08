import '../../domain/tax_status.dart';
import '../../domain/tax_treatment.dart';

String formatTaxRatePercent(double? rate) {
  if (rate == null) return '—';
  return '${_stripTrailingZeros(rate)}%';
}

String formatCurrentRateDisplay({
  required TaxTreatment treatment,
  required double? currentRate,
}) {
  switch (treatment) {
    case TaxTreatment.exempt:
      return 'Exempt';
    case TaxTreatment.zeroRated:
      return '0%';
    case TaxTreatment.taxable:
      return formatTaxRatePercent(currentRate);
  }
}

String formatTaxDate(DateTime? date) {
  if (date == null) return '—';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final day = date.day.toString().padLeft(2, '0');
  final month = months[date.month - 1];
  return '$day $month ${date.year}';
}

String formatNextChange({
  required double? nextRate,
  required DateTime? nextRateEffectiveFrom,
}) {
  if (nextRate == null || nextRateEffectiveFrom == null) {
    return '—';
  }
  return '${formatTaxRatePercent(nextRate)} on ${formatTaxDate(nextRateEffectiveFrom)}';
}

String _stripTrailingZeros(double value) {
  if (value.truncateToDouble() == value) {
    return value.toStringAsFixed(0);
  }
  var text = value.toStringAsFixed(4);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  text = text.replaceFirst(RegExp(r'\.$'), '');
  return text;
}

String taxProductStatusLabel(String status) {
  final normalized = status.trim().toUpperCase();
  if (normalized == TaxStatus.active.apiValue) return 'Active';
  if (normalized == TaxStatus.inactive.apiValue) return 'Inactive';
  if (normalized.isEmpty) return '—';
  return status;
}
