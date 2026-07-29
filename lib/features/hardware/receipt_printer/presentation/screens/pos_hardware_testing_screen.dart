import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../config/local_print_agent_config.dart';
import '../../models/pos_device_printer_config.dart';
import '../../recovery/print_operation.dart';
import '../../recovery/print_operation_store.dart';
import '../../../../sale/presentation/providers/completed_sale_print_provider.dart';
import '../../../../sale/presentation/widgets/new_sale/pos_barcode_scanner_listener.dart';
import '../../../../sale/application/services/pos_hid_scanner_input_service.dart';
import '../../../barcode_scanner/presentation/providers/barcode_scanner_test_controller.dart';
import '../../../barcode_scanner/presentation/widgets/barcode_scanner_test_card.dart';
import '../providers/local_print_agent_controller.dart';
import '../widgets/hardware_capability_card.dart';

class PosHardwareTestingScreen extends ConsumerStatefulWidget {
  const PosHardwareTestingScreen({super.key});

  @override
  ConsumerState<PosHardwareTestingScreen> createState() =>
      _PosHardwareTestingScreenState();
}

class _PosHardwareTestingScreenState
    extends ConsumerState<PosHardwareTestingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _timeoutController = TextEditingController(text: '5000');
  final _printerNameController = TextEditingController();
  final _feedLinesController = TextEditingController(text: '5');
  final _changeReasonController = TextEditingController();
  final _customerCopyCountController = TextEditingController(text: '1');
  final _merchantCopyCountController = TextEditingController(text: '0');
  bool _configurationHydrated = false;
  bool _obscureApiKey = true;
  bool _enabled = true;
  bool _autoCutEnabled = true;
  PrinterPaperWidth _paperWidth = PrinterPaperWidth.mm80;
  bool _printCustomerCopy = true;
  bool _printMerchantCopy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(localPrintAgentControllerProvider.notifier).load();
      if (!mounted) return;
      _hydrateControllers(ref.read(localPrintAgentControllerProvider));
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    _timeoutController.dispose();
    _printerNameController.dispose();
    _feedLinesController.dispose();
    _changeReasonController.dispose();
    _customerCopyCountController.dispose();
    _merchantCopyCountController.dispose();
    super.dispose();
  }

  void _hydrateControllers(LocalPrintAgentState state) {
    if (_configurationHydrated || state.config == null) return;
    final config = state.config!;
    _urlController.text = config.agentBaseUrl ?? '';
    _timeoutController.text = '${config.connectionTimeoutMs}';
    _printerNameController.text = config.agentPrinterName ?? config.displayName;
    _feedLinesController.text = '${config.feedLinesBeforeCut}';
    _enabled = config.enabled;
    _autoCutEnabled = config.autoCutEnabled;
    _paperWidth = config.paperWidth;
    _printCustomerCopy = config.printCustomerCopy;
    _printMerchantCopy = config.printMerchantCopy;
    _customerCopyCountController.text = '${config.customerCopyCount}';
    _merchantCopyCountController.text = '${config.merchantCopyCount}';
    _configurationHydrated = true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localPrintAgentControllerProvider);
    final scannerState = ref.watch(barcodeScannerTestControllerProvider);
    _hydrateControllers(state);
    final savedKeyMask = maskLocalPrintAgentApiKey(state.config?.localApiKey);
    final warning = physicalAndroidLoopbackWarning(_urlController.text);

    return PosBarcodeScannerListener(
      enabled:
          scannerState.isListening && scannerState.settings.mode == 'usbHid',
      minimumBarcodeLength: scannerState.settings.minimumBarcodeLength,
      maximumInterKeyDelay:
          Duration(milliseconds: scannerState.settings.scanTimeout),
      onBarcodeScanned: ref
          .read(barcodeScannerTestControllerProvider.notifier)
          .acceptDetectedBarcode,
      onScanRejected: (reason, _) {
        final category = switch (reason) {
          PosHidScanRejection.incomplete => 'incomplete_scan',
          PosHidScanRejection.invalidLength => 'invalid_length',
          PosHidScanRejection.unsupportedCharacters => 'unsupported_characters',
        };
        ref.read(barcodeScannerTestControllerProvider.notifier).finalizeFailure(
              category: category,
              message: 'Scanner input was rejected safely.',
            );
      },
      child: ColoredBox(
        color: TenantAdminColors.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(TenantAdminSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Hardware Testing',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  Text(
                    'Configure the Windows Local Print Agent for this POS device.',
                    style: TenantAdminTextStyles.muted(context),
                  ),
                  if (state.authoritativeConfiguration != null) ...[
                    const SizedBox(height: TenantAdminSpacing.xs),
                    Text(
                      'Configuration version '
                      '${state.authoritativeConfiguration!.configurationVersion}'
                      '${state.authoritativeConfiguration!.activeShift ? ' · Active till session' : ''}',
                      style: TenantAdminTextStyles.muted(context),
                    ),
                  ],
                  const SizedBox(height: TenantAdminSpacing.lg),
                  LocalPrintAgentStatusCard(state: state),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: 'localPrintAgent',
                              decoration:
                                  const InputDecoration(labelText: 'Transport'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'localPrintAgent',
                                  child: Text('Local Print Agent'),
                                ),
                              ],
                              onChanged: state.isBusy || !state.backendAvailable
                                  ? null
                                  : (_) {},
                            ),
                            const SizedBox(height: TenantAdminSpacing.md),
                            TextFormField(
                              controller: _urlController,
                              enabled: !state.isBusy,
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                              decoration: InputDecoration(
                                labelText: 'Agent URL',
                                hintText: 'http://<laptop-lan-ip>:9101',
                                helperText: warning ??
                                    'Phone and laptop must use the same trusted private LAN.',
                                helperStyle: warning == null
                                    ? null
                                    : const TextStyle(
                                        color: TenantAdminColors.warning,
                                      ),
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) {
                                  return 'Agent URL is required.';
                                }
                                final uri = Uri.tryParse(text);
                                if (uri == null ||
                                    !uri.hasAuthority ||
                                    (uri.scheme != 'http' &&
                                        uri.scheme != 'https')) {
                                  return 'Enter a valid http or https URL.';
                                }
                                if (uri.path
                                    .toLowerCase()
                                    .endsWith('/api/print/receipt')) {
                                  return 'Enter only the agent base URL.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: TenantAdminSpacing.md),
                            TextFormField(
                              controller: _apiKeyController,
                              enabled: !state.isBusy,
                              obscureText: _obscureApiKey,
                              autocorrect: false,
                              enableSuggestions: false,
                              decoration: InputDecoration(
                                labelText: 'Local API key',
                                hintText: savedKeyMask.isEmpty
                                    ? 'At least 24 characters'
                                    : 'Saved key: $savedKeyMask',
                                helperText: savedKeyMask.isEmpty
                                    ? 'Stored securely for this activated device.'
                                    : 'Leave blank to keep the saved key.',
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscureApiKey = !_obscureApiKey,
                                  ),
                                  icon: Icon(
                                    _obscureApiKey
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                final newValue = value ?? '';
                                if (newValue.isEmpty &&
                                    state.config?.localApiKey != null) {
                                  return null;
                                }
                                if (newValue.length <
                                    localPrintAgentMinimumApiKeyLength) {
                                  return 'API key must contain at least 24 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: TenantAdminSpacing.md),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Printer enabled'),
                              subtitle: const Text(
                                'Disabled configurations cannot run hardware tests.',
                              ),
                              value: _enabled,
                              onChanged: state.isBusy || !state.backendAvailable
                                  ? null
                                  : (value) => setState(() => _enabled = value),
                            ),
                            const SizedBox(height: TenantAdminSpacing.sm),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final fields = [
                                  TextFormField(
                                    controller: _timeoutController,
                                    enabled: !state.isBusy,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Request timeout (ms)',
                                      helperText: '1,000–30,000 ms',
                                    ),
                                    validator: (value) {
                                      final timeout =
                                          int.tryParse(value?.trim() ?? '');
                                      if (timeout == null ||
                                          timeout <
                                              localPrintAgentMinimumTimeoutMs ||
                                          timeout >
                                              localPrintAgentMaximumTimeoutMs) {
                                        return 'Use 1000–30000.';
                                      }
                                      return null;
                                    },
                                  ),
                                  TextFormField(
                                    controller: _printerNameController,
                                    enabled: !state.isBusy,
                                    decoration: const InputDecoration(
                                      labelText: 'Windows printer name',
                                    ),
                                  ),
                                ];
                                if (constraints.maxWidth < 620) {
                                  return Column(
                                    children: [
                                      fields[0],
                                      const SizedBox(
                                        height: TenantAdminSpacing.md,
                                      ),
                                      fields[1],
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(child: fields[0]),
                                    const SizedBox(
                                        width: TenantAdminSpacing.md),
                                    Expanded(child: fields[1]),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: TenantAdminSpacing.md),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final fields = [
                                  DropdownButtonFormField<PrinterPaperWidth>(
                                    initialValue: _paperWidth,
                                    decoration: const InputDecoration(
                                      labelText: 'Paper width',
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: PrinterPaperWidth.mm80,
                                        child: Text('80 mm'),
                                      ),
                                      DropdownMenuItem(
                                        value: PrinterPaperWidth.mm58,
                                        child: Text('58 mm'),
                                      ),
                                    ],
                                    onChanged:
                                        state.isBusy || !state.backendAvailable
                                            ? null
                                            : (value) => setState(
                                                  () => _paperWidth = value ??
                                                      PrinterPaperWidth.mm80,
                                                ),
                                  ),
                                  TextFormField(
                                    controller: _feedLinesController,
                                    enabled:
                                        !state.isBusy && state.backendAvailable,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Feed lines before cut',
                                      helperText: '0–10 lines',
                                    ),
                                    validator: (value) {
                                      final feed =
                                          int.tryParse(value?.trim() ?? '');
                                      if (feed == null ||
                                          feed < 0 ||
                                          feed > 10) {
                                        return 'Use 0–10.';
                                      }
                                      return null;
                                    },
                                  ),
                                ];
                                return constraints.maxWidth < 620
                                    ? Column(
                                        children: [
                                          fields[0],
                                          const SizedBox(
                                            height: TenantAdminSpacing.md,
                                          ),
                                          fields[1],
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(child: fields[0]),
                                          const SizedBox(
                                            width: TenantAdminSpacing.md,
                                          ),
                                          Expanded(child: fields[1]),
                                        ],
                                      );
                              },
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Automatic paper cut'),
                              value: _autoCutEnabled,
                              onChanged: state.isBusy || !state.backendAvailable
                                  ? null
                                  : (value) =>
                                      setState(() => _autoCutEnabled = value),
                            ),
                            const SizedBox(height: TenantAdminSpacing.sm),
                            Text(
                              'Receipt copy policy',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Print customer copy'),
                              value: _printCustomerCopy,
                              onChanged: state.isBusy || !state.backendAvailable
                                  ? null
                                  : (value) => setState(
                                        () => _printCustomerCopy = value,
                                      ),
                            ),
                            TextFormField(
                              controller: _customerCopyCountController,
                              enabled: !state.isBusy &&
                                  state.backendAvailable &&
                                  _printCustomerCopy,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Customer copy count',
                                helperText: '1–5 when enabled',
                              ),
                              validator: (value) => _validateCopyCount(
                                value,
                                enabled: _printCustomerCopy,
                              ),
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Print merchant copy'),
                              subtitle: const Text(
                                'Merchant copies are visibly labelled and audited independently.',
                              ),
                              value: _printMerchantCopy,
                              onChanged: state.isBusy || !state.backendAvailable
                                  ? null
                                  : (value) => setState(
                                        () => _printMerchantCopy = value,
                                      ),
                            ),
                            TextFormField(
                              controller: _merchantCopyCountController,
                              enabled: !state.isBusy &&
                                  state.backendAvailable &&
                                  _printMerchantCopy,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Merchant copy count',
                                helperText: '1–5 when enabled',
                              ),
                              validator: (value) => _validateCopyCount(
                                value,
                                enabled: _printMerchantCopy,
                              ),
                            ),
                            if (state.authoritativeConfiguration?.activeShift ==
                                true) ...[
                              const SizedBox(height: TenantAdminSpacing.sm),
                              TextFormField(
                                controller: _changeReasonController,
                                enabled:
                                    !state.isBusy && state.backendAvailable,
                                decoration: const InputDecoration(
                                  labelText: 'Active-shift change reason',
                                  helperText:
                                      'Required for critical configuration changes during an active till session.',
                                ),
                                validator: (value) {
                                  if (state.authoritativeConfiguration
                                              ?.activeShift ==
                                          true &&
                                      state.authoritativeConfiguration !=
                                          null &&
                                      (value?.trim().isEmpty ?? true)) {
                                    return 'Enter the reason for this active-shift change.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: TenantAdminSpacing.lg),
                            Wrap(
                              spacing: TenantAdminSpacing.sm,
                              runSpacing: TenantAdminSpacing.sm,
                              children: [
                                FilledButton.icon(
                                  onPressed:
                                      state.isBusy || !state.backendAvailable
                                          ? null
                                          : _save,
                                  icon: const Icon(Icons.save_outlined),
                                  label: const Text('Save configuration'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: state.config == null ||
                                          state.isBusy
                                      ? null
                                      : () => ref
                                          .read(
                                              localPrintAgentControllerProvider
                                                  .notifier)
                                          .checkConnection(),
                                  icon:
                                      const Icon(Icons.wifi_tethering_rounded),
                                  label: const Text('Test connection'),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: state.config == null ||
                                          state.isBusy
                                      ? null
                                      : () => ref
                                          .read(
                                              localPrintAgentControllerProvider
                                                  .notifier)
                                          .printTestReceipt(),
                                  icon: const Icon(Icons.print_outlined),
                                  label: const Text('Print test receipt'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  const Text(
                    'The test receipt is labelled “PRINTER TEST - NOT A SALE”. '
                    'It does not create a sale, payment, receipt record or print audit.',
                  ),
                  if (state.pendingPhysicalTest != null) ...[
                    const SizedBox(height: TenantAdminSpacing.md),
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(TenantAdminSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Physical confirmation required',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: TenantAdminSpacing.xs),
                            const Text(
                              'Windows accepted the test request. Confirm whether '
                              'the complete “PRINTER TEST - NOT A SALE” paper printed.',
                            ),
                            const SizedBox(height: TenantAdminSpacing.sm),
                            Wrap(
                              spacing: TenantAdminSpacing.sm,
                              children: [
                                OutlinedButton(
                                  onPressed: state.isBusy
                                      ? null
                                      : () => ref
                                          .read(
                                              localPrintAgentControllerProvider
                                                  .notifier)
                                          .confirmPhysicalPrint(false),
                                  child: const Text('Not printed'),
                                ),
                                FilledButton(
                                  onPressed: state.isBusy
                                      ? null
                                      : () => ref
                                          .read(
                                              localPrintAgentControllerProvider
                                                  .notifier)
                                          .confirmPhysicalPrint(true),
                                  child: const Text('Printed correctly'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: TenantAdminSpacing.md),
                  const BarcodeScannerTestCard(),
                  const SizedBox(height: TenantAdminSpacing.sm),
                  const HardwareCapabilityCard(
                    title: 'Cash drawer',
                    message:
                        'Not Implemented — no ESC/POS drawer pulse is sent.',
                    icon: Icons.point_of_sale_outlined,
                  ),
                  const SizedBox(height: TenantAdminSpacing.sm),
                  const HardwareCapabilityCard(
                    title: 'Card terminal',
                    message:
                        'Blocked — provider/device not configured. No fake payment is created.',
                    icon: Icons.credit_card_off_outlined,
                  ),
                  if (state.testHistory.isNotEmpty) ...[
                    const SizedBox(height: TenantAdminSpacing.lg),
                    Text(
                      'Recent hardware tests',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    ...state.testHistory.take(5).map(
                          (test) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(test.status),
                            subtitle: Text(
                              test.safeMessage ??
                                  test.resultCategory ??
                                  'No safe result message.',
                            ),
                            trailing: test.physicalConfirmation == true
                                ? const Icon(Icons.verified_rounded)
                                : const Icon(Icons.memory_rounded),
                          ),
                        ),
                  ],
                  const SizedBox(height: TenantAdminSpacing.lg),
                  const _PrintRecoveryCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final errors =
        await ref.read(localPrintAgentControllerProvider.notifier).save(
              agentBaseUrl: _urlController.text,
              apiKey: _apiKeyController.text,
              timeoutMs: int.parse(_timeoutController.text.trim()),
              printerName: _printerNameController.text,
              enabled: _enabled,
              paperWidth: _paperWidth,
              autoCutEnabled: _autoCutEnabled,
              feedLinesBeforeCut: int.parse(_feedLinesController.text.trim()),
              changeReason: _changeReasonController.text,
              printCustomerCopy: _printCustomerCopy,
              customerCopyCount:
                  int.tryParse(_customerCopyCountController.text.trim()) ?? 0,
              printMerchantCopy: _printMerchantCopy,
              merchantCopyCount:
                  int.tryParse(_merchantCopyCountController.text.trim()) ?? 0,
            );
    if (!mounted) return;
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.join('\n'))),
      );
      return;
    }
    _apiKeyController.clear();
    setState(() {});
  }

  String? _validateCopyCount(String? value, {required bool enabled}) {
    final count = int.tryParse(value?.trim() ?? '');
    if (!enabled && (count == null || count == 0)) return null;
    if (count == null || count < 1 || count > 5) {
      return 'Use 1–5 when enabled.';
    }
    return null;
  }
}

class _PrintRecoveryCard extends ConsumerStatefulWidget {
  const _PrintRecoveryCard();

  @override
  ConsumerState<_PrintRecoveryCard> createState() => _PrintRecoveryCardState();
}

class _PrintRecoveryCardState extends ConsumerState<_PrintRecoveryCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        child: FutureBuilder<List<PrintOperation>>(
          future: ref.read(printOperationStoreProvider).load(),
          builder: (context, snapshot) {
            final operations = (snapshot.data ?? const <PrintOperation>[])
                .where((item) =>
                    item.state != PrintOperationState.completed &&
                    item.state != PrintOperationState.cancelled)
                .toList()
              ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Receipt print recovery',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh operations',
                      onPressed: () async {
                        await ref
                            .read(completedSalePrintProvider.notifier)
                            .recoverPendingOperations();
                        if (mounted) setState(() {});
                      },
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                if (operations.isEmpty)
                  const Text('No unresolved receipt print operations.')
                else
                  ...operations.map(
                    (operation) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(operation.receipt.receiptNumber),
                      subtitle: Text(
                        '${operation.state.name} · request ${operation.printRequestId}',
                      ),
                      trailing: operation.state ==
                                  PrintOperationState.printOutcomeUnknown ||
                              operation.state ==
                                  PrintOperationState.requiresOperatorDecision
                          ? Wrap(
                              spacing: TenantAdminSpacing.xs,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    await ref
                                        .read(
                                            completedSalePrintProvider.notifier)
                                        .confirmNotPrinted(operation);
                                    if (mounted) setState(() {});
                                  },
                                  child: const Text('Not printed'),
                                ),
                                FilledButton.tonal(
                                  onPressed: () async {
                                    await ref
                                        .read(
                                            completedSalePrintProvider.notifier)
                                        .confirmPrinted(operation);
                                    if (mounted) setState(() {});
                                  },
                                  child: const Text('Printed'),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                const SizedBox(height: TenantAdminSpacing.sm),
                const Text(
                  'Unknown outcomes never auto-print again. Confirm the physical '
                  'result here; use Receipt History for a controlled reprint.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class LocalPrintAgentStatusCard extends StatelessWidget {
  const LocalPrintAgentStatusCard({required this.state, super.key});

  final LocalPrintAgentState state;

  @override
  Widget build(BuildContext context) {
    final (icon, color, title) = switch (state.status) {
      LocalPrintAgentUiStatus.notConfigured => (
          Icons.settings_ethernet_rounded,
          TenantAdminColors.mutedText,
          'Not configured'
        ),
      LocalPrintAgentUiStatus.saving ||
      LocalPrintAgentUiStatus.checking ||
      LocalPrintAgentUiStatus.printing =>
        (Icons.sync_rounded, TenantAdminColors.info, 'Working'),
      LocalPrintAgentUiStatus.printerReady => (
          Icons.check_circle_rounded,
          TenantAdminColors.success,
          'Printer ready'
        ),
      LocalPrintAgentUiStatus.reachable => (
          Icons.lan_rounded,
          TenantAdminColors.warning,
          'Agent reachable'
        ),
      LocalPrintAgentUiStatus.printerOffline => (
          Icons.print_disabled_outlined,
          TenantAdminColors.warning,
          'Printer offline'
        ),
      LocalPrintAgentUiStatus.unreachable => (
          Icons.cloud_off_outlined,
          TenantAdminColors.danger,
          'Agent unreachable'
        ),
      LocalPrintAgentUiStatus.authenticationFailed => (
          Icons.key_off_outlined,
          TenantAdminColors.danger,
          'Authentication failed'
        ),
      LocalPrintAgentUiStatus.invalidResponse => (
          Icons.data_object_rounded,
          TenantAdminColors.danger,
          'Agent response invalid'
        ),
      LocalPrintAgentUiStatus.printSuccessful => (
          Icons.task_alt_rounded,
          TenantAdminColors.success,
          'Print successful'
        ),
      LocalPrintAgentUiStatus.printFailed => (
          Icons.error_outline_rounded,
          TenantAdminColors.danger,
          'Print failed'
        ),
      _ => (Icons.print_outlined, TenantAdminColors.info, 'Local Print Agent'),
    };
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(state.message),
                if (state.health != null)
                  Text(
                    'Printer: ${state.health!.printerName}',
                    style: TenantAdminTextStyles.muted(context),
                  ),
              ],
            ),
          ),
          if (state.isBusy)
            const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}
