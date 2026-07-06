import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../cart/domain/entities/pos_cart_discount.dart';
import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

Future<void> showPosDiscountDialog({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: const _PosDiscountDialog(),
    ),
  );
}

enum _DiscountScope {
  manual,
  item,
}

class _PosDiscountDialog extends ConsumerStatefulWidget {
  const _PosDiscountDialog();

  @override
  ConsumerState<_PosDiscountDialog> createState() => _PosDiscountDialogState();
}

class _PosDiscountDialogState extends ConsumerState<_PosDiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  final _reasonController = TextEditingController();

  _DiscountScope _scope = _DiscountScope.manual;
  PosDiscountValueType _valueType = PosDiscountValueType.percentage;
  String? _selectedItemKey;

  @override
  void dispose() {
    _valueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(posNewSaleCartProvider);
    _selectedItemKey ??=
        cart.itemList.isEmpty ? null : cart.itemList.first.product.cartLineKey;

    return SafeArea(
      child: Dialog(
        insetPadding: const EdgeInsets.all(TenantAdminSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useTwoColumns =
                  constraints.maxWidth >= TenantAdminBreakpoints.tablet;

              final sidebar = _DiscountSidebar(
                selectedScope: _scope,
                savings: cart.discount,
                onScopeChanged: (scope) {
                  setState(() {
                    _scope = scope;
                    _formKey.currentState?.reset();
                  });
                },
                onClear: cart.hasDiscount
                    ? () => ref
                        .read(posNewSaleCartProvider.notifier)
                        .clearDiscounts()
                    : null,
                onClose: () => Navigator.of(context).pop(),
              );
              final form = _DiscountForm(
                formKey: _formKey,
                scope: _scope,
                valueType: _valueType,
                valueController: _valueController,
                reasonController: _reasonController,
                selectedItemKey: _selectedItemKey,
                onValueTypeChanged: (valueType) {
                  setState(() => _valueType = valueType);
                  _formKey.currentState?.validate();
                },
                onSelectedItemChanged: (key) {
                  setState(() => _selectedItemKey = key);
                  _formKey.currentState?.validate();
                },
                onApply: () => _applyDiscount(cart),
              );

              if (useTwoColumns) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 300, child: sidebar),
                    const VerticalDivider(width: 1),
                    Expanded(child: form),
                  ],
                );
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    sidebar,
                    const Divider(height: 1),
                    form,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _applyDiscount(PosNewSaleCartState cart) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final value = double.parse(_valueController.text.trim());
    final reason = _reasonController.text.trim();
    final discount = PosCartDiscount(
      valueType: _valueType,
      value: value,
      reason: reason.isEmpty ? null : reason,
    );

    final notifier = ref.read(posNewSaleCartProvider.notifier);
    if (_scope == _DiscountScope.manual) {
      notifier.applyCartDiscount(discount);
    } else {
      notifier.applyItemDiscount(
        cartLineKey: _selectedItemKey!,
        discount: discount,
      );
    }

    Navigator.of(context).pop();
  }
}

class _DiscountSidebar extends StatelessWidget {
  const _DiscountSidebar({
    required this.selectedScope,
    required this.savings,
    required this.onScopeChanged,
    required this.onClose,
    this.onClear,
  });

