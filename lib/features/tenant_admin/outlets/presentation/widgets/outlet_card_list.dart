import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/outlet.dart';
import '../providers/selected_outlet_provider.dart';

class OutletCardList extends ConsumerWidget {
  const OutletCardList({
    super.key,
    required this.outlets,
    required this.onView,
    required this.onEdit,
    required this.onDisable,
    this.scrollable = false,
  });

  final List<Outlet> outlets;
  final ValueChanged<Outlet> onView;
  final ValueChanged<Outlet> onEdit;
  final ValueChanged<Outlet> onDisable;
  final bool scrollable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      shrinkWrap: !scrollable,
      physics: scrollable
          ? const ClampingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.md,
      ),
      itemCount: outlets.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: TenantAdminSpacing.md),
      itemBuilder: (context, index) {
        final outlet = outlets[index];
        final isSelected = ref.watch(selectedOutletIdProvider) == outlet.id;

        return _OutletCard(
          outlet: outlet,
          isSelected: isSelected,
          onTap: () =>
              ref.read(selectedOutletIdProvider.notifier).state = outlet.id,
          onView: () => onView(outlet),
          onEdit: () => onEdit(outlet),
          onDisable: () => onDisable(outlet),
        );
      },
    );
  }
}

class _OutletCard extends StatelessWidget {
  const _OutletCard({
    required this.outlet,
    required this.isSelected,
    required this.onTap,
    required this.onView,
    required this.onEdit,
    required this.onDisable,
  });

  final Outlet outlet;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDisable;

  bool get _isActive => outlet.status.toUpperCase() == 'ACTIVE';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final content = compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OutletThumbnail(outlet: outlet, compact: true),
                      const SizedBox(width: TenantAdminSpacing.md),
                      Expanded(child: _OutletMainInfo(outlet: outlet)),
                    ],
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _ActionsColumn(
                      isActive: _isActive,
                      onView: onView,
                      onEdit: onEdit,
                      onDisable: onDisable,
                      horizontal: true,
                    ),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _OutletThumbnail(outlet: outlet),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: _OutletMainInfo(outlet: outlet)),
                  const SizedBox(width: TenantAdminSpacing.md),
                  _ActionsColumn(
                    isActive: _isActive,
                    onView: onView,
                    onEdit: onEdit,
                    onDisable: onDisable,
                  ),
                ],
              );

        return Semantics(
          button: true,
          selected: isSelected,
          label: 'Outlet ${outlet.name}',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(TenantAdminSpacing.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? TenantAdminColors.posHomeAccentOrange
                        .withValues(alpha: 0.04)
                    : TenantAdminColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? TenantAdminColors.posHomeAccentOrange
                      : TenantAdminColors.border,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: TenantAdminColors.posHomeAccentOrange
                              .withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: content,
            ),
          ),
        );
      },
    );
  }
}

class _OutletMainInfo extends StatelessWidget {
  const _OutletMainInfo({required this.outlet});

  final Outlet outlet;

