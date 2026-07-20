import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_inspection.dart';
import 'inspection_condition_selector.dart';
import 'inspection_notes_field.dart';
import 'inspection_photos_section.dart';

class InspectionItemCard extends StatelessWidget {
  const InspectionItemCard({
    super.key,
    required this.itemName,
    required this.sku,
    required this.variantLabel,
    required this.quantity,
    required this.valueLabel,
    required this.imageValue,
    required this.conditions,
    required this.inspection,
    required this.notesMaxLength,
    required this.maxPhotosPerLine,
    required this.notesController,
    required this.onConditionSelected,
    required this.onNotesChanged,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    required this.onRetryPhoto,
  });

  final String itemName;
  final String sku;
  final String variantLabel;
  final int quantity;
  final String valueLabel;
  final String? imageValue;
  final List<InspectionConditionOption> conditions;
  final ReturnLineInspection inspection;
  final int notesMaxLength;
  final int maxPhotosPerLine;
  final TextEditingController notesController;
  final ValueChanged<String> onConditionSelected;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback onAddPhoto;
  final ValueChanged<String> onRemovePhoto;
  final ValueChanged<String> onRetryPhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;

          final infoSection = _ItemInfoSection(
            itemName: itemName,
            sku: sku,
            variantLabel: variantLabel,
            quantity: quantity,
            valueLabel: valueLabel,
            imageValue: imageValue,
          );

          final formSection = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InspectionConditionSelector(
                conditions: conditions,
                selectedConditionCode: inspection.conditionCode,
                onConditionSelected: onConditionSelected,
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              InspectionNotesField(
                controller: notesController,
                notesLength: inspection.notes.length,
                maxLength: notesMaxLength,
                required: _notesRequired,
                onChanged: onNotesChanged,
              ),
            ],
          );

          final photosSection = InspectionPhotosSection(
            media: inspection.media,
            maxPhotos: maxPhotosPerLine,
            onAddPhoto: onAddPhoto,
            onRemovePhoto: onRemovePhoto,
            onRetryPhoto: onRetryPhoto,
          );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 34, child: infoSection),
                const SizedBox(width: TenantAdminSpacing.lg),
                Expanded(flex: 40, child: formSection),
                const SizedBox(width: TenantAdminSpacing.lg),
                Expanded(flex: 26, child: photosSection),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              infoSection,
              const SizedBox(height: TenantAdminSpacing.lg),
              formSection,
              const SizedBox(height: TenantAdminSpacing.lg),
              photosSection,
            ],
          );
        },
      ),
    );
  }

  bool get _notesRequired {
    final code = inspection.conditionCode;
    if (code == null) {
      return false;
    }
    for (final condition in conditions) {
      if (condition.code == code) {
        return condition.requiresNotes;
      }
    }
    return false;
  }
}

class _ItemInfoSection extends StatelessWidget {
  const _ItemInfoSection({
    required this.itemName,
    required this.sku,
    required this.variantLabel,
    required this.quantity,
    required this.valueLabel,
    required this.imageValue,
  });

  final String itemName;
  final String sku;
  final String variantLabel;
  final int quantity;
  final String valueLabel;
  final String? imageValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Checkbox(
          value: true,
          onChanged: null,
          activeColor: TenantAdminColors.primary,
        ),
        _ProductThumb(imageValue: imageValue),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                itemName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (sku.isNotEmpty || variantLabel.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  _detailsLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: TenantAdminColors.mutedText,
                      ),
                ),
              ],
              const SizedBox(height: 3),
              Text(
                'Qty: $quantity',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: TenantAdminColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                valueLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String get _detailsLabel {
    if (sku.isEmpty) {
      return variantLabel;
    }
    if (variantLabel.isEmpty) {
      return 'SKU: $sku';
    }
    return 'SKU: $sku | $variantLabel';
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.imageValue});

  final String? imageValue;
  static const _fallbackAsset = 'assets/images/product_dummy.png';

  @override
  Widget build(BuildContext context) {
    final value = imageValue?.trim() ?? '';
    final child = value.startsWith('http')
        ? Image.network(
            value,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(),
          )
        : _fallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: SizedBox(width: 52, height: 52, child: child),
    );
  }

  Widget _fallback() {
    return Image.asset(
      _fallbackAsset,
      width: 52,
      height: 52,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          width: 52,
          height: 52,
          color: TenantAdminColors.background,
          child: const Icon(
            Icons.inventory_2_outlined,
            color: TenantAdminColors.mutedText,
            size: 22,
          ),
        );
      },
    );
  }
}
