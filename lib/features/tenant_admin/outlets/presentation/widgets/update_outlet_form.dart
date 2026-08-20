import 'dart:io';

void main() {
  final file = File(
      r'c:\Users\User\Desktop\pos final wep\Tenantadmin\Nytroz-POS-App\lib\features\tenant_admin\outlets\presentation\widgets\outlet_form.dart');
  final content = file.readAsStringSync();

  const startText = 'class _OutletDetailsStep extends StatelessWidget {';
  const endText = 'class _OutletLocationContactStep extends StatelessWidget {';

  final startIndex = content.indexOf(startText);
  final endIndex = content.indexOf(endText);

  if (startIndex == -1 || endIndex == -1) {
    // ignore: avoid_print
    print('Could not find start or end index');
    return;
  }

  const newClass = '''class _OutletDetailsStep extends StatelessWidget {
  const _OutletDetailsStep({
    required this.outletName,
    required this.outletPhone,
    required this.outletEmail,
    required this.outletType,
    required this.status,
    required this.timezone,
    required this.outletTypes,
    required this.timezones,
    required this.isDefaultOutlet,
    required this.errors,
    required this.onOutletTypeChanged,
    required this.onStatusChanged,
    required this.onDefaultChanged,
  });

  final TextEditingController outletName;
  final TextEditingController outletPhone;
  final TextEditingController outletEmail;
  final String outletType;
  final String status;
  final TextEditingController timezone;
  final List<OutletSelectOption> outletTypes;
  final List<OutletSelectOption> timezones;
  final bool isDefaultOutlet;
  final Map<String, String> errors;
  final ValueChanged<String> onOutletTypeChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<bool> onDefaultChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _field(
                      'outletName',
                      'Outlet Name',
                      outletName,
                      errors: errors,
                      isRequired: true,
                      maxLength: 200,
                      icon: Icons.storefront_outlined,
                    ),
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('General Information'),
        const SizedBox(height: TenantAdminSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                'outletName',
                'Outlet Name',
                outletName,
                errors: errors,
                isRequired: true,
                maxLength: 200,
                icon: Icons.storefront_outlined,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(
              child: _buildOutletCode(context),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _outletTypeDropdown(),
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(
              child: _statusSelector(context),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildManagerField(context),
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(
              child: _field(
                'contactPhone',
                'Outlet Phone (optional)',
                outletPhone,
                errors: errors,
                icon: Icons.phone_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                'contactEmail',
                'Outlet Email (optional)',
                outletEmail,
                errors: errors,
                icon: Icons.mail_outline,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(
              child: _timezoneField(),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildSwitchOption(
                title: 'Main / Central Outlet',
                subtitle: 'Designate this outlet as the main or central outlet. Only one central outlet is allowed per tenant.',
                value: false,
                onChanged: (v) {},
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(
              child: _buildSwitchOption(
                title: 'Default for New Tills',
                subtitle: 'Newly created tills will be assigned to this outlet by default.',
                value: isDefaultOutlet,
                onChanged: onDefaultChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwitchOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: TenantAdminColors.posHomeOrangeEnd,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: TenantAdminColors.mutedText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildManagerField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Outlet Manager ',
              style: TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text('*', style: TextStyle(color: TenantAdminColors.danger)),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        TextFormField(
          enabled: false,
          decoration: InputDecoration(
            hintText: 'Search and select a user',
            hintStyle: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.normal),
            prefixIcon: const Icon(Icons.search, color: TenantAdminColors.mutedText),
            filled: true,
            fillColor: TenantAdminColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.lg,
              vertical: TenantAdminSpacing.md,
            ),
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 12, color: Color(0xFF0284C7)),
              SizedBox(width: 4),
              Text(
                'Eligible tenant users only',
                style: TextStyle(
                  color: Color(0xFF0284C7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOutletCode(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Outlet Code ',
              style: TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text('*', style: TextStyle(color: TenantAdminColors.danger)),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        TextFormField(
          initialValue: 'OUT-2025-0005',
          enabled: false,
          style: const TextStyle(color: TenantAdminColors.mutedText),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            suffixIcon: const Icon(Icons.lock_outline, size: 16, color: TenantAdminColors.mutedText),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.lg,
              vertical: TenantAdminSpacing.md,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Auto-generated and cannot be changed.',
          style: TextStyle(
            color: TenantAdminColors.mutedText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }


  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TenantAdminColors.posHomeOrangeEnd.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: TenantAdminColors.posHomeOrangeEnd,
            size: 24,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: TenantAdminColors.mutedText,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _outletTypeDropdown() {
    final options = outletTypes.isEmpty && outletType.trim().isNotEmpty
        ? [
            OutletSelectOption(
              value: _normalizeCanonicalOutletType(outletType),
              label: _displayOutletType(outletType),
            ),
          ]
        : outletTypes;
    final value = _matchingOptionValue(outletType, options);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Outlet Type ',
              style: TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text('*', style: TextStyle(color: TenantAdminColors.danger)),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        DropdownButtonFormField<String>(
          initialValue: value,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: TenantAdminColors.mutedText),
          decoration: InputDecoration(
            errorText: errors['outletType'],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.lg,
              vertical: TenantAdminSpacing.md,
            ),
          ),
          items: [
            for (final option in options)
              DropdownMenuItem(
                value: option.value,
                child: Text(option.label),
              ),
          ],
          validator: (value) => _outletTypeValidator(value, options),
          onChanged: (value) {
            if (value != null) {
              onOutletTypeChanged(_normalizeCanonicalOutletType(value));
            }
          },
        ),
      ],
    );
  }

  Widget _timezoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Timezone ',
              style: TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text('*', style: TextStyle(color: TenantAdminColors.danger)),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        if (timezones.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: _matchingOptionValue(timezone.text, timezones),
            icon: const Icon(Icons.keyboard_arrow_down,
                color: TenantAdminColors.mutedText),
            decoration: InputDecoration(
              errorText: errors['timezone'],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.lg,
                vertical: TenantAdminSpacing.md,
              ),
            ),
            items: [
              for (final option in timezones)
                DropdownMenuItem(
                  value: option.value,
                  child: Text(option.label),
                ),
            ],
            validator: (value) => _timezoneValidator(value, timezones),
            onChanged: (value) {
              timezone.text = value ?? '';
            },
          )
        else
          TextFormField(
            controller: timezone,
            decoration: InputDecoration(
              hintText: 'Enter timezone (e.g., UTC)',
              hintStyle: const TextStyle(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.normal),
              errorText: errors['timezone'],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.lg,
                vertical: TenantAdminSpacing.md,
              ),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return 'Timezone is required.';
              if (trimmed.length > 80) {
                return 'Timezone must be 80 characters or less.';
              }
              return null;
            },
          ),
      ],
    );
  }

  Widget _statusSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Status ',
              style: TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text('*', style: TextStyle(color: TenantAdminColors.danger)),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildStatusOption(
                label: 'Active',
                value: 'ACTIVE',
                icon: Icons.check,
                isSelected: status == 'ACTIVE',
                onTap: () => onStatusChanged('ACTIVE'),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: _buildStatusOption(
                label: 'Inactive',
                value: 'INACTIVE',
                icon: Icons.circle_outlined,
                isSelected: status == 'INACTIVE',
                onTap: () => onStatusChanged('INACTIVE'),
              ),
            ),
          ],
        ),
        if (errors['status'] != null) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            errors['status']!,
            style: const TextStyle(color: TenantAdminColors.danger),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusOption({
    required String label,
    required String value,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected
              ? TenantAdminColors.posHomeOrangeEnd.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          border: Border.all(
            color: isSelected
                ? TenantAdminColors.posHomeOrangeEnd
                : TenantAdminColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? TenantAdminColors.posHomeOrangeEnd
                    : TenantAdminColors.mutedText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: TenantAdminSpacing.sm),
              Icon(
                icon,
                size: 18,
                color: TenantAdminColors.posHomeOrangeEnd,
              ),
            ],
            if (!isSelected) ...[
              const SizedBox(width: TenantAdminSpacing.sm),
              const Icon(
                Icons.circle_outlined,
                size: 18,
                color: TenantAdminColors.border,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
''';

  final newContent = content.replaceRange(startIndex, endIndex, newClass);
  file.writeAsStringSync(newContent);
  // ignore: avoid_print
  print('Successfully replaced _OutletDetailsStep');
}
