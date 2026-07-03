import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import 'product_section_card.dart';

class ProductVariantSection extends StatelessWidget {
  const ProductVariantSection({
    super.key,
    required this.enabled,
  });

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ProductSectionCard(
      title: 'Variant Details',
      subtitle: 'Optional',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Has Variants'),
            value: false,
            onChanged: enabled ? (_) {} : null,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Opacity(
            opacity: enabled ? 0.45 : 0.35,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: null,
                        decoration: const InputDecoration(
                          labelText: 'Variant Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [],
                        onChanged: null,
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.sm),
                    const Expanded(
                      child: TextField(
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Variant Value',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Variant'),
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(TenantAdminSpacing.lg),
                  decoration: BoxDecoration(
                    border: Border.all(color: TenantAdminColors.border),
                    borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                  ),
                  child: const Text('No variants added yet.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            enabled
                ? 'Variant create API is not available yet. This section is shown for layout only.'
                : 'Variant manage permission is not available.',
            style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
