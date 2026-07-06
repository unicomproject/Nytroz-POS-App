import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../providers/cash_drawer_provider.dart';
import '../providers/close_till_provider.dart';
import '../widgets/close_till_bottom_actions.dart';
import '../widgets/close_till_form_card.dart';
import '../widgets/close_till_mismatch_warning_card.dart';
import '../widgets/close_till_page_header.dart';
import '../widgets/close_till_summary_card.dart';
import '../widgets/close_till_till_info_bar.dart';

class PosCloseTillScreen extends ConsumerStatefulWidget {
  const PosCloseTillScreen({super.key});

  @override
  ConsumerState<PosCloseTillScreen> createState() => _PosCloseTillScreenState();
}

class _PosCloseTillScreenState extends ConsumerState<PosCloseTillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _countedCashController = TextEditingController();
  final _notesController = TextEditingController();
  final _managerPinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(closeTillFormProvider.notifier).reset();
      ref.read(closeTillFormProvider.notifier).restoreDraftIfAvailable();
      _syncControllersFromFormState();
    });
  }

  @override
  void dispose() {
    _countedCashController.dispose();
    _notesController.dispose();
    _managerPinController.dispose();
    super.dispose();
  }

  void _syncControllersFromFormState() {
    final formState = ref.read(closeTillFormProvider);
    _countedCashController.text = formState.countedCashText;
    _notesController.text = formState.notes;
    _managerPinController.text = formState.managerPin;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};

    if (!PosPermissionAccess.canViewCashDrawer(granted) ||
        !PosPermissionAccess.canCloseTill(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    ref.listen(tillProvider, (_, __) {
      ref.read(cashDrawerProvider.notifier).refresh();
    });

    final tillState = ref.watch(tillProvider);
    final drawerState = ref.watch(cashDrawerProvider);
    final formState = ref.watch(closeTillFormProvider);
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
              CloseTillPageHeader(onBack: _goBack),
              const SizedBox(height: TenantAdminSpacing.xl),
              const _TillRequiredMessage(),
              const Spacer(),
              CloseTillBottomActions(
                canCloseTill: false,
                isLoading: false,
                onSaveDraft: () {},
                onCloseTill: () {},
              ),
            ],
          ),
        ),
      );
    }

    final expectedCash = summary.currentExpectedCash;
    final difference = formState.differenceFor(expectedCash);
    final showMismatchWarning = difference != null && difference != 0;
    final canCloseTill = formState.hasValidCountedCash;

    return ColoredBox(
      color: TenantAdminColors.background,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = TenantAdminInsets.pageForWidth(constraints.maxWidth);

          return Padding(
            padding: padding,
            child: SizedBox.expand(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CloseTillPageHeader(onBack: _goBack),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  CloseTillTillInfoBar(summary: summary),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CloseTillFormCard(
                            formKey: _formKey,
                            countedCashController: _countedCashController,
                            notesController: _notesController,
                            managerPinController: _managerPinController,
                            expectedCash: expectedCash,
                          ),
                          if (showMismatchWarning) ...[
                            const SizedBox(height: TenantAdminSpacing.lg),
                            const CloseTillMismatchWarningCard(),
                          ],
                          const SizedBox(height: TenantAdminSpacing.lg),
                          CloseTillSummaryCard(expectedCash: expectedCash),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  CloseTillBottomActions(
                    canCloseTill: canCloseTill,
                    isLoading: isSubmitting,
                    onSaveDraft: _saveDraft,
                    onCloseTill: _closeTill,
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

  void _saveDraft() {
    ref.read(closeTillFormProvider.notifier).saveDraft();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Close till draft saved locally.')),
      );
  }

  Future<void> _closeTill() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final formState = ref.read(closeTillFormProvider);
    final counted = formState.parsedCountedCash;
    if (counted == null) {
      return;
    }

    final success = await ref.read(cashDrawerProvider.notifier).submitCloseTill(
          countedCash: counted,
          mismatchReason: formState.mismatchReason,
          note: formState.notes,
        );

    if (!mounted) {
      return;
    }

    if (success) {
      ref.read(closeTillFormProvider.notifier).reset();
      final message = ref.read(cashDrawerProvider).closeTillMessage;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              message ?? 'Till close request recorded locally.',
            ),
          ),
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
        'An open till session is required before closing the till.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
