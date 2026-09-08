import 'package:flutter/material.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../../domain/tax_aggregate.dart';
import '../../domain/tax_treatment.dart';
import '../utils/tax_formatters.dart';
import 'tax_products_using_section.dart';

class TaxSetupDetailsContent extends StatelessWidget {
  const TaxSetupDetailsContent({
    super.key,
    required this.tax,
    this.showProducts = true,
  });

  final TaxSetup tax;
  final bool showProducts;

  static const _sectionGap = TenantAdminSpacing.md;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumn = constraints.maxWidth >= TenantAdminBreakpoints.tablet;

        final basicInfo = _DetailSection(
          title: 'Basic Information',
          children: [
            _DetailField(label: 'Tax Name', value: tax.name),
            _DetailField(label: 'Tax Code', value: tax.code),
            _DetailField(
              label: 'Status',
              valueWidget: TenantAdminStatusBadge(
                label: tax.status.label,
                status: tax.status.isActive
                    ? TenantAdminStatusType.active
                    : TenantAdminStatusType.inactive,
              ),
            ),
            _DetailField(
              label: 'Description',
              value: tax.description?.trim().isNotEmpty == true
                  ? tax.description!.trim()
                  : '—',
            ),
          ],
        );

        final treatment = _DetailSection(
          title: 'Tax Treatment',
          children: [
            _DetailField(label: 'Treatment', value: tax.taxTreatment.label),
            _DetailField(
              label: 'Meaning',
              value: tax.taxTreatment.description,
            ),
          ],
        );

        final rates = _DetailSection(
          title: 'Rates',
          children: [
            _DetailField(
              label: 'Current Rate',
              value: formatCurrentRateDisplay(
                treatment: tax.taxTreatment,
                currentRate: tax.currentRate,
              ),
            ),
            _DetailField(
              label: 'Effective Since',
              value: tax.currentRateEffectiveFrom == null
                  ? '—'
                  : formatTaxDate(tax.currentRateEffectiveFrom),
            ),
            _DetailField(
              label: 'Next Change',
              value: formatNextChange(
                nextRate: tax.nextRate,
                nextRateEffectiveFrom: tax.nextRateEffectiveFrom,
              ),
            ),
            _DetailField(
              label: 'Products Using',
              value: '${tax.productCount}',
            ),
          ],
        );

        final history = _RateHistoryReadOnly(tax: tax);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TaxHeaderCard(tax: tax),
            const SizedBox(height: _sectionGap),
            if (twoColumn) ...[
              _EqualHeightRow(left: basicInfo, right: treatment),
              const SizedBox(height: _sectionGap),
              rates,
              const SizedBox(height: _sectionGap),
              history,
            ] else ...[
              basicInfo,
              const SizedBox(height: _sectionGap),
              treatment,
              const SizedBox(height: _sectionGap),
              rates,
              const SizedBox(height: _sectionGap),
              history,
            ],
            const SizedBox(height: _sectionGap),
            if (showProducts)
              TaxProductsUsingSection(
                taxId: tax.id,
                productCount: tax.productCount,
              ),
          ],
        );
      },
    );
  }
}

class _EqualHeightRow extends StatelessWidget {
  const _EqualHeightRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: TaxSetupDetailsContent._sectionGap),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _TaxHeaderCard extends StatelessWidget {
  const _TaxHeaderCard({required this.tax});

  final TaxSetup tax;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: TenantAdminColors.posHomeAccentOrange.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: TenantAdminColors.posHomeAccentOrange,
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tax.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TenantAdminTextStyles.cardTitle(context),
                ),
                const SizedBox(height: 2),
                Text(
                  tax.code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TenantAdminTextStyles.muted(context),
                ),
              ],
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          TenantAdminStatusBadge(
            label: tax.status.label,
            status: tax.status.isActive
                ? TenantAdminStatusType.active
                : TenantAdminStatusType.inactive,
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        TenantAdminSpacing.md,
        TenantAdminSpacing.md,
        TenantAdminSpacing.md,
        TenantAdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TenantAdminTextStyles.cardTitle(context)),
          const SizedBox(height: TenantAdminSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    this.value,
    this.valueWidget,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: TenantAdminTextStyles.fieldLabel(context).copyWith(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: valueWidget ??
                Text(
                  value ?? '—',
                  style: TenantAdminTextStyles.body(context),
                ),
          ),
        ],
      ),
    );
  }
}

class _RateHistoryReadOnly extends StatelessWidget {
  const _RateHistoryReadOnly({required this.tax});

  final TaxSetup tax;

  @override
  Widget build(BuildContext context) {
    final history = tax.rateHistory ?? const <TaxRateHistoryItem>[];

    return _DetailSection(
      title: 'Rate History',
      children: [
        if (history.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: TenantAdminSpacing.sm),
            child: Text(
              'No rate history available yet.',
              style: TextStyle(color: TenantAdminColors.mutedText),
            ),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TenantAdminColors.border),
            ),
            child: Column(
              children: [
                const _HistoryHeaderRow(),
                for (var i = 0; i < history.length; i++) ...[
                  const Divider(height: 1, color: TenantAdminColors.border),
                  _HistoryDataRow(
                    tax: tax,
                    item: history[i],
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _HistoryHeaderRow extends StatelessWidget {
  const _HistoryHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: _HistoryCell('Rate', isHeader: true)),
          Expanded(flex: 3, child: _HistoryCell('From', isHeader: true)),
          Expanded(flex: 3, child: _HistoryCell('To', isHeader: true)),
          Expanded(flex: 2, child: _HistoryCell('State', isHeader: true)),
        ],
      ),
    );
  }
}

class _HistoryDataRow extends StatelessWidget {
  const _HistoryDataRow({
    required this.tax,
    required this.item,
  });

  final TaxSetup tax;
  final TaxRateHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final rateText = tax.taxTreatment == TaxTreatment.exempt
        ? 'Exempt'
        : formatTaxRatePercent(item.rate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _HistoryCell(rateText, emphasize: true),
          ),
          Expanded(
            flex: 3,
            child: _HistoryCell(formatTaxDate(item.effectiveFrom)),
          ),
          Expanded(
            flex: 3,
            child: _HistoryCell(formatTaxDate(item.effectiveTo)),
          ),
          Expanded(
            flex: 2,
            child: _HistoryCell(item.state.label),
          ),
        ],
      ),
    );
  }
}

class _HistoryCell extends StatelessWidget {
  const _HistoryCell(
    this.text, {
    this.isHeader = false,
    this.emphasize = false,
  });

  final String text;
  final bool isHeader;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: isHeader ? 12 : 13,
        fontWeight: isHeader
            ? FontWeight.w700
            : emphasize
                ? FontWeight.w700
                : FontWeight.w500,
        color: isHeader
            ? TenantAdminColors.mutedText
            : TenantAdminColors.bodyText,
      ),
    );
  }
}
