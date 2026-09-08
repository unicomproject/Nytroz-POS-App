import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/network/media_url_resolver.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

import '../../../domain/entities/add_product_wizard_state.dart';
import '../../../domain/entities/step4_variant_configuration_state.dart';
import '../../controllers/add_product_wizard_controller.dart';
import 'edit_variant_drawer.dart';

class GeneratedVariantsSection extends ConsumerWidget {
  const GeneratedVariantsSection({
    super.key,
    required this.step4State,
    required this.state,
    required this.controller,
    required this.onRegenerate,
  });

  final Step4VariantConfigurationState step4State;
  final AddProductWizardState state;
  final AddProductWizardController controller;
  final Future<void> Function() onRegenerate;

  static String buildSubtitle(Step4VariantConfigurationState step4State) {
    final count = step4State.totalGeneratedCount;
    final attributes = step4State.attributeRows.where((r) => r.isValid).toList();
    final attributeNames = attributes
        .map((r) => (r.templateName ?? 'Attribute').trim())
        .join(' × ');
    final combinationLabel =
        count == 1 ? 'variant combination' : 'variant combinations';
    if (attributeNames.isEmpty) {
      return '$count $combinationLabel created';
    }
    return '$count $combinationLabel created from $attributeNames';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = TenantAdminColors.posHomeAccentOrange;
    final fallbackImageUrl = _resolveFallbackImageUrl(ref, state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (MediaQuery.sizeOf(context).width <
            TenantAdminBreakpoints.smallTablet) ...[
          _buildHeader(context, accentColor),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildHeader(context, accentColor)),
              _buildRegenerateButton(context, accentColor),
            ],
          ),
        if (MediaQuery.sizeOf(context).width <
            TenantAdminBreakpoints.smallTablet) ...[
          const SizedBox(height: TenantAdminSpacing.md),
          _buildRegenerateButton(context, accentColor),
        ],
        const SizedBox(height: TenantAdminSpacing.lg),
        ...step4State.generatedVariants.map(
          (variant) => Padding(
            padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
            child: _VariantRow(
              variant: variant,
              attributeRows: step4State.attributeRows,
              imageUrl: variant.effectiveImageUrl ?? fallbackImageUrl,
              stagedImageBytes: _resolveStagedBytes(state, variant, fallbackImageUrl),
              resolveImageUrl: (raw) => _resolveImageUrl(ref, raw),
              onEdit: () => _openEditVariantDrawer(
                context,
                state: state,
                controller: controller,
                variantKey: variant.clientCombinationKey,
              ),
              onToggleIncluded: (included) => controller.toggleVariantInclusion(
                variant.clientCombinationKey,
                included,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Generated Variants',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          buildSubtitle(step4State),
          style: const TextStyle(
            fontSize: 14,
            color: TenantAdminColors.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildRegenerateButton(BuildContext context, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: state.isSavingDraft ? null : onRegenerate,
          icon: state.isSavingDraft
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accentColor,
                  ),
                )
              : Icon(Icons.refresh, size: 18, color: accentColor),
          label: Text(
            'Regenerate Variants',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: accentColor),
            padding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.lg,
              vertical: TenantAdminSpacing.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            ),
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.info_outline,
              size: 14,
              color: TenantAdminColors.mutedText,
            ),
            SizedBox(width: TenantAdminSpacing.xs),
            Text(
              'Regenerate variants whenever you change attributes.',
              style: TextStyle(
                fontSize: 12,
                color: TenantAdminColors.mutedText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String? _resolveFallbackImageUrl(WidgetRef ref, AddProductWizardState state) {
    if (state.productImages.isEmpty) return null;
    final primary = state.productImages.firstWhere(
      (image) => image.isPrimary,
      orElse: () => state.productImages.first,
    );
    if (primary.isStaged && primary.bytes != null) {
      return 'memory://${primary.id}';
    }
    return _resolveImageUrl(ref, primary.imageUrl);
  }

  String? _resolveImageUrl(WidgetRef ref, String? rawUrl) {
    final trimmed = rawUrl?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final baseUrl = ref.watch(appDioProvider).options.baseUrl;
    return MediaUrlResolver.resolve(trimmed, apiBaseUrl: baseUrl) ?? trimmed;
  }

  Uint8List? _resolveStagedBytes(
    AddProductWizardState state,
    GeneratedVariantRow variant,
    String? fallbackImageUrl,
  ) {
    if (variant.effectiveImageUrl != null) return null;
    if (fallbackImageUrl == null || !fallbackImageUrl.startsWith('memory://')) {
      return null;
    }
    final imageId = fallbackImageUrl.replaceFirst('memory://', '');
    for (final image in state.productImages) {
      if (image.id == imageId && image.bytes != null) {
        return image.bytes;
      }
    }
    return null;
  }
}

class _VariantRow extends StatelessWidget {
  const _VariantRow({
    required this.variant,
    required this.attributeRows,
    required this.imageUrl,
    this.stagedImageBytes,
    required this.resolveImageUrl,
    required this.onEdit,
    required this.onToggleIncluded,
  });

  final GeneratedVariantRow variant;
  final List<AttributeConfigRow> attributeRows;
  final String? imageUrl;
  final Uint8List? stagedImageBytes;
  final String? Function(String?) resolveImageUrl;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleIncluded;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = stagedImageBytes != null
        ? null
        : (imageUrl == null ? null : resolveImageUrl(imageUrl));

    return Container(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        border: Border.all(color: TenantAdminColors.border),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _VariantThumbnail(
            imageUrl: resolvedUrl,
            stagedImageBytes: stagedImageBytes,
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variant.combinationLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Wrap(
                  spacing: TenantAdminSpacing.md,
                  runSpacing: TenantAdminSpacing.xs,
                  children: _buildAttributeTags(),
                ),
              ],
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                key: ValueKey('edit-variant-${variant.clientCombinationKey}'),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Edit Variant'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TenantAdminColors.bodyText,
                  side: const BorderSide(color: TenantAdminColors.border),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: TenantAdminSpacing.sm,
                    vertical: TenantAdminSpacing.xs,
                  ),
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              _InclusionToggle(
                isIncluded: variant.isIncluded,
                onChanged: onToggleIncluded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAttributeTags() {
    final validAttributes = attributeRows.where((r) => r.isValid).toList();
    final tags = <Widget>[];

    for (final attribute in validAttributes) {
      SelectedOptionValue? matched;
      for (final selected in variant.selectedValues) {
        if (attribute.selectedValues
            .any((value) => value.valueId == selected.valueId)) {
          matched = selected;
          break;
        }
      }
      if (matched == null) continue;

      tags.add(
        _AttributeTagGroup(
          attributeName: (attribute.templateName ?? 'Attribute').trim(),
          value: matched,
        ),
      );
    }

    return tags;
  }
}

class _VariantThumbnail extends StatelessWidget {
  const _VariantThumbnail({
    this.imageUrl,
    this.stagedImageBytes,
  });

  final String? imageUrl;
  final Uint8List? stagedImageBytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: TenantAdminColors.subtleBackground,
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        border: Border.all(color: TenantAdminColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: stagedImageBytes != null
          ? Image.memory(stagedImageBytes!, fit: BoxFit.cover)
          : imageUrl == null
              ? const Icon(
                  Icons.inventory_2_outlined,
                  color: TenantAdminColors.mutedText,
                  size: 18,
                )
              : CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: TenantAdminColors.mutedText,
                    size: 18,
                  ),
                ),
    );
  }
}

class _AttributeTagGroup extends StatelessWidget {
  const _AttributeTagGroup({
    required this.attributeName,
    required this.value,
  });

  final String attributeName;
  final SelectedOptionValue value;

  @override
  Widget build(BuildContext context) {
    final isColorAttribute = _isColorAttribute(attributeName, value);
    final tagColor = isColorAttribute ? _resolveTagColor(value) : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          attributeName,
          style: const TextStyle(
            fontSize: 12,
            color: TenantAdminColors.mutedText,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: tagColor ?? TenantAdminColors.subtleBackground,
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            border: Border.all(
              color: tagColor != null
                  ? tagColor.withValues(alpha: 0.35)
                  : TenantAdminColors.border,
            ),
          ),
          child: Text(
            value.valueName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tagColor != null
                  ? _textColorForBackground(tagColor)
                  : TenantAdminColors.bodyText,
            ),
          ),
        ),
      ],
    );
  }

  bool _isColorAttribute(String name, SelectedOptionValue value) {
    if (value.colourHex != null && value.colourHex!.trim().isNotEmpty) {
      return true;
    }
    return name.toLowerCase().contains('color') ||
        name.toLowerCase().contains('colour');
  }

  Color _resolveTagColor(SelectedOptionValue value) {
    final fromHex = _parseHexColor(value.colourHex);
    if (fromHex != null) {
      return fromHex.withValues(alpha: 0.18);
    }
    return _colorFromName(value.valueName)?.withValues(alpha: 0.18) ??
        TenantAdminColors.subtleBackground;
  }
}

