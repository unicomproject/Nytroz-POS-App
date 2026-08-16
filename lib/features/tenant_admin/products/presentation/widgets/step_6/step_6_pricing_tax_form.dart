import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../providers/tenant_product_providers.dart';
import '../../../../pricing_tax/tax_management/application/tax_management_controller.dart';
import '../product_form_fields.dart';

class Step6PricingTaxForm extends ConsumerStatefulWidget {
  const Step6PricingTaxForm({super.key});

  @override
  ConsumerState<Step6PricingTaxForm> createState() =>
      _Step6PricingTaxFormState();
}

class _Step6PricingTaxFormState extends ConsumerState<Step6PricingTaxForm> {
  late final TextEditingController _costPriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _discountPriceController;
  bool _syncingFromState = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(addProductWizardControllerProvider);
    _costPriceController = TextEditingController(
      text: state.costPrice?.toString() ?? '',
    );
    _sellingPriceController = TextEditingController(
      text: state.standardSellingPrice?.toString() ?? '',
    );
    _discountPriceController = TextEditingController(
      text: state.discountPrice?.toString() ?? '',
    );

    _costPriceController.addListener(() {
      if (_syncingFromState) return;
      final val = num.tryParse(_costPriceController.text);
      ref.read(addProductWizardControllerProvider.notifier).updateCostPrice(val);
    });
    _sellingPriceController.addListener(() {
      if (_syncingFromState) return;
      final val = num.tryParse(_sellingPriceController.text);
      ref
          .read(addProductWizardControllerProvider.notifier)
          .updateStandardSellingPrice(val);
    });
    _discountPriceController.addListener(() {
      if (_syncingFromState) return;
      final val = num.tryParse(_discountPriceController.text);
      ref
          .read(addProductWizardControllerProvider.notifier)
          .updateDiscountPrice(val);
    });
  }

  void _syncControllersFromState() {
    final state = ref.read(addProductWizardControllerProvider);
    _syncingFromState = true;
    final cost = state.costPrice?.toString() ?? '';
    final sell = state.standardSellingPrice?.toString() ?? '';
    final discount = state.discountPrice?.toString() ?? '';
    if (_costPriceController.text != cost) {
      _costPriceController.text = cost;
    }
    if (_sellingPriceController.text != sell) {
      _sellingPriceController.text = sell;
    }
    if (_discountPriceController.text != discount) {
      _discountPriceController.text = discount;
    }
    _syncingFromState = false;
  }

  @override
  void dispose() {
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _discountPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addProductWizardControllerProvider);
    final taxListResult = ref.watch(taxListProvider);

    ref.listen(addProductWizardControllerProvider, (previous, next) {
      if (previous?.costPrice != next.costPrice ||
          previous?.standardSellingPrice != next.standardSellingPrice ||
          previous?.discountPrice != next.discountPrice) {
        _syncControllersFromState();
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pricing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ProductFormTextField(
                  label: 'Cost Price *',
                  hint: '0.00',
                  icon: Icons.attach_money,
                  controller: _costPriceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  errorText: state.fieldErrors['costPrice'],
                  enabled: !state.isSubmitting && !state.isSavingDraft,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.lg),
              Expanded(
                child: ProductFormTextField(
                  label: 'Standard Selling Price *',
                  hint: '0.00',
                  icon: Icons.sell_outlined,
                  controller: _sellingPriceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  errorText: state.fieldErrors['standardSellingPrice'],
                  enabled: !state.isSubmitting && !state.isSavingDraft,
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          SizedBox(
            width: MediaQuery.of(context).size.width > 768
                ? (MediaQuery.of(context).size.width -
                        TenantAdminSpacing.xl * 2 -
                        TenantAdminSpacing.lg -
                        320) / // assuming sidebar
                    2
                : double.infinity,
            child: ProductFormTextField(
              label: 'Discount Price',
              hint: '0.00',
              icon: Icons.local_offer_outlined,
              controller: _discountPriceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              errorText: state.fieldErrors['discountPrice'],
              enabled: !state.isSubmitting && !state.isSavingDraft,
              helperText: 'Optional promotional price.',
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          const Divider(color: TenantAdminColors.border),
          const SizedBox(height: TenantAdminSpacing.xl),
          const Text(
            'Tax',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          taxListResult.when(
            data: (data) {
              final taxes = data.items.where((t) => t.status == 'ACTIVE').toList();
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ProductOptionDropdown(
                      label: 'Tax Name *',
                      hint: 'Select Tax',
                      icon: Icons.receipt_long_outlined,
                      value: state.taxId,
                      items: taxes.map((t) {
                        return DropdownMenuItem<String>(
                          value: t.id,
                          child: Text('${t.taxName} (${t.taxPercentage}%)'),
                        );
                      }).toList(),
                      errorText: state.fieldErrors['taxId'],
                      enabled: !state.isSubmitting && !state.isSavingDraft,
                      onChanged: (val) {
                        if (val != null) {
                          final selectedTax =
                              taxes.firstWhere((t) => t.id == val);
                          ref
                              .read(addProductWizardControllerProvider.notifier)
                              .updateTaxId(
                                val,
                                taxRate: selectedTax.taxPercentage,
                                taxName: selectedTax.taxName,
                              );
                        } else {
                          ref
                              .read(addProductWizardControllerProvider.notifier)
                              .updateTaxId(null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: TenantAdminSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tax Rate',
                          style: TextStyle(
                            color: TenantAdminColors.bodyText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: TenantAdminSpacing.sm),
                        TextField(
                          controller: TextEditingController(
                            text: state.taxRate != null
                                ? '${state.taxRate}%'
                                : '',
                          ),
                          enabled: false,
                          decoration: InputDecoration(
                            hintText: 'Auto-filled',
                            prefixIcon: const Icon(Icons.percent, size: 19),
                            filled: true,
                            fillColor: TenantAdminColors.background,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(TenantAdminRadius.md),
                              borderSide: const BorderSide(
                                  color: TenantAdminColors.border),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(TenantAdminRadius.md),
                              borderSide: const BorderSide(
                                  color: TenantAdminColors.border),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text(
              'Failed to load taxes: $err',
              style: const TextStyle(color: TenantAdminColors.danger),
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Container(
            padding: const EdgeInsets.all(TenantAdminSpacing.md),
            decoration: BoxDecoration(
              color: TenantAdminColors.background,
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              border: Border.all(color: TenantAdminColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline,
                    size: 18, color: TenantAdminColors.mutedText),
                SizedBox(width: TenantAdminSpacing.sm),
                Text(
                  'Pricing model is locked to Tax Exclusive.',
                  style: TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
