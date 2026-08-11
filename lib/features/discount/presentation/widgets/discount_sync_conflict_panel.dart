import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

/// Cashier-visible Discount sync conflict / failure panel.
class DiscountSyncConflictPanel extends StatelessWidget {
  const DiscountSyncConflictPanel({
    super.key,
    required this.errorCode,
    required this.onRemoveDiscount,
    required this.onReviewSale,
    this.onRetry,
    this.isRetryable = false,
  });

  final String? errorCode;
  final VoidCallback onRemoveDiscount;
  final VoidCallback onReviewSale;
  final VoidCallback? onRetry;
  final bool isRetryable;

  static String messageForCode(String? code) {
    final normalized = code?.trim().toLowerCase() ?? '';
    return switch (normalized) {
      'pos_discounts.authority_exceeded' ||
      'pos_discounts.above_authority' ||
      'pos_discounts.limit_exceeded' =>
        'Discount authority has changed.',
      'pos_discounts.permission_denied' =>
        'You no longer have permission to apply this Discount.',
      'pos_discounts.cart_changed' ||
      'pos_discounts.target_not_in_cart' ||
      'pos_discounts.target_required' =>
        'The discounted item/cart has changed.',
      'pos_discounts.active_discount_exists' =>
        'Another Discount already exists.',
      'pos_discounts.idempotency_conflict' =>
        'This Discount request conflicted with a previous attempt.',
      'pos_discounts.rejected_after_sync' ||
      'server_rejected' =>
        'This Discount could not be accepted by the server.',
      _ => 'This Discount could not be accepted by the server.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Discount Sync Conflict',
      child: Container(
        key: const Key('discount-sync-conflict-panel'),
        width: double.infinity,
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: TenantAdminColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          border: Border.all(
            color: TenantAdminColors.warning.withValues(alpha: 0.55),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discount Sync Conflict',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: TenantAdminColors.navy,
                  ),
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(
              messageForCode(errorCode),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TenantAdminColors.navy.withValues(alpha: 0.86),
                  ),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            Wrap(
              spacing: TenantAdminSpacing.sm,
              runSpacing: TenantAdminSpacing.sm,
              children: [
                FilledButton(
                  key: const Key('discount-conflict-remove'),
                  onPressed: onRemoveDiscount,
                  child: const Text('Remove Discount'),
                ),
                OutlinedButton(
                  key: const Key('discount-conflict-review'),
                  onPressed: onReviewSale,
                  child: const Text('Review Sale'),
                ),
                if (isRetryable && onRetry != null)
                  OutlinedButton(
                    key: const Key('discount-conflict-retry'),
                    onPressed: onRetry,
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
