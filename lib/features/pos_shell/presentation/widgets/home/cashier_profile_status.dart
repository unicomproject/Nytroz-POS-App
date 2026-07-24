import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CashierProfileStatus extends StatelessWidget {
  const CashierProfileStatus({
    super.key,
    required this.label,
    required this.value,
    required this.online,
  });

  final String label;
  final String value;
  final bool online;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            color:
                online ? TenantAdminColors.success : TenantAdminColors.offline,
            size: 18,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Flexible(
            child: Text(
              '$label · $value',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: TenantAdminColors.surface),
            ),
          ),
        ],
      );
}
