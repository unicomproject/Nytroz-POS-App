import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/tenant_dashboard.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';

class SalesThisWeekCard extends StatelessWidget {
  const SalesThisWeekCard({
    super.key,
    required this.salesSummary,
    this.showTrend = true,
    this.showReportsLink = false,
  });

  final TenantDashboardSalesSummary? salesSummary;
  final bool showTrend;
  final bool showReportsLink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  salesSummary?.title ?? 'Sales this week',
                  style: TenantAdminTextStyles.sectionTitle(context),
                ),
              ),
              if (showReportsLink)
                TextButton(
                  onPressed: () => context.go('/tenant-admin/reports/sales'),
                  child: const Text('View report'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (salesSummary == null || salesSummary!.points.isEmpty)
            const TenantAdminEmptyState(
              title: 'No sales data',
              message: 'Sales data will appear here when available.',
            )
          else ...[
            Text(
              'Total sales',
              style: TenantAdminTextStyles.muted(context).copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              salesSummary!.total,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            if (showTrend &&
                salesSummary!.subtitle != null &&
                salesSummary!.subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                salesSummary!.subtitle!,
                style: const TextStyle(
                  color: TenantAdminColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _SimpleLineChart(points: salesSummary!.points),
          ],
        ],
      ),
    );
  }
}

class _SimpleLineChart extends StatelessWidget {
  const _SimpleLineChart({
    required this.points,
  });

  final List<TenantDashboardChartPoint> points;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                const SizedBox(
                  width: 30,
                  child: _YAxisLabels(),
                ),
                Expanded(
                  child: CustomPaint(
                    painter: _LineChartPainter(points),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Row(
            children: [
              const SizedBox(width: 30),
              for (final point in points)
                Expanded(
                  child: Text(
                    point.label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TenantAdminColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _YAxisLabels extends StatelessWidget {
  const _YAxisLabels();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('£4K', style: _axisStyle),
        Text('£3K', style: _axisStyle),
        Text('£2K', style: _axisStyle),
        Text('£1K', style: _axisStyle),
        Text('£0', style: _axisStyle),
      ],
    );
  }
}

const _axisStyle = TextStyle(
  color: TenantAdminColors.mutedText,
  fontSize: 10,
  fontWeight: FontWeight.w600,
);

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter(this.points);

  final List<TenantDashboardChartPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = TenantAdminColors.border.withValues(alpha: 0.75)
      ..strokeWidth = 1;
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x334F46E5),
          Color(0x004F46E5),
        ],
      ).createShader(Offset.zero & size);
    final linePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = const Color(0xFF2563EB);
    final dotInnerPaint = Paint()..color = TenantAdminColors.surface;

    for (var index = 0; index < 5; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) {
      return;
    }

    var maxValue = points.first.value;
    for (final point in points) {
      if (point.value > maxValue) {
        maxValue = point.value;
      }
    }

    final safeMax = maxValue <= 0 ? 1 : maxValue;
    final xGap = points.length == 1 ? 0.0 : size.width / (points.length - 1);
    final offsets = <Offset>[
      for (var index = 0; index < points.length; index++)
        Offset(
          points.length == 1 ? size.width / 2 : xGap * index,
          size.height - ((points[index].value / safeMax) * size.height),
        ),
    ];

    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var index = 1; index < offsets.length; index++) {
      final previous = offsets[index - 1];
      final current = offsets[index];
      final controlX = previous.dx + (current.dx - previous.dx) / 2;
      path.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final fillPath = Path.from(path)
      ..lineTo(offsets.last.dx, size.height)
      ..lineTo(offsets.first.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (final offset in offsets) {
      canvas.drawCircle(offset, 4, dotPaint);
      canvas.drawCircle(offset, 2, dotInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
