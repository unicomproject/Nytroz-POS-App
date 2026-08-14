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
    final options = state.createOptions;

    if (options == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: formKey,
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
            'Define attributes (e.g. Size, Color) and generate product variants.',
            style: TextStyle(fontSize: 14, color: TenantAdminColors.mutedText),
          ),
          const SizedBox(height: 24),

          // --- Attributes Section ---
          ...step4State.attributeRows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: TenantAdminColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: row.templateId,
                        decoration: const InputDecoration(
                          labelText: 'Attribute',
                          border: OutlineInputBorder(),
                        ),
                        items: options.variantOptionTemplates.map((t) {
                          return DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            controller.selectAttribute(index, val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            children: [
                              ...row.selectedValues.map((v) {
                                return Chip(
                                  label: Text(v.valueName),
                                  onDeleted: () {
                                    final newValues = row.selectedValues
                                        .where((x) => x.valueId != v.valueId)
                                        .map((x) => x.valueId)
                                        .toList();
                                    controller.selectValues(index, newValues);
                                  },
                                );
                              }),
                            ],
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Add Value',
                              border: OutlineInputBorder(),
                              hintText: 'Type and press enter',
                            ),
                            onFieldSubmitted: (val) {
                              final id = val.trim();
                              if (id.isNotEmpty &&
                                  !row.selectedValues
                                      .any((x) => x.valueId == id)) {
                                final newValues = row.selectedValues
                                    .map((x) => x.valueId)
                                    .toList()
                                  ..add(id);
                                controller.selectValues(index, newValues);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: TenantAdminColors.danger),
                      onPressed: () => controller.removeAttributeRow(index),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          OutlinedButton.icon(
            onPressed: () => controller.addAttributeRow(),
            icon: const Icon(Icons.add),
            label: const Text('Add Attribute'),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: () => controller.generateVariants(),
            child: const Text('Generate Variants'),
          ),

          const SizedBox(height: 32),

          // --- Generated Variants Table ---
          if (step4State.generatedVariants.isNotEmpty) ...[
            Text(
              'Generated Variants (${step4State.includedCount} included)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: TenantAdminColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: step4State.generatedVariants.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final variant = step4State.generatedVariants[index];
                  return ListTile(
                    leading: Checkbox(
                      value: variant.isIncluded,
                      onChanged: (val) {
                        if (val != null) {
                          controller.toggleVariantInclusion(
                              variant.clientCombinationKey, val);
                        }
                      },
                    ),
                    title:
                        Text(variant.displayLabel ?? variant.combinationLabel),
                    subtitle: Text('Values: ${variant.combinationLabel}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) {
                                  return Align(
                                    alignment: Alignment.centerRight,
                                    child: EditVariantDrawer(
                                      state: state,
                                      controller: controller,
                                      variantKey: variant.clientCombinationKey,
                                    ),
                                  );
                                });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => DeleteVariantModal(
                                controller: controller,
                                variantKey: variant.clientCombinationKey,
                                variantLabel: variant.displayLabel ??
                                    variant.combinationLabel,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ]
        ],
      ),
    );
  }
}
