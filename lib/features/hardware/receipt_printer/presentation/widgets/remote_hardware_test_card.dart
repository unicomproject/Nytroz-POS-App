import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../../device_activation/presentation/providers/device_activation_provider.dart';

final remoteHardwareTestsProvider = FutureProvider.autoDispose<List<Map<String,dynamic>>>((ref) async {
  final pos = ref.watch(deviceActivationProvider).deviceContext?.deviceId;
  if(pos == null || pos.isEmpty) return [];
  final response = await ref.watch(appDioProvider).get('/api/v1/pos/hardware/remote-tests', queryParameters: {'posDeviceId': pos});
  final timer = Timer(const Duration(seconds: 10), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return (response.data['data'] as List).map((e) => Map<String,dynamic>.from(e as Map)).toList();
});

class RemoteHardwareTestCard extends ConsumerWidget {
  const RemoteHardwareTestCard({super.key, required this.openTest});
  final void Function(String type) openTest;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(remoteHardwareTestsProvider).when(
    loading: () => const LinearProgressIndicator(),
    error: (_, __) => TextButton(onPressed: () => ref.invalidate(remoteHardwareTestsProvider), child: const Text('Retry remote test requests')),
    data: (batches) => batches.isEmpty ? const SizedBox.shrink() : Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Tenant Admin Test All request', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const Text('Run each requested test below and confirm the physical result. Results refresh automatically; opening a test does not report success.'),
      for(final batch in batches) ...[
        Text('Status: ${batch['status']}'),
        for(final item in batch['items'] as List) ListTile(title: Text(item['name'].toString()), subtitle: Text(item['status'].toString()), trailing: TextButton(
          onPressed: ['WAITING_FOR_POS','PENDING','FAILED','CONFIRMATION_REQUIRED'].contains(item['status']) ? () => openTest(item['type'].toString().replaceAll('_','').toLowerCase()) : null,
          child: const Text('Open test'),
        )),
      ],
    ]))),
  );
}
