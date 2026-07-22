import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_barcode_scanner_listener.dart';

void main() {
  Future<void> sendCharacters(
    WidgetTester tester,
    String value, {
    bool includeKeyUp = false,
  }) async {
    for (final rune in value.runes) {
      final character = String.fromCharCode(rune);
      final key = _keyFor(character);
      await simulateKeyDownEvent(key, character: character);
      if (includeKeyUp) {
        await simulateKeyUpEvent(key);
      }
    }
    await tester.pump();
  }

  Widget listener({
    required ValueChanged<String> onScanned,
    ValueChanged<String>? onRejected,
    bool enabled = true,
    int minimumLength = 4,
    Duration delay = const Duration(milliseconds: 120),
    Widget child = const SizedBox(),
  }) {
    return MaterialApp(
      home: PosBarcodeScannerListener(
        enabled: enabled,
        minimumBarcodeLength: minimumLength,
        maximumInterKeyDelay: delay,
        onBarcodeScanned: onScanned,
        onRejectedBarcode: onRejected,
        child: child,
      ),
    );
  }

  testWidgets('complete scan emits once on Enter', (tester) async {
    final scanned = <String>[];
    await tester.pumpWidget(listener(onScanned: scanned.add));

    await sendCharacters(tester, '82111001003');
    await simulateKeyDownEvent(LogicalKeyboardKey.enter);
    await simulateKeyUpEvent(LogicalKeyboardKey.enter);

    expect(scanned, ['82111001003']);
  });

  testWidgets('numpad Enter completes scan', (tester) async {
    final scanned = <String>[];
    await tester.pumpWidget(listener(onScanned: scanned.add));

    await sendCharacters(tester, '1234');
    await simulateKeyDownEvent(LogicalKeyboardKey.numpadEnter);

    expect(scanned, ['1234']);
  });

  testWidgets('leading zeroes are preserved and key-up is ignored',
      (tester) async {
    final scanned = <String>[];
    await tester.pumpWidget(listener(onScanned: scanned.add));

    await sendCharacters(tester, '001234', includeKeyUp: true);
    await simulateKeyDownEvent(LogicalKeyboardKey.enter);

    expect(scanned, ['001234']);
  });

  testWidgets('empty Enter is ignored and short barcode is rejected',
      (tester) async {
    final scanned = <String>[];
    final rejected = <String>[];
    await tester.pumpWidget(listener(
      onScanned: scanned.add,
      onRejected: rejected.add,
    ));

    await simulateKeyDownEvent(LogicalKeyboardKey.enter);
    await sendCharacters(tester, '123');
    await simulateKeyDownEvent(LogicalKeyboardKey.enter);

    expect(scanned, isEmpty);
    expect(rejected, ['123']);
  });

  testWidgets('inter-key timeout clears stale input', (tester) async {
    final scanned = <String>[];
    await tester.pumpWidget(listener(
      onScanned: scanned.add,
      minimumLength: 3,
      delay: const Duration(milliseconds: 50),
    ));

    await sendCharacters(tester, '123');
    await tester.pump(const Duration(milliseconds: 60));
    await sendCharacters(tester, '456');
    await simulateKeyDownEvent(LogicalKeyboardKey.enter);

    expect(scanned, ['456']);
  });

  testWidgets('non-printable keys are not buffered', (tester) async {
    final scanned = <String>[];
    await tester.pumpWidget(listener(
      onScanned: scanned.add,
      minimumLength: 1,
    ));

    await simulateKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await simulateKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await simulateKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await sendCharacters(tester, 'A');
    await simulateKeyDownEvent(LogicalKeyboardKey.enter);

    expect(scanned, ['A']);
  });

  testWidgets('disabled listener ignores scans', (tester) async {
    final scanned = <String>[];
    await tester.pumpWidget(listener(onScanned: scanned.add, enabled: false));

    await sendCharacters(tester, '1234');
    await simulateKeyDownEvent(LogicalKeyboardKey.enter);

    expect(scanned, isEmpty);
  });

  testWidgets('disabling clears partial buffer before re-enabling',
      (tester) async {
    final scanned = <String>[];
    await tester.pumpWidget(listener(onScanned: scanned.add));
    await sendCharacters(tester, '123');

    await tester.pumpWidget(listener(onScanned: scanned.add, enabled: false));
    await tester.pumpWidget(listener(onScanned: scanned.add));
    await simulateKeyDownEvent(LogicalKeyboardKey.enter);

    expect(scanned, isEmpty);
  });

  testWidgets('dispose removes handler and rebuild does not duplicate it',
      (tester) async {
    final scanned = <String>[];
    await tester.pumpWidget(listener(onScanned: scanned.add));
    await tester.pumpWidget(listener(
      onScanned: scanned.add,
      child: const ColoredBox(color: Colors.blue),
    ));
    await sendCharacters(tester, '1234');
    await simulateKeyDownEvent(LogicalKeyboardKey.enter);
    expect(scanned, ['1234']);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await sendCharacters(tester, '5678');
    await simulateKeyDownEvent(LogicalKeyboardKey.enter);
    expect(scanned, ['1234']);
  });

  testWidgets('capture works with search unfocused and focused',
      (tester) async {
    final scanned = <String>[];
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(listener(
      onScanned: scanned.add,
      child: Scaffold(body: TextField(focusNode: focusNode)),
    ));

    await sendCharacters(tester, '1234');
    await simulateKeyDownEvent(LogicalKeyboardKey.enter);
    focusNode.requestFocus();
    await tester.pump();
    await sendCharacters(tester, '5678');
    await simulateKeyDownEvent(LogicalKeyboardKey.enter);

    expect(scanned, ['1234', '5678']);
  });

  testWidgets('route-scoped listener disables for modal and re-enables after',
      (tester) async {
    final scanned = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        final enabled = ModalRoute.of(context)?.isCurrent ?? true;
        return PosBarcodeScannerListener(
          enabled: enabled,
          onBarcodeScanned: scanned.add,
          child: Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const AlertDialog(title: Text('Blocking')),
              ),
              child: const Text('Open'),
            ),
          ),
        );
      }),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await sendCharacters(tester, '1234');
    await simulateKeyDownEvent(LogicalKeyboardKey.enter);
    expect(scanned, isEmpty);

    Navigator.of(tester.element(find.text('Blocking'))).pop();
    await tester.pumpAndSettle();
    await sendCharacters(tester, '5678');
    await simulateKeyDownEvent(LogicalKeyboardKey.enter);
    expect(scanned, ['5678']);
  });
}

LogicalKeyboardKey _keyFor(String character) {
  if (RegExp(r'[0-9]').hasMatch(character)) {
    return <String, LogicalKeyboardKey>{
      '0': LogicalKeyboardKey.digit0,
      '1': LogicalKeyboardKey.digit1,
      '2': LogicalKeyboardKey.digit2,
      '3': LogicalKeyboardKey.digit3,
      '4': LogicalKeyboardKey.digit4,
      '5': LogicalKeyboardKey.digit5,
      '6': LogicalKeyboardKey.digit6,
      '7': LogicalKeyboardKey.digit7,
      '8': LogicalKeyboardKey.digit8,
      '9': LogicalKeyboardKey.digit9,
    }[character]!;
  }
  return LogicalKeyboardKey.keyA;
}
