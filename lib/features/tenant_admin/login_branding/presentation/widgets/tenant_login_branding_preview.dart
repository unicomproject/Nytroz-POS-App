import 'package:flutter/material.dart';

import '../../../../auth/domain/entities/pos_login_branding.dart';
import '../../../../auth/presentation/widgets/pos_login_branding_panel.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';

class TenantLoginBrandingPreview extends StatelessWidget {
  const TenantLoginBrandingPreview({super.key, required this.branding});

  final PosLoginBranding branding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Live preview',
            style: TenantAdminTextStyles.sectionTitle(context)),
        const SizedBox(height: TenantAdminSpacing.sm),
        Text(
          'Preview updates before save. Tenant logo and brand name come from the canonical tenant profile.',
          style: TenantAdminTextStyles.muted(context),
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        PosLoginBrandingPanel(branding: branding, compact: true),
        const SizedBox(height: TenantAdminSpacing.md),
        Text(
          branding.loginSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: TenantAdminColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
