
import 'package:flutter/material.dart';

import '../layout/tenant_admin_breadcrumb.dart';
import '../theme/tenant_admin_theme.dart';

class TenantAdminPageScaffold extends StatelessWidget {
  const TenantAdminPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.description,
    this.actions = const [],
    this.padding,
    this.headerSpacing,
    this.backgroundColor = TenantAdminColors.background,
    this.scrollable = true,
    this.fillHeight = true,
    this.showBackButton = false,
    this.onBackButtonPressed,
    this.backLinkLabel,
    this.onBackLinkPressed,
    this.breadcrumbs,
    this.emphasizeSubtitle = false,
  });

  final String title;
  final String? subtitle;
  final String? description;
  final List<Widget> actions;
  final Widget child;
  final EdgeInsets? padding;
  final double? headerSpacing;
  final Color backgroundColor;
  final bool scrollable;
  final bool fillHeight;
  final bool showBackButton;
  final VoidCallback? onBackButtonPressed;
  final String? backLinkLabel;
  final VoidCallback? onBackLinkPressed;
  final List<TenantAdminBreadcrumbItem>? breadcrumbs;
  final bool emphasizeSubtitle;

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
                    description: description,
                    actions: actions,
                    showBackButton: showBackButton,
                    onBackButtonPressed: onBackButtonPressed,
                    backLinkLabel: backLinkLabel,
                    onBackLinkPressed: onBackLinkPressed,
                    emphasizeSubtitle: emphasizeSubtitle,
                  )
                else
                  _HorizontalHeader(
                    title: title,
                    subtitle: subtitle,
                    description: description,
                    actions: actions,
                    showBackButton: showBackButton,
                    onBackButtonPressed: onBackButtonPressed,
                    backLinkLabel: backLinkLabel,
                    onBackLinkPressed: onBackLinkPressed,
                    emphasizeSubtitle: emphasizeSubtitle,
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
    required this.description,
    required this.actions,
    required this.showBackButton,
    this.onBackButtonPressed,
    this.backLinkLabel,
    this.onBackLinkPressed,
    this.emphasizeSubtitle = false,
  });

  final String title;
  final String? subtitle;
  final String? description;
  final List<Widget> actions;
  final bool showBackButton;
  final VoidCallback? onBackButtonPressed;
  final String? backLinkLabel;
  final VoidCallback? onBackLinkPressed;
  final bool emphasizeSubtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _HeaderText(
            title: title,
            subtitle: subtitle,
            description: description,
            showBackButton: showBackButton,
            onBackButtonPressed: onBackButtonPressed,
            backLinkLabel: backLinkLabel,
            onBackLinkPressed: onBackLinkPressed,
            emphasizeSubtitle: emphasizeSubtitle,
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: TenantAdminSpacing.lg),
          Wrap(
            spacing: TenantAdminSpacing.sm,
            runSpacing: TenantAdminSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
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
    required this.description,
    required this.actions,
    required this.showBackButton,
    this.onBackButtonPressed,
    this.backLinkLabel,
    this.onBackLinkPressed,
    this.emphasizeSubtitle = false,
  });

  final String title;
  final String? subtitle;
  final String? description;
  final List<Widget> actions;
  final bool showBackButton;
  final VoidCallback? onBackButtonPressed;
  final String? backLinkLabel;
  final VoidCallback? onBackLinkPressed;
  final bool emphasizeSubtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderText(
          title: title,
          subtitle: subtitle,
          description: description,
          showBackButton: showBackButton,
          onBackButtonPressed: onBackButtonPressed,
          backLinkLabel: backLinkLabel,
          onBackLinkPressed: onBackLinkPressed,
          emphasizeSubtitle: emphasizeSubtitle,
        ),
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
    required this.description,
    required this.showBackButton,
    this.onBackButtonPressed,
    this.backLinkLabel,
    this.onBackLinkPressed,
    this.emphasizeSubtitle = false,
  });

  final String title;
  final String? subtitle;
  final String? description;
  final bool showBackButton;
  final VoidCallback? onBackButtonPressed;
  final String? backLinkLabel;
  final VoidCallback? onBackLinkPressed;
  final bool emphasizeSubtitle;

  @override
  Widget build(BuildContext context) {
    if (showBackButton) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
          Expanded(child: _buildHeaderContent(context)),
        ],
      );
    }

    return _buildHeaderContent(context);
  }

  Widget _buildHeaderContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (backLinkLabel != null && onBackLinkPressed != null) ...[
          _BackToLink(
            label: backLinkLabel!,
            onPressed: onBackLinkPressed!,
          ),
          const SizedBox(height: TenantAdminSpacing.md),
        ],
        if (title.isNotEmpty)
          Text(title, style: TenantAdminTextStyles.pageTitle(context)),
        if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: emphasizeSubtitle
                ? const TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  )
                : TenantAdminTextStyles.pageSubtitle(context),
          ),
        ],
        if (description != null && description!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TenantAdminTextStyles.pageSubtitle(context),
          ),
        ],
      ],
    );
  }
}

class _BackToLink extends StatelessWidget {
  const _BackToLink({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back,
              size: 16,
              color: TenantAdminColors.primary.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: TenantAdminColors.primary.withValues(alpha: 0.85),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
