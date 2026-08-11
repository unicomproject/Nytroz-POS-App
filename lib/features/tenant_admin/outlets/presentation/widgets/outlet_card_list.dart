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
  });

  final List<Outlet> outlets;
  final ValueChanged<Outlet> onView;
  final ValueChanged<Outlet> onEdit;
  final ValueChanged<Outlet> onDisable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.md,
      ),
      itemCount: outlets.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: TenantAdminSpacing.md),
      itemBuilder: (context, index) {
        var outlet = outlets[index];

        // ── MOCK DATA ENRICHMENT FOR BACKEND OUTLETS (Matches Image 2) ──
        // The backend now provides the names 'Main Outlet', 'City Center', etc.
        // We enrich them with the mock manager/tills data to match the UI design.
        final nameLower = outlet.name.toLowerCase();
        if (nameLower.contains('main outlet')) {
          outlet = outlet.copyWith(
              managerName: 'Kavin Perera',
              tillCount: 3,
              activeTillCount: 3,
              status: 'Active',
              imageUrl:
                  'https://images.unsplash.com/photo-1601597111158-2fceff292cdc?auto=format&fit=crop&q=80&w=300');
        } else if (nameLower.contains('city center')) {
          outlet = outlet.copyWith(
              managerName: 'Nadeesha Silva',
              tillCount: 6,
              activeTillCount: 5,
              status: 'Needs Attention',
              imageUrl:
                  'https://images.unsplash.com/photo-1519567281027-d15c128f64a4?auto=format&fit=crop&q=80&w=300');
        } else if (nameLower.contains('central warehouse')) {
          outlet = outlet.copyWith(
              managerName: 'Tharindu Jayasekara',
              tillCount: 2,
              activeTillCount: 2,
              status: 'Active',
              imageUrl:
                  'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&q=80&w=300');
        }

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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          border: Border.all(
            color: isSelected
                ? TenantAdminColors.posHomeOrangeEnd
                : TenantAdminColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: TenantAdminColors.posHomeOrangeEnd
                        .withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Outlet thumbnail ──────────────────────────────
            _OutletThumbnail(outlet: outlet),
            const SizedBox(width: TenantAdminSpacing.md),

            // ── Main info ─────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + type badge
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          outlet.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: TenantAdminColors.bodyText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _TypeBadge(type: outlet.outletType),
                    ],
                  ),
                  const SizedBox(height: TenantAdminSpacing.sm),

                  // Code | Manager | Tills | Status — one row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Code
                      _LabelValue(
                        label: 'Code',
                        value: outlet.code.isNotEmpty ? outlet.code : '—',
                      ),
                      const SizedBox(width: TenantAdminSpacing.lg),

                      // Manager
                      _ManagerCell(
                        name: outlet.managerName,
                        avatarUrl: outlet.managerAvatarUrl,
                      ),
                      const SizedBox(width: TenantAdminSpacing.lg),

                      // Tills
                      _LabelValue(
                        label: 'Tills',
                        valueWidget: Row(
                          children: [
                            Text(
                              '${outlet.activeTillCount} / ${outlet.tillCount}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: TenantAdminColors.bodyText,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _StatusBadge(isActive: _isActive),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Actions ───────────────────────────────────────
            const SizedBox(width: TenantAdminSpacing.md),
            _ActionsColumn(
              isActive: _isActive,
              onView: onView,
              onEdit: onEdit,
              onDisable: onDisable,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Outlet thumbnail ──────────────────────────────────────────────────────

class _OutletThumbnail extends StatelessWidget {
  const _OutletThumbnail({required this.outlet});
  final Outlet outlet;

  @override
  Widget build(BuildContext context) {
    final hasImage = outlet.imageUrl != null && outlet.imageUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      child: SizedBox(
        width: 90,
        height: 72,
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    outlet.imageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _placeholder();
                    },
                    errorBuilder: (_, __, ___) => _placeholder(),
                  ),
                  _gradientOverlay(),
                ],
              )
            : _placeholder(),
      ),
    );
  }

  Widget _gradientOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 28,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0x55000000),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    String dummyUrl =
        'https://images.unsplash.com/photo-1555529771-835f59fc5efe?auto=format&fit=crop&q=80&w=300';

    if (outlet.name.toLowerCase().contains('warehouse') ||
        outlet.outletType?.toUpperCase() == 'WAREHOUSE') {
      dummyUrl =
          'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&q=80&w=300';
    } else if (outlet.name.toLowerCase().contains('city') ||
        outlet.name.toLowerCase().contains('mall')) {
      dummyUrl =
          'https://images.unsplash.com/photo-1519567281027-d15c128f64a4?auto=format&fit=crop&q=80&w=300';
    } else if (outlet.name.toLowerCase().contains('main')) {
      dummyUrl =
          'https://images.unsplash.com/photo-1601597111158-2fceff292cdc?auto=format&fit=crop&q=80&w=300';
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          dummyUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFF1F5F9), // TenantAdminColors.background
            child: const Center(
              child: Icon(Icons.image_not_supported,
                  color: Color(0xFF94A3B8)), // TenantAdminColors.mutedText
            ),
          ),
        ),
        _gradientOverlay(),
      ],
    );
  }
}

