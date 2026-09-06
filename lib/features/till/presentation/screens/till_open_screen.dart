import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/effective_permission_set.dart';
import '../../../../core/access/pos_cash_drawer_till_visibility.dart';
import '../../../../core/access/pos_permission_access.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../auth/presentation/providers/pos_login_branding_provider.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../pos_shell/presentation/widgets/common/pos_top_bar.dart';
import '../../../pos_shell/presentation/widgets/home/pos_dashboard_top_bar_content.dart';
import '../../../pos_shell/presentation/providers/pos_home_dashboard_provider.dart';
import '../providers/till_provider.dart';
import '../../../../shared/pos_session/pos_session_bootstrap_provider.dart';
import '../../../auth/presentation/providers/post_login_navigation_provider.dart';
import '../widgets/open_till_form.dart';

const _maxFormWidth = 1400.0;
const _scrollFallbackHeight = 420.0;

double _horizontalPaddingFor(double width) {
  if (width < TenantAdminBreakpoints.mobile) {
    return TenantAdminSpacing.lg;
  }
  if (width < TenantAdminBreakpoints.tablet) {
    return TenantAdminSpacing.xl;
  }
  return 24;
}

double _contentWidthFor(double maxWidth) {
  final horizontalPadding = _horizontalPaddingFor(maxWidth);
  final available = maxWidth - (horizontalPadding * 2);
  return available.clamp(320, _maxFormWidth);
}

OpenTillFormDensity _densityForSize(double height, double width) {
  if (height < 560 || width < 380) {
    return OpenTillFormDensity.compact;
  }

  return OpenTillFormDensity.regular;
}

class TillOpenScreen extends ConsumerStatefulWidget {
  const TillOpenScreen({super.key});

  @override
  ConsumerState<TillOpenScreen> createState() => _TillOpenScreenState();
}

class _TillOpenScreenState extends ConsumerState<TillOpenScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _openingFloatController;
  late final TextEditingController _openingNoteController;
  bool _initializedOpeningFloat = false;

  @override
  void initState() {
    super.initState();
    _openingFloatController = TextEditingController();
    _openingNoteController = TextEditingController();
  }

  @override
  void dispose() {
    _openingFloatController.dispose();
    _openingNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceActivationProvider);
    final tillState = ref.watch(tillProvider);
    final authSession = ref.watch(authSessionProvider);
    final loginBranding = ref.watch(posLoginBrandingProvider);
    final device = deviceState.deviceContext;
    final brandName = loginBranding.brandDisplayName.trim();
    final brandLogoUrl = loginBranding.logoUrl?.trim();

    final granted = authSession?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canOpenTill(granted)) {
      return const TenantAdminForbiddenScreen();
    }

    if (device != null && !_initializedOpeningFloat) {
      _initializedOpeningFloat = true;
      final perms = EffectivePermissionSet.fromIterable(granted);
      // Seeded default float is protected starting-cash view data.
      if (PosCashDrawerTillVisibility.canShowStartingCashView(perms)) {
        final defaultFloat = device.defaultOpeningFloatAmount;
        _openingFloatController.text = defaultFloat.toStringAsFixed(2);
      } else if (PosCashDrawerTillVisibility.canShowStartingCashEntry(perms)) {
        _openingFloatController.text = '0.00';
      }
    }

    if (device == null || !device.isTrusted) {
      return Scaffold(
        backgroundColor: TenantAdminColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PosTopBar(
                brandName: brandName.isEmpty ? null : brandName,
                brandLogoUrl:
                    brandLogoUrl?.isNotEmpty == true ? brandLogoUrl : null,
                content: const PosDashboardTopBarContent(),
              ),
              Expanded(
                child: Center(
                  child: _BlockedPanel(
                    title: 'Device activation required',
                    message:
                        'This POS device must be trusted before a till can be opened.',
                    actionLabel: 'Activate device',
                    onPressed: () => context.go('/pos/device-activation'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: TenantAdminColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PosTopBar(
              brandName: brandName.isEmpty ? null : brandName,
              brandLogoUrl:
                  brandLogoUrl?.isNotEmpty == true ? brandLogoUrl : null,
              content: const PosDashboardTopBarContent(),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding =
                      _horizontalPaddingFor(constraints.maxWidth);
                  final contentWidth = _contentWidthFor(constraints.maxWidth);
                  final density = _densityForSize(
                    constraints.maxHeight,
                    constraints.maxWidth,
                  );
                  final form = OpenTillForm(
                    formKey: _formKey,
                    openingFloatController: _openingFloatController,
                    openingNoteController: _openingNoteController,
                    errorMessage: tillState.errorMessage,
                    isSubmitting: tillState.isSubmitting,
                    outletName: device.outletName,
                    tillName: device.tillName,
                    deviceName: device.deviceCode,
                    currencyCode: device.currencyCode,
                    openingBy: authSession?.userDisplayName ?? '',
                    density: density,
                    onSubmit: _submitOpenTill,
                  );

                  final cardPadding = density == OpenTillFormDensity.compact
                      ? const EdgeInsets.all(TenantAdminSpacing.md)
                      : const EdgeInsets.all(TenantAdminSpacing.lg);

                  if (constraints.maxHeight < _scrollFallbackHeight) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        TenantAdminSpacing.md,
                        horizontalPadding,
                        TenantAdminSpacing.lg,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: contentWidth,
                          decoration: BoxDecoration(
                            color: TenantAdminColors.surface,
                            borderRadius:
                                BorderRadius.circular(TenantAdminRadius.lg),
                            border: Border.all(color: TenantAdminColors.border),
                            boxShadow: TenantAdminShadows.card,
                          ),
                          padding: cardPadding,
                          child: form,
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      TenantAdminSpacing.md,
                      horizontalPadding,
                      TenantAdminSpacing.lg,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: contentWidth,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: TenantAdminColors.surface,
                          borderRadius:
                              BorderRadius.circular(TenantAdminRadius.lg),
                          border: Border.all(color: TenantAdminColors.border),
                          boxShadow: TenantAdminShadows.card,
                        ),
                        padding: cardPadding,
                        child: form,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitOpenTill() async {
    final granted =
        ref.read(authSessionProvider)?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canOpenTill(granted)) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      setState(() {});
      return;
    }

    final device = ref.read(deviceActivationProvider).deviceContext;
    if (device == null) {
      context.go('/pos/device-activation');
      return;
    }

    final opened = await ref.read(tillProvider.notifier).openTill(
          deviceContext: device,
          openingFloat: double.parse(_openingFloatController.text),
          openingNote: _openingNoteController.text,
        );

    if (opened && mounted) {
      await ref
          .read(posSessionBootstrapProvider.notifier)
          .bootstrap(force: true);
      if (!mounted) {
        return;
      }
      // The Open Till screen header also watches the POS Home provider. Before
      // the till is opened that provider legitimately caches
      // NO_OPEN_TILL_SESSION. Drop that stale result after the authoritative
      // open/refresh completes so POS Home resolves the newly-created session.
      ref.invalidate(posHomeDashboardProvider);
      final route = ref.read(postLoginRouteProvider);
      context.go(route.path);
    }
  }
}

class _BlockedPanel extends StatelessWidget {
  const _BlockedPanel({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: TenantAdminColors.bodyText,
                      ),
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                Text(message),
                const SizedBox(height: TenantAdminSpacing.lg),
                FilledButton(
                  onPressed: onPressed,
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
