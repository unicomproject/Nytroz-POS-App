import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/pos/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/pos/presentation/providers/pos_catalog_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';
import 'package:nytroz_pos/shared/widgets/app_cached_network_image.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

String _formatMoney(double amount, String currency) {
  if (currency.trim().isEmpty) return 'Price unavailable';
  final fixed = amount.toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts.first;
  final grouped = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${currency.trim()} $grouped.${parts.last}';
}

String _newUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex =
      bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

abstract final class _PopupTokens {
  static const primary = Color(0xFFFF3B0A);
  static const navy = Color(0xFF0C1F4A);
  static const secondaryText = Color(0xFF667085);
  static const border = Color(0xFFE4E7EC);
  static const controlBackground = Color(0xFFF8FAFC);
  static const success = Color(0xFF16A34A);
  static const radius = 20.0;
}

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
  final Map<String, String> _selectedValueIds = {};
  final Set<String> _selectedRecommendationIds = {};
  late final TextEditingController _noteController;
  late int _quantity;
  String? _availabilityMessage;
  String? _submissionError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _quantity = widget.existingCartItem?.quantity ?? 1;
    _noteController = TextEditingController(
      text: widget.existingCartItem?.product.lineNote ?? '',
    );
    final existingAttributes =
        widget.existingCartItem?.product.selectedAttributes ?? const {};
    if (existingAttributes.isNotEmpty) {
      _selectedAttributes.addAll(existingAttributes);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(posProductDetailProvider(widget.summary.productId));
    final recommendationsAsync = ref.watch(posProductRecommendationsProvider(
      PosRecommendationQuery(widget.summary.productId),
    ));

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
        data: (detail) => _buildContent(
          context,
          detail,
          recommendationsAsync.valueOrNull ?? const [],
          recommendationsAsync.hasError,
        ),
      ),
    );
  }

  Widget _buildDialogShell(BuildContext context, Widget child) {
    final screenSize = MediaQuery.sizeOf(context);
    final isMobile = screenSize.width < 600;
    final maxWidth = isMobile
        ? screenSize.width
        : (screenSize.width * 0.72).clamp(820.0, 1040.0);
    final maxHeight = isMobile
        ? screenSize.height
        : (screenSize.height * 0.96).clamp(680.0, 960.0);

    return Dialog(
      insetPadding: EdgeInsets.all(isMobile ? 0 : 24),
      clipBehavior: Clip.antiAlias,
      backgroundColor: TenantAdminColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 0 : _PopupTokens.radius),
        side: const BorderSide(color: _PopupTokens.border),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 30),
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

  Widget _buildContent(
      BuildContext context,
      PosCatalogProductDetail detail,
      List<PosProductRecommendation> recommendations,
      bool recommendationError) {
    if (detail.variants.isEmpty || detail.variantGroups.isEmpty) {
      return _buildUnavailableMessage(context, 'No variants available.');
    }

    _initializeDefault(detail);
    final usesStableIds = detail.variantGroups.every(
            (group) => group.optionId.isNotEmpty && group.values.isNotEmpty) &&
        detail.variants
            .every((variant) => variant.selectedOptionValueIds.isNotEmpty);
    final matchedVariant = usesStableIds
        ? detail.matchVariantIds(_selectedValueIds.values.toSet())
        : detail.matchVariant(_selectedAttributes);
    final allSelected = detail.variantGroups.every(
      (group) =>
          !group.isRequired ||
          (usesStableIds
              ? (_selectedValueIds[group.optionId] ?? '').isNotEmpty
              : (_selectedAttributes[group.name] ?? '').isNotEmpty),
    );
    final hasValidVariant = matchedVariant != null;
    final isOutOfStock = matchedVariant?.isOutOfStock ?? false;
    final maxQuantity = matchedVariant?.stockQty?.floor();
    final unitPrice = matchedVariant?.authoritativePrice ??
        (matchedVariant?.price ?? detail.summary.basePrice).toDouble();
    final currency = (matchedVariant?.currency.trim().isNotEmpty == true
            ? matchedVariant!.currency
            : detail.currency)
        .trim();
    final hasStableMetadata =
        usesStableIds && matchedVariant?.salesUomId.trim().isNotEmpty == true;
    final hasValidPrice = unitPrice > 0 && currency.isNotEmpty;
    final canSubmit = allSelected &&
        hasValidVariant &&
        hasStableMetadata &&
        hasValidPrice &&
        !isOutOfStock &&
        !matchedVariant.allowFractionalQuantity &&
        !_isSubmitting &&
        _quantity >= 1 &&
        (maxQuantity == null || _quantity <= maxQuantity);

    if (matchedVariant?.allowFractionalQuantity == true) {
      _availabilityMessage =
          'Fractional quantities are not yet supported by POS checkout.';
    } else if (allSelected && !hasValidVariant) {
      _availabilityMessage = 'This variant is not available';
    } else if (allSelected && hasValidVariant && !hasStableMetadata) {
      _availabilityMessage =
          'This product is missing required variant metadata. Refresh or contact an administrator.';
    } else if (!hasValidPrice) {
      _availabilityMessage = 'Price unavailable for selected variant';
    } else if (isOutOfStock) {
      _availabilityMessage = 'This variant is out of stock';
    } else {
      _availabilityMessage = null;
    }

    final screenSize = MediaQuery.sizeOf(context);
    final variantImageUrl = matchedVariant?.imageUrl;
    final imageUrl = variantImageUrl?.isNotEmpty == true
        ? variantImageUrl
        : detail.summary.imageUrl?.isNotEmpty == true
            ? detail.summary.imageUrl
            : null;
    final useWideLayout = screenSize.width >= 1000;
    final useTwoColumns = screenSize.width >= 700;
    final desiredBodyHeight = screenSize.height * 0.78;
    final availableBodyHeight = screenSize.width < 600
        ? desiredBodyHeight
        : min(desiredBodyHeight, screenSize.height - 158);
    final maxBodyHeight = availableBodyHeight.clamp(320.0, 800.0);

    final detailsPane = _buildDetailsPane(
      context: context,
      detail: detail,
      matchedVariant: matchedVariant,
      unitPrice: unitPrice,
      currency: currency,
      maxQuantity: maxQuantity,
      canSubmit: canSubmit,
      recommendations: recommendations,
    );

    final recommendationPane = _buildRecommendationsPanel(
      context,
      recommendations,
      recommendationError,
      currency,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
          ),
        ),
        if (useWideLayout)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 34, child: _buildImagePane(imageUrl)),
              const SizedBox(width: 28),
              Expanded(
                flex: 40,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxBodyHeight),
                  child: SingleChildScrollView(
                    key: const Key('variant-details-scroll'),
                    child: detailsPane,
                  ),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(flex: 26, child: recommendationPane),
            ],
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxBodyHeight),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (useTwoColumns)
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildImagePane(imageUrl)),
                          const SizedBox(width: 24),
                          Expanded(child: detailsPane),
                        ])
                  else ...[
                    Align(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: _buildImagePane(imageUrl),
                      ),
                    ),
                    const SizedBox(height: 22),
                    detailsPane,
                  ],
                  const SizedBox(height: 22),
                  recommendationPane,
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePane(String? imageUrl) {
    final borderRadius = BorderRadius.circular(TenantAdminRadius.lg);

    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
          border: Border.all(color: TenantAdminColors.border),
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: AppCachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            memCacheWidth: 400,
            placeholder: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: const Icon(
              Icons.broken_image_outlined,
              color: TenantAdminColors.mutedText,
              size: 72,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsPane({
    required BuildContext context,
    required PosCatalogProductDetail detail,
    required PosCatalogVariant? matchedVariant,
    required double unitPrice,
    required String currency,
    required int? maxQuantity,
    required bool canSubmit,
    required List<PosProductRecommendation> recommendations,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 25,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: _PopupTokens.navy,
                ),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            _StockStatusBadge(
              stockStatus:
                  matchedVariant?.stockStatus ?? detail.summary.stockStatus,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _formatMoney(unitPrice, currency),
          style: const TextStyle(
            color: _PopupTokens.primary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'SKU: ${(matchedVariant?.sku ?? detail.summary.sku ?? '').trim().isEmpty ? 'Unavailable' : (matchedVariant?.sku ?? detail.summary.sku)}',
          style: const TextStyle(
            color: _PopupTokens.navy,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (detail.summary.description?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 10),
          Text(
            detail.summary.description!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _PopupTokens.secondaryText,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
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
              for (final option in (group.values.isNotEmpty
                  ? group.values
                  : group.options.map((label) => PosCatalogOptionValue(
                        optionValueId: label,
                        code: label,
                        displayName: label,
                      ))))
                _VariantOptionChip(
                  label: option.displayName,
                  colorHex: option.colorHex,
                  selected: group.values.isNotEmpty
                      ? _selectedValueIds[group.optionId] ==
                          option.optionValueId
                      : _selectedAttributes[group.name] == option.displayName,
                  enabled: group.values.isNotEmpty
                      ? _isOptionValueSelectable(
                          detail, group.optionId, option.optionValueId)
                      : _isLegacyOptionSelectable(
                          detail, group.name, option.displayName),
                  onSelected: () => group.values.isNotEmpty
                      ? _selectOptionValue(
                          detail, group.optionId, option.optionValueId)
                      : setState(() {
                          _selectedAttributes[group.name] = option.displayName;
                          _availabilityMessage = null;
                        }),
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
        _QuantityStepper(
          quantity: _quantity,
          canDecrease: _quantity > 1,
          canIncrease: maxQuantity == null || _quantity < maxQuantity,
          onDecrease: () => setState(() => _quantity -= 1),
          onIncrease: () => setState(() => _quantity += 1),
        ),
        if ((_submissionError ?? _availabilityMessage) != null) ...[
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            (_submissionError ?? _availabilityMessage)!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TenantAdminColors.danger,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
        const SizedBox(height: TenantAdminSpacing.md),
        const Text(
          'Note (Optional)',
          style: TextStyle(
            color: _PopupTokens.navy,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('product-line-note'),
          controller: _noteController,
          maxLength: 500,
          minLines: 1,
          maxLines: 2,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'Add note about this product',
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide: const BorderSide(color: _PopupTokens.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9),
              borderSide:
                  const BorderSide(color: _PopupTokens.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _PopupTokens.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _PopupTokens.border,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9)),
                ),
                onPressed: canSubmit && matchedVariant != null
                    ? () => _submit(detail, matchedVariant, recommendations)
                    : null,
                icon: _isSubmitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.shopping_cart_outlined),
                label: Text(widget.existingCartItem == null
                    ? 'Add to Cart'
                    : 'Update Cart'),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: _PopupTokens.navy,
                  side: const BorderSide(color: _PopupTokens.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9)),
                ),
                onPressed:
                    _isSubmitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildRecommendationsPanel(
    BuildContext context,
    List<PosProductRecommendation> recommendations,
    bool recommendationError,
    String productCurrency,
  ) {
    return Container(
      key: const Key('recommendation-panel'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _PopupTokens.border),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Frequently Bought Together',
            style: TextStyle(
              color: _PopupTokens.navy,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (recommendationError || recommendations.isEmpty)
            const Text(
              'Recommendations are unavailable. You can still add this product.',
              style: TextStyle(
                color: _PopupTokens.secondaryText,
                fontSize: 13,
                height: 1.4,
              ),
            )
          else
            for (final (index, recommendation)
                in recommendations.take(3).indexed) ...[
              if (index > 0)
                const Divider(height: 1, color: _PopupTokens.border),
              _RecommendationRow(
                recommendation: recommendation,
                selected: _selectedRecommendationIds
                    .contains(recommendation.relationshipId),
                displayCurrency: recommendation.currency.trim().isNotEmpty
                    ? recommendation.currency
                    : productCurrency,
                onChanged: _canSelectRecommendation(recommendation)
                    ? (selected) => setState(() {
                          if (selected) {
                            _selectedRecommendationIds
                                .add(recommendation.relationshipId);
                          } else {
                            _selectedRecommendationIds
                                .remove(recommendation.relationshipId);
                          }
                        })
                    : null,
              ),
            ],
        ],
      ),
    );
  }

  bool _canSelectRecommendation(PosProductRecommendation recommendation) {
    final price = recommendation.price;
    return recommendation.isSelectable &&
        !recommendation.requiresConfiguration &&
        recommendation.variantId?.isNotEmpty == true &&
        price != null &&
        price > 0 &&
        price == price.truncateToDouble();
  }

  void _initializeDefault(PosCatalogProductDetail detail) {
    if (_selectedValueIds.isNotEmpty) return;
    final existingVariantId = widget.existingCartItem?.product.variantId;
    final candidate = detail.variants
        .where((variant) =>
            variant.isSelectable &&
            !variant.isOutOfStock &&
            (variant.variantId == existingVariantId ||
                (existingVariantId == null && variant.isDefault)))
        .firstOrNull;
    if (candidate == null) return;
    for (final group in detail.variantGroups) {
      final value = group.values
          .where((item) =>
              candidate.selectedOptionValueIds.contains(item.optionValueId))
          .firstOrNull;
      if (value != null) {
        _selectedValueIds[group.optionId] = value.optionValueId;
        _selectedAttributes[group.name] = value.displayName;
      }
    }
  }

  bool _isOptionValueSelectable(
      PosCatalogProductDetail detail, String optionId, String optionValueId) {
    final candidate = Map<String, String>.from(_selectedValueIds)
      ..[optionId] = optionValueId;
    return detail.variants.any((variant) =>
        variant.isSelectable &&
        !variant.isOutOfStock &&
        candidate.values.every(variant.selectedOptionValueIds.contains));
  }

  bool _isLegacyOptionSelectable(
      PosCatalogProductDetail detail, String groupName, String option) {
    final candidate = Map<String, String>.from(_selectedAttributes)
      ..[groupName] = option;
    return detail.variants.any((variant) =>
        !variant.isOutOfStock &&
        candidate.entries.every((entry) =>
            variant.attributes[entry.key] == null ||
            variant.attributes[entry.key] == entry.value));
  }

  void _selectOptionValue(
      PosCatalogProductDetail detail, String optionId, String optionValueId) {
    setState(() {
      _selectedValueIds[optionId] = optionValueId;
      for (final entry in _selectedValueIds.entries.toList()) {
        final stillCompatible = detail.variants.any((variant) =>
            variant.isSelectable &&
            _selectedValueIds.values
                .every(variant.selectedOptionValueIds.contains));
        if (!stillCompatible && entry.key != optionId) {
          _selectedValueIds.remove(entry.key);
        }
      }
      _selectedAttributes.clear();
      for (final group in detail.variantGroups) {
        final selectedId = _selectedValueIds[group.optionId];
        final selected = group.values
            .where((value) => value.optionValueId == selectedId)
            .firstOrNull;
        if (selected != null) {
          _selectedAttributes[group.name] = selected.displayName;
        }
      }
      _availabilityMessage = null;
    });
  }

  Future<void> _submit(
    PosCatalogProductDetail detail,
    PosCatalogVariant variant,
    List<PosProductRecommendation> recommendations,
  ) async {
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });
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

    final normalizedNote = _noteController.text.trim();
    final mainClientLineId = _newUuidV4();
    final cartProduct = toCartProduct(
      summary: detail.summary,
      variant: variant,
      quantity: _quantity,
      lineNote: normalizedNote.isEmpty ? null : normalizedNote,
      clientLineId: mainClientLineId,
    );
    final notifier = ref.read(posNewSaleCartProvider.notifier);

    final selectedRecommendations = recommendations
        .where(
            (item) => _selectedRecommendationIds.contains(item.relationshipId))
        .toList(growable: false);
    final recommendationClientLineIds = <String, String>{
      for (final recommendation in selectedRecommendations)
        recommendation.relationshipId: _newUuidV4(),
    };
    final requestLines = <PosCheckoutLineRequest>[
      PosCheckoutLineRequest(
        variantId: variant.variantId,
        quantity: _quantity,
        clientLineId: mainClientLineId,
        uomId: variant.salesUomId,
        lineNote: normalizedNote.isEmpty ? null : normalizedNote,
        source: 'product_popup',
      ),
      for (final recommendation in selectedRecommendations)
        PosCheckoutLineRequest(
          variantId: recommendation.variantId!,
          quantity: 1,
          clientLineId:
              recommendationClientLineIds[recommendation.relationshipId],
          source: 'recommendation',
          recommendationParentProductId: detail.summary.productId,
          recommendationRelationshipId: recommendation.relationshipId,
        ),
    ];

    try {
      final device = ref.read(deviceActivationProvider).deviceContext;
      if (device == null) {
        throw StateError('An activated device is required.');
      }
      if (variant.salesUomId.trim().isEmpty ||
          detail.variantGroups.any((group) => group.optionId.trim().isEmpty)) {
        throw StateError(
          'This product is missing required variant metadata. Refresh or contact an administrator.',
        );
      }
      await ref.read(posCheckoutRemoteDatasourceProvider).getCheckoutSummary(
            deviceId: device.deviceId,
            lines: requestLines,
          );
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submissionError = error.toString().replaceFirst('Exception: ', '');
        });
      }
      return;
    }

    if (widget.existingCartItem == null) {
      final originalCart = ref.read(posNewSaleCartProvider);
      final mainResult = notifier.addToCart(cartProduct, quantity: _quantity);
      if (!_isSuccessfulCartMutation(mainResult)) {
        notifier.restore(originalCart);
        _showCartMutationFailure(mainResult);
        return;
      }
      for (final recommendation in selectedRecommendations) {
        final recommendationResult = notifier.addToCart(PosNewSaleProduct(
          id: recommendation.variantId!,
          productId: recommendation.productId,
          variantId: recommendation.variantId,
          name: recommendation.productName,
          category: recommendation.categoryName?.trim() ?? '',
          price: recommendation.price!.toInt(),
          authoritativePrice: recommendation.price,
          imageUrl: recommendation.imageUrl,
          stockStatus: recommendation.stockStatus,
          stockLabel: recommendation.stockStatus,
          clientLineId:
              recommendationClientLineIds[recommendation.relationshipId],
          source: 'recommendation',
          recommendationParentProductId: detail.summary.productId,
          recommendationRelationshipId: recommendation.relationshipId,
        ));
        if (!_isSuccessfulCartMutation(recommendationResult)) {
          notifier.restore(originalCart);
          _showCartMutationFailure(recommendationResult);
          return;
        }
      }
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

  bool _isSuccessfulCartMutation(PosCartMutationResult result) =>
      result == PosCartMutationResult.added ||
      result == PosCartMutationResult.quantityIncreased;

  void _showCartMutationFailure(PosCartMutationResult result) {
    if (!mounted) return;
    final message = switch (result) {
      PosCartMutationResult.invalidQuantity => 'Enter a valid quantity.',
      PosCartMutationResult.outOfStock => 'This product is out of stock.',
      PosCartMutationResult.insufficientStock =>
        'The requested quantity is no longer available.',
      PosCartMutationResult.productUnavailable =>
        'This product is currently unavailable.',
      PosCartMutationResult.variantUnavailable =>
        'The selected variant is currently unavailable.',
      PosCartMutationResult.priceUnavailable =>
        'A valid price is not available for this product.',
      PosCartMutationResult.discountMustBeRemoved =>
        'Remove the active discount before changing the cart.',
      PosCartMutationResult.added ||
      PosCartMutationResult.quantityIncreased =>
        '',
    };
    setState(() {
      _isSubmitting = false;
      _submissionError = message;
    });
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final bool canDecrease, canIncrease;
  final VoidCallback onDecrease, onIncrease;

  @override
  Widget build(BuildContext context) {
    Widget segment(Widget child, VoidCallback? onPressed) => SizedBox(
          width: 48,
          height: 44,
          child: InkWell(
            onTap: onPressed,
            child: Center(child: child),
          ),
        );

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const Key('compact-quantity-stepper'),
        decoration: BoxDecoration(
          color: _PopupTokens.controlBackground,
          border: Border.all(color: _PopupTokens.border),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          segment(
            Icon(Icons.remove_rounded,
                color: canDecrease
                    ? _PopupTokens.navy
                    : _PopupTokens.secondaryText.withValues(alpha: 0.4)),
            canDecrease ? onDecrease : null,
          ),
          Container(
            width: 58,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border.symmetric(
                vertical: BorderSide(color: _PopupTokens.border),
              ),
            ),
            child: Text('$quantity',
                style: const TextStyle(
                    color: _PopupTokens.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
          segment(
            Icon(Icons.add_rounded,
                color: canIncrease
                    ? _PopupTokens.primary
                    : _PopupTokens.secondaryText.withValues(alpha: 0.4)),
            canIncrease ? onIncrease : null,
          ),
        ]),
      ),
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  const _RecommendationRow({
    required this.recommendation,
    required this.selected,
    required this.displayCurrency,
    required this.onChanged,
  });

  final PosProductRecommendation recommendation;
  final bool selected;
  final String displayCurrency;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final imageUrl = recommendation.imageUrl?.trim();
    final subtitle = recommendation.requiresConfiguration
        ? 'Variant configuration required'
        : recommendation.price == null || displayCurrency.isEmpty
            ? 'Price unavailable'
            : _formatMoney(recommendation.price!, displayCurrency);
    return SizedBox(
      key: Key('recommendation-${recommendation.relationshipId}'),
      height: 86,
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _PopupTokens.border),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: AppCachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            memCacheWidth: 104,
            errorWidget: const Icon(
              Icons.inventory_2_outlined,
              color: _PopupTokens.secondaryText,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(recommendation.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _PopupTokens.navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: recommendation.requiresConfiguration
                          ? _PopupTokens.secondaryText
                          : _PopupTokens.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Checkbox(
          value: selected,
          activeColor: _PopupTokens.primary,
          side: const BorderSide(color: _PopupTokens.border, width: 1.5),
          onChanged:
              onChanged == null ? null : (value) => onChanged!(value == true),
        ),
      ]),
    );
  }
}

class _VariantOptionChip extends StatelessWidget {
  const _VariantOptionChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onSelected,
    this.colorHex,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;
  final String? colorHex;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(mainAxisSize: MainAxisSize.min, children: [
        if (_parseColor(colorHex) case final color?) ...[
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: TenantAdminColors.border)),
          ),
          const SizedBox(width: TenantAdminSpacing.xs),
        ],
        Text(label),
      ]),
      selected: selected,
      onSelected: enabled ? (_) => onSelected() : null,
      selectedColor: _PopupTokens.primary.withValues(alpha: 0.06),
      backgroundColor: Colors.white,
      disabledColor: _PopupTokens.controlBackground,
      labelStyle: TextStyle(
        color: !enabled
            ? _PopupTokens.secondaryText.withValues(alpha: 0.45)
            : _PopupTokens.navy,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
        side: BorderSide(
          color: selected ? _PopupTokens.primary : _PopupTokens.border,
          width: selected ? 1.5 : 1,
        ),
      ),
    );
  }

  Color? _parseColor(String? value) {
    final raw = value?.replaceFirst('#', '');
    if (raw == null || (raw.length != 6 && raw.length != 8)) return null;
    final parsed = int.tryParse(raw, radix: 16);
    if (parsed == null) return null;
    return Color(raw.length == 6 ? 0xFF000000 | parsed : parsed);
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
      'InStock' => ('In Stock', _PopupTokens.success),
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