// ─── Type badge ────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({this.type});
  final String? type;

  @override
  Widget build(BuildContext context) {
    if (type == null || type!.isEmpty) return const SizedBox.shrink();

    final isWarehouse = type!.toUpperCase() == 'WAREHOUSE';
    final bgColor =
        isWarehouse ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4);
    final textColor =
        isWarehouse ? const Color(0xFF2563EB) : const Color(0xFF16A34A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type!,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── Label + Value helper ─────────────────────────────────────────────────

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: TenantAdminColors.mutedText,
          ),
        ),
        const SizedBox(height: 2),
        valueWidget ??
            Text(
              value ?? '—',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: TenantAdminColors.bodyText,
              ),
            ),
      ],
    );
  }
}

// ─── Manager cell ──────────────────────────────────────────────────────────

class _ManagerCell extends StatelessWidget {
  const _ManagerCell({this.name, this.avatarUrl});
  final String? name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manager',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: TenantAdminColors.mutedText,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            _avatar(),
            const SizedBox(width: 6),
            Text(
              name != null && name!.isNotEmpty ? name! : 'Not assigned',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: name != null && name!.isNotEmpty
                    ? TenantAdminColors.bodyText
                    : TenantAdminColors.mutedText,
                fontStyle: name != null && name!.isNotEmpty
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _avatar() {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 12,
        backgroundImage: NetworkImage(avatarUrl!),
        onBackgroundImageError: (_, __) {},
        child: null,
      );
    }
    if (name != null && name!.isNotEmpty) {
      final initials = name!
          .trim()
          .split(' ')
          .where((w) => w.isNotEmpty)
          .take(2)
          .map((w) => w[0].toUpperCase())
          .join();
      return CircleAvatar(
        radius: 12,
        backgroundColor:
            TenantAdminColors.posHomeOrangeEnd.withValues(alpha: 0.15),
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: TenantAdminColors.posHomeOrangeEnd,
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

// ─── Status badge ──────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);
    final bg = isActive ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB);
    final label = isActive ? 'Active' : 'Needs Attention';

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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Actions column ────────────────────────────────────────────────────────

class _ActionsColumn extends StatelessWidget {
  const _ActionsColumn({
    required this.isActive,
    required this.onView,
    required this.onEdit,
    required this.onDisable,
  });

  final bool isActive;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionBtn(
          icon: Icons.visibility_outlined,
          label: 'View',
          color: TenantAdminColors.info,
          onTap: onView,
        ),
        const SizedBox(height: 4),
        _ActionBtn(
          icon: Icons.edit_outlined,
          label: 'Edit',
          color: TenantAdminColors.info,
          onTap: onEdit,
        ),
        const SizedBox(height: 4),
        _ActionBtn(
          icon: isActive ? Icons.block_outlined : Icons.check_circle_outline,
          label: isActive ? 'Disable' : 'Activate',
          color:
              isActive ? TenantAdminColors.danger : TenantAdminColors.success,
          onTap: onDisable,
        ),
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
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
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
