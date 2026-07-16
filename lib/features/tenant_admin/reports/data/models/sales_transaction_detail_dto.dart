import 'report_json.dart';

class SalesTransactionDetailDto {
  const SalesTransactionDetailDto({
    required this.orderId,
    required this.orderNumber,
    required this.invoiceInformation,
    required this.financialSummary,
    required this.sections,
    this.customerEmail,
    this.customerPhone,
    this.currencyCode,
  });

  factory SalesTransactionDetailDto.fromJson(Map<String, dynamic> json) {
    final sections = <String, List<Map<String, dynamic>>>{};
    for (final key in const [
      'items',
      'payments',
      'discounts',
      'taxes',
      'returnsAndRefunds',
      'notes',
    ]) {
      sections[key] = reportJsonList(json[key]);
    }

    final invoice = reportJsonMap(json['invoiceInformation']);
    return SalesTransactionDetailDto(
      orderId: json['orderId']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      invoiceInformation: invoice,
      financialSummary: reportJsonMap(json['financialSummary']),
      sections: sections,
      customerEmail: reportNullableString(
        invoice['customerEmail'] ?? json['customerEmail'],
      ),
      customerPhone: reportNullableString(
        invoice['customerPhone'] ?? json['customerPhone'],
      ),
      currencyCode: reportNullableString(
        json['currencyCode'] ?? invoice['currencyCode'],
      ),
    );
  }

  final String orderId;
  final String orderNumber;
  final Map<String, dynamic> invoiceInformation;
  final Map<String, dynamic> financialSummary;
  final Map<String, List<Map<String, dynamic>>> sections;
  final String? customerEmail;
  final String? customerPhone;
  final String? currencyCode;
}
