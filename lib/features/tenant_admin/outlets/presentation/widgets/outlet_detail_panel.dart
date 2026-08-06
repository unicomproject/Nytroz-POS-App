import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/outlet_detail_providers.dart';
import '../providers/selected_outlet_provider.dart';
import '../../domain/entities/outlet.dart';

class OutletDetailPanel extends ConsumerWidget {
  const OutletDetailPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedOutletIdProvider);

    if (selectedId == null) {
      return const _EmptyPanel();
    }

    final overviewState =
        ref.watch(tenantAdminOutletOverviewProvider(selectedId));

    return overviewState.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(TenantAdminSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => TenantAdminErrorState(
        title: 'Unable to load details',
        message: error.toString(),
        onRetry: () =>
            ref.refresh(tenantAdminOutletOverviewProvider(selectedId)),
      ),
      data: (overview) => _PanelContent(overview: overview),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel();

  @override
  Widget build(BuildContext context) {
    return const TenantAdminEmptyState(
      title: 'No outlet selected',
      message: 'Select an outlet from the list to view its details.',
      icon: Icons.storefront_outlined,
    );
  }
}

// ─── Filled panel ──────────────────────────────────────────────────────────

class _PanelContent extends ConsumerWidget {
  const _PanelContent({required this.overview});
  final TenantAdminOutletOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row: name + close ────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  overview.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: TenantAdminColors.bodyText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Tooltip(
                message: 'Close outlet details',
                child: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: TenantAdminColors.mutedText,
                  splashRadius: 18,
                  onPressed: () =>
                      ref.read(selectedOutletIdProvider.notifier).state = null,
                  tooltip: 'Close outlet details',
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.md),

          // ── Banner image ────────────────────────────────────
          _BannerImage(imageUrl: overview.imageUrl),
          const SizedBox(height: TenantAdminSpacing.md),

          // ── Status / type pills + code ─────────────────────
          Row(
            children: [
              _StatusPill(status: overview.status),
              const SizedBox(width: 6),
              _TypePill(type: overview.type),
              const Spacer(),
              Text(
                'Code: ${overview.code}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TenantAdminColors.bodyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),

          // ── Contact details ─────────────────────────────────
          const Text(
            'Contact Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          _ContactRow(
            icon: Icons.location_on_outlined,
            value: _addressText(overview),
          ),
          _ContactRow(
            icon: Icons.phone_outlined,
            value: _safeText(overview.managerPhone, fallback: 'Not provided'),
          ),
          _ContactRow(
            icon: Icons.email_outlined,
            value: _safeText(overview.managerEmail, fallback: 'Not provided'),
          ),

          const SizedBox(height: TenantAdminSpacing.lg),

          // ── Metrics 2×2 grid ────────────────────────────────
          _MetricsGrid(overview: overview),

          // ── Operational alert ───────────────────────────────
          if (overview.canViewAlerts && overview.totalActiveAlertCount > 0) ...[
            const SizedBox(height: TenantAdminSpacing.lg),
            _AlertBanner(overview: overview),
          ],
        ],
      ),
    );
  }

  String _addressText(TenantAdminOutletOverview o) {
    final parts = <String>[
      if (o.addressLine1 != null && o.addressLine1!.isNotEmpty) o.addressLine1!,
      if (o.city != null && o.city!.isNotEmpty) o.city!,
    ];
    return parts.isEmpty ? 'Not provided' : parts.join(', ');
  }

  String _safeText(String? raw, {required String fallback}) {
    if (raw == null || raw.isEmpty || raw == 'null') return fallback;
    return raw;
  }
}

// ─── Banner image ──────────────────────────────────────────────────────────

class _BannerImage extends StatelessWidget {
  const _BannerImage({this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Icon(
        Icons.storefront_outlined,
        size: 48,
        color: TenantAdminColors.mutedText,
      ),
    );
  }
}

