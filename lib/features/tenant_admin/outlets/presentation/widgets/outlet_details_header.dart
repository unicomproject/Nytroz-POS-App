import 'package:flutter/material.dart';

import '../../domain/entities/outlet_details.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';

class OutletDetailsHeader extends StatelessWidget {
  const OutletDetailsHeader({
    super.key,
    required this.outlet,
  });

  final OutletDetails outlet;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= TenantAdminBreakpoints.tablet;

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: isWide ? _buildWide(context) : _buildCompact(context),
    );
  }

  Widget _buildWide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StoreAvatar(),
        const SizedBox(width: TenantAdminSpacing.xl),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TitleRow(outlet: outlet),
              const SizedBox(height: TenantAdminSpacing.sm),
              Text(
                _addressLine(outlet),
                style: TenantAdminTextStyles.muted(context),
              ),
              if (outlet.code.isNotEmpty) ...[
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  'Code: ${outlet.code}',
                  style: TenantAdminTextStyles.muted(context).copyWith(
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.lg),
        Expanded(
          flex: 4,
          child: Wrap(
            spacing: TenantAdminSpacing.xl,
            runSpacing: TenantAdminSpacing.lg,
            children: [
              _HeaderInfoBlock(
                icon: Icons.person_outline,
                label: 'Manager',
                value: outlet.managerDisplay,
                hint: outlet.managerContact,
              ),
              _HeaderInfoBlock(
                icon: Icons.access_time,
                label: 'Opening hours',
                value: outlet.openingHours ?? 'Not set',
              ),
              _HeaderInfoBlock(
                icon: Icons.check_circle_outline,
                label: "Today's status",
                value: outlet.todaysStatus ?? 'Operating as normal today',
                iconColor: TenantAdminColors.success,
              ),
            ],
          ),
        ),
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
            Expanded(child: _TitleRow(outlet: outlet)),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Text(
          _addressLine(outlet),
          style: TenantAdminTextStyles.muted(context),
        ),
        if (outlet.code.isNotEmpty) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            'Code: ${outlet.code}',
            style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 12),
          ),
        ],
        const SizedBox(height: TenantAdminSpacing.lg),
        Wrap(
          spacing: TenantAdminSpacing.xl,
          runSpacing: TenantAdminSpacing.lg,
          children: [
            _HeaderInfoBlock(
              icon: Icons.person_outline,
              label: 'Manager',
              value: outlet.managerDisplay,
              hint: outlet.managerContact,
            ),
            _HeaderInfoBlock(
              icon: Icons.access_time,
              label: 'Opening hours',
              value: outlet.openingHours ?? 'Not set',
            ),
            _HeaderInfoBlock(
              icon: Icons.check_circle_outline,
              label: "Today's status",
              value: outlet.todaysStatus ?? 'Operating as normal today',
              iconColor: TenantAdminColors.success,
            ),
          ],
        ),
      ],
    );
  }

  String _addressLine(OutletDetails outlet) {
    if (outlet.address.trim().isNotEmpty) {
      return outlet.address;
    }

    if (outlet.phone != null && outlet.phone!.trim().isNotEmpty) {
      return outlet.phone!;
    }

    return 'Address not available';
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

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.outlet});

  final OutletDetails outlet;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: TenantAdminSpacing.md,
      runSpacing: TenantAdminSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          outlet.name,
          style: TenantAdminTextStyles.sectionTitle(context).copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        TenantAdminStatusBadge(
          label: _displayStatus(outlet.status),
          status: _statusType(outlet.status),
        ),
      ],
    );
  }
}

class _HeaderInfoBlock extends StatelessWidget {
  const _HeaderInfoBlock({
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? hint;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor ?? TenantAdminColors.primary, size: 20),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TenantAdminTextStyles.muted(context).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                if (hint != null && hint!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TenantAdminTextStyles.muted(context).copyWith(
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
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

  return normalized;
}

TenantAdminStatusType _statusType(String status) {
  switch (status.trim().toLowerCase()) {
    case 'active':
      return TenantAdminStatusType.active;
    case 'inactive':
      return TenantAdminStatusType.inactive;
    case '':
      return TenantAdminStatusType.active;
    default:
      return TenantAdminStatusType.pending;
  }
}
