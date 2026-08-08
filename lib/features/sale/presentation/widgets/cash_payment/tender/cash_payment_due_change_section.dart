import 'package:flutter/material.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';

class CashPaymentDueChangeSection extends StatelessWidget {
  const CashPaymentDueChangeSection({
    super.key,
    required this.totalDue,
    required this.changeDue,
  });

  final int totalDue;
  final int changeDue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InfoCard(
          title: 'TOTAL DUE',
          amount: totalDue,
          icon: Icons.payments_outlined,
          color: TenantAdminColors.posHomeAccentOrange,
          backgroundColor:
              TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.05),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        _InfoCard(
          title: 'CHANGE DUE',
          amount: changeDue > 0 ? changeDue : 0,
          icon: Icons.monetization_on_outlined,
          color: TenantAdminColors.success,
          backgroundColor: TenantAdminColors.success.withValues(alpha: 0.05),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final String title;
  final int amount;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.md,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(TenantAdminSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: TenantAdminColors.bodyText,
                      ),
                ),
                Text(
                  formatLkr(amount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
