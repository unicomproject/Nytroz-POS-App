import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_sale_summary.dart';
import '../providers/return_search_provider.dart';

class ReturnSaleResultCard extends StatelessWidget {
  const ReturnSaleResultCard({
    super.key,
    required this.sale,
    required this.selected,
    required this.onSelected,
  });

  final ReturnSaleSummary sale;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: _horizontalPaddingForWidth(context),
            vertical: TenantAdminSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected
                ? TenantAdminColors.secondary
                : TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(
              color: selected
                  ? TenantAdminColors.primary
                  : TenantAdminColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected ? TenantAdminShadows.card : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final mobile =
                  constraints.maxWidth < TenantAdminBreakpoints.mobile;
              if (mobile) {
                return _MobileResult(
                  sale: sale,
                  selected: selected,
                );
              }

              return _WideResult(
                sale: sale,
                selected: selected,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WideResult extends StatelessWidget {
  const _WideResult({
    required this.sale,
    required this.selected,
  });

  final ReturnSaleSummary sale;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: TenantAdminColors.bodyText,
          fontWeight: FontWeight.w900,
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: TenantAdminColors.bodyText,
          fontWeight: FontWeight.w700,
        );
    final mutedStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: TenantAdminColors.mutedText,
          fontWeight: FontWeight.w700,
        );

    return Row(
      children: [
        _SelectionIndicator(selected: selected),
        const SizedBox(width: TenantAdminSpacing.lg),
        Expanded(
          flex: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sale.invoiceNo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                _customerName(sale),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: bodyStyle,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 22,
          child: Text(
            formatReturnSaleDateTime(sale.saleDate),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: bodyStyle,
          ),
        ),
        Expanded(
          flex: 20,
          child: Text(
            sale.paymentDisplay.isEmpty ? '-' : sale.paymentDisplay,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: mutedStyle?.copyWith(color: TenantAdminColors.info),
          ),
        ),
        Expanded(
          flex: 17,
          child: Text(
            formatReturnSaleAmount(sale),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: titleStyle,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.lg),
        SizedBox(
          width: 68,
          child: Text(
            _itemCount(sale),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: mutedStyle,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        const Icon(
          Icons.chevron_right_rounded,
          color: TenantAdminColors.mutedText,
        ),
      ],
    );
  }
}

class _MobileResult extends StatelessWidget {
  const _MobileResult({
    required this.sale,
    required this.selected,
  });

  final ReturnSaleSummary sale;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: TenantAdminColors.bodyText,
          fontWeight: FontWeight.w900,
        );
    final amountStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: TenantAdminColors.bodyText,
          fontWeight: FontWeight.w900,
        );
    final metaStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: TenantAdminColors.info,
          fontWeight: FontWeight.w700,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _SelectionIndicator(selected: selected),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: Text(
                sale.invoiceNo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ),
            Flexible(
              child: Text(
                formatReturnSaleAmount(sale),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: amountStyle,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: TenantAdminColors.mutedText,
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Text(
            _customerName(sale),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: metaStyle,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  formatReturnSaleDateTime(sale.saleDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: metaStyle,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Text(
                  sale.paymentDisplay.isEmpty ? '-' : sale.paymentDisplay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: metaStyle,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Text(_itemCount(sale), style: metaStyle),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color:
              selected ? TenantAdminColors.primary : TenantAdminColors.border,
          width: 2,
        ),
        color: selected ? TenantAdminColors.primary : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
          : null,
    );
  }
}

String _customerName(ReturnSaleSummary sale) {
  return sale.customerName.trim().isEmpty
      ? 'Walk-in customer'
      : sale.customerName.trim();
}

String _itemCount(ReturnSaleSummary sale) {
  return '${sale.itemCount} item${sale.itemCount == 1 ? '' : 's'}';
}

double _horizontalPaddingForWidth(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return width < TenantAdminBreakpoints.mobile
      ? TenantAdminSpacing.md
      : TenantAdminSpacing.lg;
}
