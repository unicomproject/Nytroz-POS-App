import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import 'product_section_card.dart';

class ProductStatusSection extends StatelessWidget {
  const ProductStatusSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ProductSectionCard(
      title: 'Status',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              initialValue: 'draft',
              decoration: const InputDecoration(
                labelText: 'Status *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'draft', child: Text('Draft')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
              ],
              onChanged: null,
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.lg),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(TenantAdminSpacing.lg),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F7EE),
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
              child: const Text(
                'New products are currently saved as draft by the backend. '
                'Status selection will be enabled when the update API is available.',
                style: TextStyle(
                  color: Color(0xFF067647),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
