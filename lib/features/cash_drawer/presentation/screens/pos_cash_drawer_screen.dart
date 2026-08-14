import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../hardware/receipt_printer/presentation/providers/cash_drawer_controller.dart'
    as hardware;
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../providers/cash_drawer_provider.dart';
import '../widgets/cash_drawer_actions_section.dart';
import '../widgets/cash_drawer_movements_section.dart';
import '../widgets/cash_drawer_page_header.dart';
import '../widgets/cash_drawer_section_card.dart';
import '../widgets/cash_drawer_till_summary_section.dart';
import '../../domain/entities/cash_drawer_summary.dart';

class PosCashDrawerScreen extends ConsumerStatefulWidget {
  const PosCashDrawerScreen({super.key});

  @override
  ConsumerState<PosCashDrawerScreen> createState() =>
      _PosCashDrawerScreenState();
}

class _PosCashDrawerScreenState extends ConsumerState<PosCashDrawerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(cashDrawerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    if (!PosPermissionAccess.canViewCashDrawer(
      session?.permissionCodes.toSet() ?? const {},
    )) {
      return const TenantAdminForbiddenScreen();
    }

    ref.listen(tillProvider, (_, __) {
      ref.read(cashDrawerProvider.notifier).refresh();
    });

    final tillState = ref.watch(tillProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};
    final drawerState = ref.watch(cashDrawerProvider);
    final hardwareState = ref.watch(hardware.cashDrawerControllerProvider);
    final summary = drawerState.summary;

    final canOpenDrawer =
        PosPermissionAccess.canManageCashDrawerActions(granted);
    final canCashIn = PosPermissionAccess.canCreateCashDrawerMovement(granted);
    final canCashOut = PosPermissionAccess.canCreateCashDrawerMovement(granted);
    final canCloseTill = PosPermissionAccess.canCloseTill(granted);
    final actionsEnabled =
        tillState.hasOpenSession && (summary?.isOpen ?? false);

    return ColoredBox(
      color: TenantAdminColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = TenantAdminInsets.pageForWidth(constraints.maxWidth);
          final wide = constraints.maxWidth >= TenantAdminBreakpoints.tablet;

          return Padding(
            padding: padding,
            child: CashDrawerSectionCard(
              padding: EdgeInsets.all(
                wide ? TenantAdminSpacing.xxl : TenantAdminSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CashDrawerPageHeader(),
                  if (!tillState.hasOpenSession ||
                      (summary != null && !summary.isOpen)) ...[
                    const SizedBox(height: TenantAdminSpacing.md),
                    const _TillClosedBanner(),
                  ],
                  if (drawerState.errorMessage != null) ...[
                    const SizedBox(height: TenantAdminSpacing.md),
                    _ErrorBanner(
                      message: drawerState.errorMessage!,
                      onRetry: () =>
                          ref.read(cashDrawerProvider.notifier).refresh(),
                    ),
                  ],
                  const SizedBox(height: TenantAdminSpacing.lg),
                  Expanded(
                    child: _buildBody(
                      drawerState: drawerState,
                      summary: summary,
                      wide: wide,
                      canOpenDrawer: canOpenDrawer,
                      canCashIn: canCashIn,
                      canCashOut: canCashOut,
                      canCloseTill: canCloseTill,
                      actionsEnabled: actionsEnabled,
                      openDrawerBusy: hardwareState.isBusy,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody({
    required CashDrawerState drawerState,
    required CashDrawerSummary? summary,
    required bool wide,
    required bool canOpenDrawer,
    required bool canCashIn,
    required bool canCashOut,
    required bool canCloseTill,
    required bool actionsEnabled,
    required bool openDrawerBusy,
  }) {
    if (drawerState.isLoading && summary == null) {
      return Center(
        child: Semantics(
          label: 'Loading cash drawer',
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (summary == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              drawerState.errorMessage ??
                  'Cash drawer summary is unavailable for this device.',
              textAlign: TextAlign.center,
              style: TenantAdminTextStyles.muted(context),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            FilledButton(
              onPressed: () => ref.read(cashDrawerProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final actions = CashDrawerActionsSection(
      canOpenDrawer: canOpenDrawer,
      canCashIn: canCashIn,
      canCashOut: canCashOut,
      canCloseTill: canCloseTill,
      actionsEnabled: actionsEnabled,
      openDrawerBusy: openDrawerBusy,
      onOpenDrawer: () => _onOpenDrawer(context),
      onCashIn: () => _onCashIn(context),
      onCashOut: () => _onCashOut(context),
      onCloseTill: () => _onCloseTill(context),
    );
    final movements = CashDrawerMovementsSection(
      movements: drawerState.movements,
      currencyCode: summary.currencyCode,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CashDrawerTillSummarySection(summary: summary),
          const SizedBox(height: TenantAdminSpacing.lg),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: actions),
                const SizedBox(width: TenantAdminSpacing.lg),
                Expanded(flex: 6, child: movements),
              ],
            )
          else ...[
            actions,
            const SizedBox(height: TenantAdminSpacing.lg),
            movements,
          ],
        ],
      ),
    );
  }

  Future<void> _onOpenDrawer(BuildContext context) async {
    if (!PosPermissionAccess.canManageCashDrawerActions(
      ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {},
    )) {
      PosPermissionAccess.showAccessDeniedSnackBar(
        context,
        'You do not have permission to open the cash drawer.',
      );
      return;
    }

    final tillState = ref.read(tillProvider);
    if (!tillState.hasOpenSession) {
      _showMessage(
        context,
        'Till is not open. Open a till session to perform drawer actions.',
      );
      return;
    }

    final ok = await ref
        .read(hardware.cashDrawerControllerProvider.notifier)
        .triggerManualNoSaleOpen(reason: 'Manual open from Cash Drawer');

    if (!context.mounted) return;
    final message = ref.read(hardware.cashDrawerControllerProvider).message;
    final fallback =
        ok ? 'Cash drawer open requested.' : 'Cash drawer could not be opened.';
    _showMessage(
      context,
      message.trim().isEmpty ? fallback : message,
    );
  }

  void _onCashIn(BuildContext context) {
    if (!PosPermissionAccess.canCreateCashDrawerMovement(
      ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {},
    )) {
      PosPermissionAccess.showAccessDeniedSnackBar(
        context,
        'You do not have permission to record cash in.',
      );
      return;
    }
    context.push('/pos/cash-drawer/cash-in');
  }

  void _onCashOut(BuildContext context) {
    if (!PosPermissionAccess.canCreateCashDrawerMovement(
      ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {},
    )) {
      PosPermissionAccess.showAccessDeniedSnackBar(
        context,
        'You do not have permission to record cash out.',
      );
      return;
    }
    context.push('/pos/cash-drawer/cash-drop');
  }

  void _onCloseTill(BuildContext context) {
    if (!PosPermissionAccess.canCloseTill(
      ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {},
    )) {
      PosPermissionAccess.showAccessDeniedSnackBar(
        context,
        'You do not have permission to close the till.',
      );
      return;
    }

    if (!ref.read(tillProvider).hasOpenSession) {
      _showMessage(
        context,
        'An open till session is required to close the till.',
      );
      return;
    }

    ref.read(cashDrawerProvider.notifier).refresh();
    context.push('/pos/cash-drawer/close-till');
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TillClosedBanner extends StatelessWidget {
  const _TillClosedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.warningSurface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.warningBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: TenantAdminColors.warning,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              'Till is not open. Open a till session to perform drawer actions.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
          color: TenantAdminColors.danger.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: TenantAdminColors.danger),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
