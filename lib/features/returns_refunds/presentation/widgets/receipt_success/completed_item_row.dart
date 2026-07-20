import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/return_create_credit_provider.dart';
import '../../providers/return_success_display.dart';

class CompletedItemRow extends StatelessWidget {
  const CompletedItemRow({
    super.key,
    required this.item,
    required this.currencyCode,
  });

  final CompletedItemDisplay item;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.md,
      ),
      child: Row(
        children: [
          _Thumb(imageValue: item.imageValue),
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
                if (item.isReplacement || item.variantLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (item.isReplacement) 'Replacement',
                      if (item.variantLabel.isNotEmpty) item.variantLabel,
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: TenantAdminColors.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                if (!item.isReplacement &&
                    (item.reasonDisplay?.trim().isNotEmpty == true ||
                        item.conditionDisplay?.trim().isNotEmpty == true)) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (item.reasonDisplay?.trim().isNotEmpty == true)
                        item.reasonDisplay!.trim(),
                      if (item.conditionDisplay?.trim().isNotEmpty == true)
                        item.conditionDisplay!.trim(),
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: TenantAdminColors.mutedText,
                        ),
                  ),
                ],
                if ((item.discount ?? 0) > 0 || (item.tax ?? 0) > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      if ((item.discount ?? 0) > 0)
                        'Disc ${formatReturnCreditAmount(currency: currencyCode, amount: item.discount!)}',
                      if ((item.tax ?? 0) > 0)
                        'Tax ${formatReturnCreditAmount(currency: currencyCode, amount: item.tax!)}',
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: TenantAdminColors.mutedText,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Text(
            formatReturnCreditAmount(
              currency: currencyCode,
              amount: item.amount,
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.imageValue});

  final String? imageValue;
  static const _fallbackAsset = 'assets/images/product_dummy.png';

  @override
  Widget build(BuildContext context) {
    final value = imageValue?.trim() ?? '';
    final child = value.startsWith('http')
        ? Image.network(
            value,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              _fallbackAsset,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          )
        : Image.asset(
            _fallbackAsset,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: child,
    );
  }
}
