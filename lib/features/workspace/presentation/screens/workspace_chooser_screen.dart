import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../../../shared/pos_session/pos_session_bootstrap_provider.dart';
import '../../domain/workspace_access.dart';
import '../providers/workspace_selection_provider.dart';
import '../../workspace_router.dart';

const _orange = Color(0xFFFF5A16);
const _navy = Color(0xFF07101F);

class WorkspaceChooserScreen extends ConsumerStatefulWidget {
  const WorkspaceChooserScreen({super.key});

  @override
  ConsumerState<WorkspaceChooserScreen> createState() =>
      _WorkspaceChooserScreenState();
}

class _WorkspaceChooserScreenState
    extends ConsumerState<WorkspaceChooserScreen> {
  AppWorkspace? _opening;

  Future<void> _open(AppWorkspace workspace) async {
    if (_opening != null) return;
    setState(() => _opening = workspace);

    final workspaceState = ref.read(workspaceSelectionProvider);
    final selected = await ref.read(workspaceSelectionProvider.notifier).select(
          workspace,
          rememberChoice: workspaceState.rememberChoice,
        );
    if (!selected) {
      if (mounted) setState(() => _opening = null);
      return;
    }

    if (workspace == AppWorkspace.pos) {
      await ref
          .read(posSessionBootstrapProvider.notifier)
          .bootstrap(force: true);
    }

    if (!mounted) return;
    context.go(
      workspace == AppWorkspace.tenantAdmin ? '/tenant-admin' : '/pos/home',
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final workspaceState = ref.watch(workspaceSelectionProvider);
    final access = workspaceState.access;
    final permissions = session?.permissionCodes.toSet() ?? const <String>{};

    return Scaffold(
      backgroundColor: const Color(0xFF05070A),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              displayName: session?.userDisplayName ?? 'User',
              access: access,
              onOpenWorkspace: _open,
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose Workspace',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: _navy,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Select where you want to continue. Your available workspaces and features are based on your assigned permissions.',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 22),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Color(0xFF2563EB)),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'The navigation menu will show only the modules your role can use. Protected pages and APIs remain permission checked.',
                                      style: TextStyle(
                                        color: Color(0xFF1D4ED8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (workspaceState.isPreferenceLoading) ...[
                              const LinearProgressIndicator(color: _orange),
                              const SizedBox(height: 16),
                            ],
                            IgnorePointer(
                              ignoring: workspaceState.isPreferenceLoading,
                              child: Opacity(
                                opacity: workspaceState.isPreferenceLoading
                                    ? 0.55
                                    : 1,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final cards = <Widget>[
                                      if (access.canAccessTenantAdmin)
                                        _WorkspaceCard(
                                          icon: Icons.apartment_rounded,
                                          title: 'Tenant Admin',
                                          description:
                                              'Manage outlets, users, products, inventory, reports and settings.',
                                          features: _adminFeatures(permissions),
                                          buttonLabel:
                                              'Continue to Tenant Admin',
                                          busy: _opening ==
                                              AppWorkspace.tenantAdmin,
                                          onPressed: () =>
                                              _open(AppWorkspace.tenantAdmin),
                                        ),
                                      if (access.canAccessPos)
                                        _WorkspaceCard(
                                          icon: Icons.point_of_sale_rounded,
                                          title: 'POS / Cashier',
                                          description:
                                              'Process sales, manage orders, take payments and operate a till.',
                                          features: _posFeatures(permissions),
                                          buttonLabel: 'Continue to POS',
                                          busy: _opening == AppWorkspace.pos,
                                          onPressed: () =>
                                              _open(AppWorkspace.pos),
                                        ),
                                    ];

                                    if (constraints.maxWidth < 760) {
                                      return Column(
                                        children: cards
                                            .map((card) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 16),
                                                  child: card,
                                                ))
                                            .toList(),
                                      );
                                    }
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: cards
                                          .map((card) => Expanded(
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 8),
                                                  child: card,
                                                ),
                                              ))
                                          .toList(),
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (access.hasMultiple) ...[
                              const SizedBox(height: 20),
                              Center(
                                child: Column(
                                  children: [
                                    CheckboxListTile(
                                      value: workspaceState.rememberChoice,
                                      onChanged: (value) => ref
                                          .read(workspaceSelectionProvider
                                              .notifier)
                                          .setRememberChoice(value ?? false),
                                      title: const Text(
                                        'Remember my choice on this device',
                                        textAlign: TextAlign.center,
                                      ),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      activeColor: _orange,
                                    ),
                                    const Text(
                                      'Recommended only for personal devices.',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => ref
                                  .read(authSessionProvider.notifier)
                                  .clear(),
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Sign out'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ProfileAction {
  tenantAdmin,
  pos,
  accountSettings,
  signOut,
}

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.displayName,
    required this.access,
    required this.onOpenWorkspace,
  });

  final String displayName;
  final WorkspaceAccess access;
  final ValueChanged<AppWorkspace> onOpenWorkspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        child: Row(
          children: [
            const Icon(Icons.shopping_bag_rounded, color: _orange, size: 34),
            const SizedBox(width: 10),
            const Text(
              'OneVerz POS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Help',
              onPressed: () => _showInfoDialog(
                context,
                icon: Icons.help_outline_rounded,
                title: 'Workspace help',
                message:
                    'Choose Tenant Admin to manage your business, or POS / Cashier to process sales. The options shown depend on your assigned permissions.',
              ),
              icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            ),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => _showInfoDialog(
                context,
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                message: 'You have no new notifications.',
              ),
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<_ProfileAction>(
              tooltip: 'Account menu',
              position: PopupMenuPosition.under,
              color: Colors.white,
              onSelected: (action) {
                switch (action) {
                  case _ProfileAction.tenantAdmin:
                    onOpenWorkspace(AppWorkspace.tenantAdmin);
                  case _ProfileAction.pos:
                    onOpenWorkspace(AppWorkspace.pos);
                  case _ProfileAction.accountSettings:
                    context.go(workspaceAccountSettingsRoute);
                  case _ProfileAction.signOut:
                    ref.read(authSessionProvider.notifier).clear();
                }
              },
              itemBuilder: (context) => [
                if (access.canAccessTenantAdmin)
                  const PopupMenuItem(
                    value: _ProfileAction.tenantAdmin,
                    child: _ProfileMenuRow(
                      icon: Icons.apartment_rounded,
                      label: 'Tenant Admin',
                    ),
                  ),
                if (access.canAccessPos)
                  const PopupMenuItem(
                    value: _ProfileAction.pos,
                    child: _ProfileMenuRow(
                      icon: Icons.point_of_sale_rounded,
                      label: 'POS / Cashier',
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: _ProfileAction.accountSettings,
                  child: _ProfileMenuRow(
                    icon: Icons.settings_outlined,
                    label: 'Account Settings',
                  ),
                ),
                const PopupMenuItem(
                  value: _ProfileAction.signOut,
                  child: _ProfileMenuRow(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    color: Colors.red,
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF293241)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF374151),
                      child: Text(
                        _initials(displayName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            access.hasMultiple
                                ? 'Multi-access user'
                                : access.canAccessTenantAdmin
                                    ? 'Tenant Admin'
                                    : 'POS / Cashier',
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _ProfileMenuRow extends StatelessWidget {
  const _ProfileMenuRow({
    required this.icon,
    required this.label,
    this.color = _navy,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color)),
        ],
      );
}

String _initials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
  if (parts.isEmpty) return 'U';
  final values = parts.toList(growable: false);
  if (values.length == 1) {
    return values.first
        .substring(0, values.first.length.clamp(1, 2))
        .toUpperCase();
  }
  return '${values.first[0]}${values.last[0]}'.toUpperCase();
}

Future<void> _showInfoDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
}) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(icon, color: _orange, size: 34),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
    required this.buttonLabel,
    required this.busy,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<_Feature> features;
  final String buttonLabel;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFFFE9DF),
                  child: Icon(icon, color: _orange, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(description,
                style: const TextStyle(color: Color(0xFF64748B), height: 1.45)),
            const Divider(height: 34),
            const Text('Available features',
                style: TextStyle(fontWeight: FontWeight.w700, color: _navy)),
            const SizedBox(height: 12),
            ...features.where((feature) => feature.allowed).map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: _orange, size: 19),
                        const SizedBox(width: 9),
                        Text(feature.label),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _orange),
                onPressed: busy ? null : onPressed,
                child: busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(buttonLabel),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
              ),
            ),
          ],
        ),
      );
}