  final _DiscountScope selectedScope;
  final int savings;
  final ValueChanged<_DiscountScope> onScopeChanged;
  final VoidCallback onClose;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Discounts',
                  style: TenantAdminTextStyles.sectionTitle(context)),
              const Spacer(),
              IconButton(
                tooltip: 'Close',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          _DiscountScopeTile(
            selected: selectedScope == _DiscountScope.manual,
            icon: Icons.percent_rounded,
            title: 'Manual Discount',
            subtitle: 'Apply custom discount',
            onTap: () => onScopeChanged(_DiscountScope.manual),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          _DiscountScopeTile(
            selected: selectedScope == _DiscountScope.item,
            icon: Icons.sell_outlined,
            title: 'Item Discount',
            subtitle: 'Discount on specific items',
            onTap: () => onScopeChanged(_DiscountScope.item),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Container(
            padding: const EdgeInsets.all(TenantAdminSpacing.md),
            decoration: BoxDecoration(
              color: TenantAdminColors.secondary,
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Running Savings',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: TenantAdminColors.bodyText,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  formatLkr(savings),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: TenantAdminColors.info,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  'Great! You are saving on this sale.',
                  style: TenantAdminTextStyles.muted(context),
                ),
              ],
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Clear discounts'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiscountScopeTile extends StatelessWidget {
  const _DiscountScopeTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? TenantAdminColors.secondary : TenantAdminColors.surface,
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(TenantAdminSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(
              color:
                  selected ? TenantAdminColors.info : TenantAdminColors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: TenantAdminColors.info),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: TenantAdminColors.bodyText,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: TenantAdminColors.mutedText,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscountForm extends ConsumerWidget {
  const _DiscountForm({
    required this.formKey,
    required this.scope,
    required this.valueType,
    required this.valueController,
    required this.reasonController,
    required this.selectedItemKey,
    required this.onValueTypeChanged,
    required this.onSelectedItemChanged,
    required this.onApply,
  });

  final GlobalKey<FormState> formKey;
  final _DiscountScope scope;
  final PosDiscountValueType valueType;
  final TextEditingController valueController;
  final TextEditingController reasonController;
  final String? selectedItemKey;
  final ValueChanged<PosDiscountValueType> onValueTypeChanged;
  final ValueChanged<String?> onSelectedItemChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(posNewSaleCartProvider);
    final selectedItem =
        selectedItemKey == null ? null : cart.items[selectedItemKey];
    final title =
        scope == _DiscountScope.manual ? 'Manual Discount' : 'Item Discount';
    final subtitle = scope == _DiscountScope.manual
        ? 'Apply custom discount'
        : 'Discount on specific items';

    return Padding(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: TenantAdminTextStyles.sectionTitle(context)),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(subtitle, style: TenantAdminTextStyles.muted(context)),
              if (scope == _DiscountScope.item) ...[
                const SizedBox(height: TenantAdminSpacing.lg),
                _ItemPicker(
                  items: cart.itemList,
                  selectedItemKey: selectedItemKey,
                  onChanged: onSelectedItemChanged,
                ),
              ],
              const SizedBox(height: TenantAdminSpacing.lg),
              Text(
                'Discount Type',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: TenantAdminSpacing.sm),
              SegmentedButton<PosDiscountValueType>(
                segments: const [
                  ButtonSegment(
                    value: PosDiscountValueType.percentage,
                    label: Text('Percentage'),
                  ),
                  ButtonSegment(
                    value: PosDiscountValueType.fixedAmount,
                    label: Text('Fixed Amount'),
                  ),
                ],
                selected: {valueType},
                onSelectionChanged: (selection) =>
                    onValueTypeChanged(selection.first),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              TextFormField(
                controller: valueController,
                decoration: InputDecoration(
                  labelText: 'Discount Value',
                  prefixText: valueType == PosDiscountValueType.fixedAmount
                      ? '${formatLkrInputPrefix()} '
                      : null,
                  suffixText:
                      valueType == PosDiscountValueType.percentage ? '%' : null,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (value) => _validateDiscountValue(
                  value: value,
                  cart: cart,
                  selectedItem: selectedItem,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: reasonController,
                builder: (context, value, _) {
                  return TextFormField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      hintText: 'Add a reason or note (optional)',
                      counterText: '${value.text.length} / 200',
                    ),
                    maxLines: 3,
                    maxLength: 200,
                    validator: (reason) {
                      if ((reason ?? '').length > 200) {
                        return 'Reason cannot exceed 200 characters';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              FilledButton.icon(
                onPressed: cart.hasItems ? onApply : null,
                icon: const Icon(Icons.discount_outlined),
                label: const Text('Apply Discount'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateDiscountValue({
    required String? value,
    required PosNewSaleCartState cart,
    required PosNewSaleCartItem? selectedItem,
  }) {
    final trimmed = value?.trim() ?? '';
    if (!cart.hasItems) {
      return 'Cart empty should not allow applying discount';
    }
    if (scope == _DiscountScope.item && selectedItem == null) {
      return 'Item Discount requires one cart item selected';
    }
    if (trimmed.isEmpty) {
      return 'Discount value required';
    }

    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      return 'Discount value must be numeric';
    }

    if (valueType == PosDiscountValueType.percentage) {
      if (parsed <= 0 || parsed > 100) {
        return 'Percentage must be greater than 0 and less than or equal to 100';
      }
      return null;
    }

    if (parsed <= 0) {
      return 'Fixed amount must be greater than 0';
    }

    final maxAmount = scope == _DiscountScope.manual
        ? cart.subtotal
        : selectedItem?.lineTotal ?? 0;
    if (parsed > maxAmount) {
      return scope == _DiscountScope.manual
          ? 'Fixed amount cannot exceed subtotal'
          : 'Fixed amount cannot exceed selected item line total';
    }

    return null;
  }
}

class _ItemPicker extends StatelessWidget {
  const _ItemPicker({
    required this.items,
    required this.selectedItemKey,
    required this.onChanged,
  });

  final List<PosNewSaleCartItem> items;
  final String? selectedItemKey;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'No cart items available.',
        style: TenantAdminTextStyles.muted(context),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select Item',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        ...items.map(
          (item) {
            final key = item.product.cartLineKey;
            final selected = key == selectedItemKey;
            return ListTile(
              selected: selected,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? TenantAdminColors.info
                    : TenantAdminColors.mutedText,
              ),
              title: Text(item.product.name),
              subtitle:
                  Text('Qty ${item.quantity} • ${formatLkr(item.lineTotal)}'),
              onTap: () => onChanged(key),
            );
          },
        ),
      ],
    );
  }
}
