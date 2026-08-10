import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

class TenantAdminPageScaffold extends StatelessWidget {
  const TenantAdminPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.padding,
    this.backgroundColor = TenantAdminColors.background,
    this.scrollable = true,
    this.showBackButton = false,
    this.onBackButtonPressed,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final EdgeInsets? padding;
  final Color backgroundColor;
  final bool scrollable;
  final bool showBackButton;
  final VoidCallback? onBackButtonPressed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final basePadding =
              padding ?? TenantAdminInsets.pageForWidth(constraints.maxWidth);
          final isNarrow = constraints.maxWidth < TenantAdminBreakpoints.mobile;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty || showBackButton) ...[
                if (isNarrow)
                  _VerticalHeader(
                    title: title,
                    subtitle: subtitle,
                    actions: actions,
                    showBackButton: showBackButton,
                    onBackButtonPressed: onBackButtonPressed,
                  )
                else
                  _HorizontalHeader(
                    title: title,
                    subtitle: subtitle,
                    actions: actions,
                    showBackButton: showBackButton,
                    onBackButtonPressed: onBackButtonPressed,
                  ),
                const SizedBox(height: 28),
              ],
              if (scrollable) child else Expanded(child: child),
            ],
          );

          return Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: TenantAdminColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isNarrow ? null : TenantAdminShadows.card,
              ),
              child: scrollable
                  ? SingleChildScrollView(
                      padding: basePadding,
                      child: content,
                    )
                  : Padding(
                      padding: basePadding,
                      child: content,
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _HorizontalHeader extends StatelessWidget {
  const _HorizontalHeader({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.showBackButton,
    this.onBackButtonPressed,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBackButton;
  final VoidCallback? onBackButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _HeaderText(title: title, subtitle: subtitle, showBackButton: showBackButton, onBackButtonPressed: onBackButtonPressed),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: TenantAdminSpacing.lg),
          Wrap(
            spacing: TenantAdminSpacing.sm,
            runSpacing: TenantAdminSpacing.sm,
            children: actions,
          ),
        ],
      ],
    );
  }
}

class _VerticalHeader extends StatelessWidget {
  const _VerticalHeader({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.showBackButton,
    this.onBackButtonPressed,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBackButton;
  final VoidCallback? onBackButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderText(title: title, subtitle: subtitle, showBackButton: showBackButton, onBackButtonPressed: onBackButtonPressed),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: TenantAdminSpacing.lg),
          Wrap(
            spacing: TenantAdminSpacing.sm,
            runSpacing: TenantAdminSpacing.sm,
            children: actions,
          ),
        ],
      ],
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText({
    required this.title,
    required this.subtitle,
    required this.showBackButton,
    this.onBackButtonPressed,
  });

  final String title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBackButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showBackButton) ...[
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (onBackButtonPressed != null) {
                onBackButtonPressed!();
              } else if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title == 'Dashboard') ...[
                const Icon(
                  Icons.menu,
                  color: TenantAdminColors.bodyText,
                  size: 22,
                ),
                const SizedBox(height: 18),
              ],
              if (title.isNotEmpty)
                Text(title, style: TenantAdminTextStyles.pageTitle(context)),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(subtitle!, style: TenantAdminTextStyles.muted(context)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
