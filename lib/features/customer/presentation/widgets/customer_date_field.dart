import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

import 'customer_phone_field.dart' show CustomerFieldLabel;

/// Optional Date of Birth picker styled like the POS form fields. Read-only;
/// tapping opens the platform date picker. Shows DD / MM / YYYY when empty.
class CustomerDateField extends StatelessWidget {
  const CustomerDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final radius = BorderRadius.circular(TenantAdminRadius.md);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomerFieldLabel(label: label),
        const SizedBox(height: TenantAdminSpacing.sm),
        InkWell(
          borderRadius: radius,
          onTap: () => _pickDate(context),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.md,
            ),
            decoration: BoxDecoration(
              color: TenantAdminColors.background,
              borderRadius: radius,
              border: Border.all(color: TenantAdminColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    hasValue ? _formatDate(value!) : 'DD / MM / YYYY',
                    style: hasValue
                        ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: TenantAdminColors.bodyText,
                              fontWeight: FontWeight.w600,
                            )
                        : TenantAdminTextStyles.muted(context),
                  ),
                ),
                if (hasValue)
                  IconButton(
                    onPressed: () => onChanged(null),
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: TenantAdminColors.mutedText,
                    visualDensity: VisualDensity.compact,
                  ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: TenantAdminColors.mutedText,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString().padLeft(4, '0');
    return '$dd / $mm / $yyyy';
  }
}
