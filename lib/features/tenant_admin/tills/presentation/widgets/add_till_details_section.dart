import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/till_create_options.dart';

class AddTillDetailsSection extends StatelessWidget {
  const AddTillDetailsSection({
    super.key,
    required this.nameController,
    required this.codeController,
    required this.floatController,
    required this.selectedOutletId,
    required this.selectedStatus,
    required this.selectedCashierId,
    required this.options,
    required this.onOutletChanged,
    required this.onStatusChanged,
    required this.onCashierChanged,
    required this.backendErrors,
  });

  final TextEditingController nameController;
  final TextEditingController codeController;
  final TextEditingController floatController;
  final String? selectedOutletId;
  final String? selectedStatus;
  final String? selectedCashierId;
  final TillCreateOptions options;
  final ValueChanged<String?> onOutletChanged;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onCashierChanged;
  final Map<String, String> backendErrors;

  @override
  Widget build(BuildContext context) {
    final uniqueOutlets = <String, dynamic>{};
    for (final outlet in options.outlets) {
      uniqueOutlets[outlet.id] = outlet;
    }
    final outlets = uniqueOutlets.values.toList();
    final hasOutlet = outlets.any((o) => o.id == selectedOutletId);
    final safeOutletId = hasOutlet ? selectedOutletId : null;

    final uniqueStatuses = options.statuses.toSet().toList();
    final hasStatus = uniqueStatuses.contains(selectedStatus);
    final safeStatus = hasStatus ? selectedStatus : null;

    final uniqueCashiers = <String, dynamic>{};
    for (final cashier in options.cashiers) {
      uniqueCashiers[cashier.id] = cashier;
    }
    final cashiers = uniqueCashiers.values.toList();
    final hasCashier = cashiers.any((c) => c.id == selectedCashierId);
    final safeCashierId = hasCashier ? selectedCashierId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6A00),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('1',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Text(
              'Till Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLabeledField(
                label: 'Till Name',
                isRequired: true,
                child: TextFormField(
                  controller: nameController,
                  maxLength: 150,
                  decoration: _buildInputDecoration(
                    hintText: 'Enter till name',
                    icon: Icons.point_of_sale,
                    errorText: backendErrors['tillName'],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Till Name is required';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(
              child: _buildLabeledField(
                label: 'Till Code',
                isRequired: true,
                child: TextFormField(
                  controller: codeController,
                  maxLength: 60,
                  decoration: _buildInputDecoration(
                    hintText: 'Enter till code',
                    icon: Icons.tag,
                    errorText: backendErrors['tillCode'],
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Till Code is required';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLabeledField(
                label: 'Assign Outlet',
                isRequired: true,
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('outlet_dropdown'),
                  initialValue: safeOutletId,
                  decoration: _buildInputDecoration(
                    hintText: 'Select outlet',
                    icon: Icons.location_on_outlined,
                    errorText: backendErrors['outletId'],
                  ),
                  items: [
                    for (final outlet in outlets)
                      DropdownMenuItem(
                        value: outlet.id as String,
                        child: Text(outlet.name as String),
                      ),
                  ],
                  onChanged: onOutletChanged,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an outlet';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(
              child: _buildLabeledField(
                label: 'Status',
                isRequired: true,
                child: DropdownButtonFormField<String>(
                  key: const ValueKey('status_dropdown'),
                  initialValue: safeStatus,
                  decoration: _buildInputDecoration(
                    hintText: 'Select status',
                    icon: Icons.circle,
                    iconColor: TenantAdminColors.success,
                    iconSize: 12,
                    errorText: backendErrors['status'],
                  ),
                  items: [
                    for (final status in uniqueStatuses)
                      DropdownMenuItem(
                        value: status,
                        child: Text(
                          status.substring(0, 1).toUpperCase() +
                              status.substring(1).toLowerCase(),
                        ),
                      ),
                  ],
                  onChanged: onStatusChanged,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a status';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildLabeledField(
                label: 'Default Cashier',
                isRequired: true,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('cashier_dropdown_$selectedOutletId'),
                  initialValue: safeCashierId,
                  decoration: _buildInputDecoration(
                    hintText: 'Select cashier',
                    icon: Icons.person_outline,
                    errorText: backendErrors['defaultCashierTenantUserId'],
                  ),
                  items: [
                    for (final cashier in cashiers)
                      DropdownMenuItem(
                        value: cashier.id as String,
                        child: Text(cashier.displayName as String),
                      ),
                  ],
                  onChanged: onCashierChanged,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a default cashier';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(
              child: _buildLabeledField(
                label: 'Opening Float',
                isRequired: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: floatController,
                      decoration: InputDecoration(
                        hintText: 'Enter opening float amount',
                        prefixText: '${options.currencyCode} ',
                        errorText: backendErrors['defaultOpeningFloatAmount'],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: TenantAdminColors.border.withValues(alpha: 0.5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: TenantAdminColors.border.withValues(alpha: 0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFFF6A00)),
                        ),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Opening float is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14, color: TenantAdminColors.mutedText),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Opening float is the starting cash amount in this till.',
                            style: TextStyle(
                                fontSize: 12, color: TenantAdminColors.mutedText),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabeledField({required String label, required bool isRequired, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            if (isRequired)
              const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _buildInputDecoration({required String hintText, required IconData icon, Color? iconColor, double? iconSize, String? errorText}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: iconColor ?? TenantAdminColors.mutedText, size: iconSize),
      errorText: errorText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: TenantAdminColors.border.withValues(alpha: 0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: TenantAdminColors.border.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFFF6A00)),
      ),
    );
  }
}
