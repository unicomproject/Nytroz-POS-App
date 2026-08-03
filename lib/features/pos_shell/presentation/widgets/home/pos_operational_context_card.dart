import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosOperationalContextCard extends StatelessWidget {
  const PosOperationalContextCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: const Color(0xFF2E3138),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF94A3B8),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
