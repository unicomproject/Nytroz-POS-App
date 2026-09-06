import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/checkout_customer_provider.dart';

class AddCustomerForm extends StatefulWidget {
  const AddCustomerForm({
    super.key,
    required this.state,
    required this.onChangeNumber,
    required this.onNameChanged,
  });

  final CheckoutCustomerState state;
  final VoidCallback onChangeNumber;
  final ValueChanged<String> onNameChanged;

  @override
  State<AddCustomerForm> createState() => _AddCustomerFormState();
}

class _AddCustomerFormState extends State<AddCustomerForm> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.state.customerName);
  }

  @override
  void didUpdateWidget(covariant AddCustomerForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.customerName != widget.state.customerName &&
        _nameController.text != widget.state.customerName) {
      _nameController.text = widget.state.customerName;
      _nameController.selection = TextSelection.collapsed(
        offset: _nameController.text.length,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: TenantAdminColors.subtleBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: TenantAdminColors.navy,
                  size: 18,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              const Expanded(
                child: Text(
                  'Customer Details',
                  style: TextStyle(
                    color: TenantAdminColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          TextFormField(
            key: const ValueKey('checkout-customer-phone'),
            initialValue: widget.state.phone,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Mobile Number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: TenantAdminColors.subtleBackground,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const ValueKey('checkout-customer-change-number'),
              onPressed: widget.state.isBusy ? null : widget.onChangeNumber,
              child: const Text('Change number'),
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          TextFormField(
            key: const ValueKey('checkout-customer-name'),
            controller: _nameController,
            enabled: !widget.state.isBusy,
            maxLength: 150,
            decoration: InputDecoration(
              labelText: 'Customer Name',
              hintText: 'Enter customer name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: widget.onNameChanged,
          ),
          if (widget.state.stage == CheckoutCustomerStage.creating)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: TenantAdminSpacing.sm),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: TenantAdminSpacing.md),
                  Text(
                    'Creating customer...',
                    key: ValueKey('checkout-customer-creating'),
                    style: TextStyle(
                      color: TenantAdminColors.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (widget.state.stage == CheckoutCustomerStage.createError)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: TenantAdminSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: TenantAdminColors.danger),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(
                    child: Text(
                      widget.state.error ?? 'Unable to create customer',
                      key: const ValueKey('checkout-customer-create-error'),
                      style: const TextStyle(
                        color: TenantAdminColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
}
