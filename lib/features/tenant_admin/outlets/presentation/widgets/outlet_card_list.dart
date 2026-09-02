import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/core/network/media_url_resolver.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/outlet.dart';
import '../providers/selected_outlet_provider.dart';

class OutletCardList extends ConsumerWidget {
  const OutletCardList({
    super.key,
    required this.outlets,
    required this.onEdit,
    required this.onDisable,
    this.scrollable = false,
  });

  final List<Outlet> outlets;
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
    required this.onEdit,
    required this.onDisable,
  });

  final Outlet outlet;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDisable;

  bool get _isActive => outlet.status.toUpperCase() == 'ACTIVE';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 500;
        final content = compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OutletThumbnail(outlet: outlet, compact: true),
                      const SizedBox(width: TenantAdminSpacing.lg),
                      Expanded(child: _OutletMainInfo(outlet: outlet)),
                    ],
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  const Divider(height: 1, color: TenantAdminColors.border),
                  const SizedBox(height: TenantAdminSpacing.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _ActionsColumn(
                      isActive: _isActive,
                      onView: onTap,
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
                  const SizedBox(width: TenantAdminSpacing.xl),
                  Expanded(child: _OutletMainInfo(outlet: outlet)),
                  const SizedBox(width: TenantAdminSpacing.xl),
                  _ActionsColumn(
                    isActive: _isActive,
                    onView: onTap,
                    onEdit: onEdit,
                    onDisable: onDisable,
                    horizontal: false,
                  ),
                ],
              );

        return Semantics(
          button: true,
          selected: isSelected,
          label: 'Outlet ${outlet.name}',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(TenantAdminSpacing.xl),
              decoration: BoxDecoration(
                color: isSelected
                    ? TenantAdminColors.posHomeAccentOrange
                        .withValues(alpha: 0.03)
                    : TenantAdminColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? TenantAdminColors.posHomeAccentOrange
                      : TenantAdminColors.border.withValues(alpha: 0.6),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: TenantAdminColors.posHomeAccentOrange
                              .withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color:
                              const Color(0xFF0F172A).withValues(alpha: 0.04),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
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

        final nameRow = Row(
          children: [
            Flexible(
              child: Text(
                outlet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: TenantAdminColors.navy,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            _TypeBadge(type: outlet.outletType),
          ],
        );

        Widget buildMetaItem(String label, Widget child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: TenantAdminColors.mutedText,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              child,
            ],
          );
        }

        final codeBlock = buildMetaItem(
          'Code',
          Text(
            outlet.code.isNotEmpty ? outlet.code : '-',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: TenantAdminColors.bodyText,
            ),
          ),
        );

        final managerBlock = buildMetaItem(
          'Manager',
          _ManagerCell(
            name: outlet.managerName,
            avatarUrl: outlet.managerAvatarUrl,
          ),
        );

        final tillsBlock = buildMetaItem(
          'Tills',
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                outlet.canViewTillsAndHealth
                    ? '${outlet.activeTillCount} / ${outlet.tillCount}'
                    : 'Restricted',
                style: TextStyle(
                  fontSize: 14,
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
        );

        final divider = Container(
          width: 1,
          height: 32,
          color: TenantAdminColors.border.withValues(alpha: 0.6),
          margin: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.lg),
        );

        if (stackMeta) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              nameRow,
              const SizedBox(height: TenantAdminSpacing.lg),
              Wrap(
                spacing: TenantAdminSpacing.xl,
                runSpacing: TenantAdminSpacing.md,
                children: [
                  codeBlock,
                  managerBlock,
                  tillsBlock,
                ],
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            nameRow,
            const SizedBox(height: TenantAdminSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: codeBlock),
                divider,
                Expanded(flex: 2, child: managerBlock),
                divider,
                Expanded(flex: 2, child: tillsBlock),
              ],
            ),
          ],
        );
      },
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _avatar(hasManager),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            hasManager ? name!.trim() : 'Not assigned',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: hasManager
                  ? TenantAdminColors.bodyText
                  : TenantAdminColors.mutedText,
              fontStyle: hasManager ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatar(bool hasManager) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: TenantAdminColors.border, width: 1.5),
        ),
        child: CircleAvatar(
          radius: 12,
          backgroundImage: NetworkImage(avatarUrl!),
          onBackgroundImageError: (_, __) {},
        ),
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
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: CircleAvatar(
          radius: 12,
          backgroundColor:
              TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.1),
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: TenantAdminColors.posHomeAccentOrange,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: TenantAdminColors.border, width: 1.5),
      ),
      child: const CircleAvatar(
        radius: 12,
        backgroundColor: TenantAdminColors.subtleBackground,
        child: Icon(
          Icons.person_outline,
          size: 14,
          color: TenantAdminColors.mutedText,
        ),
      ),
    );
  }
}

class _OutletThumbnail extends ConsumerWidget {
  const _OutletThumbnail({
    required this.outlet,
    this.compact = false,
  });

  final Outlet outlet;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl = outlet.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final resolvedImageUrl = hasImage
        ? MediaUrlResolver.resolve(
              imageUrl,
              apiBaseUrl: ref.watch(appDioProvider).options.baseUrl,
              replaceLoopbackHost: true,
            ) ??
            imageUrl
        : null;
    final size = compact ? 64.0 : 80.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: TenantAdminColors.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: resolvedImageUrl != null
            ? Image.network(
                resolvedImageUrl,
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
    return Image.asset(
      'assets/images/outlet-placeholder.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: TenantAdminColors.secondary,
        child: Center(
          child: Icon(
            Icons.storefront_rounded,
            color: TenantAdminColors.primary,
            size: 32,
          ),
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
        isWarehouse ? const Color(0xFF1D4ED8) : const Color(0xFF15803D);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        type!.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: textColor,
        ),
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
    final label = isActive ? 'Active' : 'Needs Attention';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 0),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TenantAdminColors.mutedText,
            ),
          ),
        ),
      ],
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
      _ActionTextBtn(
        icon: Icons.visibility_outlined,
        label: 'View',
        color: TenantAdminColors.info,
        onTap: onView,
      ),
      _ActionTextBtn(
        icon: Icons.edit_outlined,
        label: 'Edit',
        color: TenantAdminColors.info,
        onTap: onEdit,
      ),
      _ActionTextBtn(
        icon: isActive ? Icons.block_outlined : Icons.check_circle_outline,
        label: isActive ? 'Disable' : 'Activate',
        color: isActive ? TenantAdminColors.danger : TenantAdminColors.success,
        onTap: onDisable,
      ),
    ];

    if (horizontal) {
      return Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: actions,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        actions[0],
        const SizedBox(height: 12),
        actions[1],
        const SizedBox(height: 12),
        actions[2],
      ],
    );
  }
}

class _ActionTextBtn extends StatelessWidget {
  const _ActionTextBtn({
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
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
