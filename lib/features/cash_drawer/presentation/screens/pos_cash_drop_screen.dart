import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../providers/cash_drawer_provider.dart';
import '../providers/cash_drop_provider.dart';
import '../widgets/cash_drawer_section_card.dart';
import '../widgets/cash_drop_bottom_actions.dart';
import '../widgets/cash_drop_form_card.dart';
import '../widgets/cash_drop_page_header.dart';
import '../widgets/cash_drop_summary_card.dart';
import '../widgets/cash_drop_till_info_bar.dart';

class PosCashDropScreen extends ConsumerStatefulWidget {
  const PosCashDropScreen({super.key});

  @override
  ConsumerState<PosCashDropScreen> createState() => _PosCashDropScreenState();
}

class _PosCashDropScreenState extends ConsumerState<PosCashDropScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _managerPinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cashDropFormProvider.notifier).reset();
      _amountController.clear();
      _noteController.clear();
      _managerPinController.clear();
      ref.read(cashDropCatalogProvider.notifier).load();
      ref.read(cashDrawerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _managerPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};

    if (!PosPermissionAccess.canViewCashDrawer(granted) ||
        !PosPermissionAccess.canCreateCashDrawerMovement(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    ref.listen(tillProvider, (_, __) {
      ref.read(cashDrawerProvider.notifier).refresh();
    });

    final tillState = ref.watch(tillProvider);
    final drawerState = ref.watch(cashDrawerProvider);
    final formState = ref.watch(cashDropFormProvider);
    final summary = drawerState.summary;
    final isSubmitting = drawerState.isSubmitting;

    if (summary == null) {
      return const ColoredBox(
        color: TenantAdminColors.background,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!tillState.hasOpenSession || !summary.isOpen) {
      return ColoredBox(
        color: TenantAdminColors.background,
        child: Padding(
          padding:
              TenantAdminInsets.pageForWidth(MediaQuery.sizeOf(context).width),
          child: CashDrawerSectionCard(
            expand: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CashDropPageHeader(),
                const SizedBox(height: TenantAdminSpacing.xl),
                const _TillRequiredMessage(),
                const Spacer(),
                CashDropBottomActions(
                  canConfirm: false,
                  isLoading: false,
                  onCancel: _goBack,
                  onConfirm: () {},
                ),
              ],
            ),
          ),
        ),
      );
    }

    final availableCash = summary.currentExpectedCash;
    final catalog = ref.watch(cashDropCatalogProvider);
    final canConfirm = formState.hasValidAmount &&
        formState.hasSelectedMovementType &&
        catalog.status == CashDropCatalogStatus.ready &&
        (formState.parsedAmount ?? 0) <= availableCash;

    return ColoredBox(
      color: TenantAdminColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = TenantAdminInsets.pageForWidth(constraints.maxWidth);
          final useSideBySide =
              constraints.maxWidth >= TenantAdminBreakpoints.tablet;
          final useTightTabletLayout =
              useSideBySide && constraints.maxHeight < 650;
          final sectionGap = useTightTabletLayout
              ? TenantAdminSpacing.sm
              : TenantAdminSpacing.md;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              padding.left > 16 ? 16 : padding.left,
              padding.top > 12 ? 12 : padding.top,
              padding.right > 16 ? 16 : padding.right,
              padding.bottom > 12 ? 12 : padding.bottom,
            ),
            child: SizedBox.expand(
              child: CashDrawerSectionCard(
                padding: EdgeInsets.all(
                  useTightTabletLayout
                      ? TenantAdminSpacing.md
                      : constraints.maxWidth >= TenantAdminBreakpoints.tablet
                          ? TenantAdminSpacing.lg
                          : TenantAdminSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CashDropPageHeader(),
                    SizedBox(height: sectionGap),
                    CashDropTillInfoBar(
                      summary: summary,
                      compact: useTightTabletLayout,
                    ),
                    SizedBox(height: sectionGap),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, bodyConstraints) {
                          if (useSideBySide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: CashDropFormCard(
                                    formKey: _formKey,
                                    amountController: _amountController,
                                    noteController: _noteController,
                                    managerPinController: _managerPinController,
                                    availableCash: availableCash,
                                    currencyCode: summary.currencyCode,
                                    expand: true,
                                    compact: true,
                                    tight: useTightTabletLayout,
                                  ),
                                ),
                                const SizedBox(width: TenantAdminSpacing.md),
                                Expanded(
                                  flex: 3,
                                  child: CashDropSummaryCard(
                                    currentExpectedCash: availableCash,
                                    currencyCode: summary.currencyCode,
                                    expand: true,
                                    compact: true,
                                    tight: useTightTabletLayout,
                                  ),
                                ),
                              ],
                            );
                          }

                          return ClipRect(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topCenter,
                              child: SizedBox(
                                width: bodyConstraints.maxWidth,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    CashDropSummaryCard(
                                      currentExpectedCash: availableCash,
                                      currencyCode: summary.currencyCode,
                                      compact: true,
                                    ),
                                    const SizedBox(
                                      height: TenantAdminSpacing.md,
                                    ),
                                    CashDropFormCard(
                                      formKey: _formKey,
                                      amountController: _amountController,
                                      noteController: _noteController,
                                      managerPinController:
                                          _managerPinController,
                                      availableCash: availableCash,
                                      currencyCode: summary.currencyCode,
                                      compact: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: sectionGap),
                    CashDropBottomActions(
                      canConfirm: canConfirm,
                      isLoading: isSubmitting,
                      onCancel: _goBack,
                      onConfirm: _submit,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/pos/cash-drawer');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final formController = ref.read(cashDropFormProvider.notifier);
    final formState = ref.read(cashDropFormProvider);
    final amount = formState.parsedAmount;
    final movementTypeId = formState.selectedMovementTypeId?.trim();
    if (amount == null || amount <= 0 || movementTypeId == null) {
      return;
    }

    if (ref.read(cashDrawerProvider).isSubmitting) {
      return;
    }

    final requestId = formController.ensurePendingRequestId();
    final success = await ref.read(cashDrawerProvider.notifier).recordCashDrop(
          amount: amount,
          movementTypeId: movementTypeId,
          requestId: requestId,
          note: formState.note,
        );

    if (!mounted) {
      return;
    }

    if (success) {
      formController.reset();
      _amountController.clear();
      _noteController.clear();
      _managerPinController.clear();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Cash drop recorded successfully.')),
        );
      _goBack();
      return;
    }

    final error = ref.read(cashDrawerProvider).errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _TillRequiredMessage extends StatelessWidget {
  const _TillRequiredMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.warningSurface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.warningBorder),
      ),
      child: Text(
        'An open till session is required before recording a cash drop.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
