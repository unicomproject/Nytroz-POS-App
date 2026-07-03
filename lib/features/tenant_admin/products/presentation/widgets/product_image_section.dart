import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import 'product_section_card.dart';

class ProductImageSection extends StatefulWidget {
  const ProductImageSection({
    super.key,
    required this.enabled,
    required this.onImageChanged,
  });

  final bool enabled;
  final ValueChanged<ProductImageDraft?> onImageChanged;

  @override
  State<ProductImageSection> createState() => _ProductImageSectionState();
}

class ProductImageDraft {
  const ProductImageDraft({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}

class _ProductImageSectionState extends State<ProductImageSection> {
  ProductImageDraft? _draft;
  String? _error;

  static const _maxBytes = 2 * 1024 * 1024;

  Future<void> _pickImage() async {
    if (!widget.enabled) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    final bytes = file.bytes;
    final name = file.name.toLowerCase();

    if (bytes == null) {
      setState(() => _error = 'Unable to read the selected image.');
      return;
    }

    if (bytes.length > _maxBytes) {
      setState(() => _error = 'Image must be 2MB or smaller.');
      return;
    }

    if (!name.endsWith('.jpg') &&
        !name.endsWith('.jpeg') &&
        !name.endsWith('.png')) {
      setState(() => _error = 'Only JPG and PNG images are supported.');
      return;
    }

    final draft = ProductImageDraft(bytes: bytes, fileName: file.name);
    setState(() {
      _draft = draft;
      _error = null;
    });
    widget.onImageChanged(draft);
  }

  void _removeImage() {
    setState(() {
      _draft = null;
      _error = null;
    });
    widget.onImageChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return ProductSectionCard(
      title: 'Product Image',
      subtitle: 'Optional',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: widget.enabled ? _pickImage : null,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 220),
              padding: const EdgeInsets.all(TenantAdminSpacing.lg),
              decoration: BoxDecoration(
                color: TenantAdminColors.background,
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                border: Border.all(
                  color: _error != null
                      ? TenantAdminColors.danger
                      : TenantAdminColors.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_draft == null)
                    _UploadPlaceholder(enabled: widget.enabled)
                  else
                    _ImagePreview(
                      draft: _draft!,
                      onRemove: widget.enabled ? _removeImage : null,
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: TenantAdminSpacing.sm),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: TenantAdminColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (widget.enabled) ...[
            const SizedBox(height: TenantAdminSpacing.sm),
            Align(
              alignment: Alignment.center,
              child: TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: const Text('Browse image'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 40,
          color: enabled ? TenantAdminColors.primary : TenantAdminColors.offline,
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        Text(
          'Drag & drop image here or click to browse',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: enabled
                ? TenantAdminColors.bodyText
                : TenantAdminColors.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Text(
          'JPG, PNG up to 2MB',
          style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.draft,
    this.onRemove,
  });

  final ProductImageDraft draft;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          child: Image.memory(
            draft.bytes,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                draft.fileName,
                style: const TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onRemove != null)
              TextButton(onPressed: onRemove, child: const Text('Remove')),
          ],
        ),
      ],
    );
  }
}
