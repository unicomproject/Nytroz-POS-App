import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_sale_eligibility.dart';
import '../providers/return_eligibility_provider.dart';

class ReturnPurchasedItemsSection extends StatelessWidget {
  const ReturnPurchasedItemsSection({
    super.key,
    required this.items,
    required this.currency,
  });

  final List<ReturnSaleLineEligibility> items;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Purchased Items',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          if (items.isEmpty)
            Text(
              'No purchased items were found for this sale.',
              style: TenantAdminTextStyles.muted(context),
            )
          else
            Column(
              children: [
                const _PurchasedItemsHeader(),
                const Divider(height: 1, color: TenantAdminColors.border),
                for (final item in items) ...[
                  _PurchasedItemRow(item: item, currency: currency),
                  const Divider(height: 1, color: TenantAdminColors.border),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _PurchasedItemsHeader extends StatelessWidget {
  const _PurchasedItemsHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: TenantAdminColors.mutedText,
          fontWeight: FontWeight.w800,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
      child: Row(
        children: [
          Expanded(flex: 34, child: Text('Item', style: style)),
          Expanded(flex: 18, child: Text('SKU', style: style)),
          Expanded(flex: 18, child: Text('Unit Price', style: style)),
          Expanded(flex: 10, child: Text('Qty', style: style)),
          Expanded(
            flex: 20,
            child: Text('Line Total', textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }
}

class _PurchasedItemRow extends StatelessWidget {
  const _PurchasedItemRow({
    required this.item,
    required this.currency,
  });

  final ReturnSaleLineEligibility item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final primaryStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: TenantAdminColors.bodyText,
          fontWeight: FontWeight.w800,
        );
    final secondaryStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: TenantAdminColors.primary,
          fontWeight: FontWeight.w700,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 34,
            child: Row(
              children: [
                _ProductThumb(imageValue: item.imageStorageKey),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: primaryStyle,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              item.sku.isEmpty ? '-' : item.sku,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: secondaryStyle,
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              formatReturnEligibilityAmount(
                currency: currency,
                amount: item.unitPrice,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: primaryStyle,
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              _qty(item.soldQty),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: primaryStyle,
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              formatReturnEligibilityAmount(
                currency: currency,
                amount: item.lineTotal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: primaryStyle,
            ),
          ),
        ],
      ),
    );
  }

  String _qty(double value) => value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
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
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(),
          )
        : _fallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: SizedBox(width: 36, height: 36, child: child),
    );
  }

  Widget _fallback() {
    return Image.asset(
      _fallbackAsset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return const ColoredBox(
          color: TenantAdminColors.background,
          child: Icon(
            Icons.inventory_2_outlined,
            size: 18,
            color: TenantAdminColors.mutedText,
          ),
        );
      },
    );
  }
}
