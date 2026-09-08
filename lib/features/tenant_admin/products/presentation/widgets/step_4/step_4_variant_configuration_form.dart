import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/add_product_wizard_state.dart';
import '../../../domain/entities/step4_variant_configuration_state.dart';
import 'generated_variants_section.dart';
import 'estimated_variant_count_card.dart';
import 'variant_configuration_summary_card.dart';

class Step4VariantConfigurationForm extends ConsumerStatefulWidget {
  final AddProductWizardState state;
  final AddProductWizardController controller;
  final GlobalKey<FormState> formKey;

  const Step4VariantConfigurationForm({
    super.key,
    required this.state,
    required this.controller,
    required this.formKey,
  });

  @override
  ConsumerState<Step4VariantConfigurationForm> createState() =>
      _Step4VariantConfigurationFormState();
}

class _Step4VariantConfigurationFormState
    extends ConsumerState<Step4VariantConfigurationForm> {
  late bool _showVariantsView;

  AddProductWizardState get state => widget.state;
  AddProductWizardController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _showVariantsView =
        widget.state.step4State.generatedVariants.isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant Step4VariantConfigurationForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.step4State.generatedVariants.isNotEmpty &&
        oldWidget.state.step4State.generatedVariants.isEmpty) {
      _showVariantsView = true;
    }
  }

  Future<void> _handleRegenerateVariants() async {
    await controller.generateVariants();
    if (!mounted) return;
    setState(() => _showVariantsView = true);
  }

  @override
  Widget build(BuildContext context) {
    final step4State = state.step4State;
    final accentColor = TenantAdminColors.posHomeAccentOrange;
    final hasGeneratedVariants = step4State.generatedVariants.isNotEmpty;
    final showingGeneratedView = _showVariantsView && hasGeneratedVariants;

    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact =
                constraints.maxWidth < TenantAdminBreakpoints.smallTablet;

            if (showingGeneratedView) {
              final generatedCard = _Step4SectionCard(
                child: GeneratedVariantsSection(
                  step4State: step4State,
                  state: state,
                  controller: controller,
                  onRegenerate: _handleRegenerateVariants,
                ),
              );
              final summaryCard = VariantConfigurationSummaryCard(
                step4State: step4State,
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    generatedCard,
                    const SizedBox(height: TenantAdminSpacing.lg),
                    summaryCard,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: generatedCard),
                  const SizedBox(width: TenantAdminSpacing.lg),
                  SizedBox(width: 260, child: summaryCard),
                ],
              );
            }

            final headerText = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Variant Attributes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
                SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  'Define the attributes and values that describe your product variants',
                  style: TextStyle(
                    fontSize: 14,
                    color: TenantAdminColors.mutedText,
                  ),
                ),
              ],
            );

            final actionButtons = Wrap(
              spacing: TenantAdminSpacing.sm,
              runSpacing: TenantAdminSpacing.sm,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => controller.addAttributeRow(),
                  icon: Icon(Icons.add, size: 18, color: accentColor),
                  label: Text(
                    'Add Attribute',
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
                      borderRadius:
                          BorderRadius.circular(TenantAdminRadius.sm),
                    ),
                  ),
                ),
                if (hasGeneratedVariants)
                  OutlinedButton(
                    onPressed: () => setState(() => _showVariantsView = true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TenantAdminColors.bodyText,
                      side: const BorderSide(color: TenantAdminColors.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: TenantAdminSpacing.lg,
                        vertical: TenantAdminSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.sm),
                      ),
                    ),
                    child: Text(
                      'View Generated Variants',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ),
              ],
            );

            final attributesCard = _Step4SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isCompact) ...[
                    headerText,
                    const SizedBox(height: TenantAdminSpacing.md),
                    actionButtons,
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: headerText),
                        actionButtons,
                      ],
                    ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  if (step4State.attributeRows.isEmpty)
                    _EmptyAttributesPlaceholder(
                      onAdd: controller.addAttributeRow,
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: step4State.attributeRows.length,
                      onReorder: controller.reorderAttributeRows,
                      itemBuilder: (context, index) {
                        final row = step4State.attributeRows[index];
                        return _AttributeCard(
                          key: ValueKey(row.localId),
                          index: index,
                          row: row,
                          controller: controller,
                        );
                      },
                    ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: TenantAdminSpacing.xl,
                          vertical: TenantAdminSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(TenantAdminRadius.sm),
                        ),
                      ),
                      onPressed: state.isSavingDraft
                          ? null
                          : () async {
                              await controller.generateVariants();
                              if (!mounted) return;
                              setState(() => _showVariantsView = true);
                            },
                      child: state.isSavingDraft
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              hasGeneratedVariants ? 'Apply Changes' : 'Apply',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );

            final countCard = EstimatedVariantCountCard(
              step4State: step4State,
              isLoading: state.isSubmitting,
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  attributesCard,
                  const SizedBox(height: TenantAdminSpacing.lg),
                  countCard,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: attributesCard),
                const SizedBox(width: TenantAdminSpacing.lg),
                Expanded(flex: 2, child: countCard),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Step4SectionCard extends StatelessWidget {
  const _Step4SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyAttributesPlaceholder extends StatelessWidget {
  const _EmptyAttributesPlaceholder({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.xxl),
      decoration: BoxDecoration(
        color: TenantAdminColors.subtleBackground,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.tune_outlined,
            size: 40,
            color: TenantAdminColors.mutedText.withValues(alpha: 0.6),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          const Text(
            'No attributes added yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          const Text(
            'Add an attribute like Color or Size to start building variants.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: TenantAdminColors.mutedText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Attribute'),
          ),
        ],
      ),
    );
  }
}