class _Feature {
  const _Feature(this.label, this.allowed);
  final String label;
  final bool allowed;
}

bool _hasPrefix(Set<String> permissions, List<String> prefixes) => permissions
    .map((permission) => permission.toLowerCase())
    .any((permission) => prefixes.any(permission.startsWith));

List<_Feature> _adminFeatures(Set<String> permissions) => [
      _Feature(
        'Outlets',
        _hasPrefix(permissions, const ['tenant.outlet', 'outlet.']),
      ),
      _Feature(
          'Users & Roles',
          _hasPrefix(permissions,
              const ['tenant.user', 'tenant.role', 'user.', 'role.'])),
      _Feature(
        'Products',
        _hasPrefix(permissions,
            const ['tenant.product', 'product.', 'catalog.product']),
      ),
      _Feature('Reports',
          _hasPrefix(permissions, const ['tenant.report', 'report.'])),
    ];

List<_Feature> _posFeatures(Set<String> permissions) => [
      _Feature(
          'New Sale', _hasPrefix(permissions, const ['sales.', 'pos.sale'])),
      _Feature('Orders', _hasPrefix(permissions, const ['orders.'])),
      _Feature('Customers', _hasPrefix(permissions, const ['customers.'])),
      _Feature('Till Operations',
          _hasPrefix(permissions, const ['pos.till', 'till.'])),
    ];

