import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CustomerTableHeader extends StatelessWidget {
  const CustomerTableHeader({
    super.key,
    required this.showSecondaryColumns,
  });

  final bool showSecondaryColumns;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: TenantAdminColors.mutedText,
          fontWeight: FontWeight.w800,
        );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: TenantAdminColors.border),
        ),
      ),
      child: Row(
        children: [
          _HeaderCell('Customer ID', flex: 14, style: style),
          _HeaderCell('Customer Name', flex: 18, style: style),
          _HeaderCell('Phone', flex: 12, style: style),
          if (showSecondaryColumns)
            _HeaderCell('Email', flex: 18, style: style),
          if (showSecondaryColumns)
            _HeaderCell('Source', flex: 10, style: style),
          _HeaderCell('Status', flex: 10, style: style),
          if (showSecondaryColumns)
            _HeaderCell('Total Orders', flex: 10, style: style),
          if (showSecondaryColumns)
            _HeaderCell('Total Spent', flex: 12, style: style),
          _HeaderCell('Action', flex: 8, style: style, alignEnd: true),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
    this.label, {
    required this.flex,
    required this.style,
    this.alignEnd = false,
  });

  final String label;
  final int flex;
  final TextStyle? style;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
