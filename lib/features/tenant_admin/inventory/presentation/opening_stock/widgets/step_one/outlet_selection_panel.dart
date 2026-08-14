import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/opening_stock_providers.dart';
import 'outlet_list_tile.dart';
import 'selection_summary_card.dart';
import 'opening_stock_info_banner.dart';

class OutletSelectionPanel extends ConsumerStatefulWidget {
  const OutletSelectionPanel({super.key});

  @override
  ConsumerState<OutletSelectionPanel> createState() =>
      _OutletSelectionPanelState();
}

class _OutletSelectionPanelState extends ConsumerState<OutletSelectionPanel> {
  final _searchController = TextEditingController();
  String _selectedType = 'All Types';

  static const primaryOrange = Color(0xFFFF6A00);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(openingStockProvider);
    final notifier = ref.read(openingStockProvider.notifier);
    final outletsAsync = ref.watch(openingStockOutletsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Outlet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Choose the outlet where opening stock will be added',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(openingStockOutletSearchProvider.notifier).state =
                        val;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search outlet or warehouse',
                    hintStyle:
                        TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon:
                        Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(
                      fontSize: 13, color: TenantAdminColors.bodyText),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedType,
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      size: 18, color: Color(0xFF64748B)),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'All Types',
                      child: Row(
                        children: [
                          Icon(Icons.filter_list,
                              size: 15, color: Color(0xFF64748B)),
                          SizedBox(width: 4),
                          Text('All Types'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(value: 'Outlet', child: Text('Outlets')),
                    DropdownMenuItem(
                        value: 'Warehouse', child: Text('Warehouses')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedType = val);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Outlet / Warehouse',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'Type',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: outletsAsync.when(
            data: (allOutlets) {
              final filteredOutlets = allOutlets.where((o) {
                if (_selectedType == 'Outlet') {
                  return o.outletType?.toLowerCase() != 'warehouse' &&
                      !o.name.toLowerCase().contains('warehouse');
                } else if (_selectedType == 'Warehouse') {
                  return o.outletType?.toLowerCase() == 'warehouse' ||
                      o.name.toLowerCase().contains('warehouse');
                }
                return true;
              }).toList();

              if (filteredOutlets.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.storefront_outlined,
                          size: 36, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 6),
                      Text(
                        'No outlets found',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredOutlets.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final outlet = filteredOutlets[index];
                        final isSelected =
                            state.selectedOutlet?.id == outlet.id;

                        return OutletListTile(
                          outlet: outlet,
                          isSelected: isSelected,
                          onTap: () => notifier.selectOutlet(outlet),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${filteredOutlets.length} of ${allOutlets.length} outlets',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                  color: primaryOrange, strokeWidth: 2.5),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Failed to load outlets: $err',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SelectionSummaryCard(
          selectedProduct: state.selectedProduct,
          selectedOutlet: state.selectedOutlet,
        ),
        const SizedBox(height: 8),
        const OpeningStockInfoBanner(),
      ],
    );
  }
}
