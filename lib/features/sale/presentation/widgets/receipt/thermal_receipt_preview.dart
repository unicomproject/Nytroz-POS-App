import 'package:flutter/material.dart';

import '../../../../../shared/pos_session/pos_session_context.dart';
import '../../../../hardware/receipt_printer/mappers/canonical_receipt_presentation_mapper.dart';
import '../../../../hardware/receipt_printer/models/canonical_receipt_presentation.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/pos_cash_payment_success_provider.dart';

/// Flutter renderer of [CanonicalReceiptPresentation].
///
/// Semantic content must match ESC/POS renderers; pixel parity is not required.
class ThermalReceiptPreview extends StatelessWidget {
  const ThermalReceiptPreview({
    super.key,
    required this.presentation,
  });

  factory ThermalReceiptPreview.fromPaymentSuccess({
    Key? key,
    required PosCashPaymentSuccessData successData,
    required String cashierName,
    required PosSessionContext sessionContext,
    String? outletTimezoneId,
  }) {
    return ThermalReceiptPreview(
      key: key,
      presentation: const CanonicalReceiptPresentationMapper().fromPaymentSuccess(
        success: successData,
        session: sessionContext,
        cashierFallback: cashierName,
        outletTimezoneId: outletTimezoneId,
      ),
    );
  }

  final CanonicalReceiptPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final p = presentation;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.lg,
              vertical: TenantAdminSpacing.xl,
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                color: TenantAdminColors.bodyText,
                fontFeatures: [FontFeature.tabularFigures()],
                letterSpacing: 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ReceiptHeader(
                    businessName: p.merchantName,
                    subtitle: p.brandSubtitle,
                    outletName: p.outletName.isEmpty ? null : p.outletName,
                    outletLocation:
                        p.outletLocation.isEmpty ? null : p.outletLocation,
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  const _DashedDivider(),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _ReceiptInfoSection(presentation: p),
                  const SizedBox(height: TenantAdminSpacing.md),
                  const _DashedDivider(),
                  const SizedBox(height: TenantAdminSpacing.md),
                  const _ItemTableHeader(),
                  const SizedBox(height: TenantAdminSpacing.sm),
                  for (final item in p.items) ...[
                    _ItemTableRow(item: item, presentation: p),
                    const SizedBox(height: TenantAdminSpacing.sm),
                  ],
                  const _DashedDivider(),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _SummarySection(presentation: p),
                  const SizedBox(height: TenantAdminSpacing.md),
                  const _DashedDivider(),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _ReceiptFooter(
                    thankYouText: p.thankYouText,
                    policyText: p.policyText,
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _ReceiptBarcode(value: p.barcodeValue),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptHeader extends StatelessWidget {
  const _ReceiptHeader({
    required this.businessName,
    required this.subtitle,
    this.outletName,
    this.outletLocation,
  });

  final String businessName;
  final String subtitle;
  final String? outletName;
  final String? outletLocation;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: TenantAdminColors.bodyText,
          letterSpacing: 0,
        );
    final mutedStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: TenantAdminColors.mutedText,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        );

    return Column(
      children: [
        Text(businessName, textAlign: TextAlign.center, style: titleStyle),
        if (subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(subtitle, textAlign: TextAlign.center, style: mutedStyle),
        ],
        if (outletName != null) ...[
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(outletName!, textAlign: TextAlign.center, style: mutedStyle),
        ],
        if (outletLocation != null) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(outletLocation!, textAlign: TextAlign.center, style: mutedStyle),
        ],
      ],
    );
  }
}

class _ReceiptInfoSection extends StatelessWidget {
  const _ReceiptInfoSection({required this.presentation});

