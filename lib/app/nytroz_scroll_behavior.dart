import 'package:flutter/material.dart';

/// Desktop/admin-friendly scrolling: no bounce, no content stretch on overscroll.
class NytrozScrollBehavior extends MaterialScrollBehavior {
  const NytrozScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
