import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class DashboardDotPattern extends StatelessWidget {
  const DashboardDotPattern({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 34,
        height: 34,
        child: CustomPaint(painter: _DotPainter()),
      );
}

class _DotPainter extends CustomPainter {
  const _DotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = TenantAdminColors.posHomeDot;
    for (var row = 0; row < 4; row++) {
      for (var column = 0; column < 4; column++) {
        canvas.drawCircle(
          Offset(column * 9 + 3, row * 9 + 3),
          1.8,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
