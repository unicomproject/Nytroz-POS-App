import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CashierProfileStatus extends StatelessWidget {
  const CashierProfileStatus({
    super.key,
    required this.label,
    required this.value,
    required this.online,
    this.showConnectivity = true,
  });

  final String label;
  final String value;
  final bool online;
  final bool showConnectivity;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showConnectivity) ...[
            Icon(
              online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              color: online
                  ? TenantAdminColors.success
                  : TenantAdminColors.offline,
              size: 18,
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
          ],
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
