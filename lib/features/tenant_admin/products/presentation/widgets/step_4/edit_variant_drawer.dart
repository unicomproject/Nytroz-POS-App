import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/network/media_url_resolver.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

import '../../../domain/entities/add_product_wizard_state.dart';
import '../../../domain/entities/step4_variant_configuration_state.dart';
import '../../controllers/add_product_wizard_controller.dart';

class EditVariantDrawer extends ConsumerStatefulWidget {
  final AddProductWizardState state;
  final AddProductWizardController controller;
  final String variantKey;

  const EditVariantDrawer({
    super.key,
    required this.state,
    required this.controller,
    required this.variantKey,
  });

  @override
  ConsumerState<EditVariantDrawer> createState() => _EditVariantDrawerState();
}

class _EditVariantDrawerState extends ConsumerState<EditVariantDrawer> {
  static const int _maxLabelLength = 100;

  late TextEditingController _labelController;
  late bool _isIncluded;
  String _applyImageTo = 'ONLY_THIS';
  Uint8List? _pickedImageBytes;
  String? _imagePreviewUrl;
  String _pickedFileName = 'variant-image.jpg';
  String _pickedMimeType = 'image/jpeg';
  bool _isSaving = false;

  GeneratedVariantRow get _variant =>
      widget.state.step4State.generatedVariants.firstWhere(
        (v) => v.clientCombinationKey == widget.variantKey,
      );

  @override
  void initState() {
    super.initState();
    final variant = _variant;
    _labelController = TextEditingController(
      text: variant.displayLabel ?? variant.combinationLabel,
    );
    _labelController.addListener(() => setState(() {}));
    _isIncluded = variant.isIncluded;
    _imagePreviewUrl = variant.effectiveImageUrl;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<void> _saveChangesAsync() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final variant = _variant;

      final label = _labelController.text.trim();
      if (label != (variant.displayLabel ?? '').trim()) {
        widget.controller.updateVariantDisplayLabel(widget.variantKey, label);
      }

      if (_isIncluded != variant.isIncluded) {
        widget.controller.toggleVariantInclusion(widget.variantKey, _isIncluded);
      }

      if (_pickedImageBytes != null) {
        final groupValue = _primaryGroupValue;
        final ok = await widget.controller.applyVariantImage(
          variantKey: widget.variantKey,
          bytes: _pickedImageBytes!,
          fileName: _pickedFileName,
          mimeType: _pickedMimeType,
          applyScope: _applyImageTo,
          groupValueId: groupValue?.valueId,
        );
        if (!ok) {
          if (!mounted) return;
          final error = widget.controller.state.pageError;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error ?? 'Failed to apply variant image.')),
          );
          return;
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 90,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;

