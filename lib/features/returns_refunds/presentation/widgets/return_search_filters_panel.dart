import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/return_sale_summary.dart';
import '../providers/return_search_provider.dart';

class ReturnSearchFiltersPanel extends StatefulWidget {
  const ReturnSearchFiltersPanel({
    super.key,
    required this.filters,
    required this.paymentMethods,
    required this.isLoading,
    required this.onApply,
    required this.onClear,
  });

  final ReturnSearchFilters filters;
  final List<ReturnPaymentMethodFilterOption> paymentMethods;
  final bool isLoading;
  final Future<void> Function(ReturnSearchFilters filters) onApply;
  final Future<void> Function() onClear;

  @override
  State<ReturnSearchFiltersPanel> createState() =>
      _ReturnSearchFiltersPanelState();
}

class _ReturnSearchFiltersPanelState extends State<ReturnSearchFiltersPanel> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _minAmountController;
  late final TextEditingController _maxAmountController;
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _paymentMethodCode;

  @override
  void initState() {
    super.initState();
    _minAmountController = TextEditingController();
    _maxAmountController = TextEditingController();
    _syncFromFilters(widget.filters);
  }

  @override
  void didUpdateWidget(covariant ReturnSearchFiltersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filters != widget.filters) {
      _syncFromFilters(widget.filters);
    }
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 720;
                final fields = [
                  _DateField(
                    label: 'Date From',
                    value: _fromDate,
                    enabled: !widget.isLoading,
                    onChanged: (value) => setState(() => _fromDate = value),
                  ),
                  _DateField(
                    label: 'Date To',
                    value: _toDate,
                    enabled: !widget.isLoading,
                    onChanged: (value) => setState(() => _toDate = value),
                  ),
                  DropdownButtonFormField<String?>(
                    initialValue: _availablePaymentValue,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All payment methods'),
                      ),
                      for (final method in widget.paymentMethods)
                        DropdownMenuItem<String?>(
                          value: method.code,
                          child: Text(method.label.isEmpty
                              ? method.code
                              : method.label),
                        ),
                    ],
                    onChanged: widget.isLoading
                        ? null
                        : (value) =>
                            setState(() => _paymentMethodCode = value),
                  ),
                  TextFormField(
                    controller: _minAmountController,
                    enabled: !widget.isLoading,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Minimum Amount',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: _validateAmount,
                  ),
                  TextFormField(
                    controller: _maxAmountController,
                    enabled: !widget.isLoading,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Maximum Amount',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    validator: _validateAmount,
                  ),
                ];

                if (compact) {
                  return Column(
                    children: [
                      for (var index = 0; index < fields.length; index++) ...[
                        fields[index],
                        if (index < fields.length - 1)
                          const SizedBox(height: TenantAdminSpacing.md),
                      ],
                    ],
                  );
                }

                return Wrap(
                  spacing: TenantAdminSpacing.md,
                  runSpacing: TenantAdminSpacing.md,
                  children: [
                    for (final field in fields)
                      SizedBox(width: 210, child: field),
                  ],
                );
              },
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.isLoading ? null : _clear,
                  child: const Text('Clear'),
                ),
                const SizedBox(width: TenantAdminSpacing.md),
                FilledButton(
                  onPressed: widget.isLoading ? null : _apply,
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? get _availablePaymentValue {
    final code = _paymentMethodCode;
    if (code == null ||
        !widget.paymentMethods.any((method) => method.code == code)) {
      return null;
    }
    return code;
  }

  Future<void> _apply() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final minAmount = _parseAmount(_minAmountController.text);
    final maxAmount = _parseAmount(_maxAmountController.text);
    if (_fromDate != null &&
        _toDate != null &&
        _fromDate!.isAfter(_toDate!)) {
      _showValidationMessage('Date From cannot be later than Date To.');
      return;
    }
    if (minAmount != null && maxAmount != null && minAmount > maxAmount) {
      _showValidationMessage(
        'Minimum Amount cannot be greater than Maximum Amount.',
      );
      return;
    }

    await widget.onApply(ReturnSearchFilters(
      fromDate: _fromDate,
      toDate: _toDate,
      paymentMethodCode: _paymentMethodCode,
      minAmount: minAmount,
      maxAmount: maxAmount,
    ));
  }

  Future<void> _clear() async {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _paymentMethodCode = null;
      _minAmountController.clear();
      _maxAmountController.clear();
    });
    await widget.onClear();
  }

  void _syncFromFilters(ReturnSearchFilters filters) {
    _fromDate = filters.fromDate;
    _toDate = filters.toDate;
    _paymentMethodCode = filters.paymentMethodCode;
    _minAmountController.text = filters.minAmount?.toString() ?? '';
    _maxAmountController.text = filters.maxAmount?.toString() ?? '';
  }

  String? _validateAmount(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    final parsed = double.tryParse(text);
    if (parsed == null) {
      return 'Enter a valid amount';
    }
    if (parsed < 0) {
      return 'Amount cannot be negative';
    }
    return null;
  }

  double? _parseAmount(String value) {
    final text = value.trim();
    return text.isEmpty ? null : double.tryParse(text);
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final bool enabled;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => _pickDate(context) : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          enabled: enabled,
          suffixIcon: value == null
              ? const Icon(Icons.calendar_today_outlined, size: 18)
              : IconButton(
                  tooltip: 'Clear $label',
                  onPressed: enabled ? () => onChanged(null) : null,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
        ),
        child: Text(value == null ? 'Any date' : _formatDate(value!)),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (selected != null) {
      onChanged(selected);
    }
  }

  static String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
