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

    test('overlay menus stay white instead of peach surface tint', () {
      expect(TenantAdminOverlaySurfaces.color, TenantAdminColors.surface);
      expect(TenantAdminOverlaySurfaces.surfaceTint, Colors.transparent);
      expect(
        TenantAdminOverlaySurfaces.popupMenuTheme.color,
        TenantAdminColors.surface,
      );
      expect(
        TenantAdminOverlaySurfaces.popupMenuTheme.surfaceTintColor,
        Colors.transparent,
      );

      final peachScheme = ColorScheme.fromSeed(
        seedColor: TenantAdminColors.primary,
      );
      final overlayScheme =
          TenantAdminOverlaySurfaces.withoutPeachTint(peachScheme);
      expect(overlayScheme.surfaceContainer, TenantAdminColors.surface);
      expect(overlayScheme.surfaceTint, Colors.transparent);
      expect(overlayScheme.surfaceContainer, isNot(peachScheme.surfaceContainer));
    });

    test('keeps tablet-friendly control and header heights', () {
      expect(TenantAdminAppHeaderTokens.height, 74.0);
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

  testWidgets('3-dot popup menu card is white, not peach', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: TenantAdminOverlaySurfaces.withoutPeachTint(
            ColorScheme.fromSeed(seedColor: TenantAdminColors.primary),
          ),
          canvasColor: TenantAdminOverlaySurfaces.color,
          popupMenuTheme: TenantAdminOverlaySurfaces.popupMenuTheme,
        ),
        home: Scaffold(
          body: PopupMenuButton<String>(
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'status', child: Text('Inactivate')),
              PopupMenuItem(value: 'archive', child: Text('Archive')),
            ],
            child: const Icon(Icons.more_vert),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Inactivate'), findsOneWidget);

    final menuMaterials = tester
        .widgetList<Material>(
          find.ancestor(
            of: find.text('Inactivate'),
            matching: find.byType(Material),
          ),
        )
        .toList();

    expect(
      menuMaterials.any(
        (material) =>
            material.color == TenantAdminColors.surface ||
            material.color == Colors.white,
      ),
      isTrue,
    );
    expect(
      menuMaterials.every(
        (material) => material.color != TenantAdminColors.secondary,
      ),
      isTrue,
    );
  });
}
