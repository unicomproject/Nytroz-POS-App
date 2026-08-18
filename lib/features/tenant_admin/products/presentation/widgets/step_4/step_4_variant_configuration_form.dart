import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/add_product_wizard_state.dart';
import 'edit_variant_drawer.dart';
import 'delete_variant_modal.dart';

class Step4VariantConfigurationForm extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final step4State = state.step4State;

    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Variant Configuration',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: TenantAdminColors.bodyText),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create product variants by defining attributes and their values.',
              style:
                  TextStyle(fontSize: 14, color: TenantAdminColors.mutedText),
            ),
            const SizedBox(height: 24),

            // --- Attributes Section ---
            const Text(
              'Define Attributes',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TenantAdminColors.bodyText),
            ),
            const SizedBox(height: 16),
            ...step4State.attributeRows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;

              return Padding(
                key: Key(row.localId),
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: TenantAdminColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Attribute Name',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            _AttributeNameField(
                              initialValue: row.templateName ?? '',
                              onChanged: (val) {
                                controller.updateAttributeName(index, val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Values',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: TenantAdminColors.border),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 8,
                                      children: [
                                        ...row.selectedValues.map((v) {
                                          return Chip(
                                            label: Text(v.valueName),
                                            backgroundColor: Colors.grey[100],
                                            side: BorderSide(
                                                color: Colors.grey[300]!),
                                            onDeleted: () {
                                              final newValues = row
                                                  .selectedValues
                                                  .where((x) =>
                                                      x.valueId != v.valueId)
                                                  .map((x) => x.valueId)
                                                  .toList();
                                              controller.selectValues(
                                                  index, newValues);
                                            },
                                          );
                                        }),
                                        _AddValueField(
                                          onSubmitted: (val) {
                                            final id = val.trim();
                                            if (id.isNotEmpty &&
                                                !row.selectedValues.any(
                                                    (x) => x.valueId == id)) {
                                              final newValues = row
                                                  .selectedValues
                                                  .map((x) => x.valueId)
                                                  .toList()
                                                ..add(id);
                                              controller.selectValues(
                                                  index, newValues);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        children: [
                          const SizedBox(height: 24),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: TenantAdminColors.danger),
                            onPressed: () =>
                                controller.removeAttributeRow(index),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => controller.addAttributeRow(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Attribute',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TenantAdminColors.posHomeAccentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: state.isSavingDraft
                      ? null
                      : () async {
                          await controller.generateVariants();
                        },
                  child: state.isSavingDraft
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Apply',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // --- Generated Variants Table ---
            if (step4State.generatedVariants.isNotEmpty) ...[
              Text(
                'Generated Variants (${step4State.totalGeneratedCount})',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: TenantAdminColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8)),
                        border: Border(
                            bottom:
                                BorderSide(color: TenantAdminColors.border)),
                      ),
                      child: Row(
                        children: const [
                          Expanded(
                              child: Text('Variant',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12))),
                          SizedBox(
                            width: 100,
                            child: Text('Actions',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                                textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: step4State.generatedVariants.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final variant = step4State.generatedVariants[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  variant.displayLabel ??
                                      variant.combinationLabel,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 20, color: Colors.blue),
                                      onPressed: () {
                                        showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) {
                                              return Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: EditVariantDrawer(
                                                  state: state,
                                                  controller: controller,
                                                  variantKey: variant
                                                      .clientCombinationKey,
                                                ),
                                              );
                                            });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 20,
                                          color: TenantAdminColors.danger),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              DeleteVariantModal(
                                            controller: controller,
                                            variantKey:
                                                variant.clientCombinationKey,
                                            variantLabel:
                                                variant.displayLabel ??
                                                    variant.combinationLabel,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _AttributeNameField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _AttributeNameField({
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_AttributeNameField> createState() => _AttributeNameFieldState();
}

class _AttributeNameFieldState extends State<_AttributeNameField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _AttributeNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue &&
        widget.initialValue != _controller.text &&
        !_focusNode.hasFocus) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'e.g. Size, Color',
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: widget.onChanged,
    );
  }
}

class _AddValueField extends StatefulWidget {
  final ValueChanged<String> onSubmitted;

  const _AddValueField({required this.onSubmitted});

  @override
  State<_AddValueField> createState() => _AddValueFieldState();
}

class _AddValueFieldState extends State<_AddValueField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _submitCurrentText();
    }
  }

  void _submitCurrentText() {
    final val = _controller.text.trim();
    if (val.isNotEmpty) {
      widget.onSubmitted(val);
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Add value',
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (val) {
          if (val.endsWith(',') || val.endsWith(' ')) {
            final text = val.substring(0, val.length - 1).trim();
            if (text.isNotEmpty) {
              widget.onSubmitted(text);
            }
            _controller.clear();
            _focusNode.requestFocus();
          }
        },
        onFieldSubmitted: (val) {
          _submitCurrentText();
          _focusNode.requestFocus();
        },
      ),
    );
  }
}
