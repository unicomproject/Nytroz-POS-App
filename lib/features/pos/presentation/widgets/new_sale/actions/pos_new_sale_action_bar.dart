import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_parked_sale_provider.dart';
import 'package:nytroz_pos/features/discount/presentation/widgets/pos_discount_dialog.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_parked_sale_dialog.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_park_sale_dialog.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import '../../../../../../core/access/pos_access_codes.dart';
import '../../../../../../core/access/pos_permission_access.dart';
import '../../../../../auth/presentation/providers/session_provider.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosNewSaleActionBar extends ConsumerWidget {
  const PosNewSaleActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final cart = ref.watch(posNewSaleCartProvider);
    final parkedSaleCount = ref.watch(posParkedSaleCountProvider);
    final canApplyDiscount =
        session?.hasPermission(PosPermissionCodes.applySaleDiscount) == true;
    final canClearCart = PosPermissionAccess.canClearCart(
      session?.permissionCodes.toSet() ?? const {},
    );
    final canCreateParkedSale =
        session?.hasPermission(PosPermissionCodes.createParkedSale) == true;
    final canViewParkedSales =
        session?.hasPermission(PosPermissionCodes.viewBackendParkedSales) ==
            true;
    // Park Sale and Recall Sale are mutually exclusive: an empty cart can
    // only recall, a non-empty cart can only park. Each is gated on its own
    // permission — never fall back to showing the other action's label on a
    // disabled button when the applicable permission is missing.
    final showParkAction = cart.hasItems && canCreateParkedSale;
    final showRecallAction = !cart.hasItems && canViewParkedSales;
    final actions = <_ActionButton>[
      if (showParkAction)
        _ActionButton(
          icon: Icons.pause_circle_outline_rounded,
          label: 'Park Sale',
          backgroundColor: TenantAdminColors.posNewSaleHoldAction,
          tooltip: 'Save current cart as a parked sale',
          onPressed: () => _saveParkedSale(context, ref, cart),
        )
      else if (showRecallAction)
        _ActionButton(
          icon: Icons.pause_circle_outline_rounded,
          label: 'Recall Sale',
          backgroundColor: TenantAdminColors.posNewSaleHoldAction,
          tooltip: parkedSaleCount > 0
              ? 'Recall a parked sale'
              : 'No parked sales to recall',
          onPressed: () => _recallParkedSale(context, ref),
        ),
      if (canClearCart)
        _ActionButton(
          icon: Icons.delete_outline_rounded,
          label: 'Clear Cart',
          backgroundColor: TenantAdminColors.posNewSaleClearAction,
          tooltip: cart.hasItems
              ? 'Remove every item from the current sale'
              : 'The current sale is empty',
          onPressed:
              cart.hasItems ? () => _confirmClearCart(context, ref) : null,
        ),
      if (canApplyDiscount)
        _ActionButton(
          icon: Icons.discount_outlined,
          label: cart.hasDiscount ? 'Edit Discount' : 'Add Discount',
          backgroundColor: TenantAdminColors.posNewSaleDiscountAction,
          tooltip: cart.hasItems
              ? 'Apply discount to this cart'
              : 'Add products before applying a discount',
          onPressed: cart.hasItems
              ? () => showPosDiscountDialog(context: context, ref: ref)
              : null,
        ),
      const _ActionButton(
        icon: Icons.add_box_outlined,
        label: 'Custom Item',
        backgroundColor: TenantAdminColors.posNewSaleCustomAction,
        tooltip: 'Custom items are not available in the current POS contract',
        onPressed: null,
      ),
    ];

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var index = 0; index < actions.length; index += 1) ...[
                  if (index > 0) const SizedBox(width: TenantAdminSpacing.md),
                  SizedBox(width: 160, child: actions[index]),
                ],
              ],
            ),
          );
        }

        return Row(
          children: [
            for (var index = 0; index < actions.length; index += 1) ...[
              if (index > 0) const SizedBox(width: TenantAdminSpacing.md),
              Expanded(child: actions[index]),
            ],
          ],
        );
      },
    );
  }

  Future<void> _confirmClearCart(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('clear-cart-dialog'),
        backgroundColor: TenantAdminColors.surface,
        surfaceTintColor: TenantAdminColors.surface,
        insetPadding: const EdgeInsets.all(TenantAdminSpacing.xl),
        titlePadding: const EdgeInsets.fromLTRB(
          TenantAdminSpacing.xl,
          TenantAdminSpacing.xl,
          TenantAdminSpacing.xl,
          TenantAdminSpacing.md,
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          TenantAdminSpacing.xl,
          0,
          TenantAdminSpacing.xl,
          TenantAdminSpacing.xl,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          TenantAdminSpacing.xl,
          0,
          TenantAdminSpacing.xl,
          TenantAdminSpacing.xl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        ),
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: TenantAdminColors.posHomeReturnsCard,
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: TenantAdminColors.posNewSaleClearAction,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: Text(
                'Clear current sale?',
                style: TenantAdminTextStyles.sectionTitle(dialogContext),
              ),
            ),
          ],
        ),
        content: const Text(
          'All items and the applied discount will be removed.',
          style: TextStyle(
            color: TenantAdminColors.mutedText,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          OutlinedButton(
            key: const ValueKey('clear-cart-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(120, 48),
              foregroundColor: TenantAdminColors.bodyText,
              side: const BorderSide(color: TenantAdminColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            key: const ValueKey('clear-cart-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(148, 48),
              backgroundColor: TenantAdminColors.posNewSaleClearAction,
              foregroundColor: TenantAdminColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            label: const Text('Clear Cart'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(posNewSaleCartProvider.notifier).clear();
    }
  }

  Future<void> _saveParkedSale(
    BuildContext context,
    WidgetRef ref,
    PosNewSaleCartState cart,
  ) async {
    if (!cart.hasItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add at least one item before parking the sale.')),
      );
      return;
    }
    final access = ref.read(posParkedSaleAccessContextProvider);
    if (!access.trustedDevice || (access.deviceId?.trim().isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'An activated trusted device is required to park this sale.')),
      );
      return;
    }
    await showPosParkSaleDialog(context: context, ref: ref, cart: cart);
  }

  Future<void> _recallParkedSale(BuildContext context, WidgetRef ref) async {
    final sale = await showPosParkedSaleDialog(context: context, ref: ref);
    if (sale == null || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${sale.reference} recalled.')),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onPrimary;
    return Tooltip(
      message: tooltip ?? label,
      child: SizedBox(
        height: 58,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 24),
          label: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foreground,
            disabledBackgroundColor: backgroundColor.withValues(alpha: 0.42),
            disabledForegroundColor: foreground.withValues(alpha: 0.82),
            padding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.sm,
            ),
            textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
          ),
        ),
      ),
    );
  }
}
