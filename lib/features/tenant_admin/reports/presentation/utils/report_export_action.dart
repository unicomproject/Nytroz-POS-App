import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/report_query.dart';
import '../providers/report_providers.dart';

Future<void> requestReportExport(
  BuildContext context,
  WidgetRef ref, {
  required String reportType,
  required String format,
  required ReportQuery query,
}) async {
  try {
    final result = await ref
        .read(reportExportControllerProvider.notifier)
        .request(reportType: reportType, format: format, query: query);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export ${result.status.toLowerCase()}.')),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Report export is currently unavailable.')),
      );
    }
  }
}