class _InclusionToggle extends StatelessWidget {
  const _InclusionToggle({
    required this.isIncluded,
    required this.onChanged,
  });

  final bool isIncluded;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    if (isIncluded) {
      return OutlinedButton.icon(
        onPressed: () => onChanged(false),
        icon: const Icon(
          Icons.check_circle_outline,
          size: 14,
          color: TenantAdminColors.success,
        ),
        label: const Text(
          'Included',
          style: TextStyle(
            color: TenantAdminColors.success,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: TenantAdminColors.successSurface,
          side: const BorderSide(color: TenantAdminColors.successBorder),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.sm,
            vertical: TenantAdminSpacing.xs,
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => onChanged(true),
      icon: const Icon(
        Icons.remove_circle_outline,
        size: 14,
        color: TenantAdminColors.danger,
      ),
      label: const Text(
        'Excluded',
        style: TextStyle(
          color: TenantAdminColors.danger,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: TenantAdminColors.dangerSurface,
        side: const BorderSide(color: TenantAdminColors.dangerBorder),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.sm,
          vertical: TenantAdminSpacing.xs,
        ),
      ),
    );
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

Color _textColorForBackground(Color background) {
  final luminance = background.computeLuminance();
  return luminance > 0.6 ? TenantAdminColors.bodyText : Colors.white;
}

Future<void> _openEditVariantDrawer(
  BuildContext context, {
  required AddProductWizardState state,
  required AddProductWizardController controller,
  required String variantKey,
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final drawerWidth = screenWidth < 440 ? screenWidth : 420.0;

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close edit variant',
    barrierColor: Colors.black54,
    useRootNavigator: false,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final slide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ));

      return Align(
        alignment: Alignment.centerRight,
        child: SlideTransition(
          position: slide,
          child: Material(
            color: TenantAdminColors.surface,
            elevation: 12,
            child: SizedBox(
              width: drawerWidth,
              height: double.infinity,
              child: EditVariantDrawer(
                state: state,
                controller: controller,
                variantKey: variantKey,
              ),
            ),
          ),
        ),
      );
    },
  );
}
