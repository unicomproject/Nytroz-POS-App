// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/add_product_wizard_state.dart';

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
  late TextEditingController _labelController;
  late bool _isIncluded;
  String? _exactImageMediaAssetId;
  String _applyImageTo = 'ONLY_THIS';

  @override
  void initState() {
    super.initState();
    final variant = widget.state.step4State.generatedVariants
        .firstWhere((v) => v.clientCombinationKey == widget.variantKey);
    _labelController = TextEditingController(
        text: variant.displayLabel ?? variant.combinationLabel);
    _isIncluded = variant.isIncluded;
    _exactImageMediaAssetId = variant.exactImageMediaAssetId;
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final variant = widget.state.step4State.generatedVariants
        .firstWhere((v) => v.clientCombinationKey == widget.variantKey);

    if (_labelController.text != variant.displayLabel) {
      widget.controller
          .updateVariantDisplayLabel(widget.variantKey, _labelController.text);
    }

    if (_isIncluded != variant.isIncluded) {
      widget.controller.toggleVariantInclusion(widget.variantKey, _isIncluded);
    }

    // Exact image would be applied here

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state.step4State;
    final variant = state.generatedVariants
        .firstWhere((v) => v.clientCombinationKey == widget.variantKey);

    return Container(
      width: 400,
      color: TenantAdminColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Variant',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Variant Information',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...variant.selectedValues.map((v) =>
                      Text('${v.templateId ?? 'Attribute'}: ${v.valueName}')),
                  const SizedBox(height: 24),
                  const Text('Variant Image',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: TenantAdminColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.image),
                            label: const Text('Change Image'),
                            onPressed: () {},
                          ),
                          if (_exactImageMediaAssetId != null)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _exactImageMediaAssetId = null;
                                });
                              },
                              child: const Text('Remove Override',
                                  style: TextStyle(color: Colors.red)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Apply Image To:'),
                  RadioListTile<String>(
                    title: const Text('Only this variant'),
                    value: 'ONLY_THIS',
                    groupValue: _applyImageTo,
                    onChanged: (val) {
                      setState(() {
                        _applyImageTo = val!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(
                        'All ${variant.selectedValues.isNotEmpty ? variant.selectedValues.last.valueName : 'group'} variants'),
                    value: 'ALL_GROUP',
                    groupValue: _applyImageTo,
                    onChanged: (val) {
                      setState(() {
                        _applyImageTo = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: 'Display Label',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Include Variant',
                          style: TextStyle(fontSize: 14)),
                      Switch(
                        value: _isIncluded,
                        onChanged: (val) {
                          setState(() {
                            _isIncluded = val;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
