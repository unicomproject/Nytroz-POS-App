import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/device_activation/presentation/widgets/device_activation_form.dart';

void main() {
  group('DeviceActivationForm', () {
    testWidgets('renders activation form fields', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceActivationForm(
              formKey: formKey,
              codeController: controller,
              isSubmitting: false,
              isWide: false,
              onSubmit: () {},
            ),
          ),
        ),
      );

      expect(find.text('Activate Device'), findsWidgets);
      expect(
        find.text('Enter your device activation code to continue.'),
        findsOneWidget,
      );
      expect(find.text('Device Activation Code'), findsOneWidget);
    });

    testWidgets('requires activation code before submit', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceActivationForm(
              formKey: formKey,
              codeController: controller,
              isSubmitting: false,
              isWide: false,
              onSubmit: () {},
            ),
          ),
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Device activation code is required.'), findsOneWidget);
    });

    testWidgets('shows server error message when provided', (tester) async {
      final formKey = GlobalKey<FormState>();
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceActivationForm(
              formKey: formKey,
              codeController: controller,
              isSubmitting: false,
              isWide: false,
              errorMessage: 'Activation code is invalid.',
              onSubmit: () {},
            ),
          ),
        ),
      );

      expect(find.text('Activation code is invalid.'), findsOneWidget);
    });
  });
}
