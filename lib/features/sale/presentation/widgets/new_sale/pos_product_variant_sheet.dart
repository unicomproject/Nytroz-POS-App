import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_catalog_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/payment/pos_bottom_action_buttons.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

Future<void> showPosProductVariantSheet({
  required BuildContext context,
  required WidgetRef ref,
  required PosCatalogProductSummary summary,
  PosNewSaleCartItem? existingCartItem,
}) {
  return showAppDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.42),
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
  int _selectedImageIndex = 0;
  String? _availabilityMessage;
  bool _isSubmitting = false;

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

    return _buildDialogShell(
      context,
      detailAsync.when(
        loading: () => const SizedBox(
          height: 280,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => _buildUnavailableMessage(
          context,
          'Unable to load product variants.',
        ),
        data: (detail) => _buildContent(context, detail),
      ),
    );
  }

  Widget _buildDialogShell(BuildContext context, Widget child) {
    final screenSize = MediaQuery.sizeOf(context);
    final maxWidth = (screenSize.width * 0.62).clamp(760.0, 1100.0);
    final maxHeight = (screenSize.height * 0.88).clamp(520.0, 860.0);

    return Dialog(
      insetPadding: const EdgeInsets.all(TenantAdminSpacing.xl),
      clipBehavior: Clip.antiAlias,
      backgroundColor: TenantAdminColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildUnavailableMessage(BuildContext context, String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
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
    if (detail.variants.isEmpty || detail.variantGroups.isEmpty) {
      return _buildUnavailableMessage(context, 'No variants available.');
    }

    final matchedVariant = detail.matchVariant(_selectedAttributes);
    final allSelected = detail.variantGroups.every(
      (group) => (_selectedAttributes[group.name] ?? '').isNotEmpty,
    );
    final hasValidVariant = matchedVariant != null;
    final isOutOfStock = matchedVariant?.isOutOfStock ?? false;
    final maxQuantity = matchedVariant?.stockQty?.floor();
    final unitPrice = matchedVariant?.price ?? detail.summary.basePrice;
    final hasValidPrice = unitPrice > 0;
    final canSubmit = allSelected &&
        hasValidVariant &&
        hasValidPrice &&
        !isOutOfStock &&
        !_isSubmitting &&
        _quantity >= 1 &&
        (maxQuantity == null || _quantity <= maxQuantity);

    if (allSelected && !hasValidVariant) {
      _availabilityMessage = 'This variant is not available';
    } else if (!hasValidPrice) {
      _availabilityMessage = 'Price unavailable for selected variant';
    } else if (isOutOfStock) {
      _availabilityMessage = 'This variant is out of stock';
    } else {
      _availabilityMessage = null;
    }

    final images = <String>[
      if (detail.summary.imageUrl != null &&
          detail.summary.imageUrl!.isNotEmpty)
        detail.summary.imageUrl!,
    ];
    if (_selectedImageIndex >= images.length) {
      _selectedImageIndex = 0;
    }

    final isCompact = MediaQuery.sizeOf(context).width < 980;

    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildImagePane(images),
                      const SizedBox(height: TenantAdminSpacing.lg),
                      _buildDetailsPane(
                        context: context,
                        detail: detail,
                        matchedVariant: matchedVariant,
                        unitPrice: unitPrice,
                        maxQuantity: maxQuantity,
                        canSubmit: canSubmit,
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 11, child: _buildImagePane(images)),
                      const SizedBox(width: TenantAdminSpacing.lg),
                      Expanded(
                        flex: 13,
                        child: _buildDetailsPane(
                          context: context,
                          detail: detail,
                          matchedVariant: matchedVariant,
                          unitPrice: unitPrice,
                          maxQuantity: maxQuantity,
                          canSubmit: canSubmit,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePane(List<String> images) {
    final imageUrl = images.isEmpty ? null : images[_selectedImageIndex];
    final borderRadius = BorderRadius.circular(TenantAdminRadius.lg);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: TenantAdminColors.background,
              borderRadius: borderRadius,
              border: Border.all(color: TenantAdminColors.border),
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: imageUrl == null
                  ? const Icon(
                      Icons.inventory_2_outlined,
                      color: TenantAdminColors.mutedText,
                      size: 72,
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: TenantAdminColors.mutedText,
                        size: 72,
                      ),
                    ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: TenantAdminSpacing.md),
          Wrap(
            spacing: TenantAdminSpacing.sm,
            runSpacing: TenantAdminSpacing.sm,
            children: List.generate(images.length, (index) {
              final isSelected = _selectedImageIndex == index;
              return InkWell(
                onTap: () => setState(() => _selectedImageIndex = index),
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                    border: Border.all(
                      color: isSelected
                          ? TenantAdminColors.primary
                          : TenantAdminColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: TenantAdminColors.mutedText,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsPane({
    required BuildContext context,
    required PosCatalogProductDetail detail,
    required PosCatalogVariant? matchedVariant,
    required int unitPrice,
    required int? maxQuantity,
    required bool canSubmit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                detail.summary.name,
                style: TenantAdminTextStyles.sectionTitle(context),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            _StockStatusBadge(
              stockStatus:
                  matchedVariant?.stockStatus ?? detail.summary.stockStatus,
            ),
          ],
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: TenantAdminColors.success,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        const Divider(height: 1, color: TenantAdminColors.border),
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
        Row(
          children: [
            Text(
              'Quantity',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const Spacer(),
            if (maxQuantity != null)
              Text(
                'Available: $maxQuantity',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: TenantAdminColors.success,
                      fontWeight: FontWeight.w700,
                    ),
              ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed:
                  _quantity > 1 ? () => setState(() => _quantity -= 1) : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.md),
              child: Text(
                '$_quantity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
        PosPrimaryActionButton(
          onPressed: canSubmit && matchedVariant != null
              ? () => _submit(detail, matchedVariant)
              : null,
          verticalPadding: TenantAdminSpacing.md,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.existingCartItem == null ? 'Add to Cart' : 'Update Cart',
              ),
              Text(formatLkr(unitPrice * _quantity)),
            ],
          ),
        ),
      ],
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

  Future<void> _submit(
    PosCatalogProductDetail detail,
    PosCatalogVariant variant,
  ) async {
    setState(() => _isSubmitting = true);
    final session = ref.read(authSessionProvider);
    final isUpdate = widget.existingCartItem != null;

    if (isUpdate && !PosPermissionAccess.canUpdateCartItemSession(session)) {
      PosPermissionAccess.showAccessDeniedSnackBar(
        context,
        'You do not have permission to update cart items.',
      );
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      return;
    }

    if (!isUpdate && !PosPermissionAccess.canAddCartItemSession(session)) {
      PosPermissionAccess.showAccessDeniedSnackBar(
        context,
        'You do not have permission to add items to the cart.',
      );
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      return;
    }

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

    if (mounted) {
      Navigator.of(context).pop();
    }
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

class _StockStatusBadge extends StatelessWidget {
  const _StockStatusBadge({required this.stockStatus});

  final String stockStatus;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (stockStatus) {
      'OutOfStock' => ('Out of Stock', TenantAdminColors.danger),
      'LowStock' => ('Low Stock', TenantAdminColors.warning),
      'InStock' => ('In Stock', TenantAdminColors.success),
      _ => ('Unavailable', TenantAdminColors.mutedText),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
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
