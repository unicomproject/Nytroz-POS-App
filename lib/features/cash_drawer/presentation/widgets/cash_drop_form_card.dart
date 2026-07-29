import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/cash_drop_reason.dart';
import '../providers/cash_drop_provider.dart';
import 'cash_drawer_section_card.dart';

class CashDropFormCard extends ConsumerWidget {
  const CashDropFormCard({
    super.key,
    required this.formKey,
    required this.amountController,
    required this.noteController,
    required this.managerPinController,
    required this.availableCash,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final TextEditingController managerPinController;
  final double availableCash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(cashDropFormProvider);

    return CashDrawerSectionCard(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cash Drop Details',
              style: TenantAdminTextStyles.sectionTitle(context),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final useRow =
                    constraints.maxWidth >= TenantAdminBreakpoints.mobile;

                final amountField = TextFormField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  onChanged:
                      ref.read(cashDropFormProvider.notifier).setAmountText,
                  decoration: InputDecoration(
                    labelText: 'Drop Amount *',
                    prefixText: '${formatLkrInputPrefix()} ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                    ),
                  ),
                  validator: (value) => validateCashDropAmount(
                    value,
                    maxAvailable: availableCash,
                  ),
                );

                final reasonField = DropdownButtonFormField<String>(
                  key: ValueKey(formState.reason),
                  initialValue: formState.reason,
                  decoration: InputDecoration(
                    labelText: 'Reason *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                    ),
                  ),
                  items: [
                    for (final reason in CashDropReason.options)
                      DropdownMenuItem(
                        value: reason,
                        child: Text(reason),
                      ),
                  ],
                  onChanged: ref.read(cashDropFormProvider.notifier).setReason,
                  validator: validateCashDropReason,
                );

                if (useRow) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: amountField),
                      const SizedBox(width: TenantAdminSpacing.lg),
                      Expanded(child: reasonField),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    amountField,
                    const SizedBox(height: TenantAdminSpacing.lg),
                    reasonField,
                  ],
                );
              },
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            TextFormField(
              controller: noteController,
              maxLines: 4,
              maxLength: 500,
              onChanged: ref.read(cashDropFormProvider.notifier).setNote,
              decoration: InputDecoration(
                labelText: 'Note',
                hintText: 'Add note...',
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
              onChanged: ref.read(cashDropFormProvider.notifier).setManagerPin,
              decoration: InputDecoration(
                labelText: 'Manager PIN (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
                suffixIcon: IconButton(
                  onPressed: ref
                      .read(cashDropFormProvider.notifier)
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
