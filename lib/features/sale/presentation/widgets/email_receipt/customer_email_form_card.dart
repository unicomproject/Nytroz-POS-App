import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/pos_email_receipt_form_provider.dart';
import '../payment/payment_panel_card.dart';

class CustomerEmailFormCard extends ConsumerStatefulWidget {
  const CustomerEmailFormCard({super.key});

  @override
  ConsumerState<CustomerEmailFormCard> createState() =>
      _CustomerEmailFormCardState();
}

class _CustomerEmailFormCardState extends ConsumerState<CustomerEmailFormCard> {
  late final TextEditingController _emailController;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(posEmailReceiptFormProvider);
    _emailController = TextEditingController(text: initial.email);
    _messageController = TextEditingController(text: initial.message);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(posEmailReceiptFormProvider);
    final notifier = ref.read(posEmailReceiptFormProvider.notifier);

    return PaymentPanelCard(
      title: 'Customer Email',
      icon: Icons.mail_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Enter the customer's email address to send the receipt.",
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Text(
            'Email Address *',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: TenantAdminColors.bodyText,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            onChanged: notifier.setEmail,
            onTap: notifier.markEmailTouched,
            decoration: InputDecoration(
              hintText: 'e.g., customer@example.com',
              prefixIcon: const Icon(Icons.mail_outline_rounded),
              errorText: formState.emailError,
              filled: true,
              fillColor: TenantAdminColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.info),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.danger),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.danger),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.lg,
                vertical: TenantAdminSpacing.md,
              ),
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Row(
            children: [
              Text(
                'Message (Optional)',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: TenantAdminColors.bodyText,
                    ),
              ),
              const Spacer(),
              Text(
                '${formState.message.length} / $posEmailReceiptMessageMaxLength',
                style: TenantAdminTextStyles.muted(context),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          TextFormField(
            controller: _messageController,
            keyboardType: TextInputType.multiline,
            maxLines: 4,
            maxLength: posEmailReceiptMessageMaxLength,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) =>
                null,
            onChanged: notifier.setMessage,
            decoration: InputDecoration(
              hintText: 'Add a short message (optional)',
              filled: true,
              fillColor: TenantAdminColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.info),
              ),
              contentPadding: const EdgeInsets.all(TenantAdminSpacing.lg),
            ),
          ),
        ],
      ),
    );
  }
}
