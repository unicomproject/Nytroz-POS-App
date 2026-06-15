import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/pos_session/pos_session_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/device_activation_provider.dart';
import '../../../../shared/pos_session/pos_session_bootstrap_provider.dart';
import '../../../auth/presentation/providers/post_login_navigation_provider.dart';
import '../widgets/device_activation_form.dart';

const _logoAsset = 'assets/images/logo.png';
const _terminalAsset = 'assets/images/log-screen-terminal.png';

class DeviceActivationScreen extends ConsumerStatefulWidget {
  const DeviceActivationScreen({super.key});

  @override
  ConsumerState<DeviceActivationScreen> createState() =>
      _DeviceActivationScreenState();
}

class _DeviceActivationScreenState
    extends ConsumerState<DeviceActivationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activationState = ref.watch(deviceActivationProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= TenantAdminBreakpoints.tablet;

    if (isWide) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(
              flex: 45,
              child: _ActivationBrandPanel(compact: false),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFE5EAF2),
            ),
            Expanded(
              flex: 55,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: DeviceActivationForm(
                      formKey: _formKey,
                      codeController: _codeController,
                      isSubmitting: activationState.isSubmitting,
                      errorMessage: activationState.errorMessage,
                      isWide: true,
                      onSubmit: _submit,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.lg,
            vertical: TenantAdminSpacing.xl,
          ),
          child: Column(
            children: [
              const _ActivationBrandPanel(compact: true),
              const SizedBox(height: TenantAdminSpacing.xl),
              DeviceActivationForm(
                formKey: _formKey,
                codeController: _codeController,
                isSubmitting: activationState.isSubmitting,
                errorMessage: activationState.errorMessage,
                isWide: false,
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final sessionContext = ref.read(posSessionContextProvider);
    final activated =
        await ref.read(deviceActivationProvider.notifier).activate(
              activationCode: _codeController.text,
              deviceName: sessionContext.deviceName,
            );

    if (activated && mounted) {
      await ref
          .read(posSessionBootstrapProvider.notifier)
          .bootstrap(force: true);
      final route = ref.read(postLoginRouteProvider);
      context.go(route.path);
    }
  }
}

class _ActivationBrandPanel extends StatelessWidget {
  const _ActivationBrandPanel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 72.0 : 96.0;
    final terminalWidth = compact ? 300.0 : 440.0;
    final terminalHeight = compact ? 215.0 : 320.0;
    final titleSize = compact ? 34.0 : 40.0;
    final taglineSize = compact ? 18.0 : 20.0;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF3F7FF),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? TenantAdminSpacing.lg : 48,
            vertical: compact ? TenantAdminSpacing.xl : 32,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                _logoAsset,
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              Text(
                'Nytroz POS',
                style: TextStyle(
                  color: TenantAdminColors.navy,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.sm),
              Text(
                'Smart Cashier System',
                style: TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontSize: taglineSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: compact ? TenantAdminSpacing.xl : 48),
              Image.asset(
                _terminalAsset,
                width: terminalWidth,
                height: terminalHeight,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
