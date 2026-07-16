import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../domain/entities/report_models.dart';
import '../../../domain/entities/report_query.dart';
import '../../providers/report_providers.dart';
import '../../utils/report_formatters.dart';

class ReportFilterBar extends StatefulWidget {
  const ReportFilterBar({
    super.key,
    required this.scope,
    required this.query,
    required this.notifier,
    required this.outlets,
    this.filterOptions,
    required this.onApply,
    required this.onClear,
  });

  final ReportScope scope;
  final ReportQuery query;
  final ReportQueryNotifier notifier;
  final List<ReportFilterOption> outlets;
  final ReportFilterOptions? filterOptions;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  State<ReportFilterBar> createState() => _ReportFilterBarState();
}

class _ReportFilterBarState extends State<ReportFilterBar> {
  late final TextEditingController _searchController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query.search ?? '');
  }

  @override
  void didUpdateWidget(covariant ReportFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.query.search ?? '';
    if (_searchController.text != next) {
      _searchController.text = next;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final optionalFilterCount = _activeFilterCount;
    final validationMessage = widget.query.validate(datesRequired: true);
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 600;
        if (mobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openFilterSheet,
                  icon: const Icon(Icons.tune),
                  label: Text(
                    'Filters${optionalFilterCount == 0 ? '' : ' ($optionalFilterCount)'}',
                  ),
                ),
              ),
              if (validationMessage != null) ...[
                const SizedBox(height: TenantAdminSpacing.sm),
                _InlineFilterValidation(message: validationMessage),
              ],
              if (optionalFilterCount > 0) ...[
                const SizedBox(height: TenantAdminSpacing.md),
                ReportActiveFilterChips(
                  query: widget.query,
                  outlets: widget.outlets,
                  onClear: widget.onClear,
                ),
              ],
            ],
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: TenantAdminSpacing.md,
                runSpacing: TenantAdminSpacing.md,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(
                    width: 300,
                    child: ReportDateRangeField(
                      from: widget.query.from,
                      to: widget.query.to,
                      onChanged: widget.notifier.setDateRange,
                    ),
                  ),
                  if (widget.outlets.length > 1)
                    SizedBox(
                      width: 220,
                      child: _OptionField(
                        label: 'Outlet',
                        value: widget.query.outletId,
                        options: widget.outlets,
                        allLabel: 'All Accessible Outlets',
                        onChanged: widget.notifier.setOutlet,
                      ),
                    ),
                  if (widget.scope != ReportScope.dashboard)
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _openFilterSheet,
                    icon: const Icon(Icons.tune),
                    label: Text(
                      'More Filters${optionalFilterCount == 0 ? '' : ' ($optionalFilterCount)'}',
                    ),
                  ),
                  TenantAdminPrimaryButton(
                    label: 'Apply Filters',
                    icon: Icons.check,
                    onPressed: widget.onApply,
                  ),
                  if (optionalFilterCount > 0)
                    TenantAdminSecondaryButton(
                      label: 'Clear',
                      icon: Icons.clear,
                      onPressed: widget.onClear,
                    ),
                ],
              ),
              if (validationMessage != null) ...[
                const SizedBox(height: TenantAdminSpacing.md),
                _InlineFilterValidation(message: validationMessage),
              ],
              if (optionalFilterCount > 0) ...[
                const SizedBox(height: TenantAdminSpacing.md),
                ReportActiveFilterChips(
                  query: widget.query,
                  outlets: widget.outlets,
                  onClear: widget.onClear,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  int get _activeFilterCount {
    final parameters = widget.query.toQueryParameters();
    parameters.removeWhere(
      (key, value) => const {
        'from',
        'to',
        'outletId',
        'section',
        'page',
        'pageSize',
        'sortBy',
        'sortDirection',
      }.contains(key),
    );
    return parameters.length;
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      widget.notifier.setSearch(value);
    });
  }

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ReportMobileFilterSheet(
        scope: widget.scope,
        query: widget.query,
        notifier: widget.notifier,
        outlets: widget.outlets,
        filterOptions: widget.filterOptions,
        onApply: () {
          Navigator.of(context).pop();
          widget.onApply();
        },
        onClear: widget.onClear,
      ),
    );
  }
}

