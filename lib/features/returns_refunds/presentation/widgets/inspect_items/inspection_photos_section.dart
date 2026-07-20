import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_inspection.dart';
import '../../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../providers/return_search_provider.dart';
import 'add_inspection_photo_button.dart';
import 'inspection_photo_thumbnail.dart';

class InspectionPhotosSection extends ConsumerWidget {
  const InspectionPhotosSection({
    super.key,
    required this.media,
    required this.maxPhotos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onRetryPhoto,
  });

  final List<InspectionMediaItem> media;
  final int maxPhotos;
  final VoidCallback onAddPhoto;
  final ValueChanged<String> onRemovePhoto;
  final ValueChanged<String> onRetryPhoto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Wrap(
          spacing: TenantAdminSpacing.sm,
          runSpacing: TenantAdminSpacing.sm,
          children: [
            for (final item in media)
              InspectionPhotoThumbnail(
                item: item,
                image: _imageForItem(item),
                onRemove: () => onRemovePhoto(item.mediaId),
                onRetry: item.uploadStatus == InspectionMediaUploadStatus.failed
                    ? () => onRetryPhoto(item.mediaId)
                    : null,
              ),
            if (media.length < maxPhotos)
              AddInspectionPhotoButton(onPressed: onAddPhoto),
          ],
        ),
        if (media.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: TenantAdminSpacing.xs),
            child: Text(
              'No photos added',
              style: TenantAdminTextStyles.muted(context),
            ),
          ),
      ],
    );
  }

  Widget? _imageForItem(InspectionMediaItem item) {
    final localPath = item.localPath;
    if (localPath != null &&
        localPath.isNotEmpty &&
        File(localPath).existsSync()) {
      return Image.file(File(localPath), fit: BoxFit.cover);
    }
    if (item.mediaId.isNotEmpty && !item.mediaId.startsWith('pending-')) {
      return _AuthenticatedInspectionMediaPreview(mediaId: item.mediaId);
    }
    return null;
  }
}

class _AuthenticatedInspectionMediaPreview extends ConsumerStatefulWidget {
  const _AuthenticatedInspectionMediaPreview({required this.mediaId});

  final String mediaId;

  @override
  ConsumerState<_AuthenticatedInspectionMediaPreview> createState() =>
      _AuthenticatedInspectionMediaPreviewState();
}

class _AuthenticatedInspectionMediaPreviewState
    extends ConsumerState<_AuthenticatedInspectionMediaPreview> {
  Future<Uint8List>? _imageBytes;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(
      covariant _AuthenticatedInspectionMediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId) {
      _loadImage();
    }
  }

  void _loadImage() {
    final deviceId = ref.read(deviceActivationProvider).deviceContext?.deviceId;
    _imageBytes = deviceId == null
        ? Future<Uint8List>.error(StateError('Device context is unavailable.'))
        : ref
            .read(returnsRefundRemoteDatasourceProvider)
            .fetchInspectionMediaBytes(
              deviceId: deviceId,
              mediaId: widget.mediaId,
            )
            .then(Uint8List.fromList);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _imageBytes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Icon(
            Icons.broken_image_outlined,
            color: TenantAdminColors.danger,
          );
        }
        return Image.memory(snapshot.data!, fit: BoxFit.cover);
      },
    );
  }
}
