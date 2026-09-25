// ignore_for_file: unused_local_variable, unused_field, unused_element, prefer_const_literals_to_create_immutables, unused_import, use_super_parameters
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/providers/outlet_visibility_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/domain/entities/outlet.dart';

class OutletAllocationForm extends ConsumerStatefulWidget {
  final AddProductWizardState state;
  final AddProductWizardController controller;

  const OutletAllocationForm({
    super.key,
    required this.state,
    required this.controller,
  });

  @override
  ConsumerState<OutletAllocationForm> createState() => _OutletAllocationFormState();
}

class _OutletAllocationFormState extends ConsumerState<OutletAllocationForm> {
  final Map<String, TextEditingController> _controllers = {};
  final Set<String> _manuallyAddedOutlets = {};
  String? _expandedOutletId;
  String _searchQuery = '';
  String _filterMode = 'Remaining Only';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(String variantKey, String outletId, num initialQty) {
    final key = '${variantKey}_$outletId';
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(text: initialQty > 0 ? initialQty.toString() : '');
    } else {
      final text = _controllers[key]!.text;
      final parsed = num.tryParse(text) ?? 0;
      if (parsed != initialQty && (text.isEmpty && initialQty > 0)) {
        _controllers[key]!.text = initialQty > 0 ? initialQty.toString() : '';
      }
    }
    return _controllers[key]!;
  }

  void _onAllocationChanged(String variantKey, String outletId, String value) {
    final qty = num.tryParse(value) ?? 0;
    widget.controller.updateOutletAllocation(variantKey, outletId, qty);
  }

  void _addOutlet(String outletId) {
    if (outletId.isEmpty) return;
    setState(() {
      _manuallyAddedOutlets.add(outletId);
      _expandedOutletId = outletId;
    });
  }
  
  void _removeOutlet(String outletId, List<String> variantKeys) {
    setState(() {
      _manuallyAddedOutlets.remove(outletId);
      if (_expandedOutletId == outletId) _expandedOutletId = null;
    });
    for (final k in variantKeys) {
      widget.controller.updateOutletAllocation(k, outletId, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final outletsAsync = ref.watch(outletListProvider);
    final isVariant = widget.state.productStructure == 'VARIANT';
    final allKeys = isVariant
        ? widget.state.step4State.generatedVariants.where((v) => v.isIncluded).map((v) => v.clientCombinationKey).toList()
        : ['SIMPLE'];
    
    // Filter out zero-opening variants
    final keys = allKeys.where((k) {
      final draft = widget.state.openingStockDrafts[k];
      return (draft?.openingQuantity ?? 0) > 0;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page Header
        const Text(
          'Outlet Allocation',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: TenantAdminColors.bodyText),
        ),
        const SizedBox(height: 4),
        const Text(
          'Allocate opening stock across your outlets.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
        ),
        const SizedBox(height: TenantAdminSpacing.xl),

        outletsAsync.when(
          data: (result) {
            final outlets = result?.items ?? [];
            if (outlets.isEmpty) {
              return const Center(child: Text('No authorized outlets found.'));
            }

            // Global Summary calculations
            num totalOpening = 0;
            num totalAllocated = 0;
            final Set<String> draftOutletIds = {};

            for (final k in keys) {
              final draft = widget.state.openingStockDrafts[k];
              if (draft != null) {
                totalOpening += draft.openingQuantity;
                for (final a in draft.allocations) {
                  totalAllocated += a.quantity;
                  if (a.quantity > 0) draftOutletIds.add(a.outletId);
                }
              }
            }
            final totalRemaining = totalOpening - totalAllocated;

            // Combine manual + draft outlets
            final selectedOutletIds = _manuallyAddedOutlets.union(draftOutletIds);
            final unselectedOutlets = outlets.where((o) => !selectedOutletIds.contains(o.id)).toList();

            // Set default expanded if null and only 1
            if (_expandedOutletId == null && selectedOutletIds.length == 1) {
              _expandedOutletId = selectedOutletIds.first;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGlobalSummary(totalOpening, totalAllocated, totalRemaining),
                const SizedBox(height: TenantAdminSpacing.xl),
                
                // Add Outlet Button - Always show
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddOutletBottomSheet(context, unselectedOutlets),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Allocate Outlet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6A00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.xl),

                if (selectedOutletIds.isEmpty)
                  _buildEmptyState(unselectedOutlets)
                else
                  ...selectedOutletIds.map((oId) {
                    final outlet = outlets.firstWhere((o) => o.id == oId, orElse: () => Outlet(id: oId, name: 'Unknown Outlet', code: '', status: ''));
                    return _buildOutletPanel(outlet, keys, isVariant, unselectedOutlets);
                  }),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const Center(child: Text('Error loading outlets')),
        ),

      ],
    );
  }

  Widget _buildEmptyState(List<Outlet> unselectedOutlets) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.store_outlined, size: 48, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          const Text('No outlets added yet.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          const Text('Add an outlet to distribute the opening stock.', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          if (unselectedOutlets.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () => _showAddOutletBottomSheet(context, unselectedOutlets),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Allocate Outlet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6A00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddOutletForVariantBottomSheet(BuildContext context, List<Outlet> availableOutlets, String variantKey, num remainingQty) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String modalSearch = '';
            final filtered = availableOutlets.where((o) => o.name.toLowerCase().contains(modalSearch.toLowerCase()) || o.code.toLowerCase().contains(modalSearch.toLowerCase())).toList();
            
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Select Outlet to Allocate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (availableOutlets.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'All authorized outlets have already been added.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ),
                      )
                    else ...[
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search outlet...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => setModalState(() => modalSearch = v),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final o = filtered[index];
                            return ListTile(
                              title: Text(o.name),
                              subtitle: o.code.isNotEmpty ? Text(o.code) : null,
                              onTap: () {
                                setState(() {
                                  _manuallyAddedOutlets.add(o.id);
                                  _expandedOutletId = o.id;
                                  
                                  final newQtyStr = remainingQty.toInt().toString();
                                  _controllers['${variantKey}_${o.id}'] = TextEditingController(text: newQtyStr);
                                  _onAllocationChanged(variantKey, o.id, newQtyStr);
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }

  void _showAddOutletBottomSheet(BuildContext context, List<Outlet> unselectedOutlets) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String modalSearch = '';
            final filtered = unselectedOutlets.where((o) => o.name.toLowerCase().contains(modalSearch.toLowerCase()) || o.code.toLowerCase().contains(modalSearch.toLowerCase())).toList();
            
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Select Outlet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (unselectedOutlets.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text(
                            'All authorized outlets have already been added.',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ),
                      )
                    else ...[
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search outlet...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => setModalState(() => modalSearch = v),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final o = filtered[index];
                            return ListTile(
                              title: Text(o.name),
                              subtitle: o.code.isNotEmpty ? Text(o.code) : null,
                              onTap: () {
                                _addOutlet(o.id);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildGlobalSummary(num totalOpening, num totalAllocated, num totalRemaining) {
    final hasError = totalRemaining < 0;
    final isComplete = totalRemaining == 0 && totalOpening > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: hasError ? const Color(0xFFEF4444) : (isComplete ? const Color(0xFF10B981) : const Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryStat('Total Opening Stock', totalOpening),
          const SizedBox(width: 1, height: 48, child: ColoredBox(color: Color(0xFFE2E8F0))),
          _buildSummaryStat('Total Allocated', totalAllocated),
          const SizedBox(width: 1, height: 48, child: ColoredBox(color: Color(0xFFE2E8F0))),
          _buildSummaryStat(
            'Total Remaining', 
            totalRemaining, 
            textColor: hasError ? const Color(0xFFEF4444) : (totalRemaining > 0 ? const Color(0xFFFF6A00) : const Color(0xFF10B981))
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, num value, {Color? textColor}) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Text(
            value.toInt().toString(),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor ?? TenantAdminColors.bodyText),
          ),
        ],
      ),
    );
  }

  Widget _buildOutletPanel(Outlet outlet, List<String> keys, bool isVariant, List<Outlet> unselectedOutlets) {
    final isExpanded = _expandedOutletId == outlet.id;
    
    // Calculate Outlet Totals
    num outletAllocated = 0;
    int variantsCount = 0;
    bool allVariantsComplete = true;

    for (final k in keys) {
      final draft = widget.state.openingStockDrafts[k];
      if (draft != null) {
        num qty = 0;
        try {
          qty = draft.allocations.firstWhere((a) => a.outletId == outlet.id).quantity;
        } catch (_) {}
        outletAllocated += qty;
        if (qty > 0) variantsCount++;

        final totalAllocForVariant = draft.allocations.fold<num>(0, (s, a) => s + a.quantity);
        if (totalAllocForVariant < draft.openingQuantity) allVariantsComplete = false;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _expandedOutletId = isExpanded ? null : outlet.id;
              });
            },
            borderRadius: BorderRadius.vertical(top: const Radius.circular(10), bottom: Radius.circular(isExpanded ? 0 : 10)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(outlet.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        if (outlet.code.isNotEmpty)
                          Text(outlet.code, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  if (!isExpanded) ...[
                     Column(
                       crossAxisAlignment: CrossAxisAlignment.end,
                       children: [
                         Text('Allocated: ${outletAllocated.toInt()}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                         Text('$variantsCount variants', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                       ],
                     ),
                     const SizedBox(width: 16),
                  ],
                  if (allVariantsComplete && !isExpanded)
                    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20)
                  else if (!isExpanded)
                    const Icon(Icons.pending, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 8),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
          
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            _buildOutletContent(outlet, keys, isVariant, unselectedOutlets),
          ],
        ],
      ),
    );
  }

  Widget _buildOutletContent(Outlet outlet, List<String> keys, bool isVariant, List<Outlet> unselectedOutlets) {
    // Apply filters
    List<String> displayKeys = keys;
    if (_searchQuery.isNotEmpty && isVariant) {
      displayKeys = displayKeys.where((k) {
        final v = widget.state.step4State.generatedVariants.firstWhere((v) => v.clientCombinationKey == k);
        final label = (v.displayLabel ?? v.combinationLabel).toLowerCase();
        return label.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    if (_filterMode == 'Remaining Only') {
      displayKeys = displayKeys.where((k) {
        final draft = widget.state.openingStockDrafts[k];
        final opening = draft?.openingQuantity ?? 0;
        final allocated = draft?.allocations.fold<num>(0, (s, a) => s + a.quantity) ?? 0;
        return (opening - allocated) > 0;
      }).toList();
    } else if (_filterMode == 'Allocated') {
      displayKeys = displayKeys.where((k) {
        final draft = widget.state.openingStockDrafts[k];
        num qty = 0;
        try { qty = draft!.allocations.firstWhere((a) => a.outletId == outlet.id).quantity; } catch (_) {}
        return qty > 0;
      }).toList();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               if (isVariant)
                 Expanded(
                   child: SizedBox(
                     height: 36,
                     child: TextField(
                       decoration: const InputDecoration(
                         hintText: 'Search Variant',
                         prefixIcon: Icon(Icons.search, size: 18),
                         border: OutlineInputBorder(),
                         contentPadding: EdgeInsets.zero,
                       ),
                       onChanged: (v) => setState(() => _searchQuery = v),
                     ),
                   ),
                 )
               else
                 const Spacer(),
                 
               const SizedBox(width: 16),
               
               SegmentedButton<String>(
                 segments: const [
                   ButtonSegment(value: 'All', label: Text('All', style: TextStyle(fontSize: 12))),
                   ButtonSegment(value: 'Remaining Only', label: Text('Remaining', style: TextStyle(fontSize: 12))),
                   ButtonSegment(value: 'Allocated', label: Text('Allocated', style: TextStyle(fontSize: 12))),
                 ],
                 selected: {_filterMode},
                 onSelectionChanged: (Set<String> newSelection) {
                   setState(() => _filterMode = newSelection.first);
                 },
                 style: const ButtonStyle(visualDensity: VisualDensity.compact),
               ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Header Row
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Variant', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                Expanded(flex: 1, child: Text('Opening', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                Expanded(flex: 1, child: Text('Already', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                Expanded(flex: 1, child: Text('Remain', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('Allocate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          
          if (displayKeys.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No variants match the current filter.', style: TextStyle(color: Color(0xFF94A3B8)))),
            )
          else
            ...displayKeys.map((k) {
              return _buildVariantRow(k, outlet.id, isVariant, unselectedOutlets);
            }),
            
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _removeOutlet(outlet.id, keys),
              icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
              label: const Text('Remove Outlet', style: TextStyle(color: Color(0xFFEF4444))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantRow(String variantKey, String outletId, bool isVariant, List<Outlet> unselectedOutlets) {
    String label = 'Product';
    String sku = '';
    if (isVariant) {
      final v = widget.state.step4State.generatedVariants.firstWhere((v) => v.clientCombinationKey == variantKey);
      label = v.displayLabel ?? v.combinationLabel;
      try { sku = widget.state.step5State.assignments.firstWhere((a) => a.clientCombinationKey == variantKey).sku ?? ''; } catch (_) {}
    }

    final draft = widget.state.openingStockDrafts[variantKey];
    final opening = draft?.openingQuantity ?? 0;
    
    num currentQty = 0;
    num alreadyAllocated = 0;
    
    if (draft != null) {
      for (final a in draft.allocations) {
        if (a.outletId == outletId) {
          currentQty = a.quantity;
        } else {
          alreadyAllocated += a.quantity;
        }
      }
    }
    
    // Projected remaining based on current typed value
    final typedText = _controllers['${variantKey}_$outletId']?.text ?? '';
    final typedQty = num.tryParse(typedText) ?? 0;
    final projectedRemaining = opening - alreadyAllocated - typedQty;
    final isError = projectedRemaining < 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top for multi-line
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: TenantAdminColors.bodyText)),
                if (sku.isNotEmpty) Text('SKU: $sku', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          // Opening Quantity
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                opening.toInt().toString(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TenantAdminColors.bodyText,
                ),
              ),
            ),
          ),
          // Already Allocated
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                alreadyAllocated.toInt().toString(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
          // Remaining
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                projectedRemaining.toInt().toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isError
                      ? const Color(0xFFEF4444)
                      : (projectedRemaining > 0 ? const Color(0xFFFF6A00) : const Color(0xFF10B981)),
                ),
              ),
            ),
          ),
          // Quantity Input & Action
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  height: 36,
                  child: Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        _onAllocationChanged(variantKey, outletId, _controllers['${variantKey}_$outletId']?.text ?? '');
                        setState(() {});
                      }
                    },
                    child: TextField(
                      controller: _getController(variantKey, outletId, currentQty),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        hintText: '0',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFCBD5E1),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: isError ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                            width: 1.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: isError ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: BorderSide(
                            color: isError ? const Color(0xFFEF4444) : const Color(0xFFFF6A00),
                            width: 1.5,
                          ),
                        ),
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      onEditingComplete: () {
                        _onAllocationChanged(variantKey, outletId, _controllers['${variantKey}_$outletId']?.text ?? '');
                        setState(() {});
                        FocusScope.of(context).nextFocus();
                      },
                      onChanged: (val) {
                        // User requested NOT to update in real-time as they type.
                        // State is updated on focus loss or on next (onEditingComplete).
                      },
                    ),
                  ),
                ),
                if (projectedRemaining > 0 && unselectedOutlets.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _showAddOutletForVariantBottomSheet(context, unselectedOutlets, variantKey, projectedRemaining);
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_circle_outline, size: 14, color: Color(0xFFFF6A00)),
                              const SizedBox(width: 4),
                              const Text(
                                'Allocate Outlet',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFF6A00),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
