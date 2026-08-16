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
  });

  final AddProductWizardState state;
  final AddProductWizardController controller;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= TenantAdminBreakpoints.desktop;

    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Header
          const Text(
            'Product Type & Tracking Setup',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose the product type and how this product should be tracked.',
            style: TextStyle(
              fontSize: 14,
              color: TenantAdminColors.mutedText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),

          // Section 1: Select Product Type
          const Text(
            'Select Product Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),

          // 3 Product Structure Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 680;
              final cards = [
                ProductStructureCard(
                  structure: 'SIMPLE',
                  title: 'Simple Product',
                  description:
                      'Single standalone product with one price and SKU.',
                  icon: Icons.inventory_2_outlined,
                  selected: state.productStructure == 'SIMPLE',
                  onSelected: () => controller.setProductStructure('SIMPLE'),
                ),
                ProductStructureCard(
                  structure: 'VARIANT',
                  title: 'Variant Product',
                  description:
                      'Product with options like size, color, or material.',
                  icon: Icons.dashboard_customize_outlined,
                  selected: state.productStructure == 'VARIANT',
                  onSelected: () => controller.setProductStructure('VARIANT'),
                ),
                ProductStructureCard(
                  structure: 'BUNDLE',
                  title: 'Bundle / Kit',
                  description: 'Collection of existing items sold together.',
                  icon: Icons.inventory_outlined,
                  selected: state.productStructure == 'BUNDLE',
                  enabled: false,
                  onSelected: () => controller.setProductStructure('BUNDLE'),
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

          // Dynamic content based on productStructure
          _buildDynamicContent(context),
        ],
      );

    return isDesktop ? content : SingleChildScrollView(child: content);
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Configure stock management and inventory tracking for this simple product.',
          style: TextStyle(
            fontSize: 14,
            color: TenantAdminColors.mutedText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.md),

        // 2x2 Grid for Desktop, Stacked for Narrow
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 680;
            final trackTile = TrackingRuleTile(
              icon: Icons.inventory_outlined,
              title: 'Track Inventory',
              subtitle: 'Maintain stock quantity for this product.',
              value: state.trackInventory,
              enabled: true,
              onChanged: (val) => controller.setTrackInventory(val),
            );
            final batchTile = TrackingRuleTile(
              icon: Icons.qr_code_outlined,
              title: 'Batch / Lot Tracking',
              subtitle: 'Track stock by batch or lot numbers.',
              value: state.batchTracking,
              enabled: state.trackInventory && !state.serialTracking,
              onChanged: (val) => controller.setBatchTracking(val),
            );
            final expiryTile = TrackingRuleTile(
              icon: Icons.event_available_outlined,
              title: 'Expiry Tracking',
              subtitle: 'Track expiry dates for perishable items.',
              value: state.expiryTracking,
              enabled: state.trackInventory &&
                  state.batchTracking &&
                  !state.serialTracking,
              onChanged: (val) => controller.setExpiryTracking(val),
            );
            final serialTile = TrackingRuleTile(
              icon: Icons.pin_outlined,
              title: 'Serial Number Tracking',
              subtitle: 'Track and manage serial numbers.',
              value: state.serialTracking,
              enabled: state.trackInventory,
              onChanged: (val) => controller.setSerialTracking(val),
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

            return Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: trackTile),
                      const SizedBox(width: TenantAdminSpacing.md),
                      Expanded(child: batchTile),
                    ],
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: expiryTile),
                      const SizedBox(width: TenantAdminSpacing.md),
                      Expanded(child: serialTile),
                    ],
                  ),
                ),
              ],
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
          'Tracking Settings',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'These settings control how stock is managed for variants at outlet level.',
          style: TextStyle(
            fontSize: 14,
            color: TenantAdminColors.mutedText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.md),

        // Left Control + Right Context Hint layout for Wide Desktop
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 800;

            final rows = [
              _buildControlHintRow(
                isNarrow: isNarrow,
                tile: TrackingRuleTile(
                  icon: Icons.inventory_outlined,
                  title: 'Track Inventory',
                  subtitle: 'Maintain stock quantity for this product.',
                  value: state.trackInventory,
                  enabled: true,
                  onChanged: (val) => controller.setTrackInventory(val),
                ),
                hint: TrackingContextHint(
                  message: state.trackInventory
                      ? 'When ON, stock will be tracked for each variant at outlet level.'
                      : 'When OFF, stock will not be tracked for any variant.',
                  isActive: state.trackInventory,
                ),
              ),
              _buildControlHintRow(
                isNarrow: isNarrow,
                tile: TrackingRuleTile(
                  icon: Icons.qr_code_outlined,
                  title: 'Batch / Lot Tracking',
                  subtitle: 'Track stock by batch or lot numbers.',
                  value: state.batchTracking,
                  enabled: state.trackInventory && !state.serialTracking,
                  onChanged: (val) => controller.setBatchTracking(val),
                ),
                hint: TrackingContextHint(
                  message: state.trackInventory
                      ? 'Each variant may maintain its own batch records.'
                      : 'Enable Track Inventory to use Batch / Lot Tracking.',
                  isActive: state.batchTracking,
                ),
              ),
              _buildControlHintRow(
                isNarrow: isNarrow,
                tile: TrackingRuleTile(
                  icon: Icons.event_available_outlined,
                  title: 'Expiry Tracking',
                  subtitle: 'Track expiry dates for perishable items.',
                  value: state.expiryTracking,
                  enabled: state.trackInventory &&
                      state.batchTracking &&
                      !state.serialTracking,
                  onChanged: (val) => controller.setExpiryTracking(val),
                ),
                hint: TrackingContextHint(
                  message: state.batchTracking
                      ? 'Expiry is tracked through variant batch records.'
                      : 'Batch / Lot Tracking must be turned ON before enabling Expiry Tracking.',
                  isActive: state.expiryTracking,
                ),
              ),
              _buildControlHintRow(
                isNarrow: isNarrow,
                tile: TrackingRuleTile(
                  icon: Icons.pin_outlined,
                  title: 'Serial Number Tracking',
                  subtitle: 'Track and manage serial numbers.',
                  value: state.serialTracking,
                  enabled: state.trackInventory,
                  onChanged: (val) => controller.setSerialTracking(val),
                ),
                hint: TrackingContextHint(
                  message: state.trackInventory
                      ? 'Serial numbers identify individual variant items.'
                      : 'Enable Track Inventory to use Serial Number Tracking.',
                  isActive: state.serialTracking,
                ),
              ),
            ];

            return Column(
              children: [
                rows[0],
                const SizedBox(height: TenantAdminSpacing.md),
                rows[1],
                const SizedBox(height: TenantAdminSpacing.md),
                rows[2],
                const SizedBox(height: TenantAdminSpacing.md),
                rows[3],
              ],
            );
          },
        ),

        const SizedBox(height: TenantAdminSpacing.lg),

        // Variant Info Banner
        _buildInfoBanner(
          'Variant options such as size and color will be configured in Product Configuration.',
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

  Widget _buildControlHintRow({
    required bool isNarrow,
    required Widget tile,
    required Widget hint,
  }) {
    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tile,
          const SizedBox(height: 6),
          hint,
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 5, child: tile),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(flex: 5, child: hint),
        ],
      ),
    );
  }

  Widget _buildInfoBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
          color: TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: TenantAdminColors.posHomeAccentOrange,
            size: 20,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
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
          padding: const EdgeInsets.all(TenantAdminSpacing.md),
          constraints: const BoxConstraints(minHeight: 88),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: selected
                        ? TenantAdminColors.posHomeAccentOrange
                        : TenantAdminColors.mutedText,
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? TenantAdminColors.posHomeAccentOrange
                            : TenantAdminColors.border,
                        width: 2,
                      ),
                      color: selected
                          ? TenantAdminColors.posHomeAccentOrange
                          : Colors.transparent,
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.sm),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? TenantAdminColors.posHomeAccentOrange
                      : TenantAdminColors.bodyText,
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
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.md,
          vertical: TenantAdminSpacing.sm,
        ),
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: TenantAdminColors.secondary,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          border: Border.all(color: TenantAdminColors.border),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled && value
                  ? TenantAdminColors.posHomeAccentOrange
                  : TenantAdminColors.mutedText,
            ),
            const SizedBox(width: TenantAdminSpacing.md),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TenantAdminColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeTrackColor: TenantAdminColors.posHomeAccentOrange,
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
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.sm,
      ),
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 18,
            color: isActive
                ? TenantAdminColors.posHomeAccentOrange
                : TenantAdminColors.mutedText,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: isActive
                    ? TenantAdminColors.bodyText
                    : TenantAdminColors.mutedText,
                height: 1.3,
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
