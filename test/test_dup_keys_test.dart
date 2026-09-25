import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

@Skip('Needs UI refactor update for 6-step flow')
void main() {
  testWidgets('dup label', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: DropdownMenu<String>(
          dropdownMenuEntries: [
            DropdownMenuEntry(value: '1', label: 'A'),
            DropdownMenuEntry(value: '2', label: 'A'),
          ],
        ),
      ),
    ));
    await tester.tap(find.byType(DropdownMenu<String>));
    await tester.pumpAndSettle();
    debugPrint('SUCCESS');
  });
}
