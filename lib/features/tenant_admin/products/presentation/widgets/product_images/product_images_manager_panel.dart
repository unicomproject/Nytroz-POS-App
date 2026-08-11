import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/staged_product_image.dart';

import 'product_image_guidelines_card.dart';
import 'product_image_tile.dart';
import 'product_upload_more_tile.dart';

class ProductImagesManagerPanel extends StatelessWidget {
  const ProductImagesManagerPanel({
    super.key,
    required this.images,
    required this.onClose,
    required this.onPickImage,
    required this.onSetPrimary,
    required this.onDelete,
    required this.onReorder,
    required this.onReplaceImages,
  });

  final List<ProductWizardImageItem> images;
  final VoidCallback onClose;
  final VoidCallback onPickImage;
  final ValueChanged<String> onSetPrimary;
  final ValueChanged<String> onDelete;
  final Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onReplaceImages;

  @override
  Widget build(BuildContext context) {
    final count = images.length;

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.lg,
              vertical: TenantAdminSpacing.md,
            ),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: TenantAdminColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Product Images',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: TenantAdminColors.bodyText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count / 10',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: TenantAdminColors.bodyText,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Helper Instruction
                const Row(
                  children: [
                    Icon(Icons.photo_library_outlined,
                        size: 16, color: TenantAdminColors.mutedText),
                    SizedBox(width: 4),
                    Text(
                      'Manage product gallery images',
                      style: TextStyle(
                        fontSize: 12,
                        color: TenantAdminColors.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TenantAdminSpacing.md),

                // Image Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: count < 10 ? count + 1 : 10,
                  itemBuilder: (context, index) {
                    if (index < count) {
                      final item = images[index];
                      return ProductImageTile(
                        item: item,
                        onSetPrimary: () => onSetPrimary(item.id),
                        onDelete: () => onDelete(item.id),
                      );
                    } else {
                      return ProductUploadMoreTile(
                        onTap: onPickImage,
                        disabled: count >= 10,
                      );
                    }
                  },
                ),

                const SizedBox(height: TenantAdminSpacing.lg),

                // Guidelines Card
                const ProductImageGuidelinesCard(),

                const SizedBox(height: TenantAdminSpacing.lg),

                // Bottom Action: Replace Images (per screenshot 2 placement)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onReplaceImages,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.sm),
                      ),
                    ),
                    icon: const Icon(Icons.sync_alt, size: 18),
                    label: const Text(
                      'Replace Images',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
