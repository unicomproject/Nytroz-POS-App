import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../../presentation/widgets/tenant_admin_page_scaffold.dart';

class ReportPageScaffold extends StatelessWidget {
  const ReportPageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
    this.breadcrumbs = const ['Reports'],
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;
  final List<String> breadcrumbs;

  @override
  Widget build(BuildContext context) {
    return TenantAdminPageScaffold(
      title: title,
      subtitle: subtitle,
      actions: actions,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportBreadcrumb(items: [...breadcrumbs, title]),
          const SizedBox(height: TenantAdminSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class ReportBreadcrumb extends StatelessWidget {
  const ReportBreadcrumb({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: TenantAdminSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0)
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: TenantAdminColors.mutedText,
            ),
          Text(
            items[index],
            style: TextStyle(
              color: index == items.length - 1
                  ? TenantAdminColors.bodyText
                  : TenantAdminColors.mutedText,
              fontWeight:
                  index == items.length - 1 ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class ReportSectionCard extends StatelessWidget {
  const ReportSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.padding = const EdgeInsets.all(18),
  });

  final String title;
  final Widget child;
  final Widget? action;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TenantAdminTextStyles.sectionTitle(context),
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class ReportQuickLinkCard extends StatelessWidget {
  const ReportQuickLinkCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
          border: Border.all(color: TenantAdminColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: TenantAdminColors.secondary,
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
              child: Icon(icon, color: TenantAdminColors.primary),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  Text(subtitle, style: TenantAdminTextStyles.muted(context)),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward,
              color: TenantAdminColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class ReportQuickLinkButton extends StatelessWidget {
  const ReportQuickLinkButton({
    super.key,
    required this.label,
    required this.route,
  });

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.go(route),
      icon: const Icon(Icons.open_in_new, size: 18),
      label: Text(label),
    );
  }
}

class ReportExportMenu extends StatelessWidget {
  const ReportExportMenu({super.key, required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Export report',
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'CSV', child: Text('Export CSV')),
        PopupMenuItem(value: 'XLSX', child: Text('Export XLSX')),
        PopupMenuItem(value: 'PDF', child: Text('Export PDF')),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: TenantAdminColors.primary,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_outlined, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Export',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
