import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/cash_in_reason.dart';
import '../providers/cash_in_provider.dart';
import 'cash_drawer_section_card.dart';

class CashInFormCard extends ConsumerWidget {
  const CashInFormCard({
    super.key,
    required this.formKey,
    required this.amountController,
    required this.noteController,
    required this.managerPinController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final TextEditingController managerPinController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(cashInFormProvider);

    return CashDrawerSectionCard(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cash In Details',
              style: TenantAdminTextStyles.sectionTitle(context),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            TextFormField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: ref.read(cashInFormProvider.notifier).setAmountText,
              decoration: InputDecoration(
                labelText: 'Amount *',
                prefixText: '${formatLkrInputPrefix()} ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
              ),
              validator: validateCashInAmount,
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            DropdownButtonFormField<String>(
              key: ValueKey(formState.reason),
              initialValue: formState.reason,
              decoration: InputDecoration(
                labelText: 'Reason *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
              ),
              items: [
                for (final reason in CashInReason.options)
                  DropdownMenuItem(
                    value: reason,
                    child: Text(reason),
                  ),
              ],
              onChanged: ref.read(cashInFormProvider.notifier).setReason,
              validator: validateCashInReason,
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            TextFormField(
              controller: noteController,
              maxLines: 4,
              maxLength: 500,
              onChanged: ref.read(cashInFormProvider.notifier).setNote,
              decoration: InputDecoration(
                labelText: 'Note',
                hintText: 'Add note for this cash in.',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            TextFormField(
              controller: managerPinController,
              obscureText: formState.obscureManagerPin,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: ref.read(cashInFormProvider.notifier).setManagerPin,
              decoration: InputDecoration(
                labelText: 'Manager PIN (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
                suffixIcon: IconButton(
                  onPressed: ref
                      .read(cashInFormProvider.notifier)
                      .toggleManagerPinVisibility,
                  icon: Icon(
                    formState.obscureManagerPin
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            Text(
              'Manager PIN is collected for future approval workflows only.',
              style: TenantAdminTextStyles.muted(context).copyWith(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
