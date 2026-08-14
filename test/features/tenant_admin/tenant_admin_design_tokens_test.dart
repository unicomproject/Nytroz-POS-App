import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

void main() {
  group('Tenant Admin design tokens', () {
    test('locks the approved orange primary brand color', () {
      expect(TenantAdminColors.primary, const Color(0xFFFF6A00));
      expect(TenantAdminColors.primaryHover, const Color(0xFFE85F00));
      expect(TenantAdminColors.secondary, const Color(0xFFFFF3EA));
    });

    test('keeps tablet-friendly control and header heights', () {
      expect(TenantAdminAppHeaderTokens.height, 44);
      expect(TenantAdminContentTokens.buttonHeight, 44);
      expect(TenantAdminContentTokens.tabletButtonHeight, 48);
      expect(TenantAdminContentTokens.defaultListPageSize, 5);
    });

    test('uses centralized responsive page padding', () {
      expect(
        TenantAdminInsets.pageForWidth(390),
        const EdgeInsets.all(TenantAdminSpacing.lg),
      );
      expect(
        TenantAdminInsets.pageForWidth(820),
        const EdgeInsets.all(TenantAdminSpacing.lg),
      );
      expect(
        TenantAdminInsets.pageForWidth(1180),
        const EdgeInsets.all(TenantAdminSpacing.xlg),
      );
      expect(
        TenantAdminInsets.pageForWidth(1600),
        const EdgeInsets.fromLTRB(
          TenantAdminSpacing.xl,
          TenantAdminSpacing.xl,
          TenantAdminSpacing.xl,
          TenantAdminSpacing.xlg,
        ),
      );
    });
  });
}