class WorkspaceAccountSettingsScreen extends ConsumerWidget {
  const WorkspaceAccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final workspaceState = ref.watch(workspaceSelectionProvider);
    final displayName = session?.userDisplayName.trim().isNotEmpty == true
        ? session!.userDisplayName.trim()
        : 'User';

    return Scaffold(
      backgroundColor: const Color(0xFF05070A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF05070A),
        foregroundColor: Colors.white,
        title: const Text('Account Settings'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            if (workspaceState.access.hasMultiple) {
              ref.read(workspaceSelectionProvider.notifier).showChooser();
              context.go(workspaceChooserRoute);
              return;
            }
            context.go(
              workspaceState.access.onlyWorkspace == AppWorkspace.tenantAdmin
                  ? '/tenant-admin'
                  : '/pos/home',
            );
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFFFFE9DF),
                          child: Text(
                            _initials(displayName),
                            style: const TextStyle(
                              color: _orange,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  color: _navy,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                'Signed-in account',
                                style: TextStyle(color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 40),
                    const Text(
                      'Workspace access',
                      style: TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (workspaceState.access.canAccessTenantAdmin)
                          const Chip(
                            avatar: Icon(Icons.apartment_rounded, size: 18),
                            label: Text('Tenant Admin'),
                          ),
                        if (workspaceState.access.canAccessPos)
                          const Chip(
                            avatar: Icon(Icons.point_of_sale_rounded, size: 18),
                            label: Text('POS / Cashier'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your workspace and module access is managed by your administrator. Contact them if your assigned access needs to change.',
                      style: TextStyle(color: Color(0xFF64748B), height: 1.45),
                    ),
                    const SizedBox(height: 28),
                    OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(authSessionProvider.notifier).clear(),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WorkspaceNoAccessScreen extends ConsumerWidget {
  const WorkspaceNoAccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 64, color: _orange),
                  const SizedBox(height: 18),
                  Text('No workspace access',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 10),
                  const Text(
                    'Your account is active, but no Tenant Admin or POS permissions are assigned. Contact your administrator.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(authSessionProvider.notifier).clear(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
