import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/report_models.dart';
import '../providers/report_providers.dart';
import '../utils/report_catalog.dart';
import '../utils/report_export_action.dart';
import '../utils/report_formatters.dart';
import '../widgets/common/report_data_components.dart';
import '../widgets/common/report_page_components.dart';
import '../widgets/common/report_states.dart';

class SalesTransactionDetailScreen extends ConsumerWidget {
  const SalesTransactionDetailScreen({
    super.key,
    required this.orderId,
  });

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(reportPermissionProvider);
    final detail = ref.watch(salesTransactionDetailProvider(orderId));
    final salesQuery = ref.watch(reportQueryProvider(ReportScope.sales));

    return permissions.when(
      loading: () => const ReportPageScaffold(
        title: 'Transaction Detail',
        subtitle: 'Loading the selected sales transaction.',
        child: ReportLoadingState(),
      ),
      error: (error, stackTrace) => ReportPageScaffold(
        title: 'Transaction Detail',
        subtitle: 'Unable to verify report access.',
        child: ReportRequestErrorState(error: error),
      ),
      data: (access) {
        if (!access.transactions) {
          return const ReportPageScaffold(
            title: 'Transaction Detail',
            subtitle: 'Sales invoice and transaction detail.',
            child: ReportPermissionDeniedState(),
          );
        }

        final actions = <Widget>[
          OutlinedButton.icon(
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go('/tenant-admin/reports/sales?tab=transactions'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
          if (access.export)
            ReportExportMenu(
              onSelected: (format) => requestReportExport(
                context,
                ref,
                reportType: 'sales-detail',
                format: format,
                query: salesQuery,
              ),
            ),
        ];

        return ReportPageScaffold(
          title: detail.asData?.value.orderNumber.isNotEmpty == true
              ? detail.asData!.value.orderNumber
              : 'Transaction Detail',
          subtitle: 'Sales invoice and transaction detail.',
          breadcrumbs: const ['Reports', 'Sales Report'],
          actions: actions,
          child: detail.when(
            loading: () => const ReportLoadingState(),
            error: (error, stackTrace) => ReportRequestErrorState(
              error: error,
              onRetry: () =>
                  ref.invalidate(salesTransactionDetailProvider(orderId)),
            ),
            data: (data) => _TransactionDetailContent(
              detail: data,
              showCustomerPii: access.customerPii,
            ),
          ),
        );
      },
    );
  }
}

class _TransactionDetailContent extends StatelessWidget {
  const _TransactionDetailContent({
    required this.detail,
    required this.showCustomerPii,
  });

  final SalesTransactionDetail detail;
  final bool showCustomerPii;

