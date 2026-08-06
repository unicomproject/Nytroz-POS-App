import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/esc_pos/esc_pos_receipt_generator.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/completed_sale_receipt.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/pos_device_printer_config.dart';

void main() {
  const feed = <int>[0x1B, 0x64, 0x05];
  const cut = <int>[0x1D, 0x56, 0x00];
  const generator = EscPosReceiptGenerator();

  test('original and reprint end with content, feed, then cut', () {
    final original = generator.generateCompletedSale(
      receipt: _receipt(const ['Thank you']),
      config: _config(),
    );
    final reprint = generator.generateCompletedSale(
      receipt: _receipt(const [
        'REPRINT',
        'Original receipt: RCPT-42',
        'Copy time: 2026-07-28T12:00:00',
      ]),
      config: _config(),
    );

    _expectSafeEnding(original, 'Thank you\n', feed, cut);
    _expectSafeEnding(reprint, 'Copy time: 2026-07-28T12:00:00\n', feed, cut);
    expect(original.sublist(original.length - 6),
        reprint.sublist(reprint.length - 6));
  });

  test('auto-cut disabled keeps feed and emits no cut', () {
    final bytes = generator.generateCompletedSale(
      receipt: _receipt(const ['Thank you']),
      config: _config(autoCut: false),
    );

    expect(bytes.sublist(bytes.length - 3), feed);
    expect(_indexOf(bytes, cut), -1);
  });

  test('58mm keeps the same safe ending sequence', () {
    final bytes = generator.generateCompletedSale(
      receipt: _receipt(const ['Thank you']),
      config: _config(width: PrinterPaperWidth.mm58),
    );

    _expectSafeEnding(bytes, 'Thank you\n', feed, cut);
  });

  test('completed sale emits Code39 barcode before footer feed and cut', () {
    final bytes = generator.generateCompletedSale(
      receipt: _receipt(const ['Thank you']),
      config: _config(),
    );
    const barcodeCommand = <int>[0x1D, 0x6B, 0x04];
    final barcodeIndex = _indexOf(bytes, barcodeCommand);
    final barcodeData = latin1.encode('RCPT-42');
    final barcodeDataIndex = barcodeIndex + barcodeCommand.length;
    final footerIndex = _indexOf(bytes, latin1.encode('Thank you\n'));
    final feedIndex = _indexOf(bytes, feed);
    final cutIndex = _indexOf(bytes, cut);

    expect(barcodeIndex, greaterThanOrEqualTo(0));
    expect(
      bytes.sublist(barcodeDataIndex, barcodeDataIndex + barcodeData.length),
      barcodeData,
    );
    expect(barcodeDataIndex, lessThan(footerIndex));
    expect(footerIndex, lessThan(feedIndex));
    expect(feedIndex, lessThan(cutIndex));
  });
}

void _expectSafeEnding(
  List<int> bytes,
  String finalText,
  List<int> feed,
  List<int> cut,
) {
  final textIndex = _indexOf(bytes, latin1.encode(finalText));
  final feedIndex = _indexOf(bytes, feed);
  final cutIndex = _indexOf(bytes, cut);
  expect(textIndex, greaterThanOrEqualTo(0));
  expect(textIndex, lessThan(feedIndex));
  expect(feedIndex, lessThan(cutIndex));
  expect(cutIndex, bytes.length - cut.length);
}

int _indexOf(List<int> source, List<int> pattern) {
  for (var index = 0; index <= source.length - pattern.length; index++) {
    var matches = true;
    for (var offset = 0; offset < pattern.length; offset++) {
      if (source[index + offset] != pattern[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) return index;
  }
  return -1;
}

PosDevicePrinterConfig _config({
  bool autoCut = true,
  PrinterPaperWidth width = PrinterPaperWidth.mm80,
}) =>
    PosDevicePrinterConfig(
      deviceId: 'device-1',
      enabled: true,
      connectionType: PrinterConnectionType.network,
      displayName: 'POS80',
      paperWidth: width,
      autoCutEnabled: autoCut,
      feedLinesBeforeCut: 5,
    );

CompletedSaleReceipt _receipt(List<String> footer) => CompletedSaleReceipt(
      receiptId: 'receipt-1',
      saleId: 'sale-1',
      receiptNumber: 'RCPT-42',
      completedAt: DateTime.utc(2026, 7, 28, 6, 30),
      merchantName: 'OneVerz POS',
      outletName: 'Main Outlet',
      tillId: 'till-1',
      tillName: 'Till 01',
      cashierId: 'cashier-1',
      cashierName: 'Cashier',
      deviceId: 'device-1',
      currency: 'LKR',
      items: const [
        CompletedSaleReceiptLine(
          name: 'Tea',
          quantity: 2,
          unitPrice: 125,
          lineTotal: 250,
        ),
      ],
      subtotal: 250,
      discountTotal: 0,
      taxTotal: 0,
      total: 250,
      paymentMethods: const ['CASH'],
      amountTendered: 300,
      change: 50,
      barcodeValue: 'RCPT-42',
      footerLines: footer,
    );
