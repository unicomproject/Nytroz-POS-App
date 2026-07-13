import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/product_dashboard.dart';
import 'product_dashboard_formatters.dart';

class ProductStockValueCard extends StatelessWidget {
  const ProductStockValueCard({
    super.key,
    required this.stockValue,
    this.currencyCode,
  });

  final ProductDashboardStockValue stockValue;
  final String? currencyCode;

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
          Text(
            'Stock Value',
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
          const SizedBox(height: 14),
          Text(
            'Current value',
            style: TenantAdminTextStyles.muted(context).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatProductDashboardCurrency(
              stockValue.currentValue,
              currencyCode: currencyCode,
            ),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w900,
                ),
          ),
          if (stockValue.changePercent != null) ...[
            const SizedBox(height: TenantAdminSpacing.xs),
            Builder(
              builder: (context) {
                final trend =
                    formatProductDashboardTrend(stockValue.changePercent);
                return Row(
                  children: [
                    if (trend.icon != null) ...[
                      Icon(
                        trend.icon,
                        size: 16,
                        color: (stockValue.changePercent ?? 0) >= 0
                            ? TenantAdminColors.success
                            : TenantAdminColors.danger,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        trend.label,
                        style: TextStyle(
                          color: (stockValue.changePercent ?? 0) >= 0
                              ? TenantAdminColors.success
                              : TenantAdminColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          if (stockValue.trend.isEmpty)
            const TenantAdminEmptyState(
              title: 'No stock value data',
              message:
                  'No stock value data is available for this period.',
            )
          else
            _StockValueLineChart(
              points: stockValue.trend,
              currencyCode: currencyCode,
            ),
        ],
      ),
    );
  }
}

class _StockValueLineChart extends StatelessWidget {
  const _StockValueLineChart({
    required this.points,
    this.currencyCode,
  });

  final List<ProductDashboardTrendPoint> points;
  final String? currencyCode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  child: _YAxisLabels(points: points, currencyCode: currencyCode),
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
              const SizedBox(width: 42),
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
  const _YAxisLabels({
    required this.points,
    this.currencyCode,
  });

  final List<ProductDashboardTrendPoint> points;
  final String? currencyCode;

  @override
  Widget build(BuildContext context) {
    final maxValue = points.fold<double>(
      0,
      (max, point) => point.value > max ? point.value : max,
    );
    final safeMax = maxValue <= 0 ? 1 : maxValue;
    final labels = [
      for (var index = 4; index >= 0; index--)
        formatProductDashboardCurrency(
          safeMax * index / 4,
          currencyCode: currencyCode,
        ),
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final label in labels)
          Text(
            label,
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter(this.points);

  final List<ProductDashboardTrendPoint> points;

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
