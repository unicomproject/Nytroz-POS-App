import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosProductImage extends StatelessWidget {
  const PosProductImage({
    super.key,
    required this.imageUrl,
    required this.category,
    this.width,
    this.height,
    this.expand = false,
    this.borderRadius = TenantAdminRadius.sm,
  });

  final String? imageUrl;
  final String category;
  final double? width;
  final double? height;
  final bool expand;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final visual = posProductVisualForCategory(category);
    final url = imageUrl?.trim();

    if (url == null || url.isEmpty) {
      return _buildFallback(visual);
    }

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => PosProductImageFallback(
          category: category,
          width: width,
          height: height,
          borderRadius: borderRadius,
        ),
      ),
    );

    if (expand) {
      return Expanded(child: image);
    }

    return SizedBox(
      width: width,
      height: height,
      child: image,
    );
  }

  Widget _buildFallback(PosProductVisual visual) {
    final fallback = PosProductImageFallback(
      category: category,
      width: width,
      height: height,
      borderRadius: borderRadius,
    );

    if (expand) {
      return Expanded(child: fallback);
    }

    return fallback;
  }
}

class PosProductImageFallback extends StatelessWidget {
  const PosProductImageFallback({
    super.key,
    required this.category,
    this.width,
    this.height,
    this.borderRadius = TenantAdminRadius.sm,
  });

  final String category;
  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final visual = posProductVisualForCategory(category);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: visual.backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            shape: BoxShape.circle,
          ),
          child: Icon(
            visual.icon,
            color: visual.iconColor,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class PosProductVisual {
  const PosProductVisual({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
}

PosProductVisual posProductVisualForCategory(String category) {
  return switch (category.toLowerCase()) {
    'tickets' || 'ticket' => const PosProductVisual(
        icon: Icons.confirmation_number_outlined,
        backgroundColor: Color(0xFFEFF6FF),
        iconColor: TenantAdminColors.info,
      ),
    'services' || 'service' => const PosProductVisual(
        icon: Icons.room_service_outlined,
        backgroundColor: Color(0xFFF5F3FF),
        iconColor: TenantAdminColors.primary,
      ),
    'memberships' || 'membership' => const PosProductVisual(
        icon: Icons.card_membership_outlined,
        backgroundColor: Color(0xFFF0FDF4),
        iconColor: TenantAdminColors.success,
      ),
    'food' => const PosProductVisual(
        icon: Icons.restaurant_outlined,
        backgroundColor: Color(0xFFFFF7ED),
        iconColor: TenantAdminColors.warning,
      ),
    'drinks' || 'drink' => const PosProductVisual(
        icon: Icons.local_cafe_outlined,
        backgroundColor: Color(0xFFECFEFF),
        iconColor: Color(0xFF0891B2),
      ),
    'apparel' => const PosProductVisual(
        icon: Icons.checkroom_outlined,
        backgroundColor: Color(0xFFEFF6FF),
        iconColor: TenantAdminColors.info,
      ),
    'accessories' => const PosProductVisual(
        icon: Icons.watch_outlined,
        backgroundColor: Color(0xFFFDF2F8),
        iconColor: Color(0xFFDB2777),
      ),
    'retail' => const PosProductVisual(
        icon: Icons.storefront_outlined,
        backgroundColor: Color(0xFFFEF9C3),
        iconColor: Color(0xFFCA8A04),
      ),
    _ => const PosProductVisual(
        icon: Icons.inventory_2_outlined,
        backgroundColor: TenantAdminColors.background,
        iconColor: TenantAdminColors.mutedText,
      ),
  };
}
