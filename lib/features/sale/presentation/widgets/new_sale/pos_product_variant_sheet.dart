import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_catalog_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

Future<void> showPosProductVariantSheet({
  required BuildContext context,
  required WidgetRef ref,
  required PosCatalogProductSummary summary,
  PosNewSaleCartItem? existingCartItem,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => PosProductVariantSheet(
      summary: summary,
      existingCartItem: existingCartItem,
    ),
  );
}

class PosProductVariantSheet extends ConsumerStatefulWidget {
  const PosProductVariantSheet({
    super.key,
    required this.summary,
    this.existingCartItem,
  });

  final PosCatalogProductSummary summary;
  final PosNewSaleCartItem? existingCartItem;

  @override
  ConsumerState<PosProductVariantSheet> createState() =>
      _PosProductVariantSheetState();
}

class _PosProductVariantSheetState
    extends ConsumerState<PosProductVariantSheet> {
  final Map<String, String> _selectedAttributes = {};
  late int _quantity;
  String? _availabilityMessage;

  @override
  void initState() {
    super.initState();
    _quantity = widget.existingCartItem?.quantity ?? 1;
    final existingAttributes =
        widget.existingCartItem?.product.selectedAttributes ?? const {};
    if (existingAttributes.isNotEmpty) {
      _selectedAttributes.addAll(existingAttributes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(posProductDetailProvider(widget.summary.productId));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: TenantAdminSpacing.lg,
          right: TenantAdminSpacing.lg,
          top: TenantAdminSpacing.sm,
          bottom:
              TenantAdminSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: detailAsync.when(
          loading: () => const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => _buildUnavailableMessage(
            context,
            'Unable to load product variants.',
          ),
          data: (detail) => _buildContent(context, detail),
        ),
      ),
    );
  }

  Widget _buildUnavailableMessage(BuildContext context, String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: TenantAdminTextStyles.muted(context)),
        const SizedBox(height: TenantAdminSpacing.md),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, PosCatalogProductDetail detail) {
    final matchedVariant = detail.matchVariant(_selectedAttributes);
    final allSelected = detail.variantGroups.every(
      (group) => (_selectedAttributes[group.name] ?? '').isNotEmpty,
    );
    final hasValidVariant = matchedVariant != null;
    final isOutOfStock = matchedVariant?.isOutOfStock ?? false;
    final maxQuantity = matchedVariant?.stockQty?.floor();
    final canSubmit = allSelected &&
        hasValidVariant &&
        !isOutOfStock &&
        _quantity >= 1 &&
        (maxQuantity == null || _quantity <= maxQuantity);

    if (allSelected && !hasValidVariant) {
      _availabilityMessage = 'This variant is not available';
    } else if (isOutOfStock) {
      _availabilityMessage = 'This variant is out of stock';
    } else {
      _availabilityMessage = null;
    }

    final unitPrice = matchedVariant?.price ?? detail.summary.basePrice;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            detail.summary.name,
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          if (detail.summary.description?.isNotEmpty == true) ...[
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(
              detail.summary.description!,
              style: TenantAdminTextStyles.muted(context),
            ),
          ],
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            formatLkr(unitPrice),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: TenantAdminColors.success,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          for (final group in detail.variantGroups) ...[
            Text(
              group.name,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            Wrap(
              spacing: TenantAdminSpacing.sm,
              runSpacing: TenantAdminSpacing.sm,
              children: [
                for (final option in group.options)
                  _VariantOptionChip(
                    label: option,
                    selected: _selectedAttributes[group.name] == option,
                    enabled: _isOptionSelectable(detail, group.name, option),
                    onSelected: () => _selectOption(group.name, option),
                  ),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.md),
          ],
          if (matchedVariant != null) ...[
            _StockStatusLabel(variant: matchedVariant),
            const SizedBox(height: TenantAdminSpacing.md),
          ],
          Row(
            children: [
              Text(
                'Quantity',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                onPressed:
                    _quantity > 1 ? () => setState(() => _quantity -= 1) : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TenantAdminSpacing.sm,
                ),
                child: Text(
                  '$_quantity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: maxQuantity == null || _quantity < maxQuantity
                    ? () => setState(() => _quantity += 1)
                    : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (_availabilityMessage != null) ...[
            const SizedBox(height: TenantAdminSpacing.sm),
            Text(
              _availabilityMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TenantAdminColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
          const SizedBox(height: TenantAdminSpacing.lg),
          FilledButton(
            onPressed: canSubmit ? () => _submit(detail, matchedVariant) : null,
            child: Text(
              widget.existingCartItem == null ? 'Add to Cart' : 'Update Cart',
            ),
          ),
        ],
      ),
    );
  }

  bool _isOptionSelectable(
    PosCatalogProductDetail detail,
    String groupName,
    String option,
  ) {
    final candidate = Map<String, String>.from(_selectedAttributes)
      ..[groupName] = option;

    for (final variant in detail.variants) {
      if (variant.isOutOfStock) {
        continue;
      }

      var matches = true;
      for (final entry in candidate.entries) {
        final variantValue = variant.attributes[entry.key];
        if (variantValue != null && variantValue != entry.value) {
          matches = false;
          break;
        }
      }

      if (matches) {
        return true;
      }
    }

    return false;
  }

  void _selectOption(String groupName, String option) {
    setState(() {
      _selectedAttributes[groupName] = option;
      _availabilityMessage = null;
    });
  }

  void _submit(PosCatalogProductDetail detail, PosCatalogVariant variant) {
    final cartProduct = toCartProduct(
      summary: detail.summary,
      variant: variant,
      quantity: _quantity,
    );
    final notifier = ref.read(posNewSaleCartProvider.notifier);

    if (widget.existingCartItem == null) {
      notifier.addToCart(cartProduct, quantity: _quantity);
    } else {
      notifier.updateCartItem(
        cartLineKey: widget.existingCartItem!.product.cartLineKey,
        product: cartProduct,
        quantity: _quantity,
      );
    }

    Navigator.of(context).pop();
  }
}

class _VariantOptionChip extends StatelessWidget {
  const _VariantOptionChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: enabled ? (_) => onSelected() : null,
      selectedColor: TenantAdminColors.info,
      backgroundColor: TenantAdminColors.surface,
      disabledColor: TenantAdminColors.background,
      labelStyle: TextStyle(
        color: !enabled
            ? TenantAdminColors.mutedText
            : selected
                ? Colors.white
                : TenantAdminColors.bodyText,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
        side: const BorderSide(color: TenantAdminColors.border),
      ),
    );
  }
}

class _StockStatusLabel extends StatelessWidget {
  const _StockStatusLabel({required this.variant});

  final PosCatalogVariant variant;

  @override
  Widget build(BuildContext context) {
    final label = switch (variant.stockStatus) {
      'OutOfStock' => 'Out of Stock',
      'LowStock' => 'Low Stock',
      _ => 'In Stock',
    };
    final color = switch (variant.stockStatus) {
      'OutOfStock' => TenantAdminColors.danger,
      'LowStock' => TenantAdminColors.warning,
      _ => TenantAdminColors.success,
    };

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: TenantAdminSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}