class _AttributeCard extends StatefulWidget {
  const _AttributeCard({
    super.key,
    required this.index,
    required this.row,
    required this.controller,
  });

  final int index;
  final AttributeConfigRow row;
  final AddProductWizardController controller;

  @override
  State<_AttributeCard> createState() => _AttributeCardState();
}

class _AttributeCardState extends State<_AttributeCard> {
  bool _isEditingName = false;
  late TextEditingController _nameController;
  late FocusNode _nameFocusNode;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.row.templateName ?? '');
    _nameFocusNode = FocusNode();
    _nameFocusNode.addListener(_onNameFocusChange);
    if ((widget.row.templateName ?? '').trim().isEmpty) {
      _isEditingName = true;
    }
  }

  @override
  void didUpdateWidget(covariant _AttributeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final name = widget.row.templateName ?? '';
    if (name != oldWidget.row.templateName &&
        name != _nameController.text &&
        !_nameFocusNode.hasFocus) {
      _nameController.text = name;
    }
  }

  void _onNameFocusChange() {
    if (!_nameFocusNode.hasFocus && _isEditingName) {
      _commitName();
    }
  }

  void _commitName() {
    widget.controller.updateAttributeName(
      widget.index,
      _nameController.text.trim(),
    );
    setState(() {
      _isEditingName = false;
    });
  }

  Future<void> _promptAddValue() async {
    final templateId = widget.row.templateId;
    if (templateId == null || templateId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter an attribute name before adding values.'),
        ),
      );
      return;
    }

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final valueController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Value'),
          content: TextField(
            controller: valueController,
            autofocus: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            onSubmitted: (val) =>
                Navigator.of(dialogContext).pop(val.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(valueController.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (value == null || value.isEmpty) return;
    if (widget.row.selectedValues.any((x) => x.valueId == value)) return;

    final newValues = widget.row.selectedValues
        .map((x) => x.valueId)
        .toList()
      ..add(value);
    widget.controller.selectValues(widget.index, newValues);
  }

  @override
  void dispose() {
    _nameFocusNode.removeListener(_onNameFocusChange);
    _nameFocusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final displayName = (row.templateName ?? '').trim();
    final isActive = row.isValid;

    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
      child: Material(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: TenantAdminColors.border),
          ),
          padding: const EdgeInsets.all(TenantAdminSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: const Padding(
                      padding: EdgeInsets.only(
                        top: 2,
                        right: TenantAdminSpacing.sm,
                      ),
                      child: Icon(
                        Icons.drag_indicator,
                        color: TenantAdminColors.mutedText,
                        size: 22,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _isEditingName
                        ? TextField(
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: TenantAdminSpacing.sm,
                                vertical: TenantAdminSpacing.sm,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.words,
                            onSubmitted: (_) => _commitName(),
                          )
                        : Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName.isEmpty
                                      ? 'Untitled Attribute'
                                      : displayName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: displayName.isEmpty
                                        ? TenantAdminColors.mutedText
                                        : TenantAdminColors.bodyText,
                                  ),
                                ),
                              ),
                              if (isActive) ...[
                                const SizedBox(width: TenantAdminSpacing.sm),
                                _ActiveBadge(),
                              ],
                            ],
                          ),
                  ),
                  _IconActionButton(
                    icon: Icons.edit_outlined,
                    onPressed: () {
                      setState(() {
                        _isEditingName = true;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _nameFocusNode.requestFocus();
                      });
                    },
                  ),
                  const SizedBox(width: TenantAdminSpacing.xs),
                  _IconActionButton(
                    icon: Icons.delete_outline,
                    iconColor: TenantAdminColors.danger,
                    borderColor: TenantAdminColors.dangerBorder,
                    onPressed: () =>
                        widget.controller.removeAttributeRow(widget.index),
                  ),
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              const Text(
                'Values',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TenantAdminColors.mutedText,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.sm),
              Wrap(
                spacing: TenantAdminSpacing.sm,
                runSpacing: TenantAdminSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...row.selectedValues.map(
                    (value) => _ValueTag(
                      label: value.valueName,
                      onRemove: () {
                        final newValues = row.selectedValues
                            .where((x) => x.valueId != value.valueId)
                            .map((x) => x.valueId)
                            .toList();
                        widget.controller.selectValues(widget.index, newValues);
                      },
                    ),
                  ),
                  _AddValueButton(onTap: _promptAddValue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.successSurface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        border: Border.all(color: TenantAdminColors.successBorder),
      ),
      child: const Text(
        'Active',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: TenantAdminColors.success,
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.icon,
    required this.onPressed,
    this.iconColor = TenantAdminColors.bodyText,
    this.borderColor = TenantAdminColors.border,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color iconColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}

class _ValueTag extends StatelessWidget {
  const _ValueTag({
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.subtleBackground,
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.xs),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(12),
            child: const Icon(
              Icons.close,
              size: 16,
              color: TenantAdminColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddValueButton extends StatelessWidget {
  const _AddValueButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = TenantAdminColors.posHomeAccentOrange;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: CustomPaint(
        painter: _DashedRectPainter(
          color: accentColor,
          radius: TenantAdminRadius.sm,
        ),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(Icons.add, size: 20, color: accentColor),
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({
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

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
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
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
