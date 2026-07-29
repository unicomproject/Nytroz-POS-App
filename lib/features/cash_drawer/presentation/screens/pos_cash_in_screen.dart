import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../providers/cash_drawer_provider.dart';
import '../providers/cash_in_provider.dart';
import '../widgets/cash_in_bottom_actions.dart';
import '../widgets/cash_in_form_card.dart';
import '../widgets/cash_in_page_header.dart';
import '../widgets/cash_in_summary_card.dart';
import '../widgets/cash_in_till_info_bar.dart';

class PosCashInScreen extends ConsumerStatefulWidget {
  const PosCashInScreen({super.key});

  @override
  ConsumerState<PosCashInScreen> createState() => _PosCashInScreenState();
}

class _PosCashInScreenState extends ConsumerState<PosCashInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _managerPinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cashInFormProvider.notifier).reset();
      _amountController.clear();
      _noteController.clear();
      _managerPinController.clear();
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
    final formState = ref.watch(cashInFormProvider);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CashInPageHeader(onBack: _goBack),
              const SizedBox(height: TenantAdminSpacing.xl),
              const _TillRequiredMessage(),
              const Spacer(),
              CashInBottomActions(
                canConfirm: false,
                isLoading: false,
                onCancel: _goBack,
                onConfirm: () {},
              ),
            ],
          ),
        ),
      );
    }

    final canConfirm =
        formState.hasValidAmount && (formState.reason?.isNotEmpty == true);

    return ColoredBox(
      color: TenantAdminColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = TenantAdminInsets.pageForWidth(constraints.maxWidth);
          final useSideBySide =
              constraints.maxWidth >= TenantAdminBreakpoints.tablet;

          return Padding(
            padding: padding,
            child: SizedBox.expand(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CashInPageHeader(onBack: _goBack),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  CashInTillInfoBar(summary: summary),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  Expanded(
                    child: SingleChildScrollView(
                      child: useSideBySide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: CashInFormCard(
                                    formKey: _formKey,
                                    amountController: _amountController,
                                    noteController: _noteController,
                                    managerPinController: _managerPinController,
                                  ),
                                ),
                                const SizedBox(width: TenantAdminSpacing.lg),
                                Expanded(
                                  flex: 2,
                                  child: CashInSummaryCard(
                                    currentExpectedCash:
                                        summary.currentExpectedCash,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                CashInSummaryCard(
                                  currentExpectedCash:
                                      summary.currentExpectedCash,
                                ),
                                const SizedBox(height: TenantAdminSpacing.lg),
                                CashInFormCard(
                                  formKey: _formKey,
                                  amountController: _amountController,
                                  noteController: _noteController,
                                  managerPinController: _managerPinController,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  CashInBottomActions(
                    canConfirm: canConfirm,
                    isLoading: isSubmitting,
                    onCancel: _goBack,
                    onConfirm: _submit,
                  ),
                ],
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

    final formState = ref.read(cashInFormProvider);
    final amount = formState.parsedAmount;
    if (amount == null || amount <= 0) {
      return;
    }

    final success = await ref.read(cashDrawerProvider.notifier).recordCashIn(
          amount: amount,
          reason: formState.reason,
          note: formState.note,
        );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Cash in recorded successfully.')),
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
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Text(
        'An open till session is required before recording cash in.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
