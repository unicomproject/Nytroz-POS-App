import 'package:flutter/material.dart';
import 'package:nytroz_pos/shared/widgets/pos_action_buttons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_parked_sale_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_discount_dialog.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_parked_sale_dialog.dart';
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
    final parkedSaleCount = ref.watch(posParkedSaleProvider).maybeWhen(
          data: (sales) => sales.length,
          orElse: () => 0,
        );
    final canApplyDiscount =
        session?.hasPermission(PosPermissionCodes.applySaleDiscount) == true;
    final canClearCart = PosPermissionAccess.canClearCart(
      session?.permissionCodes.toSet() ?? const {},
    );
    final canCreateParkedSale =
        session?.hasPermission(PosPermissionCodes.createParkedSale) == true;
    final canViewParkedSales =
        session?.hasPermission(PosPermissionCodes.viewParkedSales) == true ||
            canCreateParkedSale;
    final parkedSaleAction = cart.hasItems
        ? canCreateParkedSale
            ? () => _saveParkedSale(context, ref, cart)
            : null
        : canViewParkedSales
            ? () => _recallParkedSale(context, ref)
            : null;
    final actions = <_ActionButton>[
      if (canCreateParkedSale || canViewParkedSales)
        _ActionButton(
          icon: Icons.pause_circle_outline_rounded,
          label: cart.hasItems ? 'Hold Sale' : 'Recall Sale',
          backgroundColor: TenantAdminColors.posNewSaleHoldAction,
          tooltip: cart.hasItems
              ? 'Save current cart as a parked sale'
              : parkedSaleCount > 0
                  ? 'Recall a parked sale'
                  : 'No parked sales to recall',
          onPressed: parkedSaleAction,
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
        title: const Text('Clear current sale?'),
        content: const Text(
          'All items and the applied discount will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear Cart'),
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
    PosParkedSaleReference? referenceDetails;
    if (cart.selectedCustomer == null) {
      referenceDetails = await _showParkedSaleReferenceDialog(context);
      if (referenceDetails == null || !context.mounted) {
        return;
      }
    }

    final sale = await ref.read(posParkedSaleProvider.notifier).saveCurrentCart(
          cart,
          referenceDetails: referenceDetails,
        );

    if (sale == null || !context.mounted) {
      return;
    }

    ref.read(posNewSaleCartProvider.notifier).clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${sale.reference} saved.')),
    );
  }

  Future<void> _recallParkedSale(BuildContext context, WidgetRef ref) async {
    final sale = await showPosParkedSaleDialog(context: context, ref: ref);
    if (sale == null || !context.mounted) {
      return;
    }

    ref.read(posNewSaleCartProvider.notifier).restore(sale.toCartState());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${sale.reference} recalled.')),
    );
  }
}

Future<PosParkedSaleReference?> _showParkedSaleReferenceDialog(
  BuildContext context,
) {
  return showAppDialog<PosParkedSaleReference>(
    context: context,
    builder: (_) => const _ParkedSaleReferenceDialog(),
  );
}

class _ParkedSaleReferenceDialog extends StatefulWidget {
  const _ParkedSaleReferenceDialog();

  @override
  State<_ParkedSaleReferenceDialog> createState() =>
      _ParkedSaleReferenceDialogState();
}

class _ParkedSaleReferenceDialogState
    extends State<_ParkedSaleReferenceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reference = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _reference.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Park Sale Reference'),
      content: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _reference,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Reference / Customer name / Token',
                  hintText: 'Token 12, Table 4, Tom',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Reference is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: 'Optional',
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              TextFormField(
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'Optional',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        PosPrimaryActionButton(
          label: 'Save',
          onPressed: _submit,
          compact: true,
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      PosParkedSaleReference(
        referenceName: _reference.text.trim(),
        referencePhone: _nullableText(_phone.text),
        note: _nullableText(_note.text),
      ),
    );
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
            foregroundColor: Colors.white,
            disabledBackgroundColor: backgroundColor.withValues(alpha: 0.42),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.82),
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
