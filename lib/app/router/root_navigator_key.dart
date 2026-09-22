import 'package:flutter/widgets.dart';

/// Root navigator key for the app's [GoRouter], so code outside the widget
/// tree (e.g. a realtime event handler) can access a [BuildContext] to show
/// an overlay (toast) or push a route without needing its own listener
/// widget mounted somewhere in the tree.
final rootNavigatorKey = GlobalKey<NavigatorState>();
