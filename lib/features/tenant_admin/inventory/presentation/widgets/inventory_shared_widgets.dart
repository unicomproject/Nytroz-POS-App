import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';

class InventoryWorkspaceTokens {
  const InventoryWorkspaceTokens._();

  static const line = Color(0xFFDDE4EE);
  static const label = Color(0xFF52617C);
  static const muted = Color(0xFF64748B);
  static const ink = Color(0xFF0C1833);
  static const iconBlue = Color(0xFF1160FF);
  static const iconGreen = Color(0xFF07AF42);
  static const iconRed = Color(0xFFFF2525);
  static const iconOrange = Color(0xFFFF8400);
  static const iconPurple = Color(0xFF902CFF);
  static const blueFill = Color(0xFFEDF4FF);
  static const greenFill = Color(0xFFEAFBEC);
  static const redFill = Color(0xFFFFF0F0);
  static const orangeFill = Color(0xFFFFF4E8);
  static const purpleFill = Color(0xFFF5EBFF);
  static const metricMinHeight = 112.0;
  static const quickMinHeight = 92.0;
  static const iconBox = 58.0;
  static const searchHeight = 48.0;
  static const inputHeight = 40.0;
  static const rowMinHeight = 64.0;
  static const cardRadius = 12.0;
  static const controlRadius = 8.0;
}

class InventorySectionCard extends StatelessWidget {
  const InventorySectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TenantAdminColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        side: const BorderSide(color: TenantAdminColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class InventoryStatCard extends StatelessWidget {
  const InventoryStatCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor = TenantAdminColors.primary,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InventorySectionCard(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: InventoryWorkspaceTokens.metricMinHeight - 32,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: InventoryWorkspaceTokens.iconBox,
                height: InventoryWorkspaceTokens.iconBox,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: InventoryWorkspaceTokens.label,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                      color: InventoryWorkspaceTokens.ink,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: InventoryWorkspaceTokens.muted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InventoryMetricStrip extends StatelessWidget {
  const InventoryMetricStrip({super.key, required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < 700) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                cards[i],
              ],
            ],
          );
        }
        if (width < 1100 && cards.length > 3) {
          return Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < 2; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: cards[i]),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 2; i < cards.length; i++) ...[
                    if (i > 2) const SizedBox(width: 12),
                    Expanded(child: cards[i]),
                  ],
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 14),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }
}

class InventoryNoteBanner extends StatelessWidget {
  const InventoryNoteBanner({
    super.key,
    required this.message,
    this.tone = 'warning',
  });

  final String message;
  final String tone;

  @override
  Widget build(BuildContext context) {
    final warning = tone != 'ok';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: warning
            ? TenantAdminColors.warning.withValues(alpha: 0.08)
            : TenantAdminColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
          color: warning
              ? TenantAdminColors.warning.withValues(alpha: 0.24)
              : TenantAdminColors.success.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 12,
          color:
              warning ? TenantAdminColors.warning : TenantAdminColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class InventorySummaryRow extends StatelessWidget {
  const InventorySummaryRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: InventoryWorkspaceTokens.muted,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: InventoryWorkspaceTokens.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InventoryWorkspaceTable extends StatelessWidget {
  const InventoryWorkspaceTable({
    super.key,
    required this.headers,
    required this.rows,
    this.minWidth = 760,
  });

  final List<String> headers;
  final List<List<Widget>> rows;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : minWidth;
        final tableWidth =
            availableWidth < minWidth ? minWidth : availableWidth;
        final columnCount = headers.isEmpty ? 1 : headers.length;
        final columnWidth = tableWidth / columnCount;

        Widget cell(Widget child, {bool header = false}) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontSize: 11,
                fontWeight: header ? FontWeight.w600 : FontWeight.w500,
                color: header
                    ? const Color(0xFF355176)
                    : InventoryWorkspaceTokens.ink,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: DefaultTextStyle.merge(
                  overflow: TextOverflow.ellipsis,
                  child: child,
                ),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: {
                for (var i = 0; i < columnCount; i++)
                  i: FixedColumnWidth(columnWidth),
              },
              border: const TableBorder(
                horizontalInside: BorderSide(
                  color: InventoryWorkspaceTokens.line,
                ),
              ),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFFBFEFE)),
                  children: [
                    for (final header in headers)
                      cell(Text(header), header: true),
                  ],
                ),
                for (final row in rows)
                  TableRow(
                    children: [
                      for (var i = 0; i < columnCount; i++)
                        cell(i < row.length ? row[i] : const SizedBox.shrink()),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

InputDecoration inventoryInputDecoration({
  String? label,
  String? hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: Color(0xFFD8E0EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(7),
      borderSide: const BorderSide(color: TenantAdminColors.primary),
    ),
  );
}

class InventoryProductPickRow extends StatelessWidget {
  const InventoryProductPickRow({
    super.key,
    required this.name,
    required this.sku,
    required this.selected,
    required this.onTap,
    this.stockLabel,
  });

  final String name;
  final String sku;
  final bool selected;
  final VoidCallback onTap;
  final String? stockLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            constraints: const BoxConstraints(minHeight: 68),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: selected
                    ? TenantAdminColors.info
                    : InventoryWorkspaceTokens.line,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      size: 20, color: Color(0xFF526889)),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'SKU: $sku',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF526889),
                        ),
                      ),
                    ],
                  ),
                ),
                if (stockLabel != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    stockLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  selected ? 'Selected' : '+ Select',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? TenantAdminColors.primary
                        : TenantAdminColors.info,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InventoryLocationCard extends StatelessWidget {
  const InventoryLocationCard({
    super.key,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        height: 132,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected
                ? TenantAdminColors.info
                : InventoryWorkspaceTokens.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (selected)
              const Align(
                alignment: Alignment.topRight,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: TenantAdminColors.info,
                  child: Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.storefront_outlined,
                      size: 28, color: TenantAdminColors.info),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InventoryChannelPickCard extends StatelessWidget {
  const InventoryChannelPickCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 152,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? TenantAdminColors.info
                : InventoryWorkspaceTokens.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (selected)
              const Align(
                alignment: Alignment.topRight,
                child: Icon(Icons.check_box, color: TenantAdminColors.info),
              )
            else
              const Align(
                alignment: Alignment.topRight,
                child: Icon(Icons.check_box_outline_blank,
                    color: Color(0xFFB8C4D6)),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: InventoryWorkspaceTokens.blueFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.hub_outlined,
                        color: TenantAdminColors.info),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF667893),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InventoryFooterBar extends StatelessWidget {
  const InventoryFooterBar({
    super.key,
    required this.leading,
    required this.trailing,
  });

  final Widget leading;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          leading,
          const Spacer(),
          trailing,
        ],
      ),
    );
  }
}

