import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../presentation/providers/tenant_admin_context_provider.dart';

final hardwareTestHistoryProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, id) async {
  await ref.watch(tenantAdminContextProvider.future);
  final response = await ref.watch(appDioProvider).get(
      '/api/v1/tenant-admin/hardware-devices/${Uri.encodeComponent(id)}/test-history');
  final data = response.data;
  if (data is! Map || data['data'] is! Map || data['data']['items'] is! List) {
    throw StateError('Test history is unavailable');
  }
  return (data['data']['items'] as List)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
});

class HardwareTestHistory extends ConsumerWidget {
  const HardwareTestHistory(
      {super.key, required this.hardwareId, required this.name});
  final String hardwareId, name;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = hardwareTestHistoryProvider(hardwareId);
    final history = ref.watch(provider);
    String time(dynamic value) =>
        DateTime.tryParse(value?.toString() ?? '')
            ?.toLocal()
            .toString()
            .split('.')
            .first ??
        'Not reported';
    return AlertDialog(
      title: Text('Test history: $name'),
      content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: history.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text(
                  'Unable to load test history. Check access and retry.'),
              data: (items) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Latest 50 records within your hardware access scope. Recorded results do not establish current connectivity.'),
                    const SizedBox(height: 16),
                    if (items.isEmpty) const Text('No test results recorded.'),
                    for (final item in items)
                      Card(
                          child: ListTile(
                        title:
                            Text('${item['testType']} — ${item['testStatus']}'),
                        subtitle: Text('Tested: ${time(item['testedAt'])}\n'
                            'Completed: ${time(item['completedAt'])}\n'
                            'Configuration version: ${item['configurationVersion']}\n'
                            'Physical confirmation: ${item['physicalConfirmation'] == true ? 'Confirmed' : item['physicalConfirmation'] == false ? 'Not confirmed' : 'Not reported'}'),
                      )),
                  ]),
            ),
          )),
      actions: [
        TextButton(
            onPressed: () => showDialog<void>(
                context: context,
                builder: (_) =>
                    HardwareActivityHistory(hardwareId: hardwareId)),
            child: const Text('Device activity')),
        TextButton(
            onPressed:
                history.isLoading ? null : () => ref.invalidate(provider),
            child: const Text('Refresh')),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
      ],
    );
  }
}

final hardwareActivityProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, id) async {
  await ref.watch(tenantAdminContextProvider.future);
  final response = await ref.watch(appDioProvider).get(
      '/api/v1/tenant-admin/hardware-devices/${Uri.encodeComponent(id)}/activity');
  return (response.data['data']['items'] as List)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
});

class HardwareActivityHistory extends ConsumerWidget {
  const HardwareActivityHistory({super.key, required this.hardwareId});
  final String hardwareId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = hardwareActivityProvider(hardwareId);
    final activity = ref.watch(provider);
    return AlertDialog(
      title: const Text('Device activity'),
      content: SizedBox(
          width: 650,
          child: SingleChildScrollView(
              child: activity.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) =>
                const Text('Activity unavailable. Check access and retry.'),
            data: (items) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      'Latest 50 available creation, assignment, release and configuration records within your access scope.'),
                  if (items.isEmpty)
                    const Text('No activity records available.'),
                  for (final item in items)
                    ListTile(
                      title: Text('${item['action']}'.replaceAll('_', ' ')),
                      subtitle: Text(
                          '${DateTime.tryParse('${item['occurredAt']}')?.toLocal() ?? 'Time unavailable'}'
                          '${item['configurationVersion'] == null ? '' : '\nConfiguration version: ${item['configurationVersion']}'}'),
                    ),
                ]),
          ))),
      actions: [
        TextButton(
            onPressed:
                activity.isLoading ? null : () => ref.invalidate(provider),
            child: const Text('Refresh')),
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Close'))
      ],
    );
  }
}
