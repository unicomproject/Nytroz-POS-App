import 'package:flutter/material.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';

class SimpleDonutChart extends StatelessWidget {
  const SimpleDonutChart({
    super.key,
    required this.segments,
    this.size = 168,
    this.strokeWidth = 22,
  });

  final List<SimpleDonutSegment> segments;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: Text(
            'No data',
            style: TextStyle(
              color: TenantAdminColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutChartPainter(
          segments: segments,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class SimpleDonutSegment {
  const SimpleDonutSegment({
    required this.value,
    required this.color,
    required this.label,
  });

  final double value;
  final Color color;
  final String label;
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({
    required this.segments,
    required this.strokeWidth,
  });

  final List<SimpleDonutSegment> segments;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - strokeWidth) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final total = segments.fold<double>(
      0,
      (sum, segment) => sum + segment.value,
    );
    final safeTotal = total <= 0 ? 1 : total;

    var startAngle = -90 * (3.141592653589793 / 180);

    for (final segment in segments) {
      final sweepAngle = (segment.value / safeTotal) * 2 * 3.141592653589793;
      paint.color = segment.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
