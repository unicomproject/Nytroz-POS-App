import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../cart/domain/entities/pos_cart_discount.dart';
import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../cart/presentation/providers/pos_discount_provider.dart';
import '../../../../cart/domain/entities/pos_discount_api_models.dart';
import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../../../core/access/pos_access_codes.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/pos_checkout_summary_provider.dart';

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
  String? _selectedPolicyId;
  bool _predefined = false;
  bool _submitting = false;

  @override
  void dispose() {
    _valueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(posNewSaleCartProvider);
    final selectedItem = _selectedItemKey == null ? null : cart.items[_selectedItemKey];
    final cartVariantIds = cart.itemList
        .map((item) => item.product.variantId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    final catalogQuery = PosDiscountCatalogQuery(
      scope: _scope == _DiscountScope.item ? 'LINE' : 'ORDER',
      variantId: _scope == _DiscountScope.item ? selectedItem?.product.variantId : null,
      variantIds: _scope == _DiscountScope.item ? const [] : cartVariantIds,
      customerId: cart.selectedCustomer?.customerId,
      quantity: _scope == _DiscountScope.item
          ? selectedItem?.quantity.toDouble()
          : cart.itemList.fold<double>(0, (sum, item) => sum + item.quantity),
      cartSubtotal: cart.subtotal.toDouble(),
    );
    final canApprove = ref
            .watch(authSessionProvider)
            ?.hasPermission(PosPermissionCodes.approveSaleDiscount) ==
        true;
    final shouldLoadPolicies =
        _predefined && (_scope != _DiscountScope.item || selectedItem != null);
    final catalogAsync = shouldLoadPolicies
        ? ref.watch(posDiscountCatalogProvider(catalogQuery))
        : null;
    final catalog = catalogAsync?.valueOrNull;
    final expectedPolicyScope =
        _scope == _DiscountScope.item ? 'LINE' : 'ORDER';
    final policies = (catalog?.discounts ?? const <PosDiscountPolicy>[])
        .where((policy) => policy.scope == expectedPolicyScope)
        .toList(growable: false);
    final matchingPolicies =
        _predefined ? policies : const <PosDiscountPolicy>[];
    final selectedPolicy =
        matchingPolicies.where((x) => x.id == _selectedPolicyId).firstOrNull ??
            (matchingPolicies.isEmpty ? null : matchingPolicies.first);
    if (_predefined && selectedPolicy != null &&
        (_selectedPolicyId != selectedPolicy.id ||
            _valueController.text != selectedPolicy.predefinedValue.toString())) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_predefined) return;
        setState(() {
          _selectedPolicyId = selectedPolicy.id;
          _valueType = selectedPolicy.isPercentage
              ? PosDiscountValueType.percentage
              : PosDiscountValueType.fixedAmount;
          _valueController.text = selectedPolicy.predefinedValue.toString();
        });
      });
    }

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
                    ? () => _clearDiscounts(cart)
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
                  final candidates = policies.where((policy) =>
                      policy.isPercentage ==
                          (valueType == PosDiscountValueType.percentage) &&
                      _predefined);
                  final nextPolicy =
                      candidates.isEmpty ? null : candidates.first;
                  setState(() {
                    _valueType = valueType;
                    _selectedPolicyId = nextPolicy?.id;
                    if (_predefined && nextPolicy != null) {
                      _valueController.text =
                          nextPolicy.predefinedValue.toString();
                    }
                  });
                  _formKey.currentState?.validate();
                },
                onSelectedItemChanged: (key) {
                  setState(() => _selectedItemKey = key);
                  _formKey.currentState?.validate();
                },
                onApply: () => _applyDiscount(cart),
                policies: matchingPolicies,
                selectedPolicy: selectedPolicy,
                predefined: _predefined,
                submitting: _submitting,
                catalogLoading: catalogAsync?.isLoading == true,
                catalogError: catalogAsync?.hasError == true
                    ? catalogAsync!.error.toString()
                    : null,
                waitingForItemSelection:
                    _predefined && _scope == _DiscountScope.item && selectedItem == null,
                onPolicyChanged: (policy) {
                  setState(() {
                    _selectedPolicyId = policy?.id;
                    if (_predefined && policy != null) {
                      _valueType = policy.isPercentage
                          ? PosDiscountValueType.percentage
                          : PosDiscountValueType.fixedAmount;
                      _valueController.text = policy.predefinedValue.toString();
                    }
                  });
                },
                onPredefinedChanged: (value) {
                  final nextPolicy = value && policies.isNotEmpty
                      ? policies.first
                      : null;
                  setState(() {
                    _predefined = value;
                    _selectedPolicyId = nextPolicy?.id;
                    if (value && nextPolicy != null) {
                      _valueType = nextPolicy.isPercentage
                          ? PosDiscountValueType.percentage
                          : PosDiscountValueType.fixedAmount;
                      _valueController.text =
                          nextPolicy.predefinedValue.toString();
                    } else if (!value) {
                      _valueController.clear();
                    }
                  });
                },
                pendingDiscount: cart.pendingDiscount,
                canApprovePending: canApprove,
                onApprovePending: () => _decidePending(cart, 'APPROVE'),
                onRejectPending: () => _decidePending(cart, 'REJECT'),
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

  Future<void> _applyDiscount(PosNewSaleCartState cart) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final value = double.parse(_valueController.text.trim());
    final reason = _reasonController.text.trim();
    PosDiscountPolicy? policy;
    if (_predefined) {
      final selectedItem = _selectedItemKey == null ? null : cart.items[_selectedItemKey];
      if (_scope == _DiscountScope.item && selectedItem == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a cart item first.')),
        );
        return;
      }
      final cartVariantIds = cart.itemList
          .map((item) => item.product.variantId)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
      final query = PosDiscountCatalogQuery(
        scope: _scope == _DiscountScope.item ? 'LINE' : 'ORDER',
        variantId: _scope == _DiscountScope.item ? selectedItem?.product.variantId : null,
        variantIds: _scope == _DiscountScope.item ? const [] : cartVariantIds,
        customerId: cart.selectedCustomer?.customerId,
        quantity: _scope == _DiscountScope.item
            ? selectedItem?.quantity.toDouble()
            : cart.itemList.fold<double>(0, (sum, item) => sum + item.quantity),
        cartSubtotal: cart.subtotal.toDouble(),
      );
      final catalog = ref.read(posDiscountCatalogProvider(query)).valueOrNull;
      final policies = catalog?.discounts.where((x) => x.id == _selectedPolicyId);
      policy = policies?.firstOrNull;
    }
    if (_predefined && policy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No active discount policy is available.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await applyPosDiscount(
        ref: ref,
        policy: policy,
        valueType: _valueType,
        value: _predefined ? policy!.predefinedValue : value,
        isLineDiscount: _scope == _DiscountScope.item,
        targetVariantId:
            _scope == _DiscountScope.item
                ? cart.items[_selectedItemKey]?.product.variantId
                : null,
        reason: reason.isEmpty ? null : reason,
        predefined: _predefined,
      );
      if (!mounted) return;
      if (result.applied) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.messages.isEmpty
              ? 'Manager approval is required.'
              : result.messages.join(' ')),
        ));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _clearDiscounts(PosNewSaleCartState cart) async {
    final discounts = <PosCartDiscount>[
      if (cart.cartDiscount != null) cart.cartDiscount!,
      ...cart.items.values.map((x) => x.discount).whereType<PosCartDiscount>(),
    ];
    setState(() => _submitting = true);
    try {
      for (final discount in discounts) {
        await cancelPosDiscount(ref: ref, discount: discount);
      }
      ref.read(posNewSaleCartProvider.notifier).clearDiscounts();
      ref.invalidate(posCheckoutSummaryProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to remove discount: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _decidePending(
    PosNewSaleCartState cart,
    String decision,
  ) async {
    final pending = cart.pendingDiscount;
    if (pending?.applicationId == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      final status = await ref.read(posDiscountRemoteDatasourceProvider).decide(
            applicationId: pending!.applicationId!,
            decision: decision,
            note: _reasonController.text.trim(),
          );
      if (!mounted) return;
      final notifier = ref.read(posNewSaleCartProvider.notifier);
      final lineKey = cart.pendingDiscountCartLineKey;
      if (status == 'APPROVED') {
        final approved = pending.copyWith(status: 'approved');
        if (lineKey == null) {
          notifier.applyCartDiscount(approved);
        } else {
          notifier.applyItemDiscount(cartLineKey: lineKey, discount: approved);
        }
        ref.invalidate(posCheckoutSummaryProvider);
        Navigator.of(context).pop();
      } else {
        if (lineKey == null) {
          notifier.clearCartDiscount();
        } else {
          notifier.clearItemDiscount(lineKey);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discount request rejected.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
    required this.policies,
    required this.selectedPolicy,
    required this.predefined,
    required this.submitting,
    required this.catalogLoading,
    required this.catalogError,
    required this.waitingForItemSelection,
    required this.onPolicyChanged,
    required this.onPredefinedChanged,
    required this.pendingDiscount,
    required this.canApprovePending,
    required this.onApprovePending,
    required this.onRejectPending,
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
  final List<PosDiscountPolicy> policies;
  final PosDiscountPolicy? selectedPolicy;
  final bool predefined;
  final bool submitting;
  final bool catalogLoading;
  final String? catalogError;
  final bool waitingForItemSelection;
  final ValueChanged<PosDiscountPolicy?> onPolicyChanged;
  final ValueChanged<bool> onPredefinedChanged;
  final PosCartDiscount? pendingDiscount;
  final bool canApprovePending;
  final VoidCallback onApprovePending;
  final VoidCallback onRejectPending;

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
              if (pendingDiscount != null) ...[
                const SizedBox(height: TenantAdminSpacing.md),
                Container(
                  padding: const EdgeInsets.all(TenantAdminSpacing.md),
                  decoration: BoxDecoration(
                    color: TenantAdminColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Manager approval pending'),
                      SelectableText(
                        'Application: ${pendingDiscount!.applicationId}',
                      ),
                      if (canApprovePending) ...[
                        const SizedBox(height: TenantAdminSpacing.sm),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: submitting ? null : onRejectPending,
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: TenantAdminSpacing.sm),
                            FilledButton(
                              onPressed: submitting ? null : onApprovePending,
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: TenantAdminSpacing.lg),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Manual')),
                  ButtonSegment(value: true, label: Text('Predefined')),
                ],
                selected: {predefined},
                onSelectionChanged: (value) => onPredefinedChanged(value.first),
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              if (predefined && waitingForItemSelection)
                const Text('Select a cart item to load applicable policies.')
              else if (predefined && catalogLoading)
                const LinearProgressIndicator()
              else if (predefined && catalogError != null)
                Text('Unable to load discount policies: $catalogError',
                    style: const TextStyle(color: Colors.red))
              else if (predefined && policies.isEmpty)
                Text(scope == _DiscountScope.item
                    ? 'No applicable item discount policies.'
                    : 'No applicable order discount policies.')
              else if (predefined)
                DropdownButtonFormField<PosDiscountPolicy>(
                key: ValueKey('${valueType.name}-${selectedPolicy?.id}'),
                initialValue: selectedPolicy,
                decoration: const InputDecoration(labelText: 'Discount Policy'),
                items: policies
                    .map((policy) => DropdownMenuItem(
                          value: policy,
                          child: Text(
                              '${policy.name} (max ${policy.absoluteValueLimit})'),
                        ))
                    .toList(),
                onChanged: onPolicyChanged,
                validator: (value) =>
                    value == null ? 'Select a discount policy' : null,
              ),
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
                onSelectionChanged: predefined
                    ? null
                    : (selection) => onValueTypeChanged(selection.first),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              TextFormField(
                controller: valueController,
                readOnly: predefined,
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
                onPressed: cart.hasItems && !submitting ? onApply : null,
                icon: const Icon(Icons.discount_outlined),
                label: Text(submitting ? 'Applying…' : 'Apply Discount'),
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
