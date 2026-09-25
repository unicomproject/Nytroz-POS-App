import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/widgets/tenant_admin_toast.dart';

void main() {
  // Regression coverage for a real bug: a bare `navigatorKey.currentContext`
  // (as used by a Riverpod controller with no BuildContext of its own) is
  // the Navigator widget's own element. The Overlay a Navigator provides is
  // built as a *descendant* of that element, not an ancestor, so
  // Overlay.maybeOf(navigatorKey.currentContext) fails to find it and
  // showAppToast silently no-ops — the toast never appears even though
  // nothing throws. Passing the OverlayState directly (via
  // navigatorKey.currentState?.overlay) is what actually fixes it.
  group('showAppToast with a bare navigatorKey context', () {
    // A short duration keeps each test's own auto-dismiss timer from
    // outliving the test — pumped past explicitly below so nothing is left
    // pending when the widget tree is torn down.
    const testDuration = Duration(milliseconds: 50);

    testWidgets(
        'Overlay.maybeOf(navigatorKey.currentContext) cannot find the '
        'Navigator\'s own Overlay — toast does not appear without an '
        'explicit overlayState', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(_HostApp(navigatorKey: navigatorKey));

      showAppToast(
        navigatorKey.currentContext!,
        message: 'Should not appear',
        title: 'No overlay',
        duration: testDuration,
      );
      await tester.pump();

      expect(find.text('Should not appear'), findsNothing);
    });

    testWidgets(
        'passing overlayState explicitly shows the toast even from a bare '
        'navigatorKey context', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(_HostApp(navigatorKey: navigatorKey));

      showAppToast(
        navigatorKey.currentContext!,
        overlayState: navigatorKey.currentState?.overlay,
        message: 'New order placed',
        title: 'Order received',
        type: AppToastType.info,
        duration: testDuration,
      );
      await tester.pump();

      expect(find.text('New order placed'), findsOneWidget);
      expect(find.text('Order received'), findsOneWidget);

      await tester.pump(testDuration + const Duration(milliseconds: 400));
    });

    testWidgets('tapping the toast invokes onTap and dismisses it',
        (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(_HostApp(navigatorKey: navigatorKey));

      var tapped = false;
      showAppToast(
        navigatorKey.currentContext!,
        overlayState: navigatorKey.currentState?.overlay,
        message: 'New order placed',
        onTap: () => tapped = true,
        duration: testDuration,
      );
      await tester.pump();
      expect(find.text('New order placed'), findsOneWidget);

      await tester.tap(find.text('New order placed'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tapped, isTrue);
      expect(find.text('New order placed'), findsNothing);

      // Drain the (already-cancelled-by-removal, but still scheduled)
      // auto-dismiss timer so nothing is left pending at teardown.
      await tester.pump(testDuration);
    });
  });
}

/// Minimal app shell mirroring the real one: a MaterialApp with a Navigator
/// identified by the same navigatorKey a realtime event handler would use,
/// and nothing above it that happens to provide an Overlay ancestor.
class _HostApp extends StatelessWidget {
  const _HostApp({required this.navigatorKey});
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(body: SizedBox.shrink()),
    );
  }
}
