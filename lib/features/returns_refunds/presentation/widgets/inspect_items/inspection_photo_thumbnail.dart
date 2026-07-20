import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_inspection.dart';

class InspectionPhotoThumbnail extends StatelessWidget {
  const InspectionPhotoThumbnail({
    super.key,
    required this.item,
    required this.image,
    required this.onRemove,
    this.onRetry,
  });

  final InspectionMediaItem item;
  final Widget? image;
  final VoidCallback onRemove;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: TenantAdminColors.background,
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            border: Border.all(color: TenantAdminColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: _content(),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _content() {
    if (item.uploadStatus == InspectionMediaUploadStatus.uploading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (item.uploadStatus == InspectionMediaUploadStatus.failed) {
      return InkWell(
        onTap: onRetry,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: TenantAdminColors.danger),
              if (onRetry != null)
                const Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 10,
                    color: TenantAdminColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (image != null) {
      return image!;
    }

    return const Icon(
      Icons.image_outlined,
      color: TenantAdminColors.mutedText,
    );
  }
}
