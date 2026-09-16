import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/network/dio_provider.dart';
import '../providers/hardware_scope_provider.dart';

class HardwareTestAllDialog extends ConsumerStatefulWidget {
  const HardwareTestAllDialog({super.key, required this.outletId});
  final String outletId;
  @override
  ConsumerState<HardwareTestAllDialog> createState() => _HardwareTestAllDialogState();
}
class _HardwareTestAllDialogState extends ConsumerState<HardwareTestAllDialog> {
  String? tillId, error;
  String requestId = const Uuid().v4();
  Map<String,dynamic>? batch;
  bool busy = false;
  Timer? timer;
  @override
  void dispose() { timer?.cancel(); super.dispose(); }
  Future<void> run({bool refresh = false}) async {
    if(busy || tillId == null) return;
    setState(() { busy = true; error = null; });
    try {
      final dio = ref.read(appDioProvider);
      final path = '/api/v1/tenant-admin/tills/$tillId/hardware-test-all';
      final response = refresh ? await dio.get('$path/${batch!['id']}') : await dio.post(path, data: {'requestId': requestId});
      if(!mounted) return;
      setState(() => batch = Map<String,dynamic>.from(response.data['data'] as Map));
      timer?.cancel();
      if(batch!['status'] != 'PASSED' && batch!['status'] != 'EXPIRED') timer = Timer(const Duration(seconds: 10), () => run(refresh: true));
    } catch(e) {
      if(mounted) setState(() => error = e is DioException && e.response?.data is Map ? (e.response!.data['message']?.toString() ?? 'Test request unavailable. Check access and POS assignment.') : 'Connection failed. Retry to recover the same request.');
    } finally { if(mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final tills = ref.watch(hardwareAssignableTillsProvider);
    final allowed = tills.isLoading || tills.hasError ? null : tills.valueOrNull?.where((t) => t.outletId == widget.outletId).toList();
    final eligible = allowed?.any((t) => t.id == tillId) == true;
    return AlertDialog(title: const Text('Test All Devices'), content: SizedBox(width: 560, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Send a test session to the assigned native POS. Open Hardware Testing there and run each test. Printer output, a barcode scan and drawer opening need operator confirmation. Requests expire after 10 minutes.'),
      const SizedBox(height: 16),
      if(tills.isLoading || busy) const LinearProgressIndicator(),
      if(tills.hasError) TextButton(onPressed: () => ref.invalidate(hardwareAssignableTillsProvider), child: const Text('Retry till access')),
      DropdownButtonFormField<String>(key: ValueKey(eligible ? tillId : null), initialValue: eligible ? tillId : null, isExpanded: true, decoration: const InputDecoration(labelText: 'Assigned till'), items: [for(final t in allowed ?? []) DropdownMenuItem<String>(value: t.id, child: Text('${t.name} (${t.code})'))], onChanged: busy || batch != null ? null : (v) => setState(() { tillId = v; requestId = const Uuid().v4(); })),
      if(batch != null) ...[
        const SizedBox(height: 16), Text('Session: ${batch!['status']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('Expires: ${DateTime.tryParse(batch!['expiresAt'].toString())?.toLocal()}'),
        for(final item in batch!['items'] as List) ListTile(contentPadding: EdgeInsets.zero, title: Text(item['name'].toString()), subtitle: Text(item['status'].toString())),
      ],
      if(error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Colors.red))),
    ]))), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')), FilledButton(onPressed: busy || !eligible ? null : () => run(refresh: batch != null), child: Text(batch == null ? 'Send Test All request' : 'Refresh results'))]);
  }
}
