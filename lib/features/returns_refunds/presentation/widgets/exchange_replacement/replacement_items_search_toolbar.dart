import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ReplacementItemsSearchToolbar extends StatefulWidget {
  const ReplacementItemsSearchToolbar({
    super.key,
    required this.query,
    required this.showFilters,
    required this.inStockOnly,
    required this.onQueryChanged,
    required this.onToggleFilters,
    required this.onInStockOnlyChanged,
  });

  final String query;
  final bool showFilters;
  final bool inStockOnly;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onToggleFilters;
  final ValueChanged<bool> onInStockOnlyChanged;

  @override
  State<ReplacementItemsSearchToolbar> createState() =>
      _ReplacementItemsSearchToolbarState();
}

class _ReplacementItemsSearchToolbarState
    extends State<ReplacementItemsSearchToolbar> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant ReplacementItemsSearchToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.text = widget.query;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Search by product name, SKU, or barcode',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _controller.clear();
                            widget.onQueryChanged('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: TenantAdminColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                    borderSide:
                        const BorderSide(color: TenantAdminColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                    borderSide:
                        const BorderSide(color: TenantAdminColors.border),
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    widget.onQueryChanged(value);
                  });
                },
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            OutlinedButton.icon(
              onPressed: widget.onToggleFilters,
              icon: const Icon(Icons.filter_list_rounded, size: 18),
              label: const Text('Filters'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
                backgroundColor: widget.showFilters
                    ? TenantAdminColors.primary.withValues(alpha: 0.08)
                    : TenantAdminColors.surface,
                foregroundColor: widget.showFilters
                    ? TenantAdminColors.primary
                    : TenantAdminColors.bodyText,
                side: BorderSide(
                  color: widget.showFilters
                      ? TenantAdminColors.primary
                      : TenantAdminColors.border,
                ),
              ),
            ),
          ],
        ),
        if (widget.showFilters) ...[
          const SizedBox(height: TenantAdminSpacing.sm),
          FilterChip(
            label: const Text('In stock only'),
            selected: widget.inStockOnly,
            onSelected: widget.onInStockOnlyChanged,
          ),
        ],
      ],
    );
  }
}
