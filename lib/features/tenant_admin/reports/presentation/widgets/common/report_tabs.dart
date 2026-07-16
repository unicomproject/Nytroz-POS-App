import 'package:flutter/material.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../utils/report_catalog.dart';

class ReportTabs extends StatelessWidget {
  const ReportTabs({
    super.key,
    required this.tabs,
    required this.selectedKey,
    required this.onSelected,
  });

  final List<ReportTabSpec> tabs;
  final String selectedKey;
  final ValueChanged<ReportTabSpec> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: TenantAdminColors.border),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final selected = tab.key == selectedKey;
            return Semantics(
              selected: selected,
              button: true,
              label: '${tab.label} report tab',
              child: InkWell(
                onTap: () => onSelected(tab),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected
                            ? TenantAdminColors.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      color: selected
                          ? TenantAdminColors.primary
                          : TenantAdminColors.mutedText,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
