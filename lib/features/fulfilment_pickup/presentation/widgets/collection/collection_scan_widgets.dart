import 'package:flutter/material.dart';

import '../online_order_ui.dart';

class CollectionScannerPanel extends StatelessWidget {
  const CollectionScannerPanel({
    required this.onTapFocus,
    this.isValidating = false,
    super.key,
  });

  final VoidCallback onTapFocus;
  final bool isValidating;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isValidating ? null : onTapFocus,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 320),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: CustomPaint(
            painter: _CornerBracketPainter(color: scheme.primary),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 72,
                    color: scheme.primary.withValues(alpha: 0.9),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isValidating ? 'Validating…' : 'Ready to scan',
                    style: OnlineOrderUi.title.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isValidating
                        ? 'Checking the collection QR'
                        : 'Scan customer QR',
                    style: OnlineOrderUi.subtitle,
                  ),
                  if (!isValidating) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Tap to focus for HID scanner',
                      style: OnlineOrderUi.subtitle.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  _CornerBracketPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const inset = 18.0;
    const arm = 36.0;
    final corners = [
      (
        Offset(inset, inset),
        Offset(inset + arm, inset),
        Offset(inset, inset + arm)
      ),
      (
        Offset(size.width - inset, inset),
        Offset(size.width - inset - arm, inset),
        Offset(size.width - inset, inset + arm)
      ),
      (
        Offset(inset, size.height - inset),
        Offset(inset + arm, size.height - inset),
        Offset(inset, size.height - inset - arm)
      ),
      (
        Offset(size.width - inset, size.height - inset),
        Offset(size.width - inset - arm, size.height - inset),
        Offset(size.width - inset, size.height - inset - arm)
      ),
    ];
    for (final c in corners) {
      canvas.drawLine(c.$1, c.$2, paint);
      canvas.drawLine(c.$1, c.$3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) =>
      oldDelegate.color != color;
}

class CollectionSidebarCards extends StatelessWidget {
  const CollectionSidebarCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _InfoCard(
          icon: Icons.route_outlined,
          title: 'How it works',
          body:
              'Scan the customer collection QR, verify packed items, take any outstanding payment, then confirm handover.',
        ),
        SizedBox(height: 12),
        _InfoCard(
          icon: Icons.lightbulb_outline,
          title: 'Tips',
          body:
              'Keep the HID scanner focused on this screen. Prefer the customer QR over typing an order number.',
        ),
        SizedBox(height: 12),
        _InfoCard(
          icon: Icons.verified_user_outlined,
          title: 'Secure Collection',
          body:
              'Each QR is unique to one collection. Validation never marks the order collected.',
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: OnlineOrderUi.ink,
                      )),
                  const SizedBox(height: 6),
                  Text(body, style: OnlineOrderUi.subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
