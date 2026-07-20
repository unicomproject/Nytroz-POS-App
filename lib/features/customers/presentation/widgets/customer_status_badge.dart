import 'package:flutter/material.dart';

import '../../../sale/domain/entities/pos_customer.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CustomerStatusBadge extends StatelessWidget {
  const CustomerStatusBadge({
    super.key,
    required this.customer,
  });

  final PosCustomer customer;

  @override
  Widget build(BuildContext context) {
    final active = customer.isActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE8F8EF) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        customer.statusLabel,
        style: TextStyle(
          color: active ? TenantAdminColors.success : TenantAdminColors.danger,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