class ReportDateRangeField extends StatelessWidget {
  const ReportDateRangeField({
    super.key,
    required this.from,
    required this.to,
    required this.onChanged,
  });

  final DateTime? from;
  final DateTime? to;
  final void Function(DateTime? from, DateTime? to) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateButton(
            label: 'From',
            value: from,
            onPressed: () => _pick(context, isFrom: true),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Expanded(
          child: _DateButton(
            label: 'To',
            value: to,
            onPressed: () => _pick(context, isFrom: false),
          ),
        ),
      ],
    );
  }

  Future<void> _pick(BuildContext context, {required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? from : to;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (selected != null) {
      final nextFrom = isFrom ? selected : from;
      final nextTo = isFrom ? to : selected;
      if (nextFrom != null && nextTo != null && nextFrom.isAfter(nextTo)) {
        onChanged(selected, selected);
        return;
      }
      onChanged(nextFrom, nextTo);
    }
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined, size: 17),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '$label: ',
                children: [
                  TextSpan(
                    text: value == null
                        ? 'Select date'
                        : formatReportDate(value!),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class ReportMobileFilterSheet extends StatelessWidget {
  const ReportMobileFilterSheet({
    super.key,
    required this.scope,
    required this.query,
    required this.notifier,
    required this.outlets,
    required this.filterOptions,
    required this.onApply,
    required this.onClear,
  });

  final ReportScope scope;
  final ReportQuery query;
  final ReportQueryNotifier notifier;
  final List<ReportFilterOption> outlets;
  final ReportFilterOptions? filterOptions;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final fields = _fieldsForScope(scope);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Report Filters',
                    style: TenantAdminTextStyles.pageTitle(context),
                  ),
                ),
                IconButton(
                  tooltip: 'Close filters',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            ReportDateRangeField(
              from: query.from,
              to: query.to,
              onChanged: notifier.setDateRange,
            ),
            if (outlets.length > 1) ...[
              const SizedBox(height: TenantAdminSpacing.md),
              _OptionField(
                label: 'Outlet',
                value: query.outletId,
                options: outlets,
                allLabel: 'All Accessible Outlets',
                onChanged: notifier.setOutlet,
              ),
            ],
            for (final field in fields) ...[
              const SizedBox(height: TenantAdminSpacing.md),
              _OptionField(
                label: field.label,
                value: _queryValue(query, field.key),
                options: filterOptions?.forKey(field.groupKey) ?? const [],
                allLabel: 'All ${field.label}',
                onChanged: (value) => notifier.setNamedFilter(field.key, value),
              ),
            ],
            const SizedBox(height: TenantAdminSpacing.xl),
            Row(
              children: [
                if (_optionalFilterCount(query) > 0) ...[
                  Expanded(
                    child: TenantAdminSecondaryButton(
                      label: 'Clear Filters',
                      onPressed: onClear,
                    ),
                  ),
                  const SizedBox(width: TenantAdminSpacing.md),
                ],
                Expanded(
                  child: TenantAdminPrimaryButton(
                    label: 'Apply Filters',
                    onPressed: onApply,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ReportActiveFilterChips extends StatelessWidget {
  const ReportActiveFilterChips({
    super.key,
    required this.query,
    required this.outlets,
    required this.onClear,
  });

  final ReportQuery query;
  final List<ReportFilterOption> outlets;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];
    if (query.outletId != null && outlets.length > 1) {
      final matches = outlets.where((item) => item.id == query.outletId);
      chips.add(matches.isEmpty ? 'Selected outlet' : matches.first.name);
    }
    if (query.search?.trim().isNotEmpty == true) {
      chips.add('Search: ${query.search}');
    }
    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: TenantAdminSpacing.sm,
      runSpacing: TenantAdminSpacing.sm,
      children: [
        ...chips.map((label) => Chip(label: Text(label))),
        ActionChip(
          avatar: const Icon(Icons.clear, size: 16),
          label: const Text('Clear all'),
          onPressed: onClear,
        ),
      ],
    );
  }
}

class _InlineFilterValidation extends StatelessWidget {
  const _InlineFilterValidation({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.error_outline,
          size: 18,
          color: TenantAdminColors.warning,
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: TenantAdminTextStyles.muted(context).copyWith(
              color: TenantAdminColors.warning,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionField extends StatelessWidget {
  const _OptionField({
    required this.label,
    required this.value,
    required this.options,
    required this.allLabel,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<ReportFilterOption> options;
  final String allLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final containsValue = options.any((option) => option.id == value);
    return DropdownButtonFormField<String?>(
      initialValue: containsValue ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text(allLabel)),
        ...options.map(
          (option) => DropdownMenuItem<String?>(
            value: option.id,
            child: Text(
              option.secondaryLabel == null
                  ? option.name
                  : '${option.name} · ${option.secondaryLabel}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: options.isEmpty ? null : onChanged,
    );
  }
}

class _FilterFieldSpec {
  const _FilterFieldSpec(this.key, this.groupKey, this.label);

  final String key;
  final String groupKey;
  final String label;
}

List<_FilterFieldSpec> _fieldsForScope(ReportScope scope) {
  return switch (scope) {
    ReportScope.dashboard => const [
        _FilterFieldSpec('salesChannelId', 'salesChannels', 'Sales Channel'),
      ],
    ReportScope.sales => const [
        _FilterFieldSpec('tillId', 'tills', 'Tills'),
        _FilterFieldSpec('cashierId', 'cashiers', 'Cashiers'),
        _FilterFieldSpec('customerId', 'customers', 'Customers'),
        _FilterFieldSpec('departmentId', 'departments', 'Departments'),
        _FilterFieldSpec('categoryId', 'categories', 'Categories'),
        _FilterFieldSpec('subcategoryId', 'subcategories', 'Subcategories'),
        _FilterFieldSpec('brandId', 'brands', 'Brands'),
        _FilterFieldSpec('productId', 'products', 'Products'),
        _FilterFieldSpec('productVariantId', 'productVariants', 'Variants'),
        _FilterFieldSpec('salesChannelId', 'salesChannels', 'Sales Channels'),
        _FilterFieldSpec(
            'paymentMethodId', 'paymentMethods', 'Payment Methods'),
        _FilterFieldSpec('orderStatus', 'orderStatuses', 'Order Statuses'),
        _FilterFieldSpec(
            'paymentStatus', 'paymentStatuses', 'Payment Statuses'),
      ],
    ReportScope.stock => const [
        _FilterFieldSpec('departmentId', 'departments', 'Departments'),
        _FilterFieldSpec('categoryId', 'categories', 'Categories'),
        _FilterFieldSpec('subcategoryId', 'subcategories', 'Subcategories'),
        _FilterFieldSpec('brandId', 'brands', 'Brands'),
        _FilterFieldSpec('productId', 'products', 'Products'),
        _FilterFieldSpec('productVariantId', 'productVariants', 'Variants'),
        _FilterFieldSpec('stockStatus', 'stockStatuses', 'Stock Statuses'),
        _FilterFieldSpec('expiryStatus', 'expiryStatuses', 'Expiry Statuses'),
        _FilterFieldSpec('movementType', 'movementTypes', 'Movement Types'),
      ],
    ReportScope.outlets => const [
        _FilterFieldSpec('salesChannelId', 'salesChannels', 'Sales Channels'),
        _FilterFieldSpec(
            'paymentMethodId', 'paymentMethods', 'Payment Methods'),
      ],
  };
}

String? _queryValue(ReportQuery query, String key) {
  return switch (key) {
    'tillId' => query.tillId,
    'cashierId' => query.cashierId,
    'customerId' => query.customerId,
    'departmentId' => query.departmentId,
    'categoryId' => query.categoryId,
    'subcategoryId' => query.subcategoryId,
    'brandId' => query.brandId,
    'productId' => query.productId,
    'productVariantId' => query.productVariantId,
    'salesChannelId' => query.salesChannelId,
    'paymentMethodId' => query.paymentMethodId,
    'orderStatus' => query.orderStatus,
    'paymentStatus' => query.paymentStatus,
    'stockStatus' => query.stockStatus,
    'expiryStatus' => query.expiryStatus,
    'movementType' => query.movementType,
    _ => null,
  };
}

int _optionalFilterCount(ReportQuery query) {
  final parameters = query.toQueryParameters();
  parameters.removeWhere(
    (key, value) => const {
      'from',
      'to',
      'outletId',
      'section',
      'page',
      'pageSize',
      'sortBy',
      'sortDirection',
    }.contains(key),
  );
  return parameters.length;
}
