import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dropdown error test', (tester) async {
    final key = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Form(
          key: key,
          child: DropdownButtonFormField<String>(
            value: null,
            items: const [
              DropdownMenuItem(value: '1', child: Text('1')),
            ],
            onChanged: (v) {},
            decoration: const InputDecoration(
              errorText: null, // Simulate errors['outletType']
            ),
            validator: (v) => 'Outlet type is required.',
          ),
        ),
      ),
    ));

    key.currentState!.validate();
    await tester.pumpAndSettle();

    expect(find.text('Outlet type is required.'), findsOneWidget);
  });
}
