import 'package:flutter/material.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/till.dart';
import 'till_list_row.dart';
import 'till_mobile_list.dart';

class TillListView extends StatelessWidget {
  const TillListView({
    super.key,
    required this.result,
    required this.visibility,
    required this.isMobile,
  });

  final TillListResult result;
  final TillListVisibility visibility;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        child: TillMobileList(
          tills: result.items,
          visibility: visibility,
        ),
      );
    }

    return Column(
      children: [
        for (final till in result.items) ...[
          TillListRow(
            till: till,
            visibility: visibility,
          ),
          if (till != result.items.last)
            const Divider(height: 1, color: TenantAdminColors.border),
        ],
      ],
    );
  }
}
