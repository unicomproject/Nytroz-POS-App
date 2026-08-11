import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/pos_session/pos_session_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/device_activation_provider.dart';
import '../../../../shared/pos_session/pos_session_bootstrap_provider.dart';
import '../../../auth/presentation/providers/post_login_navigation_provider.dart';
import '../../../auth/presentation/providers/pos_login_branding_provider.dart';
import '../../../auth/domain/entities/pos_login_branding.dart';
import '../../../auth/presentation/widgets/pos_login_branding_panel.dart';
import '../widgets/device_activation_form.dart';

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
    final branding = ref.watch(posLoginBrandingProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= TenantAdminBreakpoints.tablet;

    if (isWide) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 45,
              child: PosLoginBrandingPanel(
                branding: branding.tenantSlug.isEmpty &&
                        branding.brandDisplayName.isEmpty
                    ? PosLoginBranding.packagedDefault
                    : branding,
                compact: false,
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: TenantAdminColors.border,
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
              PosLoginBrandingPanel(
                branding: branding.tenantSlug.isEmpty &&
                        branding.brandDisplayName.isEmpty
                    ? PosLoginBranding.packagedDefault
                    : branding,
                compact: true,
              ),
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
              activationCode: _codeController.text.trim(),
              deviceName: sessionContext.deviceName,
            );

    if (activated && mounted) {
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
