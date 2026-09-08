import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/customers_provider.dart';
import 'customers_ui_tokens.dart';

class CustomersSearchFilterToolbar extends StatelessWidget {
  const CustomersSearchFilterToolbar({
    super.key,
    required this.query,
    required this.statusFilter,
    required this.sourceFilter,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onSourceChanged,
    required this.onClear,
    required this.canAddCustomer,
    required this.onAddCustomer,
    this.canShowSearch = true,
    this.canShowFilters = true,
  });

  final String query;
  final CustomerStatusFilter statusFilter;
  final CustomerSourceFilter sourceFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<CustomerStatusFilter> onStatusChanged;
  final ValueChanged<CustomerSourceFilter> onSourceChanged;
  final VoidCallback onClear;
  final bool canAddCustomer;
  final VoidCallback onAddCustomer;
  final bool canShowSearch;
  final bool canShowFilters;

  @override
  Widget build(BuildContext context) {
    final showTopRow = canShowSearch || canAddCustomer;
    if (!showTopRow && !canShowFilters) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTopRow)
          Row(
            children: [
              if (canShowSearch)
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      key: const ValueKey('customer-search-input'),
                      controller: TextEditingController(text: query)
                        ..selection =
                            TextSelection.collapsed(offset: query.length),
                      onChanged: onSearchChanged,
                      decoration: InputDecoration(
                        hintText:
                            'Search customers by name, phone, email or code',
                        hintStyle: const TextStyle(
                          color: Color(0xFF8E9BAE),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF8E9BAE),
                          size: 20,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E6ED)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFE2E6ED)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: TenantAdminColors.posHomeAccentOrange,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),
              if (canAddCustomer) ...[
                if (canShowSearch) const SizedBox(width: 10),
                FilledButton.icon(
                  key: const ValueKey('customers-add-customer-button'),
                  onPressed: onAddCustomer,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text('Add Customer'),
                  style: FilledButton.styleFrom(
                    backgroundColor: TenantAdminColors.posHomeAccentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        if (showTopRow && canShowFilters) const SizedBox(height: 12),
        if (canShowFilters)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    color: Color(0xFF06235D),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusFilter(
                  value: statusFilter,
                  onChanged: onStatusChanged,
                ),
                const SizedBox(width: 16),
                const Text(
                  'Source',
                  style: TextStyle(
                    color: Color(0xFF06235D),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                _SourceFilter(
                  value: sourceFilter,
                  onChanged: onSourceChanged,
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    backgroundColor: CustomersUiTokens.lightBlueSurface,
                    foregroundColor: CustomersUiTokens.accentText,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(
                        color: CustomersUiTokens.lightBlueBorder,
                      ),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({
    required this.value,
    required this.onChanged,
  });

  final CustomerStatusFilter value;
  final ValueChanged<CustomerStatusFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E6ED)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CustomerStatusFilter>(
          key: ValueKey(value),
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF63718A), size: 18),
          style: const TextStyle(
            color: Color(0xFF06235D),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          items: const [
            DropdownMenuItem(
              value: CustomerStatusFilter.all,
              child: Text('All Status'),
            ),
            DropdownMenuItem(
              value: CustomerStatusFilter.active,
              child: Text('Active'),
            ),
            DropdownMenuItem(
              value: CustomerStatusFilter.inactive,
              child: Text('Inactive'),
            ),
            DropdownMenuItem(
              value: CustomerStatusFilter.blocked,
              child: Text('Blocked'),
            ),
          ],
          onChanged: (next) {
            if (next != null) {
              onChanged(next);
            }
          },
        ),
      ),
    );
  }
}

class _SourceFilter extends StatelessWidget {
  const _SourceFilter({
    required this.value,
    required this.onChanged,
  });

  final CustomerSourceFilter value;
  final ValueChanged<CustomerSourceFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E6ED)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CustomerSourceFilter>(
          key: ValueKey(value),
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF63718A), size: 18),
          style: const TextStyle(
            color: Color(0xFF06235D),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          items: const [
            DropdownMenuItem(
              value: CustomerSourceFilter.all,
              child: Text('All Source'),
            ),
            DropdownMenuItem(
              value: CustomerSourceFilter.pos,
              child: Text('POS'),
            ),
            DropdownMenuItem(
              value: CustomerSourceFilter.manual,
              child: Text('Manual'),
            ),
            DropdownMenuItem(
              value: CustomerSourceFilter.ecommerce,
              child: Text('E-commerce'),
            ),
            DropdownMenuItem(
              value: CustomerSourceFilter.clickAndCollect,
              child: Text('Click & Collect'),
            ),
            DropdownMenuItem(
              value: CustomerSourceFilter.import,
              child: Text('Import'),
            ),
          ],
          onChanged: (next) {
            if (next != null) {
              onChanged(next);
            }
          },
        ),
      ),
    );
  }
}
