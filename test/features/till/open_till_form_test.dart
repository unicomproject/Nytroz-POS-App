import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/till/presentation/widgets/open_till_form.dart';

void main() {
  group('OpenTillForm', () {
    testWidgets('renders till summary and open action', (tester) async {
      final formKey = GlobalKey<FormState>();
      final openingFloatController = TextEditingController(text: '150.00');
      final openingNoteController = TextEditingController();

      tester.view.physicalSize = const Size(1200, 1200);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OpenTillForm(
                formKey: formKey,
                openingFloatController: openingFloatController,
                openingNoteController: openingNoteController,
                isSubmitting: false,
                outletName: 'Main Outlet',
                tillName: 'Front Till',
                deviceName: 'DEV-001',
                onBack: () {},
                onSubmit: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Open Till'), findsWidgets);
      expect(find.text('Front Till'), findsWidgets);
      expect(find.text('Main Outlet'), findsOneWidget);
      expect(find.text('DEV-001'), findsOneWidget);
      expect(find.text('Amount is valid'), findsOneWidget);
    });

    testWidgets('requires opening cash amount', (tester) async {
      final formKey = GlobalKey<FormState>();
      final openingFloatController = TextEditingController();
      final openingNoteController = TextEditingController();

      tester.view.physicalSize = const Size(1200, 1200);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OpenTillForm(
                formKey: formKey,
                openingFloatController: openingFloatController,
                openingNoteController: openingNoteController,
                isSubmitting: false,
                outletName: 'Main Outlet',
                tillName: 'Front Till',
                deviceName: 'DEV-001',
                onBack: () {},
                onSubmit: () {},
              ),
            ),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Opening cash is required.'), findsOneWidget);
    });

    testWidgets('shows API error message when provided', (tester) async {
      final formKey = GlobalKey<FormState>();
      final openingFloatController = TextEditingController(text: '150.00');
      final openingNoteController = TextEditingController();

      tester.view.physicalSize = const Size(1200, 1200);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OpenTillForm(
                formKey: formKey,
                openingFloatController: openingFloatController,
                openingNoteController: openingNoteController,
                isSubmitting: false,
                outletName: 'Main Outlet',
                tillName: 'Front Till',
                deviceName: 'DEV-001',
                errorMessage: 'Till already has an open session.',
                onBack: () {},
                onSubmit: () {},
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('Till already has an open session.'),
        findsOneWidget,
      );
    });
  });
}
