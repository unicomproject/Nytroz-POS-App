import 'dart:io';

void main() {
  final file = File(
      r'c:\Users\User\Desktop\pos final wep\Tenantadmin\Nytroz-POS-App\lib\features\tenant_admin\outlets\presentation\widgets\business_hours_editor.dart');

  const newContent = '''import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  bool selected = false;
  bool overnight = false;
}

class SpecialDayDraft {
  final String date;
  final String name;
  final String openTime;
  final String closeTime;
  final bool open;
  
  SpecialDayDraft(this.date, this.name, this.openTime, this.closeTime, this.open);
}

class BusinessHoursEditor extends StatefulWidget {
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
  State<BusinessHoursEditor> createState() => _BusinessHoursEditorState();
}

class _BusinessHoursEditorState extends State<BusinessHoursEditor> {
  final List<SpecialDayDraft> _specialDays = [
    SpecialDayDraft('25 Dec 2025', 'Christmas Day', '09:00 AM', '06:00 PM', true),
    SpecialDayDraft('01 Jan 2026', 'New Year\\'s Day', '10:00 AM', '08:00 PM', true),
  ];

  bool get _allSelected => widget.hours.every((h) => h.selected);
  bool get _anySelected => widget.hours.any((h) => h.selected);

  void _toggleAll(bool? val) {
    setState(() {
      for (var h in widget.hours) {
        h.selected = val ?? false;
      }
    });
  }
  
  void _set24Hours() {
    setState(() {
      for (var h in widget.hours) {
        if (h.selected) {
          h.closed = false;
          h.openTime.text = '00:00';
          h.closeTime.text = '23:59';
          h.overnight = false;
        }
      }
      widget.onChanged();
    });
  }
  
  void _setClosed() {
    setState(() {
      for (var h in widget.hours) {
        if (h.selected) {
          h.closed = true;
          h.openTime.text = '00:00';
          h.closeTime.text = '00:00';
          h.overnight = false;
        }
      }
      widget.onChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 1250) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _buildMainForm(context)),
            const SizedBox(width: TenantAdminSpacing.xl),
            const Expanded(flex: 2, child: _InfoSidePanel()),
          ],
        );
      }
      if (constraints.maxWidth >= 900) {
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildMainForm(context)),
                const SizedBox(width: TenantAdminSpacing.xl),
                const Expanded(flex: 2, child: _InfoSidePanel()),
              ],
            ),
          ],
        );
      }
      return Column(
        children: [
          _buildMainForm(context),
          const SizedBox(height: TenantAdminSpacing.xl),
          const _InfoSidePanel(),
        ],
      );
    });
  }

  Widget _buildMainForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Business Hours', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: TenantAdminColors.bodyText)),
                  const SizedBox(height: 4),
                  Text('Set the regular operating hours for each day of the week.', style: TenantAdminTextStyles.muted(context)),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.onApplyMondayToWeekdays,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Monday to Tue-Fri', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TenantAdminColors.bodyText,
                    side: const BorderSide(color: TenantAdminColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _anySelected ? _set24Hours : null,
                  icon: const Icon(Icons.av_timer, size: 16),
                  label: const Text('Set selected to 24 hours', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TenantAdminColors.bodyText,
                    side: const BorderSide(color: TenantAdminColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _anySelected ? _setClosed : null,
                  icon: const Icon(Icons.lock_outline, size: 16),
                  label: const Text('Set selected to closed', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TenantAdminColors.bodyText,
                    side: const BorderSide(color: TenantAdminColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: TenantAdminColors.mutedText),
            const SizedBox(width: 8),
            Text('Business hours use the outlet timezone: America/New_York (UTC-05:00)', style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12)),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: TenantAdminColors.border),
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: TenantAdminColors.border)),
                  color: Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(TenantAdminRadius.md)),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 32, child: Checkbox(value: _allSelected, onChanged: _toggleAll, activeColor: TenantAdminColors.posHomeOrangeEnd)),
                    const SizedBox(width: 120, child: Text('Day', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    const SizedBox(width: 80, child: Text('Open', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    const Expanded(child: Text('Opening Time', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    const SizedBox(width: 16),
                    const Expanded(child: Text('Closing Time', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    const SizedBox(width: 80, child: Text('Overnight', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    const SizedBox(width: 32),
                  ],
                ),
              ),
              for (int i = 0; i < widget.hours.length; i++)
                _buildDayRow(widget.hours[i], i < widget.hours.length - 1),
            ],
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xl * 1.5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Special Days / Holiday Hours', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: TenantAdminColors.bodyText)),
                  const SizedBox(height: 4),
                  Text('Override regular hours for special days and public holidays.', style: TenantAdminTextStyles.muted(context)),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16, color: TenantAdminColors.posHomeOrangeEnd),
              label: const Text('Add Special Day', style: TextStyle(fontSize: 13, color: TenantAdminColors.posHomeOrangeEnd)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: TenantAdminColors.posHomeOrangeEnd),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: TenantAdminColors.border),
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: TenantAdminColors.border)),
                  color: Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(TenantAdminRadius.md)),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 32, child: Icon(Icons.event_outlined, size: 18, color: TenantAdminColors.mutedText)),
                    SizedBox(width: 120, child: Text('Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    Expanded(child: Text('Name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    Expanded(child: Text('Opening Time', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    Expanded(child: Text('Closing Time', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    SizedBox(width: 80, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    SizedBox(width: 64, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13), textAlign: TextAlign.center)),
                  ],
                ),
              ),
              for (int i = 0; i < _specialDays.length; i++)
                _buildSpecialDayRow(_specialDays[i], i < _specialDays.length - 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayRow(BusinessHoursDraft draft, bool hasBorder) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: hasBorder ? const Border(bottom: BorderSide(color: TenantAdminColors.border)) : null,
      ),
      child: Row(
        children: [
          SizedBox(width: 32, child: Checkbox(value: draft.selected, onChanged: (v) => setState(() => draft.selected = v ?? false), activeColor: TenantAdminColors.posHomeOrangeEnd)),
          SizedBox(width: 120, child: Text(draft.dayLabel, style: const TextStyle(fontSize: 13))),
          SizedBox(width: 80, child: Switch(
            value: !draft.closed, 
            onChanged: (v) {
              setState(() => draft.closed = !v);
              widget.onChanged();
            },
            activeColor: Colors.white,
            activeTrackColor: TenantAdminColors.posHomeOrangeEnd,
            inactiveTrackColor: Colors.grey[300],
            inactiveThumbColor: Colors.white,
          )),
          Expanded(child: _TimeField(controller: draft.openTime, enabled: !draft.closed, onChanged: widget.onChanged)),
          const SizedBox(width: 16),
          Expanded(child: _TimeField(controller: draft.closeTime, enabled: !draft.closed, onChanged: widget.onChanged)),
          SizedBox(width: 80, child: Switch(
            value: draft.overnight, 
            onChanged: !draft.closed ? (v) {
              setState(() => draft.overnight = v);
              widget.onChanged();
            } : null,
            activeColor: Colors.white,
            activeTrackColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[200],
            inactiveThumbColor: Colors.white,
          )),
          const SizedBox(width: 32, child: Icon(Icons.info_outline, size: 16, color: TenantAdminColors.mutedText)),
        ],
      ),
    );
  }

  Widget _buildSpecialDayRow(SpecialDayDraft draft, bool hasBorder) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: hasBorder ? const Border(bottom: BorderSide(color: TenantAdminColors.border)) : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 32, child: Icon(Icons.calendar_today, size: 16, color: TenantAdminColors.mutedText)),
          SizedBox(width: 120, child: Text(draft.date, style: const TextStyle(fontSize: 13))),
          Expanded(child: Text(draft.name, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(border: Border.all(color: TenantAdminColors.border), borderRadius: BorderRadius.circular(4)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(draft.openTime, style: const TextStyle(fontSize: 13)),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: TenantAdminColors.mutedText),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(border: Border.all(color: TenantAdminColors.border), borderRadius: BorderRadius.circular(4)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(draft.closeTime, style: const TextStyle(fontSize: 13)),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: TenantAdminColors.mutedText),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 80, 
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(16)),
              child: const Text('Open', textAlign: TextAlign.center, style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 64, child: Icon(Icons.more_vert, size: 18, color: TenantAdminColors.mutedText)),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Closed', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          ],
        ),
      );
    }
    
    return InkWell(
      onTap: () async {
        final value = await showTimePicker(
          context: context,
          initialTime: _parseTime(controller.text) ?? const TimeOfDay(hour: 9, minute: 0),
        );
        if (value == null) return;
        controller.text = _formatTime(value);
        onChanged();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatTimeAmPm(controller.text), style: const TextStyle(fontSize: 13)),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: TenantAdminColors.mutedText),
          ],
        ),
      ),
    );
  }
}

TimeOfDay? _parseTime(String value) {
  final parts = value.trim().split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String _formatTime(TimeOfDay value) {
  return '\${value.hour.toString().padLeft(2, '0')}:\${value.minute.toString().padLeft(2, '0')}';
}

String _formatTimeAmPm(String value) {
  final t = _parseTime(value);
  if (t == null) return value;
  final now = DateTime.now();
  final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
  return DateFormat('hh:mm a').format(dt);
}

class _InfoSidePanel extends StatelessWidget {
  const _InfoSidePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F5), // Light orange tint
        border: Border.all(color: const Color(0xFFFFE0CC)), // Light orange border
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: const Column(
        children: [
          _Guidance(Icons.access_time, 'Set your regular store hours', 'Define when your outlet is open for customers each day.'),
          Divider(color: Color(0xFFFFE0CC), height: 32),
          _Guidance(Icons.event_available, 'Add public holidays', 'Set different opening hours for holidays and special occasions.'),
          Divider(color: Color(0xFFFFE0CC), height: 32),
          _Guidance(Icons.av_timer, 'Open 24 hours', 'Use the 24 hours option to keep your outlet open all day.'),
          Divider(color: Color(0xFFFFE0CC), height: 32),
          _Guidance(Icons.visibility_outlined, 'Visible to customers', 'These hours will be shown to customers on receipts, online store and location pages.'),
        ],
      ),
    );
  }
}

class _Guidance extends StatelessWidget { 
  const _Guidance(this.icon, this.title, this.body); 
  final IconData icon; 
  final String title; 
  final String body; 
  
  @override 
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start, 
    children: [
      CircleAvatar(
        backgroundColor: Colors.white,
        radius: 20, 
        child: Icon(icon, color: TenantAdminColors.posHomeOrangeEnd, size: 20)
      ), 
      const SizedBox(width: TenantAdminSpacing.md), 
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: TenantAdminColors.bodyText, fontSize: 13)), 
            const SizedBox(height: 4), 
            Text(body, style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12))
          ]
        )
      )
    ]
  ); 
}
''';

  file.writeAsStringSync(newContent);
  // ignore: avoid_print
  print('Successfully updated business_hours_editor.dart');
}
