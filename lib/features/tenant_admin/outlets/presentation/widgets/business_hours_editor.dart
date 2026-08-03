import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class BusinessHoursDraft {
  BusinessHoursDraft({
    required this.dayLabel,
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
    required this.closed,
  });

  final String dayLabel;
  final int dayOfWeek;
  final TextEditingController openTime;
  final TextEditingController closeTime;
  bool closed;
}

class BusinessHoursEditor extends StatelessWidget {
  const BusinessHoursEditor({
    super.key,
    required this.hours,
    required this.errors,
    required this.onChanged,
    required this.onApplyMondayToWeekdays,
  });

  final List<BusinessHoursDraft> hours;
  final Map<String, String> errors;
  final VoidCallback onChanged;
  final VoidCallback onApplyMondayToWeekdays;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: onApplyMondayToWeekdays,
            icon: const Icon(Icons.copy_all_outlined, size: 18),
            label: const Text('Apply Monday hours to weekdays'),
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        for (final draft in hours) ...[
          BusinessHoursDayRow(
            draft: draft,
            error: errors['businessHours.${draft.dayOfWeek}'],
            onChanged: onChanged,
          ),
          if (draft != hours.last)
            const SizedBox(height: TenantAdminSpacing.md),
        ],
      ],
    );
  }
}

class BusinessHoursDayRow extends StatelessWidget {
  const BusinessHoursDayRow({
    super.key,
    required this.draft,
    required this.onChanged,
    this.error,
  });

  final BusinessHoursDraft draft;
  final String? error;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < TenantAdminBreakpoints.mobile;

        final controls = [
          Material(
            color: Colors.transparent,
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(draft.closed ? 'Closed' : 'Open'),
              value: !draft.closed,
              onChanged: (value) {
                draft.closed = !value;
                onChanged();
              },
            ),
          ),
          _TimeField(
            label: 'Opening time',
            controller: draft.openTime,
            enabled: !draft.closed,
            onChanged: onChanged,
          ),
          _TimeField(
            label: 'Closing time',
            controller: draft.closeTime,
            enabled: !draft.closed,
            onChanged: onChanged,
          ),
        ];

        return Container(
          padding: const EdgeInsets.all(TenantAdminSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: error == null
                  ? TenantAdminColors.border
                  : TenantAdminColors.danger,
            ),
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                draft.dayLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: TenantAdminSpacing.sm),
              if (narrow)
                Column(
                  children: [
                    for (final control in controls) ...[
                      control,
                      if (control != controls.last)
                        const SizedBox(height: TenantAdminSpacing.sm),
                    ],
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 160, child: controls[0]),
                    const SizedBox(width: TenantAdminSpacing.md),
                    Expanded(child: controls[1]),
                    const SizedBox(width: TenantAdminSpacing.md),
                    Expanded(child: controls[2]),
                  ],
                ),
              if (error != null) ...[
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  error!,
                  style: const TextStyle(
                    color: TenantAdminColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.schedule_outlined, size: 18),
      ),
      onTap: enabled
          ? () async {
              final value = await showTimePicker(
                context: context,
                initialTime: _parseTime(controller.text) ??
                    const TimeOfDay(hour: 9, minute: 0),
              );
              if (value == null) {
                return;
              }
              controller.text = _formatTime(value);
              onChanged();
            }
          : null,
      validator: (_) {
        if (enabled && _parseTime(controller.text) == null) {
          return 'Select a valid time.';
        }
        return null;
      },
    );
  }
}

TimeOfDay? _parseTime(String value) {
  final parts = value.trim().split(':');
  if (parts.length < 2) {
    return null;
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return null;
  }
  return TimeOfDay(hour: hour, minute: minute);
}

String _formatTime(TimeOfDay value) {
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
