import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/post_login_navigation_provider.dart';
import '../../../../shared/pos_session/pos_session_bootstrap_provider.dart';

import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_cash_drawer_till_visibility.dart';
import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../providers/cash_drawer_provider.dart';
import '../providers/close_till_provider.dart';
import '../widgets/close_till_bottom_actions.dart';
import '../widgets/cash_drawer_section_card.dart';
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
  bool get _isEndShiftFlow {
    final endShift = GoRouterState.of(context).uri.queryParameters['endShift'];
    return endShift == 'true' || endShift == '1';
  }

  final _formKey = GlobalKey<FormState>();
  final _countedCashController = TextEditingController();
  final _notesController = TextEditingController();
  var _initializedForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _loadCloseTillData();
    });
  }

  Future<void> _loadCloseTillData() async {
    final device = ref.read(deviceActivationProvider).deviceContext;
    if (device != null) {
      await ref
          .read(tillProvider.notifier)
          .refreshCurrentSession(deviceContext: device, force: true);
    }
    await ref.read(cashDrawerProvider.notifier).refresh();
    if (!mounted) return;
    _initializeCloseTillForm();
    setState(() {});
  }

  @override
  void dispose() {
    _countedCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _syncControllersFromFormState() {
    final formState = ref.read(closeTillFormProvider);
    _countedCashController.text = formState.countedCashText;
    _notesController.text = formState.notes;
  }

  void _initializeCloseTillForm() {
    if (_initializedForm) {
      return;
    }

    final tillState = ref.read(tillProvider);
    final summary = ref.read(cashDrawerProvider).summary;
    if (!tillState.hasOpenSession || summary == null || !summary.isOpen) {
      return;
    }
    final formNotifier = ref.read(closeTillFormProvider.notifier);

    formNotifier.reset();
    formNotifier.restoreDraftIfAvailable();

    final permissions = ref.read(effectivePermissionSetProvider);
    // Blind count: never default counted cash from expected when expected denied.
    if (PosCashDrawerTillVisibility.canShowClosingExpectedCash(permissions)) {
      formNotifier.applyDefaultCountedCash(summary.currentExpectedCash);
    }

    _syncControllersFromFormState();
    _initializedForm = true;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const {};

    if (!PosPermissionAccess.canCloseTill(granted)) {
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

    if (summary != null &&
        tillState.hasOpenSession &&
        summary.isOpen &&
        !_initializedForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _initializedForm) {
          return;
        }
        _initializeCloseTillForm();
        setState(() {});
      });
    }

    if (summary == null && drawerState.isLoading) {
      return const ColoredBox(
        color: TenantAdminColors.background,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (summary == null) {
      return ColoredBox(
        color: TenantAdminColors.background,
        child: Padding(
          padding:
              TenantAdminInsets.pageForWidth(MediaQuery.sizeOf(context).width),
          child: CashDrawerSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CloseTillPageHeader(onBack: _goBack),
                const Spacer(),
                _CloseTillLoadError(
                  message: drawerState.errorMessage ??
                      ref.watch(tillProvider).errorMessage ??
                      'Close till information is unavailable.',
                  onRetry: _loadCloseTillData,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }

    if (!tillState.hasOpenSession || !summary.isOpen) {
      return ColoredBox(
        color: TenantAdminColors.background,
        child: Padding(
          padding:
              TenantAdminInsets.pageForWidth(MediaQuery.sizeOf(context).width),
          child: CashDrawerSectionCard(
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
                  onCloseTill: () {},
                ),
              ],
            ),
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
            padding: EdgeInsets.fromLTRB(
              padding.left > 16 ? 16 : padding.left,
              padding.top > 12 ? 12 : padding.top,
              padding.right > 16 ? 16 : padding.right,
              padding.bottom > 12 ? 12 : padding.bottom,
            ),
            child: SizedBox.expand(
              child: CashDrawerSectionCard(
                padding: EdgeInsets.all(
                  constraints.maxWidth >= TenantAdminBreakpoints.tablet
                      ? TenantAdminSpacing.lg
                      : TenantAdminSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CloseTillPageHeader(onBack: _goBack),
                    const SizedBox(height: 8),
                    CloseTillTillInfoBar(summary: summary),
                    const SizedBox(height: 8),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, bodyConstraints) {
                          final useColumns = bodyConstraints.maxWidth >=
                              TenantAdminBreakpoints.tablet;
                          final form = CloseTillFormCard(
                            formKey: _formKey,
                            countedCashController: _countedCashController,
                            notesController: _notesController,
                            expectedCash: expectedCash,
                          );
                          final summaryColumn = Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CloseTillSummaryCard(expectedCash: expectedCash),
                              if (showMismatchWarning) ...[
                                const SizedBox(height: 8),
                                const CloseTillMismatchWarningCard(),
                              ],
                              const Spacer(),
                            ],
                          );

                          if (useColumns) {
                            // Fixed two-column fit — no page scroll.
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 5, child: form),
                                const SizedBox(width: 12),
                                Expanded(flex: 3, child: summaryColumn),
                              ],
                            );
                          }

                          // Narrow: fixed vertical split, no page scroll.
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 3, child: form),
                              const SizedBox(height: 8),
                              Expanded(flex: 2, child: summaryColumn),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    CloseTillBottomActions(
                      canCloseTill: canCloseTill,
                      isLoading: isSubmitting,
                      onCloseTill: _closeTill,
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
    if (_isEndShiftFlow) {
      context.go('/pos/home');
      return;
    }

    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/pos/cash-drawer');
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
      if (_isEndShiftFlow) {
        await ref.read(authSessionProvider.notifier).clear();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                message ?? 'Shift ended. Till closed successfully.',
              ),
            ),
          );
        context.go('/tenant-login');
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              message ?? 'Till closed successfully.',
            ),
          ),
        );
      await ref
          .read(posSessionBootstrapProvider.notifier)
          .bootstrap(force: true);
      if (!mounted) {
        return;
      }
      final route = ref.read(postLoginRouteProvider);
      context.go(route.path);
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

class _CloseTillLoadError extends StatelessWidget {
  const _CloseTillLoadError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: CashDrawerSectionCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: TenantAdminColors.danger, size: 40),
              const SizedBox(height: TenantAdminSpacing.md),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: TenantAdminSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
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
        'An open till session is required before closing the till.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
