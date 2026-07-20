import 'dart:convert';

import '../../../returns_refunds/domain/entities/return_receipt.dart';
import '../models/pos_device_printer_config.dart';

/// Formats authoritative Completion GET values into ESC/POS bytes.
/// Does not recalculate financial totals.
class EscPosReceiptGenerator {
  const EscPosReceiptGenerator();

  static final List<int> _init = [0x1B, 0x40];
  static final List<int> _alignCenter = [0x1B, 0x61, 0x01];
  static final List<int> _alignLeft = [0x1B, 0x61, 0x00];
  static final List<int> _boldOn = [0x1B, 0x45, 0x01];
  static final List<int> _boldOff = [0x1B, 0x45, 0x00];
  static final List<int> _cut = [0x1D, 0x56, 0x00];
  static final List<int> _feed = [0x0A];

  List<int> generate({
    required ReturnReceipt receipt,
    required PosDevicePrinterConfig config,
  }) {
    final width = config.paperWidth == PrinterPaperWidth.mm58 ? 32 : 48;
    final out = <int>[..._init, ..._alignCenter, ..._boldOn];
    _writeLine(out, receipt.outletName?.trim().isNotEmpty == true
        ? receipt.outletName!.trim()
        : 'Store');
    out.addAll(_boldOff);
    _writeLine(out, receipt.receiptType?.trim().isNotEmpty == true
        ? receipt.receiptType!.trim()
        : (receipt.isExchange ? 'EXCHANGE' : 'REFUND'));
    out.addAll(_alignLeft);
    _writeLine(out, _divider(width));
    _writeLine(out, 'Receipt: ${receipt.receiptNumber}');
    if (receipt.returnNumber?.trim().isNotEmpty == true) {
      _writeLine(out, 'Return: ${receipt.returnNumber}');
    }
    if (receipt.exchangeNumber?.trim().isNotEmpty == true) {
      _writeLine(out, 'Exchange: ${receipt.exchangeNumber}');
    }
    if (receipt.originalInvoiceNo.trim().isNotEmpty) {
      _writeLine(out, 'Original: ${receipt.originalInvoiceNo}');
    }
    if (receipt.originalSaleNumber?.trim().isNotEmpty == true) {
      _writeLine(out, 'Sale: ${receipt.originalSaleNumber}');
    }
    if (receipt.completedAt != null) {
      _writeLine(out, 'Completed: ${receipt.completedAt}');
    }
    final cashier =
        (receipt.processedByName ?? receipt.cashierName).trim();
    if (cashier.isNotEmpty) {
      _writeLine(out, 'Cashier: $cashier');
    }
    if (receipt.tillName.trim().isNotEmpty) {
      _writeLine(out, 'Till: ${receipt.tillName}');
    }
    _writeLine(out, _divider(width));

    if (receipt.returnedItems.isNotEmpty) {
      _writeLine(out, 'Returned items');
      for (final item in receipt.returnedItems) {
        _writeWrapped(out, item.name, width);
        final qtyPrice =
            '${_fmtQty(item.quantity)} x ${_money(receipt.currency, item.unitPrice)}';
        _writeColumns(
          out,
          qtyPrice,
          _money(receipt.currency, item.total ?? item.lineAmount),
          width,
        );
        if (item.discount != null && item.discount! > 0) {
          _writeColumns(
            out,
            '  Discount',
            '-${_money(receipt.currency, item.discount!)}',
            width,
          );
        }
        if (item.tax != null && item.tax! > 0) {
          _writeColumns(
            out,
            '  Tax',
            _money(receipt.currency, item.tax!),
            width,
          );
        }
        final reason = item.reasonDisplay ?? item.reasonCode;
        if (reason != null && reason.trim().isNotEmpty) {
          _writeLine(out, '  Reason: ${reason.trim()}');
        }
        final condition = item.conditionDisplay ?? item.conditionCode;
        if (condition != null && condition.trim().isNotEmpty) {
          _writeLine(out, '  Condition: ${condition.trim()}');
        }
      }
      _writeLine(out, _divider(width));
    }

    if (receipt.isExchange && receipt.replacementItems.isNotEmpty) {
      _writeLine(out, 'Replacement items');
      for (final item in receipt.replacementItems) {
        _writeWrapped(out, item.name, width);
        final qtyPrice =
            '${_fmtQty(item.quantity)} x ${_money(receipt.currency, item.unitPrice)}';
        _writeColumns(
          out,
          qtyPrice,
          _money(receipt.currency, item.total ?? item.lineAmount),
          width,
        );
        if (item.discount != null && item.discount! > 0) {
          _writeColumns(
            out,
            '  Discount',
            '-${_money(receipt.currency, item.discount!)}',
            width,
          );
        }
        if (item.tax != null && item.tax! > 0) {
          _writeColumns(
            out,
            '  Tax',
            _money(receipt.currency, item.tax!),
            width,
          );
        }
      }
      _writeLine(out, _divider(width));
    }

    if (receipt.returnSubtotal != null) {
      _writeColumns(
        out,
        'Return subtotal',
        _money(receipt.currency, receipt.returnSubtotal!),
        width,
      );
    }
    if (receipt.returnDiscount != null && receipt.returnDiscount! > 0) {
      _writeColumns(
        out,
        'Return discount',
        '-${_money(receipt.currency, receipt.returnDiscount!)}',
        width,
      );
    }
    if (receipt.returnTax != null) {
      _writeColumns(
        out,
        'Return tax',
        _money(receipt.currency, receipt.returnTax!),
        width,
      );
    }
    if (receipt.returnTotal != null) {
      _writeColumns(
        out,
        'Return total',
        _money(receipt.currency, receipt.returnTotal!),
        width,
      );
    }

    if (receipt.isExchange) {
      if (receipt.replacementSubtotal != null) {
        _writeColumns(
          out,
          'Replacement subtotal',
          _money(receipt.currency, receipt.replacementSubtotal!),
          width,
        );
      }
      if (receipt.replacementDiscount != null &&
          receipt.replacementDiscount! > 0) {
        _writeColumns(
          out,
          'Replacement discount',
          '-${_money(receipt.currency, receipt.replacementDiscount!)}',
          width,
        );
      }
      if (receipt.replacementTax != null) {
        _writeColumns(
          out,
          'Replacement tax',
          _money(receipt.currency, receipt.replacementTax!),
          width,
        );
      }
      if (receipt.replacementTotal != null) {
        _writeColumns(
          out,
          'Replacement total',
          _money(receipt.currency, receipt.replacementTotal!),
          width,
        );
      }
      if (receipt.differenceAmount != null) {
        _writeColumns(
          out,
          'Difference',
          _money(receipt.currency, receipt.differenceAmount!.abs()),
          width,
        );
      }
      final direction = receipt.differenceDirection?.trim();
      if (direction != null && direction.isNotEmpty) {
        _writeLine(out, 'Direction: $direction');
      }
    }

    _writeLine(out, _divider(width));
    _writeLine(out, 'Settlement: ${receipt.settlementMethodLabel}');
    if (!receipt.isCashSettlement &&
        receipt.maskedCard?.trim().isNotEmpty == true) {
      final brand = receipt.cardBrand?.trim();
      _writeLine(
        out,
        brand == null || brand.isEmpty
            ? 'Card: ${receipt.maskedCard}'
            : 'Card: $brand ${receipt.maskedCard}',
      );
    }
    if (receipt.providerTransactionReference?.trim().isNotEmpty == true) {
      _writeLine(out, 'Ref: ${receipt.providerTransactionReference}');
    }

    if (receipt.isExchange) {
      if (!receipt.isEvenExchange) {
        if ((receipt.amountPaidByCustomer ?? 0) > 0) {
          _writeColumns(
            out,
            'Customer paid',
            _money(receipt.currency, receipt.amountPaidByCustomer!),
            width,
          );
        }
        if ((receipt.amountRefundedToCustomer ?? 0) > 0) {
          _writeColumns(
            out,
            'Customer refunded',
            _money(receipt.currency, receipt.amountRefundedToCustomer!),
            width,
          );
        }
      } else {
        _writeLine(out, 'No Settlement');
      }
    } else {
      _writeColumns(
        out,
        'Total refund',
        _money(
          receipt.currency,
          receipt.returnTotal ?? receipt.refundAmount,
        ),
        width,
      );
    }

    final customer =
        (receipt.customerDisplayName ?? receipt.customerName).trim();
    if (customer.isNotEmpty) {
      _writeLine(out, 'Customer: $customer');
    }

    out.addAll(_feed);
    out.addAll(_alignCenter);
    _writeLine(out, 'Thank you');
    out.addAll(_feed);
    out.addAll(_feed);
    if (config.autoCutEnabled) {
      out.addAll(_cut);
    }
    return out;
  }