class InventoryStepper extends StatelessWidget {
  const InventoryStepper({
    super.key,
    required this.steps,
    required this.currentIndex,
  });

  final List<String> steps;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _StepChip(
              index: i + 1,
              label: steps[i],
              done: i < currentIndex,
              active: i == currentIndex,
            ),
            if (i < steps.length - 1)
              Container(
                width: 28,
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: i < currentIndex
                    ? const Color(0xFF62D57E)
                    : const Color(0xFFD9DFEB),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.index,
    required this.label,
    required this.done,
    required this.active,
  });

  final int index;
  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final fill = done
        ? const Color(0xFF20BE4D)
        : active
            ? TenantAdminColors.primary
            : Colors.white;
    final border = done
        ? const Color(0xFF20BE4D)
        : active
            ? TenantAdminColors.primary
            : const Color(0xFFCFD8E7);
    return Row(
      children: [
        Container(
          width: 31,
          height: 31,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fill,
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: Text(
            done ? '✓' : '$index',
            style: TextStyle(
              color: done || active ? Colors.white : const Color(0xFF95A1B2),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active
                ? TenantAdminColors.primary
                : done
                    ? const Color(0xFF314666)
                    : const Color(0xFF8390A6),
          ),
        ),
      ],
    );
  }
}

class InventorySuccessState extends StatelessWidget {
  const InventorySuccessState({
    super.key,
    required this.title,
    required this.message,
    this.details = const {},
    this.actions = const [],
  });

  final String title;
  final String message;
  final Map<String, String> details;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: InventorySectionCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border:
                          Border.all(color: const Color(0xFF18BB50), width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFFEFFDF4),
                          spreadRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check,
                        color: Color(0xFF18BB50), size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF65758D))),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    for (final e in details.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(e.key,
                                    style: const TextStyle(
                                        color: Color(0xFF64748B)))),
                            Flexible(
                              child: Text(e.value,
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(spacing: 10, runSpacing: 10, children: actions),
                  ],
                ],
              ),
            ),
          ),
        );
        if (constraints.maxHeight.isFinite) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: content,
            ),
          );
        }
        return SingleChildScrollView(child: content);
      },
    );
  }
}

class InventoryPrimaryButton extends StatelessWidget {
  const InventoryPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TenantAdminPrimaryButton(
      label: label,
      onPressed: onPressed,
    );
  }
}

class InventoryGhostButton extends StatelessWidget {
  const InventoryGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TenantAdminSecondaryButton(
      label: label,
      onPressed: onPressed,
    );
  }
}

class InventorySearchField extends StatelessWidget {
  const InventorySearchField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint = 'Search by name, SKU or barcode',
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TenantAdminSearchField(
      value: value,
      onChanged: onChanged,
      hint: hint,
    );
  }
}

class InventoryStatusBadge extends StatelessWidget {
  const InventoryStatusBadge({super.key, required this.label, this.tone});

  final String label;
  final String? tone;

  @override
  Widget build(BuildContext context) {
    final t = (tone ?? label).toLowerCase();
    TenantAdminStatusType status = TenantAdminStatusType.offline;

    if (t.contains('high') ||
        t.contains('out') ||
        t.contains('sold') ||
        t.contains('danger') ||
        t.contains('critical')) {
      status = TenantAdminStatusType.danger;
    } else if (t.contains('pending') ||
        t.contains('under review') ||
        t.contains('medium') ||
        t.contains('draft') ||
        t.contains('reserved') ||
        t.contains('warning')) {
      status = TenantAdminStatusType.warning;
    } else if (t.contains('low') && !t.contains('below')) {
      status = TenantAdminStatusType.pending;
    } else if (t.contains('posted') ||
        t.contains('received') ||
        t.contains('completed') ||
        t.contains('in stock') ||
        t.contains('success') ||
        t.contains('active')) {
      status = TenantAdminStatusType.success;
    } else if (t.contains('review') ||
        t.contains('blue') ||
        t.contains('online')) {
      status = TenantAdminStatusType.online;
    }

    return TenantAdminStatusBadge(
      label: label,
      status: status,
    );
  }
}
