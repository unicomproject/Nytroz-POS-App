import 'package:flutter/material.dart';
import 'package:nytroz_pos/shared/widgets/pos_action_buttons.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CustomerDetailsActions extends StatelessWidget {
  const CustomerDetailsActions({
    super.key,
    required this.canAttach,
    required this.canViewPurchaseHistory,
    required this.canEdit,
    required this.isAttaching,
    required this.attachDisabledReason,
    required this.onAttachToSale,
    required this.onViewPurchaseHistory,
    required this.onEditCustomer,
  });

  final bool canAttach;
  final bool canViewPurchaseHistory;
  final bool canEdit;
  final bool isAttaching;
  final String? attachDisabledReason;
  final VoidCallback onAttachToSale;
  final VoidCallback onViewPurchaseHistory;
  final VoidCallback onEditCustomer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tooltip(
          message: attachDisabledReason ??
              'Attach selected customer to the active sale',
          child: _PanelButton(
            label: 'Attach to Sale',
            icon: Icons.shopping_cart_outlined,
            primary: true,
            loading: isAttaching,
            onPressed: canAttach && !isAttaching ? onAttachToSale : null,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        if (canViewPurchaseHistory)
          _PanelButton(
            label: 'View Purchase History',
            icon: Icons.history_rounded,
            onPressed: onViewPurchaseHistory,
          ),
        if (canViewPurchaseHistory) const SizedBox(height: TenantAdminSpacing.sm),
        if (canEdit)
          _PanelButton(
            label: 'Edit Customer',
            icon: Icons.edit_outlined,
            onPressed: onEditCustomer,
          ),
      ],
    );
  }
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      children: [
        if (loading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(icon, size: 18),
        const SizedBox(width: TenantAdminSpacing.sm),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );

    if (primary) {
      return PosPrimaryActionButton(
        label: label,
        leadingIcon: icon,
        onPressed: loading ? null : onPressed,
        isLoading: loading,
        fullWidth: true,
        compact: true,
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: TenantAdminColors.primary,
        side: const BorderSide(color: TenantAdminColors.border),
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.md,
          vertical: TenantAdminSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
      ),
      child: child,
    );
  }
}
