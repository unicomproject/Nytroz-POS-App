import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosProductCard extends StatelessWidget {
  const PosProductCard({
    required this.product,
    required this.onTap,
    super.key,
  });

  final PosCatalogProductSummary product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _ProductVisual.forCategory(product.categoryName);

    return Semantics(
      label: 'Add product to cart',
      button: true,
      enabled: onTap != null,
      container: true,
      child: Material(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              border: Border.all(color: TenantAdminColors.border, width: 1.5),
              boxShadow: TenantAdminShadows.card,
            ),
            child: Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _ProductImage(product: product, visual: visual),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  Text(
                    product.name,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: TenantAdminColors.bodyText,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  _PriceDisplay(product: product),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceDisplay extends StatelessWidget {
  const _PriceDisplay({required this.product});

  final PosCatalogProductSummary product;

  @override
  Widget build(BuildContext context) {
    if (!product.hasOffer ||
        product.requiresCartValidation ||
        product.offerPrice == null) {
      return Text(
        formatLkr(product.basePrice),
        maxLines: 1,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: TenantAdminColors.posNewSaleAccent,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text(
          formatLkr(product.basePrice),
          maxLines: 1,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TenantAdminColors.mutedText,
                decoration: TextDecoration.lineThrough,
                fontSize: 12,
              ),
        ),
        Text(
          formatLkr(product.offerPrice!),
          maxLines: 1,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
        ),
      ],
    );
  }
}

class _OfferBadge extends StatelessWidget {
  const _OfferBadge({required this.label, required this.isConditional});

  final String label;
  final bool isConditional;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isConditional ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ApprovalBadge extends StatelessWidget {
  const _ApprovalBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.security_rounded,
            color: Colors.white,
            size: 10,
          ),
          SizedBox(width: 2),
          Text(
            'REQ APP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product, required this.visual});

  final PosCatalogProductSummary product;
  final _ProductVisual visual;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl?.trim();

    final imageWidget = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: visual.backgroundColor,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      clipBehavior: Clip.hardEdge,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) =>
                  _ProductImageFallback(visual: visual),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            )
          : _ProductImageFallback(visual: visual),
    );

    if (product.hasOffer) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          imageWidget,
          if (product.discountLabel != null)
            Positioned(
              top: 6,
              right: 6,
              child: _OfferBadge(
                label: product.discountLabel!,
                isConditional: product.requiresCartValidation,
              ),
            ),
          if (product.requiresManagerApproval)
            const Positioned(
              top: 6,
              left: 6,
              child: _ApprovalBadge(),
            ),
        ],
      );
    }

    return imageWidget;
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback({required this.visual});

  static const _dummyImageAsset = 'assets/images/product_dummy.png';

  final _ProductVisual visual;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _dummyImageAsset,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: visual.backgroundColor,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
          child: Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                visual.icon,
                color: visual.iconColor,
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductVisual {
  const _ProductVisual({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  static _ProductVisual forCategory(String category) {
    return switch (category.toLowerCase()) {
      'tickets' || 'ticket' => const _ProductVisual(
          icon: Icons.confirmation_number_outlined,
          backgroundColor: Color(0xFFEFF6FF),
          iconColor: TenantAdminColors.info,
        ),
      'services' || 'service' => const _ProductVisual(
          icon: Icons.room_service_outlined,
          backgroundColor: Color(0xFFF0FDF4),
          iconColor: TenantAdminColors.success,
        ),
      'retail' => const _ProductVisual(
          icon: Icons.shopping_bag_outlined,
          backgroundColor: Color(0xFFFFF7ED),
          iconColor: TenantAdminColors.warning,
        ),
      'food' => const _ProductVisual(
          icon: Icons.restaurant_outlined,
          backgroundColor: Color(0xFFFEF2F2),
          iconColor: TenantAdminColors.danger,
        ),
      'drinks' || 'drink' => const _ProductVisual(
          icon: Icons.local_cafe_outlined,
          backgroundColor: Color(0xFFFFF7ED),
          iconColor: TenantAdminColors.warning,
        ),
      'memberships' || 'membership' => const _ProductVisual(
          icon: Icons.workspace_premium_outlined,
          backgroundColor: Color(0xFFF5F3FF),
          iconColor: TenantAdminColors.pending,
        ),
      'apparel' => const _ProductVisual(
          icon: Icons.checkroom_outlined,
          backgroundColor: Color(0xFFEFF6FF),
          iconColor: TenantAdminColors.info,
        ),
      'footwear' => const _ProductVisual(
          icon: Icons.hiking_outlined,
          backgroundColor: Color(0xFFF5F3FF),
          iconColor: TenantAdminColors.pending,
        ),
      'sports' => const _ProductVisual(
          icon: Icons.sports_soccer_outlined,
          backgroundColor: Color(0xFFEFF6FF),
          iconColor: TenantAdminColors.info,
        ),
      'accessories' => const _ProductVisual(
          icon: Icons.watch_outlined,
          backgroundColor: Color(0xFFF0FDF4),
          iconColor: TenantAdminColors.success,
        ),
      _ => const _ProductVisual(
          icon: Icons.inventory_2_outlined,
          backgroundColor: TenantAdminColors.background,
          iconColor: TenantAdminColors.mutedText,
        ),
    };
  }
}
