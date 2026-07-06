import 'package:flutter/material.dart';

import '../../../cash_drawer/presentation/widgets/cash_drawer_section_card.dart';
import '../../../sale/presentation/widgets/payment/pos_bottom_action_buttons.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ReturnReceiptActionsCard extends StatelessWidget {
  const ReturnReceiptActionsCard({
    super.key,
    required this.onPrintReceipt,
    required this.onNewReturn,
    required this.onBackToDashboard,
  });

  final VoidCallback onPrintReceipt;
  final VoidCallback onNewReturn;
  final VoidCallback onBackToDashboard;

  @override
  Widget build(BuildContext context) {
    return CashDrawerSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.swap_horiz_rounded,
                color: TenantAdminColors.primary,
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              Text(
                'Actions',
                style: TenantAdminTextStyles.sectionTitle(context),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          _ActionTile(
            label: 'Print Receipt',
            icon: Icons.print_outlined,
            onTap: onPrintReceipt,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _ActionTile(
            label: 'New Return',
            icon: Icons.replay_rounded,
            onTap: onNewReturn,
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          PosBottomFilledButton(
            label: 'Back to Dashboard',
            icon: Icons.arrow_back_rounded,
            onPressed: onBackToDashboard,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TenantAdminColors.surface,
      borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.lg,
            vertical: TenantAdminSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: TenantAdminColors.primary),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: TenantAdminColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