  bool get _isActive => outlet.status.toUpperCase() == 'ACTIVE';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackMeta = constraints.maxWidth < 520;
        final metaCells = [
          _LabelValue(
            label: 'Code',
            value: outlet.code.isNotEmpty ? outlet.code : '-',
          ),
          _ManagerCell(
            name: outlet.managerName,
            avatarUrl: outlet.managerAvatarUrl,
          ),
          _LabelValue(
            label: 'Tills',
            valueWidget: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  outlet.canViewTillsAndHealth
                      ? '${outlet.activeTillCount} / ${outlet.tillCount}'
                      : 'Restricted',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: outlet.canViewTillsAndHealth
                        ? TenantAdminColors.bodyText
                        : TenantAdminColors.mutedText,
                  ),
                ),
                if (outlet.canViewTillsAndHealth)
                  _StatusBadge(isActive: _isActive),
              ],
            ),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    outlet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: TenantAdminColors.bodyText,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _TypeBadge(type: outlet.outletType),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            if (stackMeta)
              Wrap(
                spacing: TenantAdminSpacing.lg,
                runSpacing: TenantAdminSpacing.sm,
                children: metaCells,
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: metaCells[0]),
                  const SizedBox(width: TenantAdminSpacing.lg),
                  Expanded(flex: 2, child: metaCells[1]),
                  const SizedBox(width: TenantAdminSpacing.lg),
                  Expanded(flex: 2, child: metaCells[2]),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _OutletThumbnail extends StatelessWidget {
  const _OutletThumbnail({
    required this.outlet,
    this.compact = false,
  });

  final Outlet outlet;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasImage = outlet.imageUrl != null && outlet.imageUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: compact ? 72 : 90,
        height: compact ? 64 : 72,
        child: hasImage
            ? Image.network(
                outlet.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  return loadingProgress == null ? child : _placeholder();
                },
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: const Center(
        child: Icon(
          Icons.storefront_outlined,
          color: TenantAdminColors.mutedText,
          size: 28,
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({this.type});

  final String? type;

  @override
  Widget build(BuildContext context) {
    if (type == null || type!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final isWarehouse = type!.toUpperCase() == 'WAREHOUSE';
    final bgColor =
        isWarehouse ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4);
    final textColor =
        isWarehouse ? const Color(0xFF2563EB) : TenantAdminColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({
    required this.label,
    this.value,
    this.valueWidget,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 72, maxWidth: 190),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: TenantAdminColors.mutedText,
            ),
          ),
          const SizedBox(height: 2),
          valueWidget ??
              Text(
                value ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: TenantAdminColors.bodyText,
                ),
              ),
        ],
      ),
    );
  }
}

class _ManagerCell extends StatelessWidget {
  const _ManagerCell({this.name, this.avatarUrl});

  final String? name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final hasManager = name != null && name!.trim().isNotEmpty;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manager',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: TenantAdminColors.mutedText,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              _avatar(hasManager),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasManager ? name!.trim() : 'Not assigned',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: hasManager
                        ? TenantAdminColors.bodyText
                        : TenantAdminColors.mutedText,
                    fontStyle: hasManager ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatar(bool hasManager) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 12,
        backgroundImage: NetworkImage(avatarUrl!),
        onBackgroundImageError: (_, __) {},
      );
    }

    if (hasManager) {
      final initials = name!
          .trim()
          .split(' ')
          .where((word) => word.isNotEmpty)
          .take(2)
          .map((word) => word[0].toUpperCase())
          .join();
      return CircleAvatar(
        radius: 12,
        backgroundColor:
            TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.12),
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: TenantAdminColors.posHomeAccentOrange,
          ),
        ),
      );
    }

    return const CircleAvatar(
      radius: 12,
      backgroundColor: Color(0xFFF1F5F9),
      child: Icon(
        Icons.person_outline,
        size: 14,
        color: TenantAdminColors.mutedText,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? TenantAdminColors.success : TenantAdminColors.warning;
    final bg = isActive ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB);
    final label = isActive ? 'Active' : 'Attention';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsColumn extends StatelessWidget {
  const _ActionsColumn({
    required this.isActive,
    required this.onView,
    required this.onEdit,
    required this.onDisable,
    this.horizontal = false,
  });

  final bool isActive;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDisable;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionBtn(
        icon: Icons.visibility_outlined,
        label: 'View',
        color: TenantAdminColors.info,
        onTap: onView,
      ),
      _ActionBtn(
        icon: Icons.edit_outlined,
        label: 'Edit',
        color: TenantAdminColors.info,
        onTap: onEdit,
      ),
      _ActionBtn(
        icon: isActive ? Icons.block_outlined : Icons.check_circle_outline,
        label: isActive ? 'Disable' : 'Activate',
        color: isActive ? TenantAdminColors.danger : TenantAdminColors.success,
        onTap: onDisable,
      ),
    ];

    if (horizontal) {
      return Wrap(
        spacing: TenantAdminSpacing.sm,
        runSpacing: TenantAdminSpacing.xs,
        alignment: WrapAlignment.end,
        children: actions,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        actions[0],
        const SizedBox(height: 4),
        actions[1],
        const SizedBox(height: 4),
        actions[2],
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
