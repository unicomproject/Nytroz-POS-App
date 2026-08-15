import 'package:flutter/material.dart';

import '../../../../../shared/pos_session/pos_session_context.dart';
import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/pos_cash_payment_success_provider.dart';
import '../../utils/receipt_cashier_display.dart';

class ThermalReceiptPreview extends StatelessWidget {
  const ThermalReceiptPreview({
    super.key,
    required this.successData,
    required this.cashierName,
    required this.sessionContext,
  });

  final PosCashPaymentSuccessData successData;
  final String cashierName;
  final PosSessionContext sessionContext;

  @override
  Widget build(BuildContext context) {
    final outletName = _cleanPending(sessionContext.outletName);
    final outletLocation = _cleanPending(sessionContext.outletLocation);
    final terminal = _cleanPending(sessionContext.tillName);
    final resolvedCashierName = resolveReceiptCashierDisplayName(
      receiptDataJson: successData.receiptDataJson,
      paymentCashierName: successData.cashierName,
      sessionDisplayName: cashierName,
    );

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
                    businessName: sessionContext.brandName,
                    subtitle: sessionContext.brandSubtitle,
                    outletName: outletName,
                    outletLocation: outletLocation,
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  const _DashedDivider(),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _ReceiptInfoSection(
                    receiptNumber: successData.receiptNumber,
                    completedAt: successData.completedAt,
                    cashierName: resolvedCashierName,
                    customerName: successData.customerName,
                    terminal: terminal,
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  const _DashedDivider(),
                  const SizedBox(height: TenantAdminSpacing.md),
                  const _ItemTableHeader(),
                  const SizedBox(height: TenantAdminSpacing.sm),
                  for (final item in successData.items) ...[
                    _ItemTableRow(item: item),
                    const SizedBox(height: TenantAdminSpacing.sm),
                  ],
                  const _DashedDivider(),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _SummarySection(successData: successData),
                  const SizedBox(height: TenantAdminSpacing.md),
                  const _DashedDivider(),
                  const SizedBox(height: TenantAdminSpacing.md),
                  const _ReceiptFooter(),
                  const SizedBox(height: TenantAdminSpacing.md),
                  _ReceiptBarcode(value: successData.barcodeValue),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _cleanPending(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty ||
        trimmed.toLowerCase().contains('pending') ||
        trimmed.toLowerCase().contains('unpaired')) {
      return null;
    }

    return trimmed;
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
        Text(
          businessName,
          textAlign: TextAlign.center,
          style: titleStyle,
        ),
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
          Text(
            outletLocation!,
            textAlign: TextAlign.center,
            style: mutedStyle,
          ),
        ],
      ],
    );
  }
}

class _ReceiptInfoSection extends StatelessWidget {
  const _ReceiptInfoSection({
    required this.receiptNumber,
    required this.completedAt,
    required this.cashierName,
    this.customerName,
    this.terminal,
  });

  final String receiptNumber;
  final DateTime completedAt;
  final String cashierName;
  final String? customerName;
  final String? terminal;

  @override
  Widget build(BuildContext context) {
    final customerDisplay = customerName?.trim().isNotEmpty == true
        ? customerName!.trim()
        : 'Walk-in Customer';

    return Column(
      children: [
        _InfoLine(label: 'Receipt No', value: receiptNumber),
        _InfoLine(
          label: 'Date & Time',
          value: formatReceiptDateTime(completedAt),
        ),
        _InfoLine(label: 'Cashier', value: cashierName),
        _InfoLine(label: 'Customer', value: customerDisplay),
        if (terminal != null) _InfoLine(label: 'Terminal', value: terminal!),
        const _InfoLine(label: 'Payment', value: 'Cash'),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

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
  const _ItemTableRow({required this.item});

  final PosCashPaymentSuccessLineItem item;

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
                _amount(item.unitPrice),
                textAlign: TextAlign.end,
                style: itemStyle,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _amount(item.lineTotal),
                textAlign: TextAlign.end,
                style: itemStyle,
              ),
            ),
          ],
        ),
        if (item.variantSummary != null && item.variantSummary!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(item.variantSummary!, style: metaStyle),
          ),
      ],
    );
  }

  String _amount(int value) => formatLkr(value).replaceFirst('LKR ', '');
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.successData});

  final PosCashPaymentSuccessData successData;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TotalLine(label: 'No. of Items', value: '${successData.itemCount}'),
        _TotalLine(label: 'Subtotal', value: formatLkr(successData.subtotal)),
        if (successData.discount > 0)
          _TotalLine(
            label: 'Discount',
            value: '- ${formatLkr(successData.discount)}',
          ),
        if (successData.tax > 0)
          _TotalLine(label: 'Tax', value: formatLkr(successData.tax)),
        const SizedBox(height: TenantAdminSpacing.xs),
        _TotalLine(
          label: 'Total',
          value: formatLkr(successData.total),
          emphasized: true,
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        _TotalLine(
          label: 'Paid by Cash',
          value: formatLkr(successData.cashReceived),
        ),
        _TotalLine(
          label: 'Change Due',
          value: formatLkr(successData.changeDue),
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
  const _ReceiptFooter();

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
        Text(
          'Thank you for your purchase',
          textAlign: TextAlign.center,
          style: bodyStyle,
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          'Goods once sold can be exchanged with the original receipt.',
          textAlign: TextAlign.center,
          style: mutedStyle,
        ),
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
