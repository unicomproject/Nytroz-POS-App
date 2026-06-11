import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_buttons.dart';
import '../providers/tenant_payment_provider.dart';
import '../widgets/auth_error_banner.dart';
import '../widgets/auth_page_shell.dart';
import '../widgets/payment_summary_card.dart';

class BillingSummaryScreen extends ConsumerStatefulWidget {
  const BillingSummaryScreen({
    super.key,
    required this.paymentToken,
  });

  final String paymentToken;

  @override
  ConsumerState<BillingSummaryScreen> createState() =>
      _BillingSummaryScreenState();
}

class _BillingSummaryScreenState extends ConsumerState<BillingSummaryScreen> {
  var _paying = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final summaryState = ref.watch(paymentSummaryProvider(widget.paymentToken));

    return AuthPageShell(
      title: 'Review billing summary',
      subtitle: 'Confirm your subscription before continuing.',
      child: summaryState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Column(
          children: [
            const AuthErrorBanner(message: 'Unable to load billing summary.'),
            const SizedBox(height: TenantAdminSpacing.lg),
            TenantAdminSecondaryButton(
              label: 'Retry',
              onPressed: () {
                ref
                    .refresh(paymentSummaryProvider(widget.paymentToken))
                    .maybeWhen(orElse: () {});
              },
            ),
          ],
        ),
        data: (summary) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              AuthErrorBanner(message: _error!),
              const SizedBox(height: TenantAdminSpacing.lg),
            ],
            PaymentSummaryCard(summary: summary),
            const SizedBox(height: TenantAdminSpacing.xl),
            TenantAdminPrimaryButton(
              label: 'Pay Now',
              icon: Icons.payment,
              loading: _paying,
              onPressed: _payNow,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _payNow() async {
    setState(() {
      _paying = true;
      _error = null;
    });

    try {
      final status =
          await ref.read(startPaymentProvider).call(widget.paymentToken);
      if (!mounted) {
        return;
      }

      if (status.redirectUrl != null && status.redirectUrl!.isNotEmpty) {
        context.go(
          '/tenant-admin/payment/processing?paymentToken=${widget.paymentToken}',
        );
        return;
      }

      context.go(
        '/tenant-admin/payment/processing?paymentToken=${widget.paymentToken}',
      );
    } catch (_) {
      setState(
          () => _error = 'Payment could not be started. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _paying = false);
      }
    }
  }
}