  void _writeLine(List<int> out, String text) {
    out.addAll(_encode(text));
    out.addAll(_feed);
  }

  void _writeWrapped(List<int> out, String text, int width) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) {
      return;
    }
    if (cleaned.length <= width) {
      _writeLine(out, cleaned);
      return;
    }
    for (var i = 0; i < cleaned.length; i += width) {
      final end = (i + width < cleaned.length) ? i + width : cleaned.length;
      _writeLine(out, cleaned.substring(i, end));
    }
  }

  void _writeColumns(
    List<int> out,
    String left,
    String right,
    int width,
  ) {
    final gap = width - left.length - right.length;
    if (gap <= 0) {
      _writeLine(out, left);
      _writeLine(out, right.padLeft(width));
      return;
    }
    _writeLine(out, '$left${' ' * gap}$right');
  }

  List<int> _encode(String text) {
    // Prefer ASCII/Latin-1 for ESC/POS. Non-Latin (e.g. Tamil) characters that
    // cannot be encoded are replaced so printers without Unicode glyphs do not
    // receive invalid bytes. Full Tamil requires rasterization or a code page
    // verified against the attached printer profile.
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      if (rune <= 0xFF) {
        buffer.writeCharCode(rune);
      } else {
        buffer.write('?');
      }
    }
    return latin1.encode(buffer.toString());
  }

  String _divider(int width) => '-' * width;

  String _fmtQty(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toStringAsFixed(0);
    }
    return qty.toStringAsFixed(2);
  }

  String _money(String currency, double amount) {
    final code = currency.trim().isEmpty ? '' : '${currency.trim()} ';
    return '$code${amount.toStringAsFixed(2)}';
  }
}
