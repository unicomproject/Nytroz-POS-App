import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/inventory_entities.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../providers/inventory_providers.dart';

class StockInReferenceSection extends ConsumerWidget {
  const StockInReferenceSection({
    super.key,
    required this.outlets,
    required this.fieldErrors,
  });

  final List<AccessibleOutletOption> outlets;
  final Map<String, String> fieldErrors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(stockInFormProvider);
    final notifier = ref.read(stockInFormProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reference details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          DropdownButtonFormField<String?>(
            initialValue: form.outletId,
            decoration: InputDecoration(
              labelText: 'Outlet *',
              border: const OutlineInputBorder(),
              errorText: fieldErrors['outletId'],
            ),
            items: outlets
                .map(
                  (outlet) => DropdownMenuItem<String?>(
                    value: outlet.id,
                    child: Text(outlet.name),
                  ),
                )
                .toList(),
            onChanged: notifier.setOutletId,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          TextFormField(
            initialValue: form.referenceNumber,
            decoration: InputDecoration(
              labelText: 'Reference number',
              border: const OutlineInputBorder(),
              errorText: fieldErrors['referenceNumber'],
            ),
            onChanged: notifier.setReferenceNumber,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Received date/time'),
            subtitle: Text(
              form.receivedAt?.toLocal().toString() ?? 'Not set',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today_outlined),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: form.receivedAt ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date == null || !context.mounted) return;

                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(
                    form.receivedAt ?? DateTime.now(),
                  ),
                );
                if (time == null) return;

                notifier.setReceivedAt(
                  DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  ),
                );
              },
            ),
          ),
          if (fieldErrors['receivedAt'] != null)
            Text(
              fieldErrors['receivedAt']!,
              style: const TextStyle(color: TenantAdminColors.danger),
            ),
          const SizedBox(height: TenantAdminSpacing.md),
          TextFormField(
            initialValue: form.notes,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Notes',
              border: const OutlineInputBorder(),
              errorText: fieldErrors['notes'],
            ),
            onChanged: notifier.setNotes,
          ),
        ],
      ),
    );
  }
}
