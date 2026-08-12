import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ProductImageGuidelinesCard extends StatelessWidget {
  const ProductImageGuidelinesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Image Guidelines',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: 8),
          _buildGuidelineRow('Front image is recommended as primary.'),
          _buildGuidelineRow('Use high quality images for better visibility.'),
          _buildGuidelineRow('Supported formats: PNG, JPG, WEBP, GIF, etc.'),
          _buildGuidelineRow('Max file size: 5MB per image.'),
        ],
      ),
    );
  }

  Widget _buildGuidelineRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 14,
            color: TenantAdminColors.success,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: TenantAdminColors.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
