import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product.dart';
import '../../providers/opening_stock_providers.dart';
import 'product_list_tile.dart';

class ProductSelectionPanel extends ConsumerStatefulWidget {
  const ProductSelectionPanel({super.key});

  @override
  ConsumerState<ProductSelectionPanel> createState() =>
      _ProductSelectionPanelState();
}

class _ProductSelectionPanelState extends ConsumerState<ProductSelectionPanel> {
  final _searchController = TextEditingController();
  String _selectedSort = 'Product A-Z';
  int _currentPage = 1;
  final int _itemsPerPage = 6;

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
    final productsAsync = ref.watch(openingStockProductsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Product',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Search or scan to find the product',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(openingStockProductSearchProvider.notifier).state =
                        val;
                    setState(() => _currentPage = 1);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search by product name, SKU or scan barcode',
                    hintStyle:
                        TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(
                      fontSize: 13, color: TenantAdminColors.bodyText),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear,
                      size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(openingStockProductSearchProvider.notifier).state =
                        '';
                    setState(() => _currentPage = 1);
                  },
                ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(Icons.qr_code_scanner,
                    color: Color(0xFF64748B), size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        productsAsync.when(
          data: (allProducts) {
            final sortedProducts = List<TenantProduct>.from(allProducts);
            if (_selectedSort == 'Product A-Z') {
              sortedProducts.sort((a, b) =>
                  a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            } else if (_selectedSort == 'Product Z-A') {
              sortedProducts.sort((a, b) =>
                  b.name.toLowerCase().compareTo(a.name.toLowerCase()));
            } else if (_selectedSort == 'SKU') {
              sortedProducts.sort(
                  (a, b) => a.sku.toLowerCase().compareTo(b.sku.toLowerCase()));
            }

            final totalItems = sortedProducts.length;
            final totalPages =
                (totalItems / _itemsPerPage).ceil().clamp(1, 999);
            final startIndex = (_currentPage - 1) * _itemsPerPage;
            final pageItems =
                sortedProducts.skip(startIndex).take(_itemsPerPage).toList();

            return Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$totalItems products found',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSort,
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
                                  value: 'Product A-Z',
                                  child: Text('Sort by: Product A-Z')),
                              DropdownMenuItem(
                                  value: 'Product Z-A',
                                  child: Text('Sort by: Product Z-A')),
                              DropdownMenuItem(
                                  value: 'SKU', child: Text('Sort by: SKU')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedSort = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: pageItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.inventory_2_outlined,
                                    size: 40, color: Color(0xFFCBD5E1)),
                                SizedBox(height: 8),
                                Text(
                                  'No products match your search.',
                                  style: TextStyle(
                                      color: Color(0xFF94A3B8), fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: pageItems.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final product = pageItems[index];
                              final isSelected =
                                  state.selectedProduct?.id == product.id;

                              return ProductListTile(
                                product: product,
                                isSelected: isSelected,
                                onTap: () => notifier.selectProduct(product),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  if (totalPages > 1)
                    _PaginationBar(
                      currentPage: _currentPage,
                      totalPages: totalPages,
                      onPageChanged: (page) =>
                          setState(() => _currentPage = page),
                    ),
                ],
              ),
            );
          },
          loading: () => const Expanded(
            child: Center(
              child: CircularProgressIndicator(
                  color: primaryOrange, strokeWidth: 2.5),
            ),
          ),
          error: (err, stack) => Expanded(
            child: Center(
              child: Text(
                'Failed to load products: $err',
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _PageArrowButton(
          icon: Icons.chevron_left,
          enabled: currentPage > 1,
          onTap: () => onPageChanged(currentPage - 1),
        ),
        const SizedBox(width: 4),
        for (int p = 1; p <= totalPages; p++) ...[
          if (totalPages <= 7 ||
              p == 1 ||
              p == totalPages ||
              (p >= currentPage - 1 && p <= currentPage + 1))
            _PageNumberButton(
              page: p,
              isActive: p == currentPage,
              onTap: () => onPageChanged(p),
            )
          else if (p == currentPage - 2 || p == currentPage + 2)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('...',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ),
        ],
        const SizedBox(width: 4),
        _PageArrowButton(
          icon: Icons.chevron_right,
          enabled: currentPage < totalPages,
          onTap: () => onPageChanged(currentPage + 1),
        ),
      ],
    );
  }
}

class _PageNumberButton extends StatelessWidget {
  const _PageNumberButton({
    required this.page,
    required this.isActive,
    required this.onTap,
  });

  final int page;
  final bool isActive;
  final VoidCallback onTap;

  static const primaryOrange = Color(0xFFFF6A00);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? primaryOrange : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? primaryOrange : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

class _PageArrowButton extends StatelessWidget {
  const _PageArrowButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}
