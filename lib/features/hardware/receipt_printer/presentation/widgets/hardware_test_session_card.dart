import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../device_configuration/models/pos_hardware_models.dart';
import '../providers/local_print_agent_controller.dart';

String sessionTestStatus(PosHardwareConfiguration config,
    List<HardwareTestOperation> history, Set<String> previousIds) {
  final expected = switch (config.hardwareType.toLowerCase()) {
    'receiptprinter' => {'testprint'},
    'barcodescanner' => {'hidinput', 'camerascan'},
    'cashdrawer' => {'drawerpulse'},
    _ => <String>{},
  };
  if (expected.isEmpty) return 'Unsupported';
  final matches = history
      .where((h) =>
          !previousIds.contains(h.testId) &&
          h.hardwareType.toLowerCase() == config.hardwareType.toLowerCase() &&
          h.configurationVersion == config.configurationVersion &&
          expected.contains(h.testType.toLowerCase()))
      .toList()
    ..sort((a, b) => (b.initiatedAt ?? DateTime(1970))
        .compareTo(a.initiatedAt ?? DateTime(1970)));
  if (matches.isEmpty) return 'Not tested';
  final latest = matches.first;
  if (latest.status.toLowerCase() == 'passed') {
    return latest.physicalConfirmation == true && latest.completedAt != null
        ? 'Passed'
        : 'Confirmation required';
  }
  return latest.status;
}

/// Coordinates existing POS tests; never sends commands from Tenant Admin.
class HardwareTestSessionCard extends ConsumerStatefulWidget {
  const HardwareTestSessionCard({super.key, required this.openTest});
  final void Function(String type) openTest;
  @override
  ConsumerState<HardwareTestSessionCard> createState() =>
      _HardwareTestSessionCardState();
}

class _HardwareTestSessionCardState
    extends ConsumerState<HardwareTestSessionCard> {
  List<PosHardwareConfiguration> configs = [];
  List<HardwareTestOperation> history = [];
  Set<String> previousIds = {};
  String? deviceId, message;
  bool busy = false, active = false;
  Future<void> refresh({bool start = false}) async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final current =
          ref.read(deviceActivationProvider).deviceContext?.deviceId;
      if (current == null ||
          current.isEmpty ||
          (!start && current != deviceId)) {
        throw StateError(
            'Activate the assigned POS before starting a session.');
      }
      final repository = ref.read(posHardwareRepositoryProvider);
      final fresh = (await repository.getConfigurations(current))
          .where((c) => c.enabled)
          .toList();
      final logs = await repository.getHistory(current);
      if (!mounted) return;
      if (!start &&
          (fresh.length != configs.length ||
              fresh.any((c) => !configs.any((old) =>
                  old.configurationId == c.configurationId &&
                  old.configurationVersion == c.configurationVersion)))) {
        setState(() {
          active = false;
          message = 'Configuration changed. Start a new test session.';
        });
        return;
      }
      setState(() {
        configs = fresh;
        history = logs;
        deviceId = current;
        if (start) previousIds = logs.map((h) => h.testId).toSet();
        active = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          active = false;
          message =
              'Unable to verify session. Check device activation, hardware access and API connection.';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(deviceActivationProvider).deviceContext?.deviceId;
    final valid = active && current == deviceId;
    final passed = valid
        ? configs
            .where(
                (c) => sessionTestStatus(c, history, previousIds) == 'Passed')
            .length
        : 0;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Test All — guided POS session',
                    style: Theme.of(context).textTheme.titleLarge),
                const Text(
                    'Run each configured device test below, confirm the observed result, then refresh. Tests run on this POS. Starting a session does not print or open the drawer.'),
                if (message != null) Text(message!),
                if (busy) const LinearProgressIndicator(),
                Wrap(spacing: 12, children: [
                  FilledButton(
                      onPressed: busy ? null : () => refresh(start: true),
                      child: Text(
                          active ? 'Start new session' : 'Start Test All')),
                  OutlinedButton(
                      onPressed: busy || !valid ? null : refresh,
                      child: const Text('Refresh results')),
                ]),
                if (valid) ...[
                  Text(configs.isEmpty
                      ? 'No enabled hardware configured.'
                      : '$passed of ${configs.length} configured devices passed'),
                  for (final config in configs)
                    ListTile(
                      title: Text(config.displayName),
                      subtitle: Text(
                          '${sessionTestStatus(config, history, previousIds)} · Version ${config.configurationVersion}'),
                      trailing: TextButton(
                          onPressed: busy ||
                                  !{
                                    'receiptprinter',
                                    'barcodescanner',
                                    'cashdrawer'
                                  }.contains(config.hardwareType.toLowerCase())
                              ? null
                              : () => widget
                                  .openTest(config.hardwareType.toLowerCase()),
                          child: const Text('Open test')),
                    ),
                  if (configs.isNotEmpty && passed == configs.length)
                    const Text(
                        'All configured device tests confirmed in this session.'),
                ],
              ],
            )));
  }
}
