import 'package:flutter/material.dart';

import '../../domain/entities/outlet_detail_entities.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import 'outlet_details_section_card.dart';

class OutletInformationTab extends StatelessWidget {
  const OutletInformationTab({
    super.key,
    required this.outlet,
    required this.canEdit,
    required this.onEdit,
  });

  final OutletDetail outlet;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= TenantAdminBreakpoints.tablet ? 2 : 1;

    final items = <_InfoItem>[
      _InfoItem(Icons.location_on_outlined, 'Address',
          _join([outlet.addressLine1, outlet.addressLine2])),
      _InfoItem(Icons.location_city_outlined, 'City', outlet.city),
      _InfoItem(
          Icons.map_outlined, 'District / Province', outlet.districtOrProvince),
      _InfoItem(
          Icons.local_post_office_outlined, 'Postal Code', outlet.postalCode),
      _InfoItem(Icons.phone_outlined, 'Phone Number', outlet.phoneNumber),
      _InfoItem(Icons.email_outlined, 'Email Address', outlet.emailAddress),
      _InfoItem(
          Icons.storefront_outlined, 'Outlet Type', outlet.displayOutletType),
      _InfoItem(Icons.access_time, 'Operating Hours', outlet.operatingHours),
      _InfoItem(Icons.person_outline, 'Manager Name', outlet.managerName),
      _InfoItem(Icons.event_outlined, 'Opening Date',
          _formatDate(outlet.openingDate)),
      _InfoItem(Icons.receipt_long_outlined, 'Tax / Registration ID',
          outlet.taxRegistrationId),
      _InfoItem(Icons.notes_outlined, 'Notes', outlet.notes),
    ];

    return OutletDetailsSectionCard(
      title: 'Outlet Information',
      trailing: canEdit
          ? TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            )
          : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = columns == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - TenantAdminSpacing.lg) / 2;

          return Wrap(
            spacing: TenantAdminSpacing.lg,
            runSpacing: TenantAdminSpacing.lg,
            children: [
              for (final item in items)
                SizedBox(
                  width: itemWidth,
                  child: _InfoTile(item: item),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String? value;
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.secondary,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: TenantAdminColors.primary, size: 20),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TenantAdminTextStyles.muted(context).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _display(item.value),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _display(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '—';
  }

  return value.trim();
}

String _join(List<String?> parts) {
  final filtered = parts
      .whereType<String>()
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);

  return filtered.isEmpty ? '' : filtered.join(', ');
}

String _formatDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '';
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
}