// ─── Pills ─────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status.toUpperCase() == 'ACTIVE';
    final color = isActive ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);
    final bg = isActive ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Active' : 'Needs Attention',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final isWarehouse = type.toUpperCase() == 'WAREHOUSE';
    final bg = isWarehouse ? const Color(0xFFEFF6FF) : const Color(0xFFF0FDF4);
    final textColor =
        isWarehouse ? const Color(0xFF2563EB) : const Color(0xFF16A34A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── Contact row ───────────────────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: TenantAdminColors.mutedText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
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

// ─── Metrics grid ──────────────────────────────────────────────────────────

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.overview});
  final TenantAdminOutletOverview overview;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: TenantAdminSpacing.sm,
      mainAxisSpacing: TenantAdminSpacing.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: [
        _MetricCard(
          title: "Today's Sales",
          value: overview.canViewSales
              ? '${overview.salesCurrency} ${overview.todayNetSales.toStringAsFixed(2)}'
              : 'Restricted',
          subtitle: overview.canViewSales ? '↑ vs Yesterday' : null,
          subtitleColor: const Color(0xFF16A34A),
          icon: Icons.shopping_bag_outlined,
          iconColor: TenantAdminColors.posHomeOrangeEnd,
          iconBg: TenantAdminColors.posHomeOrangeEnd.withValues(alpha: 0.10),
          isRestricted: !overview.canViewSales,
        ),
        _MetricCard(
          title: 'Active Tills',
          value: overview.canViewTills
              ? '${overview.activeTills} / ${overview.totalTills}'
              : 'Restricted',
          subtitle: overview.canViewTills ? '100% Online' : null,
          subtitleColor: const Color(0xFF16A34A),
          icon: Icons.point_of_sale_outlined,
          iconColor: const Color(0xFF7C3AED),
          iconBg: const Color(0xFF7C3AED).withValues(alpha: 0.1),
          isRestricted: !overview.canViewTills,
        ),
        _MetricCard(
          title: 'Stock Value',
          value: overview.canViewInventory
              ? '${overview.inventoryCurrency} ${overview.stockValue.toStringAsFixed(2)}'
              : 'Restricted',
          subtitle: overview.canViewInventory ? 'Items in stock' : null,
          subtitleColor: TenantAdminColors.mutedText,
          icon: Icons.inventory_2_outlined,
          iconColor: TenantAdminColors.info,
          iconBg: TenantAdminColors.info.withValues(alpha: 0.1),
          isRestricted: !overview.canViewInventory,
        ),
        _MetricCard(
          title: 'Open Orders',
          value: overview.canViewOrders
              ? '${overview.openOrderCount}'
              : 'Restricted',
          subtitle: overview.canViewOrders ? 'View Orders ›' : null,
          subtitleColor: TenantAdminColors.info,
          icon: Icons.shopping_cart_outlined,
          iconColor: const Color(0xFF16A34A),
          iconBg: const Color(0xFF16A34A).withValues(alpha: 0.1),
          isRestricted: !overview.canViewOrders,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.isRestricted,
  });

  final String title;
  final String value;
  final String? subtitle;
  final Color subtitleColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool isRestricted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TenantAdminColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: TenantAdminColors.mutedText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Value
          if (isRestricted)
            const Tooltip(
              message: 'Restricted',
              child: Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 14, color: TenantAdminColors.mutedText),
                  SizedBox(width: 4),
                  Text(
                    'Restricted',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: TenantAdminColors.mutedText,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: TenantAdminColors.bodyText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          if (subtitle != null && !isRestricted) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: subtitleColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Operational alert banner ──────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.overview});
  final TenantAdminOutletOverview overview;

  @override
  Widget build(BuildContext context) {
    // Use first alert message if available, else generic
    final firstAlert =
        overview.alerts.isNotEmpty ? overview.alerts.first : null;
    final message = firstAlert?.title ??
        '${overview.totalActiveAlertCount} active alert(s)';
    final activityText =
        firstAlert != null ? _formatTime(firstAlert.occurredAt) : null;

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        border: Border.all(color: const Color(0xFFFED7AA), width: 1),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFF59E0B),
            size: 20,
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                  ),
                ),
                if (activityText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    activityText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF92400E),
              side: const BorderSide(color: Color(0xFFF59E0B)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return 'Since ${diff.inMinutes}m ago · Last activity';
    }
    return 'Since ${dt.hour}:${dt.minute.toString().padLeft(2, '0')} AM · Last activity';
  }
}
