import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:intl/intl.dart';

class BatchTrackingForm extends StatelessWidget {
  final AddProductWizardState state;
  final AddProductWizardController controller;
  final TextEditingController? batchController;

  const BatchTrackingForm({
    super.key,
    required this.state,
    required this.controller,
    this.batchController,
  });

  @override
  Widget build(BuildContext context) {
    final isExpiry = state.expiryTracking;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isExpiry ? 'Batch & Expiry Details' : 'Batch Details',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Optionally define the initial tracking details for this product. You can skip this and add them later during goods receipt.',
          style: TextStyle(
            fontSize: 13,
            color: TenantAdminColors.mutedText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
        
        Container(
          padding: const EdgeInsets.all(TenantAdminSpacing.lg),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: batchController,
                decoration: const InputDecoration(
                  labelText: 'Initial Batch Number (Optional)',
                  hintText: 'e.g. BAT-2026-0001',
                ),
                onChanged: controller.updateInitialBatchNumber,
              ),
              if (isExpiry) ...[
                const SizedBox(height: TenantAdminSpacing.lg),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: state.initialExpiryDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      controller.updateInitialExpiryDate(date);
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Initial Expiry Date (Optional)',
                        hintText: 'Select date',
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                      controller: TextEditingController(
                        text: state.initialExpiryDate != null 
                            ? DateFormat.yMMMd().format(state.initialExpiryDate!) 
                            : '',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: TenantAdminSpacing.xl),
      ],
    );
  }
}
