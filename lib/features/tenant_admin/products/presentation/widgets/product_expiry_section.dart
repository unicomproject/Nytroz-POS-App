import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import 'product_section_card.dart';

class ProductExpirySection extends StatelessWidget {
  const ProductExpirySection({
    super.key,
    required this.enabled,
  });

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ProductSectionCard(
      title: 'Expiry / Batch Details',
      subtitle: 'Optional',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Has Expiry Date'),
            value: false,
            onChanged: enabled ? (_) {} : null,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Opacity(
            opacity: enabled ? 0.45 : 0.35,
            child: const Column(
              children: [
                TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Batch Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: TenantAdminSpacing.md),
                TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Manufacture Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                SizedBox(height: TenantAdminSpacing.md),
                TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Expiry Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                SizedBox(height: TenantAdminSpacing.md),
                TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Expiry Alert Days',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            enabled
                ? 'Batch/expiry create API is not available yet. This section is shown for layout only.'
                : 'Expiry/batch permission is not available.',
            style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
