import 'package:flutter/material.dart';

import '../../../domain/entities/tenant_admin_context.dart';
import '../../domain/entities/report_models.dart';
import '../providers/report_providers.dart';

List<ReportFilterOption> reportOutletOptions(TenantAdminContext? context) {
  return context?.outletScope
          .map(
            (outlet) => ReportFilterOption(
              id: outlet.outletId,
              code: '',
              name: outlet.outletName,
              status: 'ACTIVE',
              isActive: true,
            ),
          )
          .toList() ??
      const [];
}

void autoSelectSingleReportOutlet(
  List<ReportFilterOption> outlets,
  String? selectedOutletId,
  ReportQueryNotifier notifier,
) {
  if (outlets.length == 1 && selectedOutletId == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.setOutlet(outlets.first.id);
    });
  }
}