  final CanonicalReceiptPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final p = presentation;
    return Column(
      children: [
        _InfoLine(
          label: CanonicalReceiptPresentation.receiptNoLabel,
          value: p.receiptNumber,
        ),
        _InfoLine(
          label: CanonicalReceiptPresentation.dateTimeLabel,
          value: p.issuedAtDisplay,
        ),
        _InfoLine(label: 'Cashier', value: p.cashierName),
        _InfoLine(label: 'Customer', value: p.customerDisplayName),
        if (p.terminalName.isNotEmpty)
          _InfoLine(
            label: CanonicalReceiptPresentation.terminalFieldLabel,
            value: p.terminalName,
          ),
        _InfoLine(label: 'Payment', value: p.paymentMethodDisplay),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: TenantAdminColors.mutedText,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        );
    final valueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: TenantAdminColors.bodyText,
          letterSpacing: 0,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 94, child: Text(label, style: labelStyle)),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              softWrap: true,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTableHeader extends StatelessWidget {
  const _ItemTableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: TenantAdminColors.bodyText,
          letterSpacing: 0,
        );

    return Row(
      children: [
        Expanded(flex: 5, child: Text('ITEM', style: style)),
        Expanded(child: Text('QTY', textAlign: TextAlign.center, style: style)),
        Expanded(
          flex: 2,
          child: Text('VALUE', textAlign: TextAlign.end, style: style),
        ),
        Expanded(
          flex: 2,
          child: Text('RATE', textAlign: TextAlign.end, style: style),
        ),
      ],
    );
  }
}

class _ItemTableRow extends StatelessWidget {
  const _ItemTableRow({
    required this.item,
    required this.presentation,
  });

  final CanonicalReceiptItemPresentation item;
  final CanonicalReceiptPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final itemStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: TenantAdminColors.bodyText,
          letterSpacing: 0,
        );
    final metaStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: TenantAdminColors.mutedText,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: itemStyle,
              ),
            ),
            Expanded(
              child: Text(
                '${item.quantity}',
                textAlign: TextAlign.center,
                style: itemStyle,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                presentation.formatMoneyAmountOnly(item.valueUnitPrice),
                textAlign: TextAlign.end,
                style: itemStyle,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                presentation.formatMoneyAmountOnly(item.rateUnitPrice),
                textAlign: TextAlign.end,
                style: itemStyle,
              ),
            ),
          ],
        ),
        if (item.sku.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(item.sku, style: metaStyle),
          ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.presentation});

  final CanonicalReceiptPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final p = presentation;
    return Column(
      children: [
        _TotalLine(label: 'No. of Items', value: '${p.itemCount}'),
        _TotalLine(label: 'Subtotal', value: p.formatMoney(p.subtotal)),
        if (p.discountTotal > 0)
          _TotalLine(
            label: 'Discount',
            value: '- ${p.formatMoney(p.discountTotal)}',
          ),
        if (p.taxTotal > 0)
          _TotalLine(label: 'Tax', value: p.formatMoney(p.taxTotal)),
        const SizedBox(height: TenantAdminSpacing.xs),
        _TotalLine(
          label: 'Total',
          value: p.formatMoney(p.total),
          emphasized: true,
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        _TotalLine(label: p.paidByLabel, value: p.formatMoney(p.amountTendered)),
        _TotalLine(
          label: 'Change Due',
          value: p.formatMoney(p.changeDue),
        ),
      ],
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = (emphasized
            ? Theme.of(context).textTheme.titleSmall
            : Theme.of(context).textTheme.bodySmall)
        ?.copyWith(
      fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
      color: TenantAdminColors.bodyText,
      letterSpacing: 0,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _ReceiptFooter extends StatelessWidget {
  const _ReceiptFooter({
    required this.thankYouText,
    required this.policyText,
  });

  final String thankYouText;
  final String policyText;

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: TenantAdminColors.bodyText,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        );
    final mutedStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: TenantAdminColors.mutedText,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        );

    return Column(
      children: [
        Text(thankYouText, textAlign: TextAlign.center, style: bodyStyle),
        if (policyText.trim().isNotEmpty) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(policyText, textAlign: TextAlign.center, style: mutedStyle),
        ],
      ],
    );
  }
}

