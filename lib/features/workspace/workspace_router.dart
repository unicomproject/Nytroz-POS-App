import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/workspace_chooser_screen.dart';

const workspaceChooserRoute = '/workspace';
const workspaceNoAccessRoute = '/workspace/no-access';
const workspaceAccountSettingsRoute = '/workspace/account-settings';

List<RouteBase> workspaceRoutes(Ref ref) => [
      GoRoute(
        path: workspaceChooserRoute,
        builder: (context, state) => const WorkspaceChooserScreen(),
      ),
      GoRoute(
        path: workspaceNoAccessRoute,
        builder: (context, state) => const WorkspaceNoAccessScreen(),
      ),
      GoRoute(
        path: workspaceAccountSettingsRoute,
        builder: (context, state) => const WorkspaceAccountSettingsScreen(),
      ),
    ];
