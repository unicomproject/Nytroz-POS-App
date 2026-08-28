import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

class TenantAdminSingleImageUploadCard extends StatelessWidget {
  const TenantAdminSingleImageUploadCard({
    super.key,
    required this.title,
    required this.description,
    required this.onChooseImage,
    this.fileName,
    this.preview,
    this.onRemoveImage,
    this.onRetry,
    this.isBusy = false,
    this.progress,
    this.errorText,
    this.enabled = true,
  });

  final String title;
  final String description;
  final String? fileName;
  final Widget? preview;
  final VoidCallback onChooseImage;
  final VoidCallback? onRemoveImage;
  final VoidCallback? onRetry;
  final bool isBusy;
  final double? progress;
  final String? errorText;
  final bool enabled;

  bool get _hasImage =>
      preview != null || (fileName != null && fileName!.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final canChoose = enabled && !isBusy;
    final canRemove = canChoose && _hasImage && onRemoveImage != null;
    final count = _hasImage ? 1 : 0;

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.add_photo_alternate_outlined,
                color: TenantAdminColors.primary,
                size: 22,
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
              ),
              _CountBadge(count: count),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          if (_hasImage)
            _SelectedImage(
              preview: preview,
              fileName: fileName,
              onReplace: canChoose ? onChooseImage : null,
              onRemove: canRemove ? onRemoveImage : null,
            )
          else
            _UploadDropZone(
              title: 'Click to Upload $title',
              enabled: canChoose,
              isBusy: isBusy,
              onTap: onChooseImage,
            ),
          if (isBusy) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            LinearProgressIndicator(
              value: progress,
              color: TenantAdminColors.primary,
              backgroundColor: TenantAdminColors.secondary,
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(
              progress == null
                  ? 'Uploading image...'
                  : 'Uploading image... ${(progress! * 100).round()}%',
              style: TenantAdminTextStyles.muted(context),
            ),
          ],
          if (errorText != null) ...[
            const SizedBox(height: TenantAdminSpacing.sm),
            Text(
              errorText!,
              style: const TextStyle(
                color: TenantAdminColors.danger,
                fontSize: 12,
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: canChoose ? onRetry : null,
                style: TextButton.styleFrom(
                  foregroundColor: TenantAdminColors.info,
                ),
                child: const Text('Retry'),
              ),
          ],
          const SizedBox(height: TenantAdminSpacing.lg),
          _ImageGuidelines(description: description),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.md,
          vertical: TenantAdminSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: count == 0
              ? TenantAdminColors.subtleBackground
              : TenantAdminColors.secondary,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$count / 1',
          style: TextStyle(
            color: count == 0
                ? TenantAdminColors.mutedText
                : TenantAdminColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _UploadDropZone extends StatelessWidget {
  const _UploadDropZone({
    required this.title,
    required this.enabled,
    required this.isBusy,
    required this.onTap,
  });

  final String title;
  final bool enabled;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.lg,
            vertical: TenantAdminSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: TenantAdminColors.subtleBackground,
            border: Border.all(
              color: TenantAdminColors.primary.withValues(alpha: 0.55),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(TenantAdminSpacing.md),
                decoration: const BoxDecoration(
                  color: TenantAdminColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: isBusy
                    ? const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: TenantAdminColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.cloud_upload_outlined,
                        size: 30,
                        color: TenantAdminColors.primary,
                      ),
              ),
              const SizedBox(height: TenantAdminSpacing.sm),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: TenantAdminColors.bodyText,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              const Text(
                'Browse files to select • One image allowed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TenantAdminColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
}

class _SelectedImage extends StatelessWidget {
  const _SelectedImage({
    required this.preview,
    required this.fileName,
    required this.onReplace,
    required this.onRemove,
  });

  final Widget? preview;
  final String? fileName;
  final VoidCallback? onReplace;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: TenantAdminColors.subtleBackground,
          border: Border.all(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                child: preview ??
                    Container(
                      color: TenantAdminColors.secondary,
                      child: const Icon(
                        Icons.image_outlined,
                        color: TenantAdminColors.primary,
                      ),
                    ),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: Text(
                fileName?.trim().isNotEmpty == true
                    ? fileName!
                    : 'Image selected',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: onReplace,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Replace'),
                  style: TextButton.styleFrom(
                    foregroundColor: TenantAdminColors.info,
                  ),
                ),
                if (onRemove != null)
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remove'),
                    style: TextButton.styleFrom(
                      foregroundColor: TenantAdminColors.danger,
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
}

class _ImageGuidelines extends StatelessWidget {
  const _ImageGuidelines({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: TenantAdminColors.subtleBackground,
          border: Border.all(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Image Guidelines',
              style: TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            _Guideline(text: description),
            const _Guideline(text: 'Use one clear, high-quality image.'),
            const _Guideline(text: 'Supported formats: JPG, JPEG, PNG.'),
            const _Guideline(text: 'Maximum file size: 2 MB.'),
          ],
        ),
      );
}

class _Guideline extends StatelessWidget {
  const _Guideline({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: TenantAdminSpacing.xs),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 15,
              color: TenantAdminColors.success,
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: TenantAdminColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
}
