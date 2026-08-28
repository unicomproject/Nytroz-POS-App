import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';

/// Semantic presentation component for Product Type & Tracking wizard stage.
class ProductTypeTracking extends StatelessWidget {
  const ProductTypeTracking({
    super.key,
    required this.state,
    required this.controller,
    this.canManageVariants = true,
    this.canManageBundleComponents = false,
    this.canUseAdvancedInventoryTracking = true,
  });

  final AddProductWizardState state;
  final AddProductWizardController controller;
  final bool canManageVariants;
  final bool canManageBundleComponents;
  final bool canUseAdvancedInventoryTracking;

  @override
  Widget build(BuildContext context) {



    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          const Text(
            'Product Type *',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),

          // 3 Product Structure Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 680;
              final cards = [
                ProductStructureCard(
                  structure: 'SIMPLE',
                  title: 'Simple Product',
                  description:
                      'Single SKU product with no variants (e.g., T-shirt)',
                  icon: Icons.inventory_2_outlined,
                  selected: state.productStructure == 'SIMPLE' && state.productStructureConfirmed,
                  onSelected: () => _selectStructure(context, 'SIMPLE'),
                ),
                ProductStructureCard(
                  structure: 'VARIANT',
                  title: 'Variant Product',
                  description:
                      'Product with multiple options (e.g., T-shirt with size, color)',
                  icon: Icons.dashboard_customize_outlined,
                  selected: state.productStructure == 'VARIANT' && state.productStructureConfirmed,
                  enabled: canManageVariants,
                  onSelected: () => _selectStructure(context, 'VARIANT'),
                ),
                ProductStructureCard(
                  structure: 'BUNDLE',
                  title: 'Bundle / Kit',
                  description: 'Collection of existing items sold together.',
                  icon: Icons.inventory_outlined,
                  selected: state.productStructure == 'BUNDLE' && state.productStructureConfirmed,
                  enabled: canManageBundleComponents,
                  onSelected: () => _selectStructure(context, 'BUNDLE'),
                ),
              ];

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    cards[0],
                    const SizedBox(height: TenantAdminSpacing.md),
                    cards[1],
                    const SizedBox(height: TenantAdminSpacing.md),
                    cards[2],
                  ],
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: TenantAdminSpacing.md),
                    Expanded(child: cards[1]),
                    const SizedBox(width: TenantAdminSpacing.md),
                    Expanded(child: cards[2]),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 32),
          // Dynamic content based on productStructure
          _buildDynamicContent(context),
        ],
      );

    return content;
  }

  Future<void> _selectStructure(BuildContext context, String structure) async {
    final confirmed = await _confirmIfNeeded(
      context,
      productStructure: structure,
      trackInventory: structure == 'BUNDLE' ? false : state.trackInventory,
      batchTracking: structure == 'BUNDLE' ? false : state.batchTracking,
      expiryTracking: structure == 'BUNDLE' ? false : state.expiryTracking,
      serialTracking: structure == 'BUNDLE' ? false : state.serialTracking,
    );
    if (!confirmed) return;
    controller.setProductStructure(structure);
  }

  Future<void> _setTrackInventory(BuildContext context, bool value) async {
    final confirmed = await _confirmIfNeeded(
      context,
      trackInventory: value,
      batchTracking: value ? state.batchTracking : false,
      expiryTracking: value ? state.expiryTracking : false,
      serialTracking: value ? state.serialTracking : false,
    );
    if (!confirmed) return;
    controller.setTrackInventory(value);
  }

  Future<void> _setBatchTracking(BuildContext context, bool value) async {
    final confirmed = await _confirmIfNeeded(
      context,
      batchTracking: value,
      expiryTracking: value ? state.expiryTracking : false,
    );
    if (!confirmed) return;
    controller.setBatchTracking(value);
  }

  Future<void> _setExpiryTracking(BuildContext context, bool value) async {
    final confirmed = await _confirmIfNeeded(context, expiryTracking: value);
    if (!confirmed) return;
    controller.setExpiryTracking(value);
  }

  Future<void> _setSerialTracking(BuildContext context, bool value) async {
    final confirmed = await _confirmIfNeeded(
      context,
      serialTracking: value,
      batchTracking: value ? false : state.batchTracking,
      expiryTracking: value ? false : state.expiryTracking,
    );
    if (!confirmed) return;
    controller.setSerialTracking(value);
  }

  Future<bool> _confirmIfNeeded(
    BuildContext context, {
    String? productStructure,
    bool? trackInventory,
    bool? batchTracking,
    bool? expiryTracking,
    bool? serialTracking,
  }) async {
    final plan = controller.previewTrackingClear(
      productStructure: productStructure,
      trackInventory: trackInventory,
      batchTracking: batchTracking,
      expiryTracking: expiryTracking,
      serialTracking: serialTracking,
    );
    if (plan.requiresConfirmation) {
      controller.applyInitialTrackingPlan(plan, confirmed: true);
    }
    return true;
  }

  Widget _buildDynamicContent(BuildContext context) {
    switch (state.productStructure) {
      case 'VARIANT':
        return _buildVariantTrackingContent(context);
      case 'BUNDLE':
        return _buildBundleInventoryBehaviour(context);
      case 'SIMPLE':
      default:
        return _buildSimpleTrackingContent(context);
    }
  }

  // --- SIMPLE PRODUCT CONTENT ---
  Widget _buildSimpleTrackingContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tracking & Stock Rules',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Configure stock management and inventory tracking for this simple product.',
          style: TextStyle(
            fontSize: 13,
            color: TenantAdminColors.mutedText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),

        // 2x2 Grid for Desktop, Stacked for Narrow
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 680;
            final trackTile = TrackingRuleTile(
              icon: Icons.inventory_outlined,
              iconColor: const Color(0xFF22C55E), // Green
              title: 'Track Inventory',
              subtitle: 'Track stock quantity for this product',
              value: state.trackInventory,
              enabled: true,
              onChanged: (val) => _setTrackInventory(context, val),
            );
            final batchTile = TrackingRuleTile(
              icon: Icons.widgets_outlined,
              iconColor: const Color(0xFF6366F1), // Purple
              title: 'Batch / Lot Tracking',
              subtitle: 'Track by batch or lot numbers',
              value: state.batchTracking,
              enabled: state.trackInventory && !state.serialTracking,
              onChanged: (val) => _setBatchTracking(context, val),
            );
            final expiryTile = TrackingRuleTile(
              icon: Icons.event_available_outlined,
              iconColor: Colors.orange,
              title: 'Expiry Date Tracking',
              subtitle: 'Track expiry dates for perishable items',
              value: state.expiryTracking,
              enabled: state.trackInventory &&
                  state.batchTracking &&
                  !state.serialTracking,
              onChanged: (val) => _setExpiryTracking(context, val),
            );
            final serialTile = TrackingRuleTile(
              icon: Icons.qr_code_scanner_outlined,
              iconColor: Colors.teal,
              title: 'Serial Number Tracking',
              subtitle: 'Track by unique serial numbers',
              value: state.serialTracking,
              enabled: state.trackInventory,
              onChanged: (val) => _setSerialTracking(context, val),
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  trackTile,
                  const SizedBox(height: TenantAdminSpacing.md),
                  batchTile,
                  const SizedBox(height: TenantAdminSpacing.md),
                  expiryTile,
                  const SizedBox(height: TenantAdminSpacing.md),
                  serialTile,
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: trackTile),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: batchTile),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: expiryTile),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: serialTile),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: TenantAdminSpacing.lg),

        // Simple Info Banner
        _buildInfoBanner(
          'Units & Pack Conversion will be configured in the next stage.',
        ),
      ],
    );
  }

  // --- VARIANT PRODUCT CONTENT ---
  Widget _buildVariantTrackingContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Inventory Tracking (Applied at Variant Level) *',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Choose how you want to track inventory for this product variants.',
          style: TextStyle(
            fontSize: 13,
            color: TenantAdminColors.mutedText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),

        // 2x2 Grid for Desktop, Stacked for Narrow
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 680;
            final trackTile = TrackingRuleTile(
              icon: Icons.inventory_outlined,
              iconColor: const Color(0xFF22C55E),
              title: 'Track Inventory',
              subtitle: 'Track stock quantity for each variant',
              value: state.trackInventory,
              enabled: true,
              onChanged: (val) => _setTrackInventory(context, val),
            );
            final batchTile = TrackingRuleTile(
              icon: Icons.widgets_outlined,
              iconColor: const Color(0xFF6366F1),
              title: 'Batch / Lot Tracking',
              subtitle: 'Track by batch or lot numbers for each variant',
              value: state.batchTracking,
              enabled: state.trackInventory && !state.serialTracking,
              onChanged: (val) => _setBatchTracking(context, val),
            );
            final expiryTile = TrackingRuleTile(
              icon: Icons.event_available_outlined,
              iconColor: Colors.orange,
              title: 'Expiry Date Tracking',
              subtitle: 'Track expiry dates for perishable items (per variant)',
              value: state.expiryTracking,
              enabled: state.trackInventory &&
                  state.batchTracking &&
                  !state.serialTracking,
              onChanged: (val) => _setExpiryTracking(context, val),
            );
            final serialTile = TrackingRuleTile(
              icon: Icons.qr_code_scanner_outlined,
              iconColor: Colors.teal,
              title: 'Serial Number Tracking',
              subtitle: 'Track by unique serial numbers (per variant)',
              value: state.serialTracking,
              enabled: state.trackInventory,
              onChanged: (val) => _setSerialTracking(context, val),
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  trackTile,
                  const SizedBox(height: TenantAdminSpacing.md),
                  batchTile,
                  const SizedBox(height: TenantAdminSpacing.md),
                  expiryTile,
                  const SizedBox(height: TenantAdminSpacing.md),
                  serialTile,
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: trackTile),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: batchTile),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: expiryTile),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: serialTile),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: TenantAdminSpacing.lg),

        // Green Info Banner at the bottom
        _buildInfoBanner(
          'Inventory will be tracked by total quantity at variant level.',
          icon: Icons.check_circle,
          color: const Color(0xFF22C55E),
        ),
      ],
    );
  }

  // --- BUNDLE PRODUCT CONTENT ---
  Widget _buildBundleInventoryBehaviour(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bundle Inventory Behaviour',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Bundle items do not track stock directly. Stock is derived from components.',
          style: TextStyle(
            fontSize: 14,
            color: TenantAdminColors.mutedText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.md),

        // 3 Informational Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 720;
            final cards = [
              const BundleInventoryBehaviourCard(
                icon: Icons.account_tree_outlined,
                title: 'Component-based Inventory',
                description:
                    'Bundle availability is calculated from available component stock.',
              ),
              const BundleInventoryBehaviourCard(
                icon: Icons.remove_shopping_cart_outlined,
                title: 'Component Stock Deduction',
                description:
                    'Selling one Bundle deducts configured quantities from component items.',
              ),
              const BundleInventoryBehaviourCard(
                icon: Icons.rule_outlined,
                title: 'Component Tracking Rules',
                description:
                    'Batch, Expiry and Serial tracking follow each underlying component Product / Variant\'s own tracking configuration.',
              ),
            ];

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  cards[0],
                  const SizedBox(height: TenantAdminSpacing.md),
                  cards[1],
                  const SizedBox(height: TenantAdminSpacing.md),
                  cards[2],
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: cards[1]),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: cards[2]),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: TenantAdminSpacing.lg),

        // Bundle Info Banner
        _buildInfoBanner(
          'Bundle components will be configured in Product Configuration.',
        ),
      ],
    );
  }
  Widget _buildInfoBanner(String message, {IconData? icon, Color? color}) {
    final bannerColor = color ?? TenantAdminColors.posHomeAccentOrange;
    final iconData = icon ?? Icons.info_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
          color: bannerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            iconData,
            color: bannerColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: TenantAdminColors.bodyText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable Product Structure selection card.
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
                      ? TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.1)
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
                      style: TextStyle(
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

/// Reusable tracking switch control tile.
class TrackingRuleTile extends StatelessWidget {
  const TrackingRuleTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.5;
    const activeColor = Color(0xFF22C55E); // Green

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        constraints: const BoxConstraints(minHeight: 40),
        decoration: BoxDecoration(
          color: enabled && value
              ? activeColor.withValues(alpha: 0.04)
              : TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          border: Border.all(
            color: enabled && value ? activeColor : TenantAdminColors.border,
            width: enabled && value ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? (enabled && value
                      ? activeColor
                      : TenantAdminColors.mutedText),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: value,
                    onChanged: enabled ? onChanged : null,
                    activeTrackColor: activeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: TenantAdminColors.bodyText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: TenantAdminColors.mutedText,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable contextual hint card for variant tracking.
class TrackingContextHint extends StatelessWidget {
  const TrackingContextHint({
    super.key,
    required this.message,
    required this.isActive,
  });

  final String message;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final borderColor = isActive
        ? TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.3)
        : TenantAdminColors.border;
    final backgroundColor = isActive
        ? TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.04)
        : TenantAdminColors.secondary.withValues(alpha: 0.5);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: isActive
                ? TenantAdminColors.posHomeAccentOrange
                : TenantAdminColors.mutedText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11,
                color: isActive
                    ? TenantAdminColors.bodyText
                    : TenantAdminColors.mutedText,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable informational card for Bundle inventory behaviour.
class BundleInventoryBehaviourCard extends StatelessWidget {
  const BundleInventoryBehaviourCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      constraints: const BoxConstraints(minHeight: 88),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 24,
            color: TenantAdminColors.posHomeAccentOrange,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
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
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