  @override
  Widget build(BuildContext context) {
    final invoice = Map<String, Object?>.from(detail.invoiceInformation);
    invoice['customerEmail'] = showCustomerPii
        ? detail.customerEmail
        : maskReportEmail(detail.customerEmail);
    invoice['customerPhone'] = showCustomerPii
        ? detail.customerPhone
        : maskReportPhone(detail.customerPhone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 900
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: TenantAdminSpacing.lg,
              runSpacing: TenantAdminSpacing.lg,
              children: [
                SizedBox(
                  width: width,
                  child: ReportSectionCard(
                    title: 'Invoice Information',
                    child: _DetailMap(
                      values: invoice,
                      currencyCode: detail.currencyCode,
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: ReportSectionCard(
                    title: 'Financial Summary',
                    child: _DetailMap(
                      values: detail.financialSummary,
                      currencyCode: detail.currencyCode,
                      financial: true,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        for (final section in _detailSections) ...[
          if ((detail.sections[section.key] ?? const []).isNotEmpty) ...[
            const SizedBox(height: TenantAdminSpacing.xl),
            ReportSectionCard(
              title: section.title,
              child: ReportDataView(
                records: detail.sections[section.key]!,
                columns: section.columns,
                currencyCode: detail.currencyCode,
                allowSensitiveColumns: showCustomerPii,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _DetailMap extends StatelessWidget {
  const _DetailMap({
    required this.values,
    required this.currencyCode,
    this.financial = false,
  });

  final Map<String, Object?> values;
  final String? currencyCode;
  final bool financial;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return Text('—', style: TenantAdminTextStyles.muted(context));
    }
    return Column(
      children: values.entries
          .where((entry) => !_blockedKeys.contains(entry.key))
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _labelForKey(entry.key),
                      style: TenantAdminTextStyles.muted(context),
                    ),
                  ),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(
                    child: Text(
                      formatReportValue(
                        entry.value,
                        currencyCode: financial && entry.value is num
                            ? currencyCode
                            : null,
                      ),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: TenantAdminColors.bodyText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DetailSectionSpec {
  const _DetailSectionSpec(this.key, this.title, this.columns);

  final String key;
  final String title;
  final List<ReportColumnSpec> columns;
}

const _detailSections = [
  _DetailSectionSpec('items', 'Items', [
    ReportColumnSpec(key: 'lineNumber', label: 'Line'),
    ReportColumnSpec(key: 'productName', label: 'Product', primary: true),
    ReportColumnSpec(key: 'variantName', label: 'Variant'),
    ReportColumnSpec(key: 'sku', label: 'SKU'),
    ReportColumnSpec(key: 'barcode', label: 'Barcode'),
    ReportColumnSpec(key: 'uomName', label: 'UOM'),
    ReportColumnSpec(key: 'quantity', label: 'Quantity'),
    ReportColumnSpec(key: 'returnedQuantity', label: 'Returned'),
    ReportColumnSpec(
        key: 'originalUnitPrice', label: 'Original Price', financial: true),
    ReportColumnSpec(key: 'unitPrice', label: 'Selling Price', financial: true),
    ReportColumnSpec(
        key: 'lineSubtotalAmount', label: 'Subtotal', financial: true),
    ReportColumnSpec(
        key: 'lineDiscountAmount', label: 'Discount', financial: true),
    ReportColumnSpec(key: 'lineTaxAmount', label: 'Tax', financial: true),
    ReportColumnSpec(key: 'lineTotalAmount', label: 'Total', financial: true),
    ReportColumnSpec(key: 'lineStatus', label: 'Status', status: true),
  ]),
  _DetailSectionSpec('payments', 'Payments', [
    ReportColumnSpec(key: 'paymentNumber', label: 'Payment', primary: true),
    ReportColumnSpec(key: 'paymentMethodName', label: 'Method'),
    ReportColumnSpec(key: 'status', label: 'Status', status: true),
    ReportColumnSpec(
        key: 'requestedAmount', label: 'Requested', financial: true),
    ReportColumnSpec(key: 'tenderedAmount', label: 'Tendered', financial: true),
    ReportColumnSpec(key: 'paidAmount', label: 'Paid', financial: true),
    ReportColumnSpec(key: 'changeAmount', label: 'Change', financial: true),
    ReportColumnSpec(key: 'refundedAmount', label: 'Refunded', financial: true),
    ReportColumnSpec(key: 'externalReference', label: 'External Reference'),
    ReportColumnSpec(key: 'paidAt', label: 'Paid Date'),
  ]),
  _DetailSectionSpec('discounts', 'Discounts', [
    ReportColumnSpec(key: 'discountName', label: 'Discount', primary: true),
    ReportColumnSpec(key: 'discountCode', label: 'Code'),
    ReportColumnSpec(key: 'target', label: 'Target'),
    ReportColumnSpec(key: 'calculationMethod', label: 'Calculation'),
    ReportColumnSpec(key: 'discountValue', label: 'Value'),
    ReportColumnSpec(key: 'discountAmount', label: 'Amount', financial: true),
    ReportColumnSpec(key: 'appliedByName', label: 'Applied By'),
    ReportColumnSpec(key: 'appliedAt', label: 'Applied Date'),
  ]),
  _DetailSectionSpec('taxes', 'Taxes', [
    ReportColumnSpec(key: 'taxClassName', label: 'Tax Class', primary: true),
    ReportColumnSpec(key: 'taxName', label: 'Tax Name'),
    ReportColumnSpec(key: 'taxRate', label: 'Tax Rate'),
    ReportColumnSpec(
        key: 'taxableAmount', label: 'Taxable Amount', financial: true),
    ReportColumnSpec(key: 'taxAmount', label: 'Tax Amount', financial: true),
    ReportColumnSpec(key: 'isTaxIncluded', label: 'Tax Included'),
  ]),
  _DetailSectionSpec('returnsAndRefunds', 'Returns & Refunds', [
    ReportColumnSpec(key: 'returnNumber', label: 'Return', primary: true),
    ReportColumnSpec(key: 'refundNumber', label: 'Refund'),
    ReportColumnSpec(key: 'productName', label: 'Product'),
    ReportColumnSpec(key: 'variantName', label: 'Variant'),
    ReportColumnSpec(key: 'quantity', label: 'Quantity'),
    ReportColumnSpec(
        key: 'requestedAmount', label: 'Requested', financial: true),
    ReportColumnSpec(key: 'approvedAmount', label: 'Approved', financial: true),
    ReportColumnSpec(key: 'refundedAmount', label: 'Refunded', financial: true),
    ReportColumnSpec(key: 'status', label: 'Status', status: true),
    ReportColumnSpec(key: 'completedAt', label: 'Completed Date'),
  ]),
  _DetailSectionSpec('notes', 'Notes', [
    ReportColumnSpec(key: 'type', label: 'Type', primary: true),
    ReportColumnSpec(key: 'text', label: 'Note'),
  ]),
];

const _blockedKeys = {
  'cardNumber',
  'cvv',
  'providerSecret',
  'password',
  'token',
  'pin',
  'providerResponseJson',
};

String _labelForKey(String key) {
  final spaced = key.replaceAllMapped(
    RegExp(r'([a-z0-9])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  return spaced.isEmpty
      ? key
      : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}
