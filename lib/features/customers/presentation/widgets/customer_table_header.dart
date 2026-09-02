import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CustomerTableHeader extends StatelessWidget {
  const CustomerTableHeader({
    super.key,
    this.showSecondaryColumns = true,
  });

  final bool showSecondaryColumns;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E6ED)),
        ),
      ),
      child: Row(
        children: showSecondaryColumns
            ? const [
                _HeaderCell('Customer ID', flex: 14),
                _HeaderCell('Customer', flex: 18, sortable: true),
                _HeaderCell('Phone', flex: 12),
                _HeaderCell('Email', flex: 18),
                _HeaderCell('Source', flex: 10),
                _HeaderCell('Status', flex: 10),
                _HeaderCell('Orders', flex: 10),
                _HeaderCell('Total Spend', flex: 12),
              ]
            : const [
                _HeaderCell('Customer', flex: 22, sortable: true),
                _HeaderCell('Phone', flex: 15),
                _HeaderCell('Email', flex: 22),
                _HeaderCell('Last Purchase', flex: 16),
                _HeaderCell('Total Spend', flex: 15),
                SizedBox(width: 48),
              ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
    this.label, {
    required this.flex,
    this.sortable = false,
  });

  final String label;
  final int flex;
  final bool sortable;

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      color: TenantAdminColors.posHomeAccentOrange,
      fontWeight: FontWeight.w800,
      fontSize: 13,
    );

    return Expanded(
      flex: flex,
      child: Row(
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: headerStyle,
            ),
          ),
          if (sortable) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.unfold_more_rounded,
              size: 16,
              color: TenantAdminColors.posHomeAccentOrange,
            ),
          ],
        ],
      ),
    );
  }
}
