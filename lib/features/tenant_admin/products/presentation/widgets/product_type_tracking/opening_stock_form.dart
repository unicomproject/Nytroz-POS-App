// ignore_for_file: unused_local_variable, unused_field, unused_element, prefer_const_literals_to_create_immutables, unused_import, use_super_parameters
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';

class OpeningStockForm extends ConsumerStatefulWidget {
  final AddProductWizardState state;
  final AddProductWizardController controller;
  final String variantKey; // 'SIMPLE' or 'VARIANT'

  const OpeningStockForm({
    super.key,
    required this.state,
    required this.controller,
    required this.variantKey,
  });

  @override
  ConsumerState<OpeningStockForm> createState() => _OpeningStockFormState();
}

class _OpeningStockFormState extends ConsumerState<OpeningStockForm> {
  final Map<String, TextEditingController> _controllers = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    if (widget.variantKey == 'SIMPLE') {
      final draft = widget.state.openingStockDrafts['SIMPLE'];
      _controllers['SIMPLE'] = TextEditingController(
        text: draft != null && draft.openingQuantity > 0 ? draft.openingQuantity.toString() : '',
      );
    } else {
      final included = widget.state.step4State.generatedVariants.where((v) => v.isIncluded);
      for (final v in included) {
        final draft = widget.state.openingStockDrafts[v.clientCombinationKey];
        _controllers[v.clientCombinationKey] = TextEditingController(
          text: draft != null && draft.openingQuantity > 0 ? draft.openingQuantity.toString() : '',
        );
      }
    }
  }

  @override
  void didUpdateWidget(OpeningStockForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.variantKey != widget.variantKey) {
      for (final c in _controllers.values) {
        c.dispose();
      }
      _controllers.clear();
      _initControllers();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onQuantityChanged(String key, String value) {
    final qty = num.tryParse(value) ?? 0;
    widget.controller.updateOpeningStockQuantity(key, qty);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total for variants
    num totalOpening = 0;
    if (widget.variantKey == 'VARIANT') {
      final included = widget.state.step4State.generatedVariants.where((v) => v.isIncluded);
      for (final v in included) {
        final draft = widget.state.openingStockDrafts[v.clientCombinationKey];
        if (draft != null) {
          totalOpening += draft.openingQuantity;
        }
      }
    } else {
      final draft = widget.state.openingStockDrafts['SIMPLE'];
      if (draft != null) {
        totalOpening = draft.openingQuantity;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opening Stock',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Define the initial stock quantity for this product before allocating it to outlets.',
          style: TextStyle(
            fontSize: 13,
            color: TenantAdminColors.mutedText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xl),



        if (widget.variantKey == 'SIMPLE')
          _buildSimpleStockCard(totalOpening)
        else
          _buildVariantStockList(totalOpening),

        const SizedBox(height: TenantAdminSpacing.xl),
        const Divider(height: 1, color: TenantAdminColors.border),
        const SizedBox(height: TenantAdminSpacing.lg),

      ],
    );
  }

  Widget _buildSimpleStockCard(num totalOpening) {
    final sku = widget.state.step5State.baseSku.trim().isNotEmpty
        ? widget.state.step5State.baseSku
        : widget.state.step5State.assignments
            .where((a) => a.clientCombinationKey == 'SIMPLE_DEFAULT')
            .map((a) => a.sku)
            .firstWhere((s) => s != null && s.trim().isNotEmpty, orElse: () => null) ?? 'No SKU';

    final draft = widget.state.openingStockDrafts['SIMPLE'];
    final quantity = draft?.openingQuantity ?? 0;
    final currentQty = int.tryParse(_controllers['SIMPLE']?.text ?? '0') ?? 0;

    // Calculate values
    final costPrice = widget.state.costPrice;
    final hasCost = costPrice != null;
    final openingValue = hasCost ? (quantity * costPrice) : null;

    // Find Unit
    final unitName = widget.state.baseUnitId ?? 'Unit'; // In real app we'd resolve the name from ID

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_outlined,
                  color: Color(0xFF94A3B8), size: 24),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.state.productName.isEmpty ? 'Untitled Product' : widget.state.productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: TenantAdminColors.bodyText,
                      ),
                    ),
                    Text(
                      'SKU: $sku',
                      style: const TextStyle(
                        fontSize: 12,
                        color: TenantAdminColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          const Divider(height: 1, color: TenantAdminColors.border),
          const SizedBox(height: TenantAdminSpacing.lg),

          // Quantity Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Opening Quantity',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TenantAdminColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Base Unit: $unitName',
                      style: const TextStyle(
                        fontSize: 11,
                        color: TenantAdminColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD8E0EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Minus Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: currentQty > 0 ? () {
                          final newQty = currentQty - 1;
                          _controllers['SIMPLE']!.text = newQty.toString();
                          _onQuantityChanged('SIMPLE', newQty.toString());
                          setState(() {});
                        } : null,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Icon(
                            Icons.remove,
                            size: 18,
                            color: currentQty > 0
                              ? const Color(0xFF64748B)
                              : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                    ),
                    // Text Input Field
                    Expanded(
                      child: TextField(
                        controller: _controllers['SIMPLE'],
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                          hintText: '0',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: TenantAdminColors.bodyText,
                        ),
                        onChanged: (val) {
                          _onQuantityChanged('SIMPLE', val);
                        },
                      ),
                    ),
                    // Plus Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final newQty = currentQty + 1;
                          _controllers['SIMPLE']!.text = newQty.toString();
                          _onQuantityChanged('SIMPLE', newQty.toString());
                          setState(() {});
                        },
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Icon(
                            Icons.add,
                            size: 18,
                            color: const Color(0xFFFF6A00),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                unitName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: TenantAdminColors.mutedText,
                ),
              ),
            ],
          ),

          if (hasCost) ...[
            const SizedBox(height: TenantAdminSpacing.lg),
            const Divider(height: 1, color: TenantAdminColors.border),
            const SizedBox(height: TenantAdminSpacing.lg),
            // Cost Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unit Cost',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TenantAdminColors.bodyText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'LKR ${costPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6A00),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Opening Stock Value',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TenantAdminColors.bodyText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'LKR ${openingValue?.toStringAsFixed(2) ?? "0.00"}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVariantStockList(num totalOpening) {
    final included = widget.state.step4State.generatedVariants.where((v) => v.isIncluded).toList();
    if (included.isEmpty) return const Text('No variants included.');

    // Filter variants based on search
    final filtered = included.where((v) {
      if (_searchQuery.isEmpty) return true;
      final label = (v.displayLabel ?? v.combinationLabel).toLowerCase();
      return label.contains(_searchQuery);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.state.productName.isEmpty ? 'Untitled Product' : widget.state.productName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const Text(
          'Set opening stock quantities for each variant',
          style: TextStyle(fontSize: 14, color: TenantAdminColors.mutedText),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),

        // Search Bar
        TextFormField(
          decoration: InputDecoration(
            hintText: 'Search by variant name or SKU...',
            prefixIcon: const Icon(Icons.search, color: TenantAdminColors.mutedText),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 1.5),
            ),
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val.toLowerCase();
            });
          },
        ),
        const SizedBox(height: TenantAdminSpacing.lg),

        // Variants List with Cards
        filtered.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.search_off, size: 48, color: TenantAdminColors.mutedText),
                      const SizedBox(height: 12),
                      Text(
                        'No variants found',
                        style: TextStyle(
                          fontSize: 14,
                          color: TenantAdminColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const SizedBox(height: TenantAdminSpacing.md),
                itemBuilder: (context, index) {
                  final v = filtered[index];
                  final label = v.displayLabel ?? v.combinationLabel;

                  final assignment = widget.state.step5State.assignments.firstWhere(
                    (a) => a.clientCombinationKey == v.clientCombinationKey,
                    orElse: () => throw StateError('Missing assignment'),
                  );
                  final sku = assignment.sku ?? 'No SKU';
                  final currentQty = int.tryParse(_controllers[v.clientCombinationKey]?.text ?? '0') ?? 0;

                  return Container(
                    padding: const EdgeInsets.all(TenantAdminSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                      border: Border.all(color: TenantAdminColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Variant Header
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.shopping_bag_outlined,
                                color: Color(0xFF94A3B8), size: 20),
                            ),
                            const SizedBox(width: TenantAdminSpacing.md),
                            Expanded(
                              child: Column(
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
                                  Text(
                                    'SKU: $sku',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: TenantAdminColors.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: TenantAdminSpacing.lg),

                        // Quantity Control
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Opening Quantity',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: TenantAdminColors.mutedText,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFD8E0EB)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Minus Button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: currentQty > 0 ? () {
                                        final newQty = currentQty - 1;
                                        _controllers[v.clientCombinationKey]!.text = newQty.toString();
                                        _onQuantityChanged(v.clientCombinationKey, newQty.toString());
                                        setState(() {});
                                      } : null,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        child: Icon(
                                          Icons.remove,
                                          size: 18,
                                          color: currentQty > 0
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Text Input Field
                                  SizedBox(
                                    width: 60,
                                    child: TextField(
                                      controller: _controllers[v.clientCombinationKey],
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                                        hintText: '0',
                                        hintStyle: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: TenantAdminColors.bodyText,
                                      ),
                                      onChanged: (val) {
                                        _onQuantityChanged(v.clientCombinationKey, val);
                                      },
                                    ),
                                  ),
                                  // Plus Button
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        final newQty = currentQty + 1;
                                        _controllers[v.clientCombinationKey]!.text = newQty.toString();
                                        _onQuantityChanged(v.clientCombinationKey, newQty.toString());
                                        setState(() {});
                                      },
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        child: Icon(
                                          Icons.add,
                                          size: 18,
                                          color: const Color(0xFFFF6A00),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'pcs',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: TenantAdminColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }
}
