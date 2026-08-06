import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/outlet.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';

class OutletOverviewCard extends StatelessWidget {
  const OutletOverviewCard({
    super.key,
    required this.summaryState,
  });

  final AsyncValue<OutletSummaryDashboard> summaryState;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TenantAdminSpacing.lg,
              TenantAdminSpacing.lg,
              TenantAdminSpacing.lg,
              TenantAdminSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Outlet Overview',
                    style: TenantAdminTextStyles.sectionTitle(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TenantAdminSpacing.md,
                    vertical: TenantAdminSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: TenantAdminColors.border),
                    borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'This Month',
                        style: TenantAdminTextStyles.muted(context).copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: TenantAdminColors.mutedText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TenantAdminSpacing.lg,
              0,
              TenantAdminSpacing.lg,
              TenantAdminSpacing.lg,
            ),
            child: summaryState.when(
              loading: () => const SizedBox(
                height: 160,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: TenantAdminColors.primary,
                  ),
                ),
              ),
              error: (err, stack) => const SizedBox(
                height: 160,
                child: TenantAdminErrorState(
                  title: 'Data unavailable',
                  message: 'Could not load overview data.',
                  onRetry: null,
                ),
              ),
              data: (summary) => _OverviewContent(summary: summary),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({required this.summary});

  final OutletSummaryDashboard summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.totalOutlets;
    final active = summary.activeOutlets;
    final attention = summary.needsAttention ?? 0;
    final inactive = (total - active - attention).clamp(0, total);

    final hasAttentionSupport = summary.needsAttention != null;

    final activePct = total == 0 ? 0.0 : (active / total) * 100;
    final attentionPct = total == 0 ? 0.0 : (attention / total) * 100;
    final inactivePct = total == 0 ? 0.0 : (inactive / total) * 100;

    return Row(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      active: active,
                      attention: hasAttentionSupport ? attention : 0,
                      inactive: inactive,
                      total: total,
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: TenantAdminColors.bodyText,
                                height: 1.1,
                              ),
                    ),
                    Text(
                      'Total',
                      style: TenantAdminTextStyles.muted(context).copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.xl),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LegendRow(
                color: TenantAdminColors.success,
                label: 'Active',
                count: active,
                percentage: activePct,
              ),
              if (hasAttentionSupport) ...[
                const SizedBox(height: TenantAdminSpacing.md),
                _LegendRow(
                  color: TenantAdminColors.warning,
                  label: 'Attention',
                  count: attention,
                  percentage: attentionPct,
                ),
              ],
              const SizedBox(height: TenantAdminSpacing.md),
              _LegendRow(
                color: TenantAdminColors.danger,
                label: 'Inactive',
                count: inactive,
                percentage: inactivePct,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.percentage,
  });

  final Color color;
  final String label;
  final int count;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Text(
          label,
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          '$count',
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        SizedBox(
          width: 48,
          child: Text(
            '(${percentage.toStringAsFixed(1)}%)',
            textAlign: TextAlign.right,
            style: TenantAdminTextStyles.muted(context).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  _DonutChartPainter({
    required this.active,
    required this.attention,
    required this.inactive,
    required this.total,
  });

  final int active;
  final int attention;
  final int inactive;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) {
      _drawEmpty(canvas, size);
      return;
    }

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const strokeWidth = 18.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -pi / 2; // Start at top

    void drawSegment(int count, Color color) {
      if (count <= 0) return;
      final sweepAngle = (count / total) * 2 * pi;
      paint.color = color;

      final gap = (active > 0 && (attention > 0 || inactive > 0)) ||
              (attention > 0 && inactive > 0)
          ? 0.05
          : 0.0;

      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle + (gap / 2),
        sweepAngle - gap,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }

    drawSegment(active, TenantAdminColors.success);
    drawSegment(attention, TenantAdminColors.warning);
    drawSegment(inactive, TenantAdminColors.danger);
  }

  void _drawEmpty(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..color = TenantAdminColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18.0;

    canvas.drawArc(
      rect.deflate(9.0),
      0,
      2 * pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.active != active ||
        oldDelegate.attention != attention ||
        oldDelegate.inactive != inactive ||
        oldDelegate.total != total;
  }
}
