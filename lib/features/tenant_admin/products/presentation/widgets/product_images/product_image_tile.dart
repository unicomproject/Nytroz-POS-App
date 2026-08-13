import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/staged_product_image.dart';

class ProductImageTile extends StatelessWidget {
  const ProductImageTile({
    super.key,
    required this.item,
    required this.onSetPrimary,
    required this.onDelete,
  });

  final ProductWizardImageItem item;
  final VoidCallback onSetPrimary;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        border: Border.all(
          color: item.isPrimary
              ? TenantAdminColors.posHomeAccentOrange
              : TenantAdminColors.border,
          width: item.isPrimary ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          // Image Preview
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm - 1),
              child: item.bytes != null && item.bytes!.isNotEmpty
                  ? Image.memory(
                      item.bytes!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  : (item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: Colors.grey),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.image_outlined, color: Colors.grey),
                        )),
            ),
          ),

          // Primary Badge or Set Primary Action
          if (item.isPrimary)
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: TenantAdminColors.posHomeAccentOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Primary',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            Positioned(
              bottom: 4,
              left: 4,
              child: InkWell(
                onTap: onSetPrimary,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Set Primary',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

          // Delete Action Overlay
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
