
import 'package:flutter/material.dart';

import '../layout/tenant_admin_breadcrumb.dart';
import '../theme/tenant_admin_theme.dart';

class TenantAdminPageScaffold extends StatelessWidget {
  const TenantAdminPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.padding,
    this.headerSpacing,
    this.backgroundColor = TenantAdminColors.background,
    this.scrollable = true,
    this.fillHeight = true,
    this.showBackButton = false,
    this.onBackButtonPressed,
    this.breadcrumbs,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final EdgeInsets? padding;
  final double? headerSpacing;
  final Color backgroundColor;
  final bool scrollable;
  final bool fillHeight;
  final bool showBackButton;
  final VoidCallback? onBackButtonPressed;
  final List<TenantAdminBreadcrumbItem>? breadcrumbs;

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
              if (breadcrumbs != null && breadcrumbs!.isNotEmpty) ...[
                TenantAdminBreadcrumb(items: breadcrumbs!),
                const SizedBox(height: TenantAdminSpacing.md),
              ],
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
                SizedBox(
                  height: headerSpacing ??
                      (constraints.maxHeight < 720
                          ? TenantAdminSpacing.sm
                          : TenantAdminSpacing.xl) +
                          20,
                ),
              ],
              if (scrollable) child else Expanded(child: child),
            ],
          );

          // Eliminate margins/gaps on desktop/tablet by setting framePadding to zero
          final framePadding = isNarrow
              ? (fillHeight
                  ? EdgeInsets.all(TenantAdminSpacing.sm)
                  : const EdgeInsets.only(top: 12))
              : EdgeInsets.zero;

          final verticalFrameInset =
              fillHeight ? framePadding.vertical : framePadding.top;

          return Padding(
            padding: framePadding,
            child: Container(
              width: double.infinity,
              constraints: fillHeight && constraints.maxHeight.isFinite && constraints.maxHeight < 10000
                  ? BoxConstraints(
                      minHeight: (constraints.maxHeight - verticalFrameInset)
                          .clamp(0.0, double.infinity),
                    )
                  : null,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: TenantAdminColors.surface,
                borderRadius: isNarrow
                    ? BorderRadius.circular(24)
                    : BorderRadius.zero, // Dock perfectly flush against sidebar/header
                boxShadow: isNarrow ? null : null, // Remove shadows to keep flat contiguous layout
              ),
              child: scrollable
                  ? SingleChildScrollView(
                      padding: basePadding,
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: fillHeight && constraints.maxHeight.isFinite && constraints.maxHeight < 10000
                            ? BoxConstraints(
                                minHeight: (constraints.maxHeight -
                                        verticalFrameInset -
                                        basePadding.vertical)
                                    .clamp(0.0, double.infinity),
                              )
                            : const BoxConstraints(),
                        child: content,
                      ),
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
          child: _HeaderText(
              title: title,
              subtitle: subtitle,
              showBackButton: showBackButton,
              onBackButtonPressed: onBackButtonPressed),
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
        _HeaderText(
            title: title,
            subtitle: subtitle,
            showBackButton: showBackButton,
            onBackButtonPressed: onBackButtonPressed),
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
              if (title.isNotEmpty)
                Text(title, style: TenantAdminTextStyles.pageTitle(context)),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(subtitle!, style: TenantAdminTextStyles.muted(context)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
