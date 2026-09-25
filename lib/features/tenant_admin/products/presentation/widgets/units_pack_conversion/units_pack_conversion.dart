import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';

class UnitsPackConversionForm extends ConsumerStatefulWidget {
  const UnitsPackConversionForm({
    super.key,
    required this.state,
    required this.controller,
  });

  final AddProductWizardState state;
  final AddProductWizardController controller;

  @override
  ConsumerState<UnitsPackConversionForm> createState() =>
      _UnitsPackConversionFormState();
}

class _UnitsPackConversionFormState
    extends ConsumerState<UnitsPackConversionForm> {
  late final TextEditingController _pack1ContainsController;
  late final TextEditingController _pack2ContainsController;

  @override
  void initState() {
    super.initState();
    _pack1ContainsController = TextEditingController(
      text: widget.state.itemsPerPurchaseUnit != null
          ? _formatNumber(widget.state.itemsPerPurchaseUnit!)
          : '',
    );
    _pack2ContainsController = TextEditingController(
      text: _getPack2ContainsText(widget.state),
    );
  }

  String _getPack2ContainsText(AddProductWizardState state) {
    if (state.itemsPerPurchaseUnit != null &&
        state.purchaseUnitsPerOuterPack != null &&
        state.purchaseUnitsPerOuterPack! > 0) {
      final totalBaseUnits =
          state.itemsPerPurchaseUnit! * state.purchaseUnitsPerOuterPack!;
      return _formatNumber(totalBaseUnits);
    }
    return '';
  }

  @override
  void didUpdateWidget(covariant UnitsPackConversionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.itemsPerPurchaseUnit !=
        oldWidget.state.itemsPerPurchaseUnit) {
      final formatted = widget.state.itemsPerPurchaseUnit != null
          ? _formatNumber(widget.state.itemsPerPurchaseUnit!)
          : '';
      if (_pack1ContainsController.text != formatted) {
        _pack1ContainsController.text = formatted;
      }
    }

    final newPack2Text = _getPack2ContainsText(widget.state);
    if (_pack2ContainsController.text != newPack2Text) {
      _pack2ContainsController.text = newPack2Text;
    }
  }

  @override
  void dispose() {
    _pack1ContainsController.dispose();
    _pack2ContainsController.dispose();
    super.dispose();
  }

  String _formatNumber(num val) {
    if (val % 1 == 0) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  ProductUnitOption? _findUnit(String? unitId) {
    if (unitId == null || widget.state.createOptions == null) return null;
    try {
      return widget.state.createOptions!.units
          .firstWhere((u) => u.id == unitId);
    } catch (_) {
      return null;
    }
  }

  void _onPacksToggled(bool value) {
    widget.controller.selectUnitModel(value ? 'MULTIPLE_UNITS' : 'SINGLE_UNIT');
    if (!value) {
      // Clear pack configurations when turning off
      widget.controller.setPurchaseUnit(null);
      widget.controller.setItemsPerPurchaseUnit(null);
      widget.controller.setOuterPackUnit(null);
      widget.controller.setPurchaseUnitsPerOuterPack(null);
    }
  }

  void _onPack2ContainsChanged(String val) {
    final state = widget.state;
    final controller = widget.controller;
    
    final parsed = num.tryParse(val);
    if (parsed != null && state.itemsPerPurchaseUnit != null && state.itemsPerPurchaseUnit! > 0) {
      // Set the derived factor
      final factor = parsed / state.itemsPerPurchaseUnit!;
      controller.setPurchaseUnitsPerOuterPack(factor);
    } else {
      controller.setPurchaseUnitsPerOuterPack(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final controller = widget.controller;
    final options = state.createOptions;
    final unitOptions = options?.units ?? const [];

    final hasPacks = state.unitModel == 'MULTIPLE_UNITS';
    final baseUnit = _findUnit(state.baseUnitId);
    final baseUnitName = baseUnit?.name ?? 'Base Unit';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildUomDropdown(
          label: 'Base Unit *',
          value: state.baseUnitId,
          options: unitOptions,
          errorText: state.fieldErrors['baseUnitId'],
          onChanged: (val) {
            controller.setBaseUnit(val);
            // Also sync product unit and selling unit for simplicity as per existing controller mapping
            controller.setProductUnit(val);
            controller.setSellingUnit(val);
          },
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: TenantAdminColors.border),
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
          child: SwitchListTile(
            title: const Text(
              'This product has packs/cases',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Enable this if the product is also handled in packs, boxes, cases, cartons, or similar grouped units.',
              style: TextStyle(fontSize: 12),
            ),
            value: hasPacks,
            onChanged: _onPacksToggled,
            activeColor: TenantAdminColors.posHomeAccentOrange,
          ),
        ),

        if (hasPacks) ...[
          const SizedBox(height: TenantAdminSpacing.xl),
          const Text(
            'Pack 1',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildUomDropdown(
                  label: 'Pack Type *',
                  value: state.purchaseUnitId,
                  options: unitOptions,
                  errorText: state.fieldErrors['purchaseUnitId'],
                  onChanged: (val) => controller.setPurchaseUnit(val),
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                flex: 1,
                child: _buildNumberInput(
                  label: 'Contains *',
                  controller: _pack1ContainsController,
                  errorText: state.fieldErrors['itemsPerPurchaseUnit'],
                  hint: 'e.g. 6',
                  suffixText: baseUnitName,
                  onChanged: (val) {
                    final parsed = num.tryParse(val);
                    controller.setItemsPerPurchaseUnit(parsed);
                    // If Pack 2 exists, we need to recompute its factor based on new Pack 1
                    if (state.outerPackUnitId != null && _pack2ContainsController.text.isNotEmpty) {
                      _onPack2ContainsChanged(_pack2ContainsController.text);
                    }
                  },
                ),
              ),
            ],
          ),

          if (state.outerPackUnitId != null || state.purchaseUnitsPerOuterPack != null) ...[
             const SizedBox(height: TenantAdminSpacing.xl),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text(
                  'Pack 2',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                 ),
                 TextButton.icon(
                   onPressed: () {
                     controller.setOuterPackUnit(null);
                     controller.setPurchaseUnitsPerOuterPack(null);
                     _pack2ContainsController.clear();
                   },
                   icon: const Icon(Icons.delete_outline, size: 18),
                   label: const Text('Remove Pack 2'),
                   style: TextButton.styleFrom(foregroundColor: Colors.red),
                 ),
               ],
             ),
             const SizedBox(height: TenantAdminSpacing.sm),
             Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Expanded(
                   flex: 1,
                   child: _buildUomDropdown(
                     label: 'Pack Type *',
                     value: state.outerPackUnitId,
                     options: unitOptions,
                     errorText: state.fieldErrors['outerPackUnitId'],
                     onChanged: (val) => controller.setOuterPackUnit(val),
                   ),
                 ),
                 const SizedBox(width: TenantAdminSpacing.md),
                 Expanded(
                   flex: 1,
                   child: _buildNumberInput(
                     label: 'Contains *',
                     controller: _pack2ContainsController,
                     errorText: state.fieldErrors['purchaseUnitsPerOuterPack'],
                     hint: 'e.g. 24',
                     suffixText: baseUnitName,
                     onChanged: _onPack2ContainsChanged,
                   ),
                 ),
               ],
             ),
             const SizedBox(height: TenantAdminSpacing.sm),
             const Text(
               'Maximum 2 pack levels are currently supported.',
               style: TextStyle(fontSize: 12, color: TenantAdminColors.mutedText),
             ),
          ] else ...[
             const SizedBox(height: TenantAdminSpacing.md),
             Align(
               alignment: Alignment.centerLeft,
               child: OutlinedButton.icon(
                 onPressed: () {
                   // Add Pack 2 by just initializing the ID to something or relying on user selection.
                   // Since we check `outerPackUnitId != null || purchaseUnitsPerOuterPack != null`, we can set `outerPackUnitId = ''`.
                   controller.setOuterPackUnit('');
                 },
                 icon: const Icon(Icons.add),
                 label: const Text('Add Another Pack'),
                 style: OutlinedButton.styleFrom(
                   foregroundColor: TenantAdminColors.posHomeAccentOrange,
                   side: const BorderSide(color: TenantAdminColors.posHomeAccentOrange),
                 ),
               ),
             ),
          ]
        ],

        const SizedBox(height: TenantAdminSpacing.xl),
        _buildConversionSummaryCard(
          baseUnit: baseUnit,
          purchaseUnit: _findUnit(state.purchaseUnitId),
          outerPackUnit: _findUnit(state.outerPackUnitId),
          itemsPerPurchase: state.itemsPerPurchaseUnit,
          purchaseUnitsPerOuter: state.purchaseUnitsPerOuterPack,
        ),
      ],
    );
  }

  Widget _buildUomDropdown({
    required String label,
    required String? value,
    required List<ProductUnitOption> options,
    required ValueChanged<String?> onChanged,
    String? errorText,
  }) {
    final validValue = options.any((o) => o.id == value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        DropdownButtonFormField<String>(
          initialValue: validValue,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Select Unit',
            errorText: errorText,
            filled: true,
            fillColor: TenantAdminColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(
                color: TenantAdminColors.posHomeAccentOrange,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.md,
              vertical: TenantAdminSpacing.sm,
            ),
          ),
          items: options.map((unit) {
            return DropdownMenuItem<String>(
              value: unit.id,
              child: Text(
                unit.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildNumberInput({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    String? errorText,
    String? hint,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            suffixText: suffixText,
            filled: true,
            fillColor: TenantAdminColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(
                color: TenantAdminColors.posHomeAccentOrange,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.md,
              vertical: TenantAdminSpacing.sm,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildConversionSummaryCard({
    required ProductUnitOption? baseUnit,
    required ProductUnitOption? purchaseUnit,
    required ProductUnitOption? outerPackUnit,
    required num? itemsPerPurchase,
    required num? purchaseUnitsPerOuter,
  }) {
    if (baseUnit == null) {
      return const SizedBox.shrink();
    }

    final lines = <String>[];
    lines.add('1 ${baseUnit.name} = 1 Base Unit');

    if (purchaseUnit != null && itemsPerPurchase != null && itemsPerPurchase > 0) {
      lines.add('1 ${purchaseUnit.name} = ${_formatNumber(itemsPerPurchase)} ${baseUnit.name}s');

      if (outerPackUnit != null && purchaseUnitsPerOuter != null && purchaseUnitsPerOuter > 0) {
        final totalBase = itemsPerPurchase * purchaseUnitsPerOuter;
        lines.add('1 ${outerPackUnit.name} = ${_formatNumber(totalBase)} ${baseUnit.name}s');
      }
    }

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
          color: TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration Summary',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: TenantAdminSpacing.xs),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: TenantAdminColors.posHomeAccentOrange,
                  ),
                  const SizedBox(width: TenantAdminSpacing.xs),
                  Text(
                    line,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TenantAdminColors.bodyText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
