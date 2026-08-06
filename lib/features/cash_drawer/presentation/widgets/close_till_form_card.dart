import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/close_till_mismatch_reason.dart';
import '../providers/cash_drawer_provider.dart';
import '../providers/close_till_provider.dart';
import 'cash_drawer_section_card.dart';
import 'close_till_difference_badge.dart';

class CloseTillFormCard extends ConsumerWidget {
  const CloseTillFormCard({
    super.key,
    required this.formKey,
    required this.countedCashController,
    required this.notesController,
    required this.expectedCash,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController countedCashController;
  final TextEditingController notesController;
  final double expectedCash;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(closeTillFormProvider);
    final difference = formState.differenceFor(expectedCash);
    final mismatchReasonRequired = difference != null && difference != 0;

    return CashDrawerSectionCard(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Close Till Form',
              style: TenantAdminTextStyles.sectionTitle(context),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final useRow =
                    constraints.maxWidth >= TenantAdminBreakpoints.mobile;

                final countedField = TextFormField(
                  controller: countedCashController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  onChanged: ref
                      .read(closeTillFormProvider.notifier)
                      .setCountedCashText,
                  decoration: InputDecoration(
                    labelText: 'Counted Cash *',
                    prefixText: '${formatLkrInputPrefix()} ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                    ),
                  ),
                  validator: validateCloseTillCountedCash,
                );

                final expectedField = InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Expected Cash',
                    filled: true,
                    fillColor: TenantAdminColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: TenantAdminSpacing.md,
                      vertical: TenantAdminSpacing.md,
                    ),
                  ),
                  child: Text(
                    formatCashDrawerAmount(expectedCash),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: TenantAdminColors.bodyText,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                );

                if (useRow) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: countedField),
                      const SizedBox(width: TenantAdminSpacing.lg),
                      Expanded(child: expectedField),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    countedField,
                    const SizedBox(height: TenantAdminSpacing.lg),
                    expectedField,
                  ],
                );
              },
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            CloseTillDifferenceBadge(difference: difference),
            const SizedBox(height: TenantAdminSpacing.lg),
            DropdownButtonFormField<String>(
              key: ValueKey(formState.mismatchReason),
              initialValue: formState.mismatchReason,
              decoration: InputDecoration(
                labelText:
                    'Mismatch Reason${mismatchReasonRequired ? ' *' : ''}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
              ),
              items: [
                for (final reason in CloseTillMismatchReason.options)
                  DropdownMenuItem(
                    value: reason,
                    child: Text(reason),
                  ),
              ],
              onChanged:
                  ref.read(closeTillFormProvider.notifier).setMismatchReason,
              validator: (value) => validateCloseTillMismatchReason(
                value,
                required: mismatchReasonRequired,
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            TextFormField(
              controller: notesController,
              maxLines: 4,
              maxLength: 500,
              onChanged: ref.read(closeTillFormProvider.notifier).setNotes,
              decoration: InputDecoration(
                labelText: 'Notes',
                hintText: 'Add notes about the till close...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
