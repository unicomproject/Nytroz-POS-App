import 'package:go_router/go_router.dart';

import 'presentation/screens/pos_home_screen.dart';

List<RouteBase> posShellRoutes() {
  return [
    GoRoute(
      path: '/pos/home',
      builder: (context, state) => const PosHomeScreen(),
    ),
  ];
}
