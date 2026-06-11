import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';
import 'tenant_admin_buttons.dart';

class TenantAdminEmptyState extends StatelessWidget {
  const TenantAdminEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return _StateShell(
      icon: icon,
      title: title,
      message: message,
      iconColor: TenantAdminColors.mutedText,
      action: action,
    );
  }
}

class TenantAdminErrorState extends StatelessWidget {
  const TenantAdminErrorState({
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
    return _StateShell(
      icon: Icons.error_outline,
      title: title,
      message: message,
      iconColor: TenantAdminColors.danger,
      action: onRetry == null
          ? null
          : TenantAdminSecondaryButton(
              label: 'Retry',
              onPressed: onRetry,
              icon: Icons.refresh,
            ),
    );
  }
}

class TenantAdminLoadingSkeleton extends StatelessWidget {
  const TenantAdminLoadingSkeleton({
    super.key,
    this.rowCount = 4,
  });

  final int rowCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < rowCount; index++) ...[
          _SkeletonLine(widthFactor: index.isEven ? 0.82 : 0.64),
          if (index != rowCount - 1)
            const SizedBox(height: TenantAdminSpacing.md),
        ],
      ],
    );
  }
}

class _StateShell extends StatelessWidget {
  const _StateShell({
    required this.icon,
    required this.title,
    required this.message,
    required this.iconColor,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color iconColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: TenantAdminSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TenantAdminTextStyles.sectionTitle(context),
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TenantAdminTextStyles.muted(context),
            ),
            if (action != null) ...[
              const SizedBox(height: TenantAdminSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.widthFactor,
  });

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 18,
        decoration: BoxDecoration(
          color: TenantAdminColors.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
