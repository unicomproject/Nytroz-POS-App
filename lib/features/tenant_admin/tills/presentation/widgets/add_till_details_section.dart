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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: TenantAdminColors.primary,
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
              child: TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Till Name *',
                  hintText: 'Enter till name',
                  prefixIcon: const Icon(Icons.point_of_sale,
                      color: TenantAdminColors.mutedText),
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
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(
              child: TextFormField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: 'Till Code *',
                  hintText: 'Enter till code',
                  prefixIcon:
                      const Icon(Icons.tag, color: TenantAdminColors.mutedText),
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
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: selectedOutletId,
                decoration: InputDecoration(
                  labelText: 'Assign Outlet *',
                  prefixIcon: const Icon(Icons.location_on_outlined,
                      color: TenantAdminColors.mutedText),
                  errorText: backendErrors['outletId'],
                ),
                items: [
                  for (final outlet in options.outlets)
                    DropdownMenuItem(
                      value: outlet.id,
                      child: Text(outlet.name),
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
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Status *',
                  prefixIcon: const Icon(Icons.circle,
                      color: TenantAdminColors.success, size: 12),
                  errorText: backendErrors['status'],
                ),
                items: [
                  for (final status in options.statuses)
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
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: selectedCashierId,
                decoration: InputDecoration(
                  labelText: 'Default Cashier *',
                  prefixIcon: const Icon(Icons.person_outline,
                      color: TenantAdminColors.mutedText),
                  errorText: backendErrors['defaultCashierTenantUserId'],
                ),
                items: [
                  for (final cashier in options.cashiers)
                    if (selectedOutletId == null ||
                        cashier.outletIds.contains(selectedOutletId))
                      DropdownMenuItem(
                        value: cashier.id,
                        child: Text(cashier.displayName),
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
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: floatController,
                    decoration: InputDecoration(
                      labelText: 'Opening Float *',
                      hintText: 'Enter opening float amount',
                      prefixText: 'Rs. ',
                      errorText: backendErrors['defaultOpeningFloatAmount'],
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
                  const SizedBox(height: TenantAdminSpacing.xs),
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
          ],
        ),
      ],
    );
  }
}
