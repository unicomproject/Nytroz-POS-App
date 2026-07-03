import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_parked_sale_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_discount_dialog.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_parked_sale_dialog.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_new_sale_customer_dialog.dart';

import '../../../../../core/access/pos_access_codes.dart';
import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosNewSaleActionBar extends ConsumerWidget {
  const PosNewSaleActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final cart = ref.watch(posNewSaleCartProvider);
    final selectedCustomer = cart.selectedCustomer;
    final parkedSaleCount = ref.watch(posParkedSaleProvider).maybeWhen(
          data: (sales) => sales.length,
          orElse: () => 0,
        );
    final canViewOrCreateCustomer =
        session?.hasPermission(PosPermissionCodes.viewNewSaleCustomers) ==
                true ||
            session?.hasPermission(PosPermissionCodes.createNewSaleCustomer) ==
                true;
    final canCreateCustomer =
        session?.hasPermission(PosPermissionCodes.createNewSaleCustomer) ==
            true;
    final canApplyDiscount =
        session?.hasPermission(PosPermissionCodes.applySaleDiscount) == true;
    final canCreateParkedSale =
        session?.hasPermission(PosPermissionCodes.createParkedSale) == true;
    final canViewParkedSales =
        session?.hasPermission(PosPermissionCodes.viewParkedSales) == true ||
            canCreateParkedSale;
    final parkedSaleLabel =
        cart.hasItems ? 'Save as Parked Sale' : 'Recall Parked Sale';
    final parkedSaleAction = cart.hasItems
        ? canCreateParkedSale
            ? () => _saveParkedSale(context, ref, cart)
            : null
        : canViewParkedSales
            ? () => _recallParkedSale(context, ref)
            : null;
    final customerLabel =
        selectedCustomer == null ? 'Add Customer' : 'Change customer';
    final actions = <Widget>[
      if (canViewOrCreateCustomer)
        Expanded(
          child: _ActionButton(
            icon: Icons.person_add_alt_1_outlined,
            label: customerLabel,
            onPressed: () async {
              final customer = await showPosNewSaleCustomerDialog(
                context: context,
                ref: ref,
                canCreateCustomer: canCreateCustomer,
              );
              if (customer != null) {
                ref.read(posNewSaleCartProvider.notifier).setCustomer(customer);
              }
            },
          ),
        ),
      if (canApplyDiscount)
        Expanded(
          child: _ActionButton(
            icon: Icons.discount_outlined,
            label: cart.hasDiscount ? 'Edit Discount' : 'Apply Discount',
            tooltip: cart.hasItems
                ? 'Apply discount to this cart'
                : 'Add products before applying a discount',
            onPressed: cart.hasItems
                ? () => showPosDiscountDialog(context: context, ref: ref)
                : null,
          ),
        ),
      if (canCreateParkedSale || canViewParkedSales)
        Expanded(
          child: _ActionButton(
            icon: Icons.pause_circle_outline_rounded,
            label: parkedSaleLabel,
            tooltip: cart.hasItems
                ? 'Save current cart as a parked sale'
                : parkedSaleCount > 0
                    ? 'Recall a parked sale'
                    : 'No parked sales to recall',
            onPressed: parkedSaleAction,
          ),
        ),
    ];

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        for (var index = 0; index < actions.length; index += 1) ...[
          if (index > 0) const SizedBox(width: TenantAdminSpacing.sm),
          actions[index],
        ],
      ],
    );
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
  return showDialog<PosParkedSaleReference>(
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
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
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
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? label,
      child: SizedBox(
        height: 42,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.sm,
            ),
            textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
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
