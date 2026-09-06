import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_cash_drawer_till_visibility.dart';

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
  final double? expectedCash;

  InputDecoration _fieldDecoration({
    required String labelText,
    String? hintText,
    String? prefixText,
    bool filled = false,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixText: prefixText,
      filled: filled,
      fillColor: filled ? TenantAdminColors.subtleBackground : null,
      alignLabelWithHint: alignLabelWithHint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: const TextStyle(fontSize: 14),
      hintStyle: const TextStyle(fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(effectivePermissionSetProvider);
    final formState = ref.watch(closeTillFormProvider);
    final showExpected =
        PosCashDrawerTillVisibility.canShowClosingExpectedCash(p);
    final showCountedEntry =
        PosCashDrawerTillVisibility.canShowClosingCountedCashEntry(p);
    final showDifferenceUi =
        PosCashDrawerTillVisibility.canExposeCloseTillDifferenceUi(p);
    final showMismatch =
        PosCashDrawerTillVisibility.canShowClosingMismatchReason(p);
    final showNotes = PosCashDrawerTillVisibility.canShowClosingNotes(p);

    final safeExpected = showExpected ? expectedCash : null;
    final difference =
        showDifferenceUi ? formState.differenceFor(safeExpected) : null;
    final mismatchReasonRequired = difference != null && difference != 0;

    return CashDrawerSectionCard(
      expand: true,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Close Till Form',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: TenantAdminColors.bodyText,
                    fontSize: 17,
                  ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final useRow =
                    constraints.maxWidth >= TenantAdminBreakpoints.mobile;

                final countedField = showCountedEntry
                    ? TextFormField(
                        controller: countedCashController,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        onChanged: ref
                            .read(closeTillFormProvider.notifier)
                            .setCountedCashText,
                        decoration: _fieldDecoration(
                          labelText: 'Counted Cash *',
                          prefixText: '${formatLkrInputPrefix()} ',
                        ).copyWith(
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(TenantAdminRadius.sm),
                            borderSide: const BorderSide(
                              color: TenantAdminColors.posHomeAccentOrange,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(TenantAdminRadius.sm),
                            borderSide: const BorderSide(
                              color: TenantAdminColors.posHomeAccentOrange,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: validateCloseTillCountedCash,
                      )
                    : null;

                final expectedField = showExpected
                    ? InputDecorator(
                        decoration: _fieldDecoration(
                          labelText: 'Expected Cash',
                          filled: true,
                        ),
                        child: Text(
                          formatCashDrawerAmount(expectedCash),
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: TenantAdminColors.bodyText,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                        ),
                      )
                    : null;

                final fields = <Widget>[
                  if (countedField != null) countedField,
                  if (expectedField != null) expectedField,
                ];

                if (fields.isEmpty) {
                  return const SizedBox.shrink();
                }

                if (useRow && fields.length == 2) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: fields[0]),
                      const SizedBox(width: 10),
                      Expanded(child: fields[1]),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      fields[i],
                    ],
                  ],
                );
              },
            ),
            if (showDifferenceUi) ...[
              const SizedBox(height: 12),
              CloseTillDifferenceBadge(difference: difference),
            ],
            if (showMismatch) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(formState.mismatchReason),
                initialValue: formState.mismatchReason,
                style: const TextStyle(
                  fontSize: 15,
                  color: TenantAdminColors.bodyText,
                ),
                decoration: _fieldDecoration(
                  labelText:
                      'Mismatch Reason${mismatchReasonRequired ? ' *' : ''}',
                ),
                items: [
                  for (final reason in CloseTillMismatchReason.options)
                    DropdownMenuItem(
                      value: reason,
                      child: Text(reason, style: const TextStyle(fontSize: 15)),
                    ),
                ],
                onChanged:
                    ref.read(closeTillFormProvider.notifier).setMismatchReason,
                validator: (value) => validateCloseTillMismatchReason(
                  value,
                  required: mismatchReasonRequired,
                ),
              ),
            ],
            if (showNotes) ...[
              const SizedBox(height: 12),
              Expanded(
                child: TextFormField(
                  controller: notesController,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  maxLength: 500,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontSize: 15),
                  onChanged: ref.read(closeTillFormProvider.notifier).setNotes,
                  decoration: _fieldDecoration(
                    labelText: 'Notes',
                    hintText: 'Add notes about the till close...',
                    alignLabelWithHint: true,
                  ),
                ),
              ),
            ] else
              const Spacer(),
          ],
        ),
      ),
    );
  }
}
