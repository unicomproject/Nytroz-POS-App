import 'package:flutter/material.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../domain/entities/pos_receipt_snapshot.dart';
import 'receipt_branding_section.dart';
import 'receipt_footer_section.dart';
import 'receipt_identity_section.dart';
import 'receipt_items_section.dart';
import 'receipt_tenders_section.dart';
import 'receipt_totals_section.dart';

class PaymentSuccessReceiptPreview extends StatelessWidget {
  const PaymentSuccessReceiptPreview({
    super.key,
    required this.snapshot,
  });

  final PosReceiptSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    if (snapshot == null) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          border: Border.all(color: TenantAdminColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Receipt Preview Unavailable',
            style: TextStyle(
              color: TenantAdminColors.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border.all(color: TenantAdminColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Simulated jagged edge top
          _buildJaggedEdge(isTop: true),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.xl,
              vertical: TenantAdminSpacing.lg,
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                color: Colors.black,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ReceiptBrandingSection(branding: snapshot!.branding),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _buildDivider(),
                  const SizedBox(height: TenantAdminSpacing.sm),
                  ReceiptIdentitySection(
                    identity: snapshot!.receiptIdentity,
                    operatorDetails: snapshot!.operatorDetails,
                  ),
                  const SizedBox(height: TenantAdminSpacing.sm),
                  _buildDivider(),
                  const SizedBox(height: TenantAdminSpacing.md),
                  ReceiptItemsSection(items: snapshot!.items),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _buildDivider(),
                  const SizedBox(height: TenantAdminSpacing.sm),
                  ReceiptTotalsSection(totals: snapshot!.totals),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _buildDivider(),
                  const SizedBox(height: TenantAdminSpacing.md),
                  ReceiptTendersSection(tenders: snapshot!.tenders),
                  if (snapshot!.presentation.barcodeVisibility ||
                      snapshot!.presentation.qrVisibility ||
                      snapshot!.presentation.footerMessage != null) ...[
                    const SizedBox(height: TenantAdminSpacing.lg),
                    _buildDivider(),
                    const SizedBox(height: TenantAdminSpacing.md),
                    ReceiptFooterSection(presentation: snapshot!.presentation),
                  ],
                ],
              ),
            ),
          ),
          // Simulated jagged edge bottom
          _buildJaggedEdge(isTop: false),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const SizedBox(
      height: 1,
      child: CustomPaint(painter: _DashedDividerPainter()),
    );
  }

  Widget _buildJaggedEdge({required bool isTop}) {
    return SizedBox(
      height: 8,
      child: CustomPaint(
        painter: _JaggedEdgePainter(isTop: isTop),
      ),
    );
  }
}

class _DashedDividerPainter extends CustomPainter {
  const _DashedDividerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 1;
    const dashWidth = 4.0;
    const dashSpace = 3.0;

    for (double x = 0; x < size.width; x += dashWidth + dashSpace) {
      canvas.drawLine(
        Offset(x, 0.5),
        Offset((x + dashWidth).clamp(0, size.width), 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedDividerPainter oldDelegate) => false;
}

class _JaggedEdgePainter extends CustomPainter {
  const _JaggedEdgePainter({required this.isTop});

  final bool isTop;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    const double toothWidth = 8.0;
    final int teethCount = (size.width / toothWidth).ceil();

    if (isTop) {
      path.moveTo(0, size.height);
      for (int i = 0; i < teethCount; i++) {
        final x = i * toothWidth;
        path.lineTo(x + toothWidth / 2, 0);
        path.lineTo(x + toothWidth, size.height);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, 0);
      for (int i = 0; i < teethCount; i++) {
        final x = i * toothWidth;
        path.lineTo(x + toothWidth / 2, size.height);
        path.lineTo(x + toothWidth, 0);
      }
      path.lineTo(size.width, 0);
      path.lineTo(0, 0);
    }

    canvas.drawPath(path, paint);

    // Draw subtle border line to match the container's border
    final borderPaint = Paint()
      ..color = TenantAdminColors.border.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
