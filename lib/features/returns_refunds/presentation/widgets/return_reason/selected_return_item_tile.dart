import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/return_eligibility_provider.dart';
import '../../providers/return_flow_provider.dart';

class SelectedReturnItemTile extends StatelessWidget {
  const SelectedReturnItemTile({
    super.key,
    required this.item,
    required this.currency,
  });

  final ReturnSelectedReturnLine item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final value = formatReturnEligibilityAmount(
      currency: currency,
      amount: item.lineTotal,
    );

    return Row(
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (item.sku.isNotEmpty || item.variantLabel.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  _detailsLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: TenantAdminColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              const SizedBox(height: 3),
              Text(
                'Qty: ${item.returnQty}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: TenantAdminColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }

  String get _detailsLabel {
    if (item.sku.isEmpty) {
      return item.variantLabel;
    }
    if (item.variantLabel.isEmpty) {
      return 'SKU: ${item.sku}';
    }
    return 'SKU: ${item.sku} | ${item.variantLabel}';
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
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(),
          )
        : _fallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: SizedBox(width: 52, height: 52, child: child),
    );
  }

  Widget _fallback() {
    return Image.asset(
      _fallbackAsset,
      width: 52,
      height: 52,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          width: 52,
          height: 52,
          color: TenantAdminColors.background,
          child: const Icon(
            Icons.inventory_2_outlined,
            color: TenantAdminColors.mutedText,
            size: 22,
          ),
        );
      },
    );
  }
}
