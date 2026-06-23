import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/pos_cash_payment_success_provider.dart';
import '../providers/pos_email_receipt_form_provider.dart';
import '../widgets/email_receipt/customer_email_form_card.dart';
import '../widgets/email_receipt/email_receipt_bottom_actions.dart';
import '../widgets/email_receipt/email_receipt_header.dart';
import '../widgets/email_receipt/email_receipt_info_box.dart';
import '../widgets/email_receipt/email_receipt_sale_summary_card.dart';
import '../widgets/email_receipt/receipt_preview_summary_card.dart';

class PosEmailReceiptScreen extends ConsumerWidget {
  const PosEmailReceiptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final successData = ref.watch(posCashPaymentSuccessProvider);
    final formState = ref.watch(posEmailReceiptFormProvider);

    if (!PosPermissionAccess.canAccessPaymentMethodScreenSession(session)) {
      return const TenantAdminForbiddenScreen();
    }

    if (successData == null) {
      return _MissingEmailReceiptFallback(
        onBack: () => context.go('/pos/new-sale'),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = TenantAdminInsets.pageForWidth(constraints.maxWidth);
        final useWideLayout =
            constraints.maxWidth >= TenantAdminBreakpoints.tablet;

        return Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmailReceiptHeader(
                onBack: () => context.pop(),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              Expanded(
                child: useWideLayout
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 2,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  EmailReceiptSaleSummaryCard(
                                    successData: successData,
                                  ),
                                  const SizedBox(height: TenantAdminSpacing.lg),
                                  const EmailReceiptInfoBox(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: TenantAdminSpacing.lg),
                          Expanded(
                            flex: 3,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const CustomerEmailFormCard(),
                                  const SizedBox(height: TenantAdminSpacing.lg),
                                  ReceiptPreviewSummaryCard(
                                    successData: successData,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            EmailReceiptSaleSummaryCard(
                              successData: successData,
                            ),
                            const SizedBox(height: TenantAdminSpacing.lg),
                            const EmailReceiptInfoBox(),
                            const SizedBox(height: TenantAdminSpacing.lg),
                            const CustomerEmailFormCard(),
                            const SizedBox(height: TenantAdminSpacing.lg),
                            ReceiptPreviewSummaryCard(
                              successData: successData,
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              EmailReceiptBottomActions(
                canSendReceipt: formState.canSendReceipt,
                onBack: () => context.pop(),
                onSendReceipt: () => _sendReceipt(context, ref),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendReceipt(BuildContext context, WidgetRef ref) {
    ref.read(posEmailReceiptFormProvider.notifier).markEmailTouched();

    final formState = ref.read(posEmailReceiptFormProvider);
    if (!formState.canSendReceipt) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Email receipt is not implemented yet.')),
      );
  }
}

class _MissingEmailReceiptFallback extends StatelessWidget {
  const _MissingEmailReceiptFallback({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.mail_outline_rounded,
            size: 48,
            color: TenantAdminColors.mutedText,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Text(
            'Email receipt unavailable',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            'Complete a cash payment to email the receipt to a customer.',
            textAlign: TextAlign.center,
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          FilledButton(
            onPressed: onBack,
            child: const Text('Back to New Sale'),
          ),
        ],
      ),
    );
  }
}
