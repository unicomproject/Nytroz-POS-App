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
  late final TextEditingController _itemsPerPurchaseController;
  late final TextEditingController _purchaseUnitsPerOuterController;

  @override
  void initState() {
    super.initState();
    _itemsPerPurchaseController = TextEditingController(
      text: widget.state.itemsPerPurchaseUnit != null
          ? _formatNumber(widget.state.itemsPerPurchaseUnit!)
          : '',
    );
    _purchaseUnitsPerOuterController = TextEditingController(
      text: widget.state.purchaseUnitsPerOuterPack != null
          ? _formatNumber(widget.state.purchaseUnitsPerOuterPack!)
          : '',
    );
  }

  @override
  void didUpdateWidget(covariant UnitsPackConversionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.itemsPerPurchaseUnit !=
        oldWidget.state.itemsPerPurchaseUnit) {
      final formatted = widget.state.itemsPerPurchaseUnit != null
          ? _formatNumber(widget.state.itemsPerPurchaseUnit!)
          : '';
      if (_itemsPerPurchaseController.text != formatted) {
        _itemsPerPurchaseController.text = formatted;
      }
    }
    if (widget.state.purchaseUnitsPerOuterPack !=
        oldWidget.state.purchaseUnitsPerOuterPack) {
      final formatted = widget.state.purchaseUnitsPerOuterPack != null
          ? _formatNumber(widget.state.purchaseUnitsPerOuterPack!)
          : '';
      if (_purchaseUnitsPerOuterController.text != formatted) {
        _purchaseUnitsPerOuterController.text = formatted;
      }
    }
  }

  @override
  void dispose() {
    _itemsPerPurchaseController.dispose();
    _purchaseUnitsPerOuterController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final controller = widget.controller;
    final options = state.createOptions;
    final unitOptions = options?.units ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        const Text(
          'Units & Pack Conversion',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        const Text(
          'Configure the unit of measure used to manage this product.',
          style: TextStyle(
            fontSize: 14,
            color: TenantAdminColors.mutedText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xl),

        // Unit Model Card Selector
        Row(
          children: [
            Expanded(
              child: _buildUnitModelCard(
                title: 'Single Unit Only',
                description:
                    'Use one unit for purchase, selling and stock counting.',
                icon: Icons.inventory_2_outlined,
                isSelected: state.unitModel == 'SINGLE_UNIT',
                onTap: () => controller.selectUnitModel('SINGLE_UNIT'),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: _buildUnitModelCard(
                title: 'Multiple Units & Pack Conversion',
                description:
                    'Use different units and set conversion between them.',
                icon: Icons.layers_outlined,
                isSelected: state.unitModel == 'MULTIPLE_UNITS',
                onTap: () => controller.selectUnitModel('MULTIPLE_UNITS'),
              ),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.xl),

        // Form Section (State A or State B)
        if (state.unitModel == 'SINGLE_UNIT')
          _buildSingleUnitSection(state, controller, unitOptions)
        else
          _buildMultipleUnitsSection(state, controller, unitOptions),
      ],
    );
  }

  Widget _buildUnitModelCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const activeColor = TenantAdminColors.posHomeAccentOrange;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      child: Container(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.04)
              : TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          border: Border.all(
            color: isSelected ? activeColor : TenantAdminColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? activeColor : TenantAdminColors.mutedText,
              size: 24,
            ),
            const SizedBox(width: TenantAdminSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: isSelected
                            ? activeColor
                            : TenantAdminColors.mutedText,
                      ),
                      const SizedBox(width: TenantAdminSpacing.xs),
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? TenantAdminColors.bodyText
                                : TenantAdminColors.bodyText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: TenantAdminColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STATE A: SINGLE UNIT ONLY ---

  Widget _buildSingleUnitSection(
    AddProductWizardState state,
    AddProductWizardController controller,
    List<ProductUnitOption> unitOptions,
  ) {
    final selectedUnitId = state.productUnitId ?? state.baseUnitId;
    final selectedUnit = _findUnit(selectedUnitId);
    final unitError =
        state.fieldErrors['productUnitId'] ?? state.fieldErrors['baseUnitId'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildUomDropdown(
                          label: 'Product Unit *',
                          value: selectedUnitId,
                          options: unitOptions,
                          errorText: unitError,
                          onChanged: (val) => controller.setProductUnit(val),
                        ),
                      ),
                      const SizedBox(width: TenantAdminSpacing.xl),
                      Expanded(
                        child: _buildDecimalToggle(state, controller),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUomDropdown(
                        label: 'Product Unit *',
                        value: selectedUnitId,
                        options: unitOptions,
                        errorText: unitError,
                        onChanged: (val) => controller.setProductUnit(val),
                      ),
                      const SizedBox(height: TenantAdminSpacing.lg),
                      _buildDecimalToggle(state, controller),
                    ],
                  );
          },
        ),
        const SizedBox(height: TenantAdminSpacing.xl),

        // Information Banner
        Container(
          padding: const EdgeInsets.all(TenantAdminSpacing.lg),
          decoration: BoxDecoration(
            color: TenantAdminColors.subtleBackground,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: TenantAdminColors.posHomeAccentOrange,
                size: 22,
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Text(
                  selectedUnit != null
                      ? 'This product will be purchased, sold and counted in ${selectedUnit.name}. No pack conversion is applied.'
                      : 'Select a Product Unit to configure basic unit settings. No pack conversion is applied.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- STATE B: MULTIPLE UNITS & PACK CONVERSION ---

  Widget _buildMultipleUnitsSection(
    AddProductWizardState state,
    AddProductWizardController controller,
    List<ProductUnitOption> unitOptions,
  ) {
    final baseUnit = _findUnit(state.baseUnitId);
    final purchaseUnit = _findUnit(state.purchaseUnitId);
    final outerPackUnit = _findUnit(state.outerPackUnitId);
    final sellingUnit = _findUnit(state.sellingUnitId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final isMedium = constraints.maxWidth >= 600;

            if (isWide) {
              return Column(
                children: [
                  // Row 1: Base Unit, Purchase Unit, Outer Pack Unit
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildUomDropdown(
                          label: 'Base Unit *',
                          value: state.baseUnitId,
                          options: unitOptions,
                          errorText: state.fieldErrors['baseUnitId'],
                          onChanged: (val) => controller.setBaseUnit(val),
                        ),
                      ),
                      const SizedBox(width: TenantAdminSpacing.lg),
                      Expanded(
                        child: _buildUomDropdown(
                          label: 'Purchase Unit *',
                          value: state.purchaseUnitId,
                          options: unitOptions,
                          errorText: state.fieldErrors['purchaseUnitId'],
                          onChanged: (val) => controller.setPurchaseUnit(val),
                        ),
                      ),
                      const SizedBox(width: TenantAdminSpacing.lg),
                      Expanded(
                        child: _buildUomDropdown(
                          label: 'Outer Pack Unit',
                          value: state.outerPackUnitId,
                          options: unitOptions,
                          errorText: state.fieldErrors['outerPackUnitId'],
                          onChanged: (val) => controller.setOuterPackUnit(val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),

                  // Row 2: Selling Unit, Items per Purchase Unit, Purchase Units per Outer Pack
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildUomDropdown(
                          label: 'Selling Unit *',
                          value: state.sellingUnitId,
                          options: unitOptions,
                          errorText: state.fieldErrors['sellingUnitId'],
                          onChanged: (val) => controller.setSellingUnit(val),
                        ),
                      ),
                      const SizedBox(width: TenantAdminSpacing.lg),
                      Expanded(
                        child: _buildNumberInput(
                          label: 'Items per Purchase Unit *',
                          controller: _itemsPerPurchaseController,
                          errorText: state.fieldErrors['itemsPerPurchaseUnit'],
                          hint: 'e.g. 6',
                          onChanged: (val) {
                            final parsed = num.tryParse(val);
                            controller.setItemsPerPurchaseUnit(parsed);
                          },
                        ),
                      ),
                      const SizedBox(width: TenantAdminSpacing.lg),
                      Expanded(
                        child: _buildNumberInput(
                          label: 'Purchase Units per Outer Pack',
                          controller: _purchaseUnitsPerOuterController,
                          enabled: state.outerPackUnitId != null &&
                              state.outerPackUnitId!.isNotEmpty,
                          errorText:
                              state.fieldErrors['purchaseUnitsPerOuterPack'],
                          hint: 'e.g. 12',
                          onChanged: (val) {
                            final parsed = num.tryParse(val);
                            controller.setPurchaseUnitsPerOuterPack(parsed);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else if (isMedium) {
              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildUomDropdown(
                          label: 'Base Unit *',
                          value: state.baseUnitId,
                          options: unitOptions,
                          errorText: state.fieldErrors['baseUnitId'],
                          onChanged: (val) => controller.setBaseUnit(val),
                        ),
                      ),
                      const SizedBox(width: TenantAdminSpacing.lg),
                      Expanded(
                        child: _buildUomDropdown(
                          label: 'Purchase Unit *',
                          value: state.purchaseUnitId,
                          options: unitOptions,
                          errorText: state.fieldErrors['purchaseUnitId'],
                          onChanged: (val) => controller.setPurchaseUnit(val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildUomDropdown(
                          label: 'Outer Pack Unit',
                          value: state.outerPackUnitId,
                          options: unitOptions,
                          errorText: state.fieldErrors['outerPackUnitId'],
                          onChanged: (val) => controller.setOuterPackUnit(val),
                        ),
                      ),
                      const SizedBox(width: TenantAdminSpacing.lg),
                      Expanded(
                        child: _buildUomDropdown(
                          label: 'Selling Unit *',
                          value: state.sellingUnitId,
                          options: unitOptions,
                          errorText: state.fieldErrors['sellingUnitId'],
                          onChanged: (val) => controller.setSellingUnit(val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildNumberInput(
                          label: 'Items per Purchase Unit *',
                          controller: _itemsPerPurchaseController,
                          errorText: state.fieldErrors['itemsPerPurchaseUnit'],
                          hint: 'e.g. 6',
                          onChanged: (val) {
                            final parsed = num.tryParse(val);
                            controller.setItemsPerPurchaseUnit(parsed);
                          },
                        ),
                      ),
                      const SizedBox(width: TenantAdminSpacing.lg),
                      Expanded(
                        child: _buildNumberInput(
                          label: 'Purchase Units per Outer Pack',
                          controller: _purchaseUnitsPerOuterController,
                          enabled: state.outerPackUnitId != null &&
                              state.outerPackUnitId!.isNotEmpty,
                          errorText:
                              state.fieldErrors['purchaseUnitsPerOuterPack'],
                          hint: 'e.g. 12',
                          onChanged: (val) {
                            final parsed = num.tryParse(val);
                            controller.setPurchaseUnitsPerOuterPack(parsed);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildUomDropdown(
                    label: 'Base Unit *',
                    value: state.baseUnitId,
                    options: unitOptions,
                    errorText: state.fieldErrors['baseUnitId'],
                    onChanged: (val) => controller.setBaseUnit(val),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _buildUomDropdown(
                    label: 'Purchase Unit *',
                    value: state.purchaseUnitId,
                    options: unitOptions,
                    errorText: state.fieldErrors['purchaseUnitId'],
                    onChanged: (val) => controller.setPurchaseUnit(val),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _buildUomDropdown(
                    label: 'Outer Pack Unit',
                    value: state.outerPackUnitId,
                    options: unitOptions,
                    errorText: state.fieldErrors['outerPackUnitId'],
                    onChanged: (val) => controller.setOuterPackUnit(val),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _buildUomDropdown(
                    label: 'Selling Unit *',
                    value: state.sellingUnitId,
                    options: unitOptions,
                    errorText: state.fieldErrors['sellingUnitId'],
                    onChanged: (val) => controller.setSellingUnit(val),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _buildNumberInput(
                    label: 'Items per Purchase Unit *',
                    controller: _itemsPerPurchaseController,
                    errorText: state.fieldErrors['itemsPerPurchaseUnit'],
                    hint: 'e.g. 6',
                    onChanged: (val) {
                      final parsed = num.tryParse(val);
                      controller.setItemsPerPurchaseUnit(parsed);
                    },
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _buildNumberInput(
                    label: 'Purchase Units per Outer Pack',
                    controller: _purchaseUnitsPerOuterController,
                    enabled: state.outerPackUnitId != null &&
                        state.outerPackUnitId!.isNotEmpty,
                    errorText: state.fieldErrors['purchaseUnitsPerOuterPack'],
                    hint: 'e.g. 12',
                    onChanged: (val) {
                      final parsed = num.tryParse(val);
                      controller.setPurchaseUnitsPerOuterPack(parsed);
                    },
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: TenantAdminSpacing.lg),

        // Decimal Quantity Toggle
        _buildDecimalToggle(state, controller),
        const SizedBox(height: TenantAdminSpacing.xl),

        // Conversion Summary Card
        _buildConversionSummaryCard(
          baseUnit: baseUnit,
          purchaseUnit: purchaseUnit,
          outerPackUnit: outerPackUnit,
          itemsPerPurchase: state.itemsPerPurchaseUnit,
          purchaseUnitsPerOuter: state.purchaseUnitsPerOuterPack,
        ),
        const SizedBox(height: TenantAdminSpacing.xl),

        // Units & Pack Conversion Table
        _buildConversionTable(
          state: state,
          baseUnit: baseUnit,
          purchaseUnit: purchaseUnit,
          outerPackUnit: outerPackUnit,
          sellingUnit: sellingUnit,
          itemsPerPurchase: state.itemsPerPurchaseUnit,
          purchaseUnitsPerOuter: state.purchaseUnitsPerOuterPack,
        ),
        const SizedBox(height: TenantAdminSpacing.xl),

        // Informational Note Panel
        Container(
          padding: const EdgeInsets.all(TenantAdminSpacing.lg),
          decoration: BoxDecoration(
            color: TenantAdminColors.subtleBackground,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: TenantAdminColors.posHomeAccentOrange,
                size: 22,
              ),
              SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Text(
                  'This conversion setup is useful for buying in cartons, stocking in packs, and selling in pieces. It helps maintain accurate inventory and smooth sales operations.',
                  style: TextStyle(
                    fontSize: 13,
                    color: TenantAdminColors.mutedText,
                  ),
                ),
              ),
            ],
          ),
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
    bool enabled = true,
    String? errorText,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: enabled
                ? TenantAdminColors.bodyText
                : TenantAdminColors.mutedText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            filled: true,
            fillColor: enabled
                ? TenantAdminColors.surface
                : TenantAdminColors.subtleBackground,
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

  Widget _buildDecimalToggle(
    AddProductWizardState state,
    AddProductWizardController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.sm,
            vertical: TenantAdminSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Allow Decimal Quantity',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TenantAdminColors.bodyText,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Allow fractional quantities when the configured product supports them.',
                      style: TextStyle(
                        fontSize: 12,
                        color: TenantAdminColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: state.allowDecimalQuantity,
                activeColor: TenantAdminColors.posHomeAccentOrange,
                onChanged: (val) => controller.setAllowDecimalQuantity(val),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversionSummaryCard({
    required ProductUnitOption? baseUnit,
    required ProductUnitOption? purchaseUnit,
    required ProductUnitOption? outerPackUnit,
    required num? itemsPerPurchase,
    required num? purchaseUnitsPerOuter,
  }) {
    final lines = <String>[];

    if (purchaseUnit != null &&
        baseUnit != null &&
        itemsPerPurchase != null &&
        itemsPerPurchase > 0) {
      lines.add(
          '1 ${purchaseUnit.name} = ${_formatNumber(itemsPerPurchase)} ${baseUnit.name}s');
    }

    if (outerPackUnit != null &&
        purchaseUnit != null &&
        purchaseUnitsPerOuter != null &&
        purchaseUnitsPerOuter > 0) {
      lines.add(
          '1 ${outerPackUnit.name} = ${_formatNumber(purchaseUnitsPerOuter)} ${purchaseUnit.name}s');

      if (baseUnit != null &&
          itemsPerPurchase != null &&
          itemsPerPurchase > 0) {
        final totalBase = itemsPerPurchase * purchaseUnitsPerOuter;
        lines.add(
            '1 ${outerPackUnit.name} = ${_formatNumber(totalBase)} ${baseUnit.name}s');
      }
    }

    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
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
            'Conversion Summary',
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

  Widget _buildConversionTable({
    required AddProductWizardState state,
    required ProductUnitOption? baseUnit,
    required ProductUnitOption? purchaseUnit,
    required ProductUnitOption? outerPackUnit,
    required ProductUnitOption? sellingUnit,
    required num? itemsPerPurchase,
    required num? purchaseUnitsPerOuter,
  }) {
    final rows = <_TableDataRow>[];

    // Base Unit row
    if (baseUnit != null) {
      final isSelling = sellingUnit != null && sellingUnit.id == baseUnit.id;
      rows.add(_TableDataRow(
        unitName:
            '${baseUnit.name}${isSelling ? " (Selling & Base Unit)" : " (Base Unit)"}',
        conversionText: '1 ${baseUnit.name}',
        barcode: 'Assigned in Step 5',
        status: 'Active',
      ));
    }

    // Purchase Unit row
    if (purchaseUnit != null &&
        (baseUnit == null || purchaseUnit.id != baseUnit.id)) {
      final isSelling =
          sellingUnit != null && sellingUnit.id == purchaseUnit.id;
      final factor =
          itemsPerPurchase != null ? _formatNumber(itemsPerPurchase) : '1';
      final baseName = baseUnit?.name ?? 'Base Unit';
      rows.add(_TableDataRow(
        unitName:
            '${purchaseUnit.name}${isSelling ? " (Selling & Purchase Unit)" : ""}',
        conversionText: '1 ${purchaseUnit.name} = $factor ${baseName}s',
        barcode: 'Assigned in Step 5',
        status: 'Active',
      ));
    }

    // Outer Pack Unit row
    if (outerPackUnit != null &&
        (baseUnit == null || outerPackUnit.id != baseUnit.id) &&
        (purchaseUnit == null || outerPackUnit.id != purchaseUnit.id)) {
      final isSelling =
          sellingUnit != null && sellingUnit.id == outerPackUnit.id;
      final outerFactor = purchaseUnitsPerOuter != null
          ? _formatNumber(purchaseUnitsPerOuter)
          : '1';
      final purName = purchaseUnit?.name ?? 'Purchase Unit';
      final baseName = baseUnit?.name ?? 'Base Unit';

      String convText = '1 ${outerPackUnit.name} = $outerFactor ${purName}s';
      if (itemsPerPurchase != null && purchaseUnitsPerOuter != null) {
        final totalBase =
            _formatNumber(itemsPerPurchase * purchaseUnitsPerOuter);
        convText += ' ($totalBase ${baseName}s)';
      }

      rows.add(_TableDataRow(
        unitName: '${outerPackUnit.name}${isSelling ? " (Selling Unit)" : ""}',
        conversionText: convText,
        barcode: 'Assigned in Step 5',
        status: 'Active',
      ));
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Units & Pack Conversion Table',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(3),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(1),
            },
            children: [
              // Header
              TableRow(
                decoration: const BoxDecoration(
                  color: TenantAdminColors.subtleBackground,
                ),
                children: [
                  _buildTableHeaderCell('Unit Name'),
                  _buildTableHeaderCell('Conversion to Base Unit'),
                  _buildTableHeaderCell('Barcode'),
                  _buildTableHeaderCell('Status'),
                ],
              ),
              // Rows
              ...rows.map(
                (r) => TableRow(
                  children: [
                    _buildTableCell(r.unitName, isBold: true),
                    _buildTableCell(r.conversionText),
                    _buildTableCell(r.barcode, isMuted: true),
                    _buildTableCell(r.status, isStatus: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: TenantAdminColors.bodyText,
        ),
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    bool isBold = false,
    bool isMuted = false,
    bool isStatus = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      child: isStatus
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            )
          : Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                color: isMuted
                    ? TenantAdminColors.mutedText
                    : TenantAdminColors.bodyText,
              ),
            ),
    );
  }
}

class _TableDataRow {
  final String unitName;
  final String conversionText;
  final String barcode;
  final String status;

  const _TableDataRow({
    required this.unitName,
    required this.conversionText,
    required this.barcode,
    required this.status,
  });
}
