import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ProductInitialTrackingCard extends StatelessWidget {
  const ProductInitialTrackingCard({
    super.key,
    required this.batchController,
    required this.serialController,
    required this.expiryDate,
    required this.onExpiryChanged,
    this.enabled = true,
  });

  final TextEditingController batchController;
  final TextEditingController serialController;
  final DateTime? expiryDate;
  final ValueChanged<DateTime?> onExpiryChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= TenantAdminBreakpoints.smallTablet;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.qr_code_scanner_outlined,
                    color: TenantAdminColors.posHomeAccentOrange,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Initial Tracking Details',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: TenantAdminColors.bodyText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Tracking behaviour will be configured in the next step.',
                style: TextStyle(
                  fontSize: 12,
                  color: TenantAdminColors.mutedText,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _compactField(
                        label: 'Initial Batch Number',
                        hint: 'e.g. BAT-2026-0001',
                        controller: batchController,
                        enabled: enabled,
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.md),
                    Expanded(child: _expiryField(context)),
                    const SizedBox(width: TenantAdminSpacing.md),
                    Expanded(
                      child: _compactField(
                        label: 'Initial Serial Number',
                        hint: 'e.g. SN-100045',
                        controller: serialController,
                        enabled: enabled,
                      ),
                    ),
                  ],
                )
              else ...[
                _compactField(
                  label: 'Initial Batch Number',
                  hint: 'e.g. BAT-2026-0001',
                  controller: batchController,
                  enabled: enabled,
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                _expiryField(context),
                const SizedBox(height: TenantAdminSpacing.sm),
                _compactField(
                  label: 'Initial Serial Number',
                  hint: 'e.g. SN-100045',
                  controller: serialController,
                  enabled: enabled,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _expiryField(BuildContext context) {
    final label = expiryDate == null
        ? 'Select date'
        : '${expiryDate!.year.toString().padLeft(4, '0')}-${expiryDate!.month.toString().padLeft(2, '0')}-${expiryDate!.day.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Initial Expiry Date',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: enabled ? () => _pickDate(context) : null,
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          child: InputDecorator(
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Optional',
              suffixIcon: expiryDate != null && enabled
                  ? IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => onExpiryChanged(null),
                    )
                  : const Icon(Icons.calendar_today_outlined, size: 16),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              ),
            ),
            child: Text(
              expiryDate == null ? 'Optional' : label,
              style: TextStyle(
                fontSize: 13,
                color: expiryDate == null
                    ? TenantAdminColors.mutedText
                    : TenantAdminColors.bodyText,
              ),
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
      initialDate: expiryDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null) {
      onExpiryChanged(DateTime(picked.year, picked.month, picked.day));
    }
  }

  Widget _compactField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: TenantAdminColors.mutedText,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            ),
          ),
        ),
      ],
    );
  }
}