class _ReceiptBarcode extends StatelessWidget {
  const _ReceiptBarcode({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final normalized = _Code39BarcodePainter.normalize(value);
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: TenantAdminColors.bodyText,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        );

    return Column(
      children: [
        SizedBox(
          height: 58,
          width: double.infinity,
          child: CustomPaint(
            painter: _Code39BarcodePainter(normalized),
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(normalized, textAlign: TextAlign.center, style: labelStyle),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      child: CustomPaint(painter: _ThermalDashedDividerPainter()),
    );
  }
}

class _ThermalDashedDividerPainter extends CustomPainter {
  const _ThermalDashedDividerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TenantAdminColors.mutedText.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    const dashWidth = 5.0;
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
  bool shouldRepaint(covariant _ThermalDashedDividerPainter oldDelegate) =>
      false;
}

class _Code39BarcodePainter extends CustomPainter {
  const _Code39BarcodePainter(this.value);

  final String value;

  static const _patterns = <String, String>{
    '0': 'nnnwwnwnn',
    '1': 'wnnwnnnnw',
    '2': 'nnwwnnnnw',
    '3': 'wnwwnnnnn',
    '4': 'nnnwwnnnw',
    '5': 'wnnwwnnnn',
    '6': 'nnwwwnnnn',
    '7': 'nnnwnnwnw',
    '8': 'wnnwnnwnn',
    '9': 'nnwwnnwnn',
    'A': 'wnnnnwnnw',
    'B': 'nnwnnwnnw',
    'C': 'wnwnnwnnn',
    'D': 'nnnnwwnnw',
    'E': 'wnnnwwnnn',
    'F': 'nnwnwwnnn',
    'G': 'nnnnnwwnw',
    'H': 'wnnnnwwnn',
    'I': 'nnwnnwwnn',
    'J': 'nnnnwwwnn',
    'K': 'wnnnnnnww',
    'L': 'nnwnnnnww',
    'M': 'wnwnnnnwn',
    'N': 'nnnnwnnww',
    'O': 'wnnnwnnwn',
    'P': 'nnwnwnnwn',
    'Q': 'nnnnnnwww',
    'R': 'wnnnnnwwn',
    'S': 'nnwnnnwwn',
    'T': 'nnnnwnwwn',
    'U': 'wwnnnnnnw',
    'V': 'nwwnnnnnw',
    'W': 'wwwnnnnnn',
    'X': 'nwnnwnnnw',
    'Y': 'wwnnwnnnn',
    'Z': 'nwwnwnnnn',
    '-': 'nwnnnnwnw',
    '.': 'wwnnnnwnn',
    ' ': 'nwwnnnwnn',
    r'$': 'nwnwnwnnn',
    '/': 'nwnwnnnwn',
    '+': 'nwnnnwnwn',
    '%': 'nnnwnwnwn',
    '*': 'nwnnwnwnn',
  };

  static String normalize(String value) {
    final upper = value.trim().toUpperCase();
    final buffer = StringBuffer();

    for (final codeUnit in upper.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      if (_patterns.containsKey(char) && char != '*') {
        buffer.write(char);
      }
    }

    return buffer.isEmpty ? 'RECEIPT' : buffer.toString();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final encoded = '*${normalize(value)}*';
    final units = _measureUnits(encoded);
    final narrow = (size.width / units).clamp(1.0, 2.4);
    final barcodeWidth = units * narrow;
    final left = (size.width - barcodeWidth) / 2;
    final paint = Paint()..color = Colors.black;

    var x = left;
    for (final codeUnit in encoded.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      final pattern = _patterns[char]!;

      for (var index = 0; index < pattern.length; index += 1) {
        final width = pattern[index] == 'w' ? narrow * 3 : narrow;
        final isBar = index.isEven;
        if (isBar) {
          canvas.drawRect(
            Rect.fromLTWH(x, 0, width, size.height),
            paint,
          );
        }
        x += width;
      }

      x += narrow;
    }
  }

  double _measureUnits(String encoded) {
    var units = 0.0;
    for (final codeUnit in encoded.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      final pattern = _patterns[char]!;
      for (final codeUnit in pattern.codeUnits) {
        units += String.fromCharCode(codeUnit) == 'w' ? 3 : 1;
      }
      units += 1;
    }

    return units;
  }

  @override
  bool shouldRepaint(covariant _Code39BarcodePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
