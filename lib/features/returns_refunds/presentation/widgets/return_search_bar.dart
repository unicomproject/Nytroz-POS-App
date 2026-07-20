import 'dart:async';

import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ReturnSearchBar extends StatefulWidget {
  const ReturnSearchBar({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.onSearch,
    required this.onToggleFilters,
    this.showFilters = false,
    this.activeFilterCount = 0,
    this.isLoading = false,
  });

  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSearch;
  final VoidCallback onToggleFilters;
  final bool showFilters;
  final int activeFilterCount;
  final bool isLoading;

  @override
  State<ReturnSearchBar> createState() => _ReturnSearchBarState();
}

class _ReturnSearchBarState extends State<ReturnSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant ReturnSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically =
            constraints.maxWidth < TenantAdminBreakpoints.mobile;
        final filterButton = stackVertically
            ? SizedBox(
                width: 44,
                height: 44,
                child: OutlinedButton(
                  onPressed: widget.isLoading ? null : widget.onToggleFilters,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: widget.showFilters
                        ? TenantAdminColors.primary.withValues(alpha: 0.08)
                        : TenantAdminColors.surface,
                    side: BorderSide(
                      color: widget.showFilters
                          ? TenantAdminColors.primary
                          : TenantAdminColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                    ),
                  ),
                  child: const Icon(Icons.filter_list_rounded, size: 18),
                ),
              )
            : OutlinedButton.icon(
                onPressed: widget.isLoading ? null : widget.onToggleFilters,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(104, 44),
                  backgroundColor: widget.showFilters
                      ? TenantAdminColors.primary.withValues(alpha: 0.08)
                      : TenantAdminColors.surface,
                  side: BorderSide(
                    color: widget.showFilters
                        ? TenantAdminColors.primary
                        : TenantAdminColors.border,
                  ),
                ),
                icon: const Icon(Icons.filter_list_rounded, size: 18),
                label: Text(
                  widget.activeFilterCount == 0
                      ? 'Filters'
                      : 'Filters (${widget.activeFilterCount})',
                ),
              );

        final field = SizedBox(
          height: 44,
          child: TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: (_) {
              if (!widget.isLoading) {
                widget.onSearch();
              }
            },
            decoration: InputDecoration(
              hintText: 'Search by invoice no, mobile number, customer name',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _controller.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: _clear,
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
              filled: true,
              fillColor: TenantAdminColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.lg,
                vertical: TenantAdminSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                borderSide: const BorderSide(color: TenantAdminColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                borderSide: const BorderSide(color: TenantAdminColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                borderSide: const BorderSide(color: TenantAdminColors.primary),
              ),
            ),
          ),
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: field),
            const SizedBox(width: TenantAdminSpacing.md),
            filterButton,
          ],
        );
      },
    );
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onQueryChanged(value);
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    widget.onQueryChanged('');
    setState(() {});
  }
}
