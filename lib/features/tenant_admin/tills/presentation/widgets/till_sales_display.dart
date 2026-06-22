import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class TillSalesDisplay extends StatelessWidget {
  const TillSalesDisplay({
    super.key,
    required this.amount,
    required this.currency,
    required this.lastSyncAt,
  });

  final double? amount;
  final String? currency;
  final DateTime? lastSyncAt;

  @override
  Widget build(BuildContext context) {
    if (amount == null || currency == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's sales",
          style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          _formatAmount(amount!, currency!),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: TenantAdminColors.bodyText,
          ),
        ),
        if (lastSyncAt != null) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            'Last sync: ${_relativeTime(lastSyncAt!)}',
            style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12),
          ),
        ],
      ],
    );
  }

  String _formatAmount(double amount, String currencyCode) {
    final value = amount.toStringAsFixed(2);
    switch (currencyCode.toUpperCase()) {
      case 'GBP':
        return '£$value';
      case 'USD':
        return '\$$value';
      case 'EUR':
        return '€$value';
      case 'LKR':
        return 'Rs $value';
      default:
        return '$currencyCode $value';
    }
  }

  String _relativeTime(DateTime value) {
    final diff = DateTime.now().difference(value.toLocal());
    if (diff.inMinutes < 1) {
      return 'just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hr ago';
    }

    final local = value.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}
