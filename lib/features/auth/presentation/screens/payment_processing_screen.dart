import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_buttons.dart';
import '../providers/payment_provider.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_page_shell.dart';

class PaymentProcessingScreen extends ConsumerStatefulWidget {
  const PaymentProcessingScreen({
    super.key,
    required this.paymentToken,
  });

  final String paymentToken;

  @override
  ConsumerState<PaymentProcessingScreen> createState() =>
      _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState
    extends ConsumerState<PaymentProcessingScreen> {
  var _checking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      title: 'Processing payment',
      subtitle: 'Please wait while we confirm the payment status.',
      child: Column(
        children: [
          if (_checking)
            const CircularProgressIndicator()
          else if (_error != null)
            AuthErrorBanner(message: _error!)
          else
            const Icon(
              Icons.check_circle,
              size: 54,
              color: TenantAdminColors.success,
            ),
          const SizedBox(height: TenantAdminSpacing.xl),
          if (!_checking && _error != null)
            TenantAdminSecondaryButton(label: 'Retry', onPressed: _verify),
        ],
      ),
    );
  }

  Future<void> _verify() async {
    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      final status =
          await ref.read(verifyPaymentStatusProvider).call(widget.paymentToken);

      if (!mounted) {
        return;
      }

      if (status.isSuccess) {
        context.go('/tenant-admin/payment/success');
        return;
      }

      setState(() {
        _error = status.isFailed
            ? 'Payment failed. Please try again.'
            : 'Payment is not completed yet. Please retry.';
      });
    } catch (_) {
      setState(() => _error = 'Unable to verify payment status.');
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }
}
