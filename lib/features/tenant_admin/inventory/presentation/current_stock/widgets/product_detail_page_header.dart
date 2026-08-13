import 'package:flutter/material.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';

/// In-page header for the Product Stock Detail screen.
///
/// Layout (matches the Figma mockup):
/// ```
/// Product Stock Detail
/// Detailed stock information and recent movements for this variant.
/// ──────────────────────────────────────────────────────────────────
/// ```
class ProductDetailPageHeader extends StatelessWidget {
  const ProductDetailPageHeader({
    super.key,
    required this.variantId,
  });

  final String variantId;

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Row 2: Page title + subtitle ──
        Text(
          'Product Stock Detail',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: TenantAdminColors.bodyText,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Detailed stock information and recent movements for this variant.',
          style: TextStyle(fontSize: 13, color: TenantAdminColors.mutedText),
        ),
        SizedBox(height: TenantAdminSpacing.lg),
        Divider(height: 1, color: TenantAdminColors.border),
        SizedBox(height: TenantAdminSpacing.lg),
      ],
    );
  }
}
