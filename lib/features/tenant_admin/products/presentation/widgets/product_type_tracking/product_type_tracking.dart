import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/product_type_tracking/opening_stock_form.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/product_type_tracking/outlet_allocation_form.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/product_type_tracking/batch_tracking_form.dart';

/// Semantic presentation component for Product Type & Tracking wizard stage.
class ProductTypeTracking extends StatelessWidget {
  const ProductTypeTracking({
    super.key,
    required this.state,
    required this.controller,
    this.canManageVariants = true,
    this.canUseAdvancedInventoryTracking = true,
    this.batchController,
    this.serialController,
  });

  final AddProductWizardState state;
  final AddProductWizardController controller;
  final bool canManageVariants;
  final bool canUseAdvancedInventoryTracking;
  final TextEditingController? batchController;
  final TextEditingController? serialController;

  @override
  Widget build(BuildContext context) {
    if (!state.productStructureConfirmed) {
      return const SizedBox.shrink();
    }
    
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const SizedBox(height: TenantAdminSpacing.lg),
        _buildDynamicContent(context),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight.isFinite) {
          return SingleChildScrollView(
            primary: false,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
            child: content,
          );
        }
        return content;
      },
    );
  }
  

  Widget _buildDynamicContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.trackingInternalStep == 1) ...[
          _buildMethodSelection(context),
        ] else if (state.trackingInternalStep == 2 && state.trackInventory) ...[
          OpeningStockForm(
            state: state,
            controller: controller,
            variantKey: state.productStructure == 'VARIANT' ? 'VARIANT' : 'SIMPLE',
          ),
        ] else if (state.trackingInternalStep == 3 && state.trackInventory) ...[
          OutletAllocationForm(
            state: state,
            controller: controller,
          ),
        ] else if (state.trackingInternalStep == 4 && (state.batchTracking || state.expiryTracking)) ...[
          BatchTrackingForm(
            state: state,
            controller: controller,
            batchController: batchController,
          ),
        ],
      ],
    );
  }

  Widget _buildMethodSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Tracking',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Choose how inventory will be tracked for this product',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
        
        // Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 680;
            final qtyCard = _TrackingMethodCard(
              title: 'Track by Quantity',
              description: 'Track stock as total quantity on hand. Best for most retail products.',
              icon: Icons.inventory_2_outlined,
              selected: state.trackInventory,
              onTap: () => controller.toggleTrackInventory(!state.trackInventory),
            );
            final serialCard = _TrackingMethodCard(
              title: 'Track by Serial / IMEI',
              description: 'Track each item individually using serial numbers or IMEI.',
              icon: Icons.barcode_reader,
              selected: state.serialTracking,
              onTap: () => controller.toggleSerialTracking(!state.serialTracking),
            );
            final expiryCard = _TrackingMethodCard(
              title: 'Track by Batch / Expiry',
              description: 'Track stock using batch number and expiry date. Best for perishable or regulated items.',
              icon: Icons.event_available_outlined,
              selected: state.batchTracking && state.expiryTracking,
              onTap: () => controller.toggleBatchExpiryTracking(!(state.batchTracking && state.expiryTracking)),
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  qtyCard,
                  const SizedBox(height: TenantAdminSpacing.lg),
                  serialCard,
                  const SizedBox(height: TenantAdminSpacing.lg),
                  expiryCard,
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: qtyCard),
                  const SizedBox(width: TenantAdminSpacing.lg),
                  Expanded(child: serialCard),
                  const SizedBox(width: TenantAdminSpacing.lg),
                  Expanded(child: expiryCard),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TrackingMethodCard extends StatelessWidget {
  const _TrackingMethodCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? TenantAdminColors.posHomeAccentOrange
        : const Color(0xFFE2E8F0);
    final bgColor = selected
        ? TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.04)
        : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: selected ? 2.0 : 1.5,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              if (!selected)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox Button
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: selected,
                  onChanged: (_) => onTap(),
                  activeColor: TenantAdminColors.posHomeAccentOrange,
                ),
              ),
              const SizedBox(height: 16),

              // Large Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: selected
                      ? TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.1)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: selected
                      ? TenantAdminColors.posHomeAccentOrange
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? TenantAdminColors.posHomeAccentOrange
                      : TenantAdminColors.bodyText,
                ),
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductStructureCard extends StatelessWidget {
  const ProductStructureCard({
    super.key,
    required this.structure,
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    this.enabled = true,
    required this.onSelected,
  });

  final String structure;
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? TenantAdminColors.posHomeAccentOrange
        : TenantAdminColors.border;
    final backgroundColor = selected
        ? TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.04)
        : TenantAdminColors.surface;

    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: InkWell(
        onTap: enabled ? onSelected : null,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: const BoxConstraints(minHeight: 72),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(
              color: borderColor,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? TenantAdminColors.posHomeAccentOrange
                        : TenantAdminColors.border,
                    width: selected ? 5.0 : 1.5,
                  ),
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected
                      ? TenantAdminColors.posHomeAccentOrange
                          .withValues(alpha: 0.1)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: selected
                      ? TenantAdminColors.posHomeAccentOrange
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: TenantAdminColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TenantAdminColors.mutedText,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class BundleInventoryBehaviourCard extends StatelessWidget {
  const BundleInventoryBehaviourCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome_motion_outlined,
                  size: 24,
                  color: TenantAdminColors.posHomeAccentOrange,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Derived Inventory',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: TenantAdminColors.bodyText,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Stock levels are automatically calculated based on the lowest available component.',
                      style: TextStyle(
                        fontSize: 12,
                        color: TenantAdminColors.mutedText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
