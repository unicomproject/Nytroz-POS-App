import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

void main() {
  testWidgets('app dialogs blur the content behind the modal', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final context = tester.element(find.byType(Scaffold));

    showAppDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(title: Text('Dialog')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('app bottom sheets blur the content behind the modal',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final context = tester.element(find.byType(Scaffold));

    showAppModalBottomSheet<void>(
      context: context,
      builder: (_) => const SizedBox(height: 120),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BackdropFilter), findsOneWidget);
  });
}
