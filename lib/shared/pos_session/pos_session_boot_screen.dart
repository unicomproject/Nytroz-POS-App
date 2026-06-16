import 'package:flutter/material.dart';

import '../../features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosSessionBootScreen extends StatelessWidget {
  const PosSessionBootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F9FD),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: TenantAdminColors.navy,
              ),
            ),
            SizedBox(height: TenantAdminSpacing.lg),
            Text(
              'Preparing POS session...',
              style: TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
