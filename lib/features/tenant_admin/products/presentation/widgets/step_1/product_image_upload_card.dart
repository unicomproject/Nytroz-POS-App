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
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: TenantAdminColors.posHomeAccentOrange,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Product Images',
                    style: TextStyle(
                      fontSize: 16,
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
                  color: count > 0
                      ? const Color(0x1AFF9800)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count / 10',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: count > 0
                        ? TenantAdminColors.posHomeAccentOrange
                        : TenantAdminColors.mutedText,
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
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                  border: Border.all(
                    color: const Color(0x80FF9800),
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
                              color: TenantAdminColors.posHomeAccentOrange,
                              size: 32,
                            ),
                    ),
                    const SizedBox(height: TenantAdminSpacing.sm),
                    Text(
                      count == 0
                          ? 'Click to Upload Product Images'
                          : 'Click to Add More Product Images ($count/10)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: TenantAdminColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Browse files to select • Up to 10 images allowed',
                      style: TextStyle(
                        fontSize: 12,
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
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final img in widget.images)
                  Container(
                    width: 105,
                    height: 105,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                      border: Border.all(
                        color: img.isPrimary
                            ? TenantAdminColors.posHomeAccentOrange
                            : TenantAdminColors.border,
                        width: img.isPrimary ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Image Preview with Quick WhatsApp Style Loader
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(TenantAdminRadius.sm - 1),
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
                                            child: Center(
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                decoration: const BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Center(
                                                  child: SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2.2,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
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

                        // Delete Icon (Top Right)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => widget.onDelete(img.id),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0x99000000),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),

                        // Primary Badge or Set Primary Action Button (Bottom Left)
                        if (img.isPrimary)
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: TenantAdminColors.posHomeAccentOrange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Primary',
                                style: TextStyle(
                                  fontSize: 9,
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
                              onTap: () => widget.onSetPrimary(img.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Set Primary',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // WhatsApp-Style Uploading Tile (Appears instantly on Open/Drop)
                if (_isUploading)
                  Container(
                    width: 105,
                    height: 105,
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
                        // Dark translucent circular overlay with white spinner (WhatsApp style)
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
                  ),
              ],
            ),
          ],

          const SizedBox(height: TenantAdminSpacing.lg),
          // Direct Embedded Guidelines (No popup required)
          const ProductImageGuidelinesCard(),
        ],
      ),
    );
  }
}
