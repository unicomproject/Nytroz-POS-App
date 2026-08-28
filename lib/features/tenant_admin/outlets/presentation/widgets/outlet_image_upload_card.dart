import 'package:flutter/material.dart';

import '../../../presentation/widgets/tenant_admin_single_image_upload_card.dart';
import '../providers/outlet_image_upload_provider.dart';

class OutletImageUploadCard extends StatelessWidget {
  const OutletImageUploadCard({
    super.key,
    required this.state,
    required this.onChoose,
    required this.onReplace,
    required this.onRemove,
    required this.onRetry,
  });

  final OutletImageUploadState state;
  final VoidCallback onChoose;
  final VoidCallback onReplace;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isBusy = state.status == OutletImageUploadStatus.uploading ||
        state.status == OutletImageUploadStatus.deleting;
    final hasImage = state.previewBytes != null ||
        state.remoteImageUrl?.trim().isNotEmpty == true;

    return TenantAdminSingleImageUploadCard(
      title: 'Outlet Image',
      description: 'Use an image that makes this outlet easy to identify.',
      fileName: state.fileName,
      preview: hasImage ? _buildPreview() : null,
      isBusy: isBusy,
      progress: state.status == OutletImageUploadStatus.uploading
          ? state.progress
          : null,
      errorText: state.errorMessage,
      onChooseImage: hasImage ? onReplace : onChoose,
      onRemoveImage: hasImage ? onRemove : null,
      onRetry: state.errorMessage == null ? null : onRetry,
    );
  }

  Widget _buildPreview() {
    if (state.previewBytes != null) {
      return Image.memory(state.previewBytes!, fit: BoxFit.cover);
    }

    final imageUrl = state.remoteImageUrl;
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallbackPreview(),
      );
    }

    return _fallbackPreview();
  }

  Widget _fallbackPreview() => Container(
        color: const Color(0xFFFFF3EA),
        child: const Icon(
          Icons.storefront_outlined,
          color: Color(0xFFFF6A00),
        ),
      );
}
