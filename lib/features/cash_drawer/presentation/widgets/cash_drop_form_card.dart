import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/cash_drop_provider.dart';
import '../providers/cash_in_provider.dart';
import 'cash_drawer_section_card.dart';

class CashDropFormCard extends ConsumerWidget {
  const CashDropFormCard({
    super.key,
    required this.formKey,
    required this.amountController,
    required this.noteController,
    required this.managerPinController,
    required this.availableCash,
    this.currencyCode = '',
    this.expand = false,
    this.compact = false,
    this.tight = false,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final TextEditingController managerPinController;
  final double availableCash;
  final String currencyCode;
  final bool expand;
  final bool compact;
  final bool tight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(cashDropFormProvider);
    final catalog = ref.watch(cashDropCatalogProvider);
    final prefix = currencyInputPrefix(currencyCode);
    final reasonEnabled = catalog.status == CashDropCatalogStatus.ready &&
        catalog.types.isNotEmpty;

    return CashDrawerSectionCard(
      expand: expand,
      padding: EdgeInsets.all(
        tight
            ? TenantAdminSpacing.sm
            : compact
                ? TenantAdminSpacing.lg
                : TenantAdminSpacing.xl,
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeading(
              icon: Icons.point_of_sale_outlined,
              label: 'Cash Drop Details',
              compact: tight,
            ),
            SizedBox(
              height: tight
                  ? TenantAdminSpacing.xs
                  : compact
                      ? TenantAdminSpacing.md
                      : TenantAdminSpacing.lg,
            ),
            if (catalog.isLoading)
              Padding(
                padding: EdgeInsets.only(
                  bottom: tight
                      ? TenantAdminSpacing.xs
                      : TenantAdminSpacing.md,
                ),
                child: const LinearProgressIndicator(minHeight: 2),
              ),
            if (catalog.status == CashDropCatalogStatus.empty)
              Padding(
                padding: EdgeInsets.only(
                  bottom: tight
                      ? TenantAdminSpacing.xs
                      : TenantAdminSpacing.md,
                ),
                child: Text(
                  'No Cash Drop reasons are available. Contact your administrator.',
                  style: TenantAdminTextStyles.muted(context).copyWith(
                    color: TenantAdminColors.danger,
                    fontSize: tight ? 10 : 12,
                  ),
                ),
              ),
            if (catalog.status == CashDropCatalogStatus.failure)
              Padding(
                padding: EdgeInsets.only(
                  bottom: tight
                      ? TenantAdminSpacing.xs
                      : TenantAdminSpacing.md,
                ),
                child: Text(
                  catalog.errorMessage ??
                      'Cash Drop reasons could not be loaded.',
                  style: TenantAdminTextStyles.muted(context).copyWith(
                    color: TenantAdminColors.danger,
                    fontSize: tight ? 10 : 12,
                  ),
                ),
              ),
            LayoutBuilder(
              builder: (context, fieldConstraints) {
                final sideBySide =
                    fieldConstraints.maxWidth >= TenantAdminBreakpoints.mobile;
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
                    prefixText: prefix.isEmpty ? null : '$prefix ',
                    helperText: sideBySide
                        ? 'Amount cannot exceed available cash'
                        : 'Cannot exceed available cash',
                    helperStyle: tight ? const TextStyle(fontSize: 9) : null,
                    isDense: compact,
                    contentPadding: compact
                        ? EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: tight ? 7 : 12,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(TenantAdminRadius.md),
                    ),
                  ),
                  validator: (value) => validateCashDropAmount(
                    value,
                    maxAvailable: availableCash,
                  ),
                );
                final reasonField = DropdownButtonFormField<String>(
                  key: ValueKey(
                    '${catalog.status.name}-${formState.selectedMovementTypeId}',
                  ),
                  isExpanded: true,
                  initialValue: reasonEnabled
                      ? formState.selectedMovementTypeId
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Reason *',
                    isDense: compact,
                    contentPadding: compact
                        ? EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: tight ? 7 : 12,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(TenantAdminRadius.md),
                    ),
                  ),
                  items: [
                    for (final type in catalog.types)
                      DropdownMenuItem(
                        value: type.movementTypeId,
                        child: Text(
                          type.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                  selectedItemBuilder: (context) => [
                    for (final type in catalog.types)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          type.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                  onChanged: reasonEnabled
                      ? ref
                          .read(cashDropFormProvider.notifier)
                          .setSelectedMovementTypeId
                      : null,
                  validator: (value) => validateCashDropMovementType(
                    value,
                    availableTypes: catalog.types,
                  ),
                );

                if (sideBySide) {
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
                    SizedBox(
                      height: tight
                          ? TenantAdminSpacing.xs
                          : TenantAdminSpacing.md,
                    ),
                    reasonField,
                  ],
                );
              },
            ),
            SizedBox(
              height: tight
                  ? TenantAdminSpacing.xs
                  : compact
                      ? TenantAdminSpacing.md
                      : TenantAdminSpacing.lg,
            ),
            TextFormField(
              controller: noteController,
              maxLines: tight ? 1 : (compact ? 2 : 4),
              maxLength: 500,
              onChanged: ref.read(cashDropFormProvider.notifier).setNote,
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Add note for this cash drop.',
                alignLabelWithHint: true,
                isDense: compact,
                contentPadding: tight
                    ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                    : null,
                counterStyle: tight ? const TextStyle(fontSize: 9) : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
              ),
            ),
            SizedBox(
              height: tight
                  ? TenantAdminSpacing.xs
                  : compact
                      ? TenantAdminSpacing.md
                      : TenantAdminSpacing.lg,
            ),
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
                isDense: compact,
                contentPadding: compact
                    ? EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: tight ? 7 : 12,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
                suffixIcon: IconButton(
                  tooltip: formState.obscureManagerPin
                      ? 'Show Manager PIN'
                      : 'Hide Manager PIN',
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
            SizedBox(height: tight ? 2 : TenantAdminSpacing.sm),
            Text(
              'Manager PIN is collected for future approval workflows only.',
              style: TenantAdminTextStyles.muted(context).copyWith(
                fontSize: tight ? 9 : (compact ? 10 : 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.label,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 28 : 36,
          height: compact ? 28 : 36,
          decoration: BoxDecoration(
            color: TenantAdminColors.expectedCashSurface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          ),
          child: Icon(
            icon,
            color: TenantAdminColors.posHomeAccentOrange,
            size: compact ? 17 : 21,
          ),
        ),
        SizedBox(
          width: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
        ),
        Text(
          label,
          style: TenantAdminTextStyles.sectionTitle(context).copyWith(
            fontSize: compact ? 14 : null,
          ),
        ),
      ],
    );
  }
}
