import 'package:flutter/material.dart';
import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../data/models/inventory_dashboard_models.dart';

class InventoryActivitiesTable extends StatelessWidget {
  const InventoryActivitiesTable({
    super.key,
    required this.activities,
  });

  final List<InventoryDashboardActivityItemDto> activities;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: Color(0xFF64748B), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Row(
                    children: [
                      Text(
                        'View All Activity',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right,
                          size: 16, color: Color(0xFF3B82F6)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.xxl),
              child: Center(
                child: Text('No activities found.',
                    style: (Theme.of(context).textTheme.bodyMedium ??
                            const TextStyle())
                        .copyWith(color: TenantAdminColors.mutedText)),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < activities.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _ActivityRow(activity: activities[i]),
                ]
              ],
            ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final InventoryDashboardActivityItemDto activity;

  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon
          _buildIcon(),
          const SizedBox(width: 16),

          // Activity Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  activity.activityType,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  activity.outletName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Date & Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatDate(activity.timestamp),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(activity.timestamp),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Chevron
          const Icon(Icons.chevron_right, size: 20, color: Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData = Icons.history;
    Color color = const Color(0xFF64748B);

    if (activity.activityType.toLowerCase().contains('opening')) {
      iconData = Icons.check_circle_outline;
      color = const Color(0xFF22C55E); // Green
    } else if (activity.activityType.toLowerCase().contains('adjust')) {
      iconData = Icons.tune_outlined;
      color = const Color(0xFF3B82F6); // Blue
    } else if (activity.activityType.toLowerCase().contains('count')) {
      iconData = Icons.assignment_outlined;
      color = const Color(0xFFF97316); // Orange
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Icon(iconData, color: color, size: 22),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour =
        date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
  }
}
