import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/till_provider.dart';
import '../../../../shared/pos_session/pos_session_bootstrap_provider.dart';
import '../../../auth/presentation/providers/post_login_navigation_provider.dart';
import '../widgets/open_till_form.dart';

const _oneVerzLogoAsset = 'assets/images/logo.png';
const _maxFormWidth = 1400.0;
const _contentWidthFraction = 0.96;
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
  return (available * _contentWidthFraction).clamp(320, _maxFormWidth);
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
    final device = deviceState.deviceContext;

    if (device != null && !_initializedOpeningFloat) {
      _initializedOpeningFloat = true;
      final defaultFloat = device.defaultOpeningFloatAmount;
      _openingFloatController.text = defaultFloat.toStringAsFixed(2);
    }

    if (device == null || !device.isTrusted) {
      return Scaffold(
        backgroundColor: TenantAdminColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _OneVerzAppHeader(),
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
            const _OneVerzAppHeader(),
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
                        child: SizedBox(
                          width: contentWidth,
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
                      child: SizedBox(
                        width: contentWidth,
                        height: constraints.maxHeight,
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
      final route = ref.read(postLoginRouteProvider);
      context.go(route.path);
    }
  }
}

class _OneVerzAppHeader extends StatelessWidget {
  const _OneVerzAppHeader();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = _horizontalPaddingFor(screenWidth);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: TenantAdminColors.surface,
        border: Border(
          bottom: BorderSide(color: TenantAdminColors.border),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          TenantAdminSpacing.md,
          horizontalPadding,
          TenantAdminSpacing.md,
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: Navigator.of(context).canPop()
                  ? () => Navigator.of(context).maybePop()
                  : null,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: TenantAdminColors.navy,
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Image.asset(
              _oneVerzLogoAsset,
              width: 34,
              height: 34,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Text(
              'OneVerz',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: TenantAdminColors.navy,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
            ),
          ],
        ),
      ),
    );
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
