import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/network/media_url_resolver.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/staged_product_image.dart';

import '../product_images/product_image_guidelines_card.dart';

class ProductImageUploadCard extends ConsumerStatefulWidget {
  const ProductImageUploadCard({
    super.key,
    required this.images,
    required this.onPickImage,
    required this.onSetPrimary,
    required this.onDelete,
  });

  final List<ProductWizardImageItem> images;
  final Future<void> Function({VoidCallback? onStartUpload}) onPickImage;
  final ValueChanged<String> onSetPrimary;
  final ValueChanged<String> onDelete;

  @override
  ConsumerState<ProductImageUploadCard> createState() =>
      _ProductImageUploadCardState();
}

class _ProductImageUploadCardState
    extends ConsumerState<ProductImageUploadCard> {
  bool _isUploading = false;

  String _resolveImageUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final baseUrl = ref.watch(appDioProvider).options.baseUrl;
    return MediaUrlResolver.resolve(trimmed, apiBaseUrl: baseUrl) ?? trimmed;
  }

  Future<void> _handlePickImage() async {
    if (_isUploading) return;
    try {
      await widget.onPickImage(
        onStartUpload: () {
          if (mounted) {
            setState(() => _isUploading = true);
          }
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.images.length;
    final isFull = count >= 10;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text(
                    'Product Images',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: TenantAdminColors.bodyText,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Up to 10 images',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TenantAdminColors.mutedText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),

          // Upload Button Box (File Browse only)
          if (!isFull)
            InkWell(
              onTap: _isUploading ? null : _handlePickImage,
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: TenantAdminSpacing.xl,
                  horizontal: TenantAdminSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0x1AFF9800),
                        shape: BoxShape.circle,
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: TenantAdminColors.posHomeAccentOrange,
                              ),
                            )
                          : const Icon(
                              Icons.cloud_upload_outlined,
                              color: Color(0xFF64748B),
                              size: 32,
                            ),
                    ),
                    const SizedBox(height: TenantAdminSpacing.sm),
                    const Text(
                      'Drag and drop images here\nor tap to browse',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'JPG, PNG up to 5MB each',
                      style: TextStyle(
                        fontSize: 11,
                        color: TenantAdminColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (widget.images.isNotEmpty || _isUploading) ...[
            const SizedBox(height: TenantAdminSpacing.lg),

            // Inline Grid of Uploaded Images (Direct management right here)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: widget.images.length + (_isUploading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isUploading && index == widget.images.length) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                      border: Border.all(
                        color: TenantAdminColors.posHomeAccentOrange,
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.image_outlined,
                          color: TenantAdminColors.mutedText,
                          size: 32,
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final img = widget.images[index];
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                    border: Border.all(
                      color: img.isPrimary
                          ? TenantAdminColors.posHomeAccentOrange
                          : const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(TenantAdminRadius.sm - 1.5),
                          child: img.bytes != null && img.bytes!.isNotEmpty
                              ? Image.memory(
                                  img.bytes!,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                )
                              : (img.imageUrl.isNotEmpty
                                  ? Image.network(
                                      _resolveImageUrl(img.imageUrl),
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: const Color(0xFFF1F5F9),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) => const Center(
                                        child: Icon(Icons.broken_image_outlined,
                                            color: Colors.grey),
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(Icons.image_outlined,
                                          color: Colors.grey),
                                    )),
                        ),
                      ),
                      if (img.isPrimary)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: TenantAdminColors.posHomeAccentOrange,
                              borderRadius: BorderRadius.circular(12),
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
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 16),
                            padding: EdgeInsets.zero,
                            onSelected: (value) {
                              if (value == 'delete') {
                                widget.onDelete(img.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete Image', style: TextStyle(color: TenantAdminColors.danger)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: InkWell(
                          onTap: () {
                            if (!img.isPrimary) {
                              widget.onSetPrimary(img.id);
                            }
                          },
                          child: Icon(
                            img.isPrimary
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: img.isPrimary
                                ? TenantAdminColors.posHomeAccentOrange
                                : const Color(0xFFCBD5E1),
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: TenantAdminSpacing.lg),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The first image is used as the default primary image unless you change it.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
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
