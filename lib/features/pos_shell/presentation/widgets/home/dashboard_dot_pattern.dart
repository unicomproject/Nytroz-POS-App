import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class DashboardDotPattern extends StatelessWidget {
  const DashboardDotPattern({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: 38,
        height: 38,
        child: CustomPaint(painter: _DotPainter()),
      );
}

class _DotPainter extends CustomPainter {
  const _DotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = TenantAdminColors.posHomeDot;
    const positions = <Offset>[
      Offset(4, 4),
      Offset(14, 4),
      Offset(24, 4),
      Offset(34, 4),
      Offset(4, 14),
      Offset(14, 14),
      Offset(24, 14),
      Offset(34, 14),
      Offset(4, 24),
      Offset(14, 24),
      Offset(24, 24),
      Offset(34, 24),
      Offset(4, 34),
    ];
    for (final position in positions) {
      canvas.drawCircle(position, 2.25, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
