import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_credit_preview.dart';
import '../../providers/return_create_credit_provider.dart';

class ReturnReviewItemRow extends StatelessWidget {
  const ReturnReviewItemRow({
    super.key,
    required this.item,
    required this.currencyCode,
    required this.conditionLabel,
    required this.invoiceLabel,
    this.compact = false,
  });

  final ReturnCreditPreviewItem item;
  final String currencyCode;
  final String conditionLabel;
  final String invoiceLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductThumb(imageValue: item.imageStorageKey),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (invoiceLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          invoiceLabel,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: TenantAdminColors.mutedText,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            Text('Condition: $conditionLabel'),
            Text('Qty: ${_qtyLabel(item.returnQty)}'),
            Text(
              'Unit: ${formatReturnCreditAmount(currency: currencyCode, amount: item.unitPrice)}',
            ),
            Text(
              'Amount: ${formatReturnCreditAmount(currency: currencyCode, amount: item.lineAmount)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _ProductThumb(imageValue: item.imageStorageKey),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      if (invoiceLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          invoiceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: TenantAdminColors.mutedText,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              conditionLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              _qtyLabel(item.returnQty),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatReturnCreditAmount(
                currency: currencyCode,
                amount: item.unitPrice,
              ),
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatReturnCreditAmount(
                currency: currencyCode,
                amount: item.lineAmount,
              ),
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _qtyLabel(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(2);
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.imageValue});

  final String? imageValue;
  static const _fallbackAsset = 'assets/images/product_dummy.png';

  @override
  Widget build(BuildContext context) {
    final value = imageValue?.trim() ?? '';
    final child = value.startsWith('http')
        ? Image.network(
            value,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              _fallbackAsset,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          )
        : Image.asset(
            _fallbackAsset,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: child,
    );
  }
}
