import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/return_flow_provider.dart';

class ReturnSelectedItemCard extends StatelessWidget {
  const ReturnSelectedItemCard({
    super.key,
    required this.item,
  });

  final ReturnSelectedReturnLine item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ItemThumbnail(name: item.name),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (item.sku.isNotEmpty || item.variantLabel.isNotEmpty) ...[
                  const SizedBox(height: TenantAdminSpacing.xs),
                  Text(
                    _skuDisplay,
                    style: TenantAdminTextStyles.muted(context),
                  ),
                ],
              ],
            ),
          ),
          Text(
            'Qty ${item.returnQty}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  String get _skuDisplay {
    if (item.sku.isEmpty) {
      return item.variantLabel;
    }
    if (item.variantLabel.isEmpty) {
      return 'SKU: ${item.sku}';
    }
    return 'SKU: ${item.sku} | ${item.variantLabel}';
  }
}

class _ItemThumbnail extends StatelessWidget {
  const _ItemThumbnail({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: TenantAdminColors.secondary,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: Icon(
        Icons.inventory_2_outlined,
        color: TenantAdminColors.info,
        semanticLabel: name,
      ),
    );
  }
}
