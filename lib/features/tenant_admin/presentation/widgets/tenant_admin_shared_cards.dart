import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';
import 'tenant_admin_states.dart';

class TenantAdminPageHeaderCard extends StatelessWidget {
  const TenantAdminPageHeaderCard({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackActions = constraints.maxWidth < 640;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TenantAdminTextStyles.pageTitle(context)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: TenantAdminTextStyles.muted(context)),
              ],
            ],
          );

          if (stackActions || actions.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: TenantAdminSpacing.md),
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleBlock),
              const SizedBox(width: 12),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          );
        },
      ),
    );
  }
}

class TenantAdminSearchCard extends StatelessWidget {
  const TenantAdminSearchCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => _CardShell(child: child);
}

class TenantAdminFilterCard extends StatelessWidget {
  const TenantAdminFilterCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => _CardShell(child: child);
}

class TenantAdminTableCard extends StatelessWidget {
  const TenantAdminTableCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => _CardShell(child: child);
}

class TenantAdminFormCard extends StatelessWidget {
  const TenantAdminFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => _CardShell(child: child);
}

class TenantAdminEmptyStateCard extends StatelessWidget {
  const TenantAdminEmptyStateCard({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: TenantAdminEmptyState(
        title: title,
        message: message,
        icon: icon,
        action: action,
      ),
    );
  }
}

class TenantAdminErrorStateCard extends StatelessWidget {
  const TenantAdminErrorStateCard({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: TenantAdminErrorState(
        title: title,
        message: message,
        onRetry: onRetry,
      ),
    );
  }
}

class TenantAdminPermissionDeniedCard extends StatelessWidget {
  const TenantAdminPermissionDeniedCard({
    super.key,
    this.title = 'Access denied',
    this.message = 'You do not have permission to view this content.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: _StateBody(
        icon: Icons.lock_outline,
        iconColor: TenantAdminColors.warning,
        title: title,
        message: message,
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: child,
    );
  }
}

class _StateBody extends StatelessWidget {
  const _StateBody({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: iconColor),
          const SizedBox(height: 12),
          Text(title, style: TenantAdminTextStyles.sectionTitle(context)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TenantAdminTextStyles.muted(context),
          ),
        ],
      ),
    );
  }
}