      var mimeType = file.mimeType ?? '';
      final lower = file.name.toLowerCase();
      if (mimeType.isEmpty || mimeType == 'application/octet-stream') {
        if (lower.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (lower.endsWith('.webp')) {
          mimeType = 'image/webp';
        } else {
          mimeType = 'image/jpeg';
        }
      }

      setState(() {
        _pickedImageBytes = bytes;
        _pickedFileName = file.name;
        _pickedMimeType = mimeType;
        _imagePreviewUrl = null;
      });
    } catch (_) {
      // Ignore picker failures; keep existing preview.
    }
  }

  String? _resolveImageUrl(String? rawUrl) {
    final trimmed = rawUrl?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final baseUrl = ref.read(appDioProvider).options.baseUrl;
    return MediaUrlResolver.resolve(trimmed, apiBaseUrl: baseUrl) ?? trimmed;
  }

  String _attributeNameFor(SelectedOptionValue value) {
    for (final row in widget.state.step4State.attributeRows) {
      if (row.selectedValues.any((v) => v.valueId == value.valueId)) {
        final name = (row.templateName ?? '').trim();
        if (name.isNotEmpty) return name;
      }
    }
    return (value.templateId ?? 'Attribute').trim().isEmpty
        ? 'Attribute'
        : value.templateId!.trim();
  }

  SelectedOptionValue? get _primaryGroupValue {
    final values = _variant.selectedValues;
    if (values.isEmpty) return null;
    for (final value in values) {
      final name = _attributeNameFor(value).toLowerCase();
      if (name.contains('color') ||
          name.contains('colour') ||
          (value.colourHex?.trim().isNotEmpty ?? false)) {
        return value;
      }
    }
    return values.first;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = TenantAdminColors.posHomeAccentOrange;
    final variant = _variant;
    final groupValue = _primaryGroupValue;
    final fallbackProductImage = widget.state.productImages.isEmpty
        ? null
        : widget.state.productImages.firstWhere(
            (image) => image.isPrimary,
            orElse: () => widget.state.productImages.first,
          );
    final resolvedNetworkUrl = _resolveImageUrl(
      _imagePreviewUrl ??
          variant.effectiveImageUrl ??
          fallbackProductImage?.imageUrl,
    );
    final stagedFallbackBytes =
        (_pickedImageBytes == null &&
                resolvedNetworkUrl == null &&
                fallbackProductImage?.bytes != null)
            ? fallbackProductImage!.bytes
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TenantAdminSpacing.lg,
            TenantAdminSpacing.md,
            TenantAdminSpacing.sm,
            TenantAdminSpacing.md,
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Edit Variant',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                color: TenantAdminColors.mutedText,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: TenantAdminColors.border),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Variant Attributes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                Wrap(
                  spacing: TenantAdminSpacing.sm,
                  runSpacing: TenantAdminSpacing.sm,
                  children: variant.selectedValues
                      .map(
                        (value) => _AttributeInfoCard(
                          label: _attributeNameFor(value),
                          value: value,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                const Text(
                  'Display Label',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                TextField(
                  controller: _labelController,
                  maxLength: _maxLabelLength,
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: TenantAdminSpacing.md,
                      vertical: TenantAdminSpacing.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(TenantAdminRadius.sm),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(TenantAdminRadius.sm),
                      borderSide:
                          const BorderSide(color: TenantAdminColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(TenantAdminRadius.sm),
                      borderSide: BorderSide(color: accentColor, width: 1.5),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_labelController.text.characters.length} / $_maxLabelLength',
                    style: const TextStyle(
                      fontSize: 12,
                      color: TenantAdminColors.mutedText,
                    ),
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                const Text(
                  'Variant Image',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                CustomPaint(
                  painter: _DashedBorderPainter(
                    color: TenantAdminColors.border,
                    radius: TenantAdminRadius.md,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(TenantAdminSpacing.lg),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(TenantAdminRadius.sm),
                          child: SizedBox(
                            width: 120,
                            height: 120,
                            child: _buildImagePreview(
                              resolvedNetworkUrl,
                              stagedFallbackBytes,
                            ),
                          ),
                        ),
                        const SizedBox(height: TenantAdminSpacing.md),
                        OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                          label: const Text(
                            'Upload / Replace Image',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: TenantAdminColors.bodyText,
                            side: const BorderSide(
                              color: TenantAdminColors.border,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: TenantAdminSpacing.lg,
                              vertical: TenantAdminSpacing.md,
                            ),
                          ),
                        ),
                        const SizedBox(height: TenantAdminSpacing.xs),
                        const Text(
                          'PNG, JPG or WebP • Max 5MB',
                          style: TextStyle(
                            fontSize: 12,
                            color: TenantAdminColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                const Text(
                  'Apply image to',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ApplyImageOptionCard(
                        selected: _applyImageTo == 'ONLY_THIS',
                        icon: Icons.inventory_2_outlined,
                        title: 'This variant only',
                        subtitle:
                            'Apply image to ${variant.combinationLabel} only',
                        onTap: () =>
                            setState(() => _applyImageTo = 'ONLY_THIS'),
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.sm),
                    Expanded(
                      child: _ApplyImageOptionCard(
                        selected: _applyImageTo == 'ALL_GROUP',
                        icon: Icons.layers_outlined,
                        title: groupValue == null
                            ? 'All group variants'
                            : 'All ${groupValue.valueName} variants',
                        subtitle: groupValue == null
                            ? 'Apply image to matching variants'
                            : 'Apply image to all variants with ${groupValue.valueName} ${_attributeNameFor(groupValue).toLowerCase()}',
                        onTap: () =>
                            setState(() => _applyImageTo = 'ALL_GROUP'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(TenantAdminSpacing.md),
                  decoration: BoxDecoration(
                    color: TenantAdminColors.surface,
                    borderRadius:
                        BorderRadius.circular(TenantAdminRadius.sm),
                    border: Border.all(color: TenantAdminColors.border),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Include in Product',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: TenantAdminColors.bodyText,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'This variant will be available for sale and visible in channels.',
                              style: TextStyle(
                                fontSize: 12,
                                color: TenantAdminColors.mutedText,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: TenantAdminSpacing.md),
                      Switch.adaptive(
                        value: _isIncluded,
                        activeColor: TenantAdminColors.success,
                        onChanged: (val) => setState(() => _isIncluded = val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(TenantAdminSpacing.lg),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: TenantAdminColors.border),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TenantAdminColors.bodyText,
                    side: const BorderSide(color: TenantAdminColors.border),
                    padding: const EdgeInsets.symmetric(
                      vertical: TenantAdminSpacing.md,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveChangesAsync,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 18, color: Colors.white),
                  label: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: TenantAdminSpacing.md,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(String? networkUrl, Uint8List? stagedBytes) {
    if (_pickedImageBytes != null) {
      return Image.memory(_pickedImageBytes!, fit: BoxFit.cover);
    }
    if (stagedBytes != null) {
      return Image.memory(stagedBytes, fit: BoxFit.cover);
    }
    if (networkUrl != null) {
      return CachedNetworkImage(
        imageUrl: networkUrl,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      color: TenantAdminColors.subtleBackground,
      child: const Icon(
        Icons.inventory_2_outlined,
        size: 36,
        color: TenantAdminColors.mutedText,
      ),
    );
  }
}

class _AttributeInfoCard extends StatelessWidget {
  const _AttributeInfoCard({
    required this.label,
    required this.value,
  });

  final String label;
  final SelectedOptionValue value;

  @override
  Widget build(BuildContext context) {
    final color = _parseHexColor(value.colourHex) ??
        (_isColorLabel(label) ? _colorFromName(value.valueName) : null);

    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.subtleBackground,
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: TenantAdminColors.mutedText,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: TenantAdminColors.border),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                value.valueName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: TenantAdminColors.bodyText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isColorLabel(String name) {
    final lower = name.toLowerCase();
    return lower.contains('color') || lower.contains('colour');
  }
}

class _ApplyImageOptionCard extends StatelessWidget {
  const _ApplyImageOptionCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? TenantAdminColors.info : TenantAdminColors.border;
    final fillColor = selected
        ? TenantAdminColors.info.withValues(alpha: 0.04)
        : TenantAdminColors.surface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: Container(
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 18,
                  color: selected
                      ? TenantAdminColors.info
                      : TenantAdminColors.mutedText,
                ),
                const Spacer(),
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? TenantAdminColors.info
                      : TenantAdminColors.mutedText,
                ),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: TenantAdminColors.bodyText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: TenantAdminColors.mutedText,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

Color? _parseHexColor(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;
  final normalized = value.startsWith('#') ? value.substring(1) : value;
  if (normalized.length == 6) {
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed != null) return Color(0xFF000000 | parsed);
  }
  return null;
}

Color? _colorFromName(String name) {
  switch (name.trim().toLowerCase()) {
    case 'blue':
      return Colors.blue;
    case 'black':
      return Colors.black;
    case 'red':
      return Colors.red;
    case 'green':
      return Colors.green;
    case 'white':
      return Colors.grey.shade300;
    case 'yellow':
      return Colors.yellow.shade700;
    case 'orange':
      return Colors.orange;
    case 'purple':
      return Colors.purple;
    case 'pink':
      return Colors.pink;
    case 'grey':
    case 'gray':
      return Colors.grey;
    default:
      return null;
  }
}
