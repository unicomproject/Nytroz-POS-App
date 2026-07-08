import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/outlet_detail_entities.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';

class OutletDetailHeader extends StatelessWidget {
  const OutletDetailHeader({
    super.key,
    required this.outlet,
    required this.canEdit,
    this.outletOptions = const [],
    this.onOutletSelected,
  });

  final OutletDetail outlet;
  final bool canEdit;
  final List<OutletDetail> outletOptions;
  final ValueChanged<String>? onOutletSelected;

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.sizeOf(context).width >= TenantAdminBreakpoints.tablet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: TenantAdminSpacing.sm,
          runSpacing: TenantAdminSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _BreadcrumbLink(
              label: 'Dashboard',
              onTap: () => context.go('/tenant-admin/dashboard'),
            ),
            const Icon(Icons.chevron_right, size: 16, color: TenantAdminColors.mutedText),
            _BreadcrumbLink(
              label: 'Outlets',
              onTap: () => context.go('/tenant-admin/outlets'),
            ),
            const Icon(Icons.chevron_right, size: 16, color: TenantAdminColors.mutedText),
            Text(
              outlet.outletName,
              style: TenantAdminTextStyles.muted(context).copyWith(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(TenantAdminSpacing.xl),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            border: Border.all(color: TenantAdminColors.border),
            boxShadow: TenantAdminShadows.card,
          ),
          child: isWide ? _buildWide(context) : _buildCompact(context),
        ),
      ],
    );
  }

  Widget _buildWide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StoreAvatar(),
        const SizedBox(width: TenantAdminSpacing.xl),
        Expanded(child: _buildTitleBlock(context)),
        if (outletOptions.length > 1) ...[
          const SizedBox(width: TenantAdminSpacing.lg),
          SizedBox(width: 220, child: _outletSelector()),
        ],
        if (canEdit) ...[
          const SizedBox(width: TenantAdminSpacing.lg),
          TenantAdminPrimaryButton(
            label: 'Edit',
            icon: Icons.edit_outlined,
            onPressed: () =>
                context.go('/tenant-admin/outlets/${outlet.outletId}/edit'),
          ),
        ],
      ],
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StoreAvatar(),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(child: _buildTitleBlock(context)),
          ],
        ),
        if (outletOptions.length > 1) ...[
          const SizedBox(height: TenantAdminSpacing.md),
          _outletSelector(),
        ],
        if (canEdit) ...[
          const SizedBox(height: TenantAdminSpacing.md),
          TenantAdminPrimaryButton(
            label: 'Edit',
            icon: Icons.edit_outlined,
            onPressed: () =>
                context.go('/tenant-admin/outlets/${outlet.outletId}/edit'),
          ),
        ],
      ],
    );
  }

  Widget _buildTitleBlock(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          outlet.outletName,
          style: TenantAdminTextStyles.sectionTitle(context).copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Wrap(
          spacing: TenantAdminSpacing.md,
          runSpacing: TenantAdminSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _MetaChip(
              icon: Icons.tag,
              label: 'Outlet Code: ${outlet.outletCode}',
            ),
            TenantAdminStatusBadge(
              label: _displayStatus(outlet.status),
              status: _statusType(outlet.status),
            ),
            _MetaChip(
              icon: Icons.storefront_outlined,
              label: outlet.displayOutletType,
            ),
          ],
        ),
      ],
    );
  }

  Widget _outletSelector() {
    return DropdownButtonFormField<String>(
      initialValue: outlet.outletId,
      decoration: const InputDecoration(
        labelText: 'Outlet',
        prefixIcon: Icon(Icons.store_outlined, size: 18),
      ),
      items: [
        for (final option in outletOptions)
          DropdownMenuItem(
            value: option.outletId,
            child: Text(option.outletName),
          ),
      ],
      onChanged: (value) {
        if (value == null || value == outlet.outletId) {
          return;
        }

        onOutletSelected?.call(value);
      },
    );
  }
}

class _BreadcrumbLink extends StatelessWidget {
  const _BreadcrumbLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(
          label,
          style: TenantAdminTextStyles.muted(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StoreAvatar extends StatelessWidget {
  const _StoreAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: TenantAdminColors.secondary,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      ),
      child: const Icon(
        Icons.storefront,
        color: TenantAdminColors.primary,
        size: 28,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.secondary,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: TenantAdminColors.primary),
          const SizedBox(width: TenantAdminSpacing.sm),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

String _displayStatus(String status) {
  final normalized = status.trim();
  if (normalized.isEmpty) {
    return 'Active';
  }

  return normalized[0].toUpperCase() + normalized.substring(1).toLowerCase();
}

TenantAdminStatusType _statusType(String status) {
  switch (status.trim().toLowerCase()) {
    case 'active':
      return TenantAdminStatusType.active;
    case 'inactive':
      return TenantAdminStatusType.inactive;
    default:
      return TenantAdminStatusType.pending;
  }
}
