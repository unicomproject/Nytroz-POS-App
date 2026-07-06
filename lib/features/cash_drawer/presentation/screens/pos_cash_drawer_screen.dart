import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../sale/presentation/widgets/payment/pos_bottom_action_buttons.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../../domain/entities/cash_drawer_summary.dart';
import '../providers/cash_drawer_provider.dart';
import '../widgets/cash_drawer_actions_section.dart';
import '../widgets/cash_drawer_movements_section.dart';
import '../widgets/cash_drawer_page_header.dart';
import '../widgets/cash_drawer_till_summary_section.dart';

class PosCashDrawerScreen extends ConsumerStatefulWidget {
  const PosCashDrawerScreen({super.key});

  @override
  ConsumerState<PosCashDrawerScreen> createState() =>
      _PosCashDrawerScreenState();
}

class _PosCashDrawerScreenState extends ConsumerState<PosCashDrawerScreen> {
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
    final summary = drawerState.summary;

    final canCashIn = PosPermissionAccess.canCreateCashDrawerMovement(granted);
    final canCashOut = PosPermissionAccess.canCreateCashDrawerMovement(granted);
    final canCloseTill = PosPermissionAccess.canCloseTill(granted);
    final actionsEnabled = tillState.hasOpenSession && summary?.isOpen == true;

    return ColoredBox(
      color: TenantAdminColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = TenantAdminInsets.pageForWidth(constraints.maxWidth);

          if (summary == null) {
            return Padding(
              padding: padding,
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          return Padding(
            padding: padding,
            child: SizedBox.expand(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CashDrawerPageHeader(onBack: () => context.go('/pos/home')),
                  if (!tillState.hasOpenSession) ...[
                    const SizedBox(height: TenantAdminSpacing.md),
                    const _TillClosedBanner(),
                  ],
                  const SizedBox(height: TenantAdminSpacing.lg),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CashDrawerTillSummarySection(summary: summary),
                          const SizedBox(height: TenantAdminSpacing.lg),
                          CashDrawerActionsSection(
                            canCashIn: canCashIn,
                            canCashOut: canCashOut,
                            canCloseTill: canCloseTill,
                            actionsEnabled: actionsEnabled,
                            onCashIn: () => _onCashIn(context),
                            onCashOut: () => _onCashOut(context),
                            onCloseTill: () => _onCloseTill(context, summary),
                          ),
                          const SizedBox(height: TenantAdminSpacing.lg),
                          CashDrawerMovementsSection(
                            movements: drawerState.movements,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  PosBottomFilledButton(
                    label: 'Continue',
                    icon: Icons.home_rounded,
                    onPressed: () => context.go('/pos/home'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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

  Future<void> _onCloseTill(
    BuildContext context,
    CashDrawerSummary summary,
  ) async {
    if (!PosPermissionAccess.canCloseTill(
      ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {},
    )) {
      PosPermissionAccess.showAccessDeniedSnackBar(
        context,
        'You do not have permission to close the till.',
      );
      return;
    }

    if (!summary.isOpen) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('An open till session is required to close the till.'),
          ),
        );
      return;
    }

    context.push('/pos/cash-drawer/close-till');
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
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: const Color(0xFFFED7AA)),
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
