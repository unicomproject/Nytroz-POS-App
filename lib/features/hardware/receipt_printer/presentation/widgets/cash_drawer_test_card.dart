import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/cash_drawer_controller.dart';
import '../providers/local_print_agent_controller.dart';

class CashDrawerTestCard extends ConsumerStatefulWidget {
  const CashDrawerTestCard({super.key});

  @override
  ConsumerState<CashDrawerTestCard> createState() => _CashDrawerTestCardState();
}

class _CashDrawerTestCardState extends ConsumerState<CashDrawerTestCard> {
  final _pulseOn = TextEditingController(text: '100');
  final _pulseOff = TextEditingController(text: '200');
  final _reason = TextEditingController();
  final _manualReason = TextEditingController();
  bool _hydrated = false;
  bool _enabled = true;
  bool _openOnCashSale = true;
  bool _openOnCashRefund = true;
  bool _openOnCashSplit = true;
  bool _manualOpenEnabled = true;
  String _drawerPort = 'drawerPin2';
  String _policy = 'approvalRequired';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cashDrawerControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _pulseOn.dispose();
    _pulseOff.dispose();
    _reason.dispose();
    _manualReason.dispose();
    super.dispose();
  }

  void _hydrate(CashDrawerState state) {
    if (_hydrated || state.config == null) return;
    _pulseOn.text = '${state.config!.pulseOnMilliseconds}';
    _pulseOff.text = '${state.config!.pulseOffMilliseconds}';
    _enabled = state.config!.enabled;
    _openOnCashSale = state.config!.openOnCashSale;
    _openOnCashRefund = state.config!.openOnCashRefund;
    _openOnCashSplit = state.config!.openOnCashSplit;
    _manualOpenEnabled = state.config!.manualOpenEnabled;
    _drawerPort = state.config!.drawerPort;
    _policy = state.config!.policy;
    _hydrated = true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cashDrawerControllerProvider);
    final printerState = ref.watch(localPrintAgentControllerProvider);
    _hydrate(state);

    final linkedPrinterId =
        printerState.authoritativeConfiguration?.configurationId;
    final linkedPrinterName =
        printerState.authoritativeConfiguration?.displayName ?? 'None';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.point_of_sale_outlined),
                const SizedBox(width: TenantAdminSpacing.sm),
                Expanded(
                  child: Text(
                    'Cash drawer',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                if (state.authoritativeConfiguration != null)
                  Text(
                      'v${state.authoritativeConfiguration!.configurationVersion}'),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.xs),
            Text(state.message),
            const SizedBox(height: TenantAdminSpacing.md),
            if (linkedPrinterId == null) ...[
              Container(
                padding: const EdgeInsets.all(TenantAdminSpacing.md),
                decoration: BoxDecoration(
                  color: TenantAdminColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
                child: const Text(
                  'Please configure and enable the Receipt Printer first before setting up the Cash Drawer.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.md),
            ],
            Wrap(
              spacing: TenantAdminSpacing.md,
              runSpacing: TenantAdminSpacing.md,
              children: [
                SizedBox(
                  width: 260,
                  child: DropdownButtonFormField<String>(
                    initialValue: _drawerPort,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Drawer port'),
                    items: const [
                      DropdownMenuItem(
                          value: 'drawerPin2', child: Text('Pin 2 (Standard)')),
                      DropdownMenuItem(
                          value: 'drawerPin5', child: Text('Pin 5')),
                    ],
                    onChanged: state.isBusy || linkedPrinterId == null
                        ? null
                        : (val) =>
                            setState(() => _drawerPort = val ?? 'drawerPin2'),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: TextFormField(
                    controller: _pulseOn,
                    enabled: !state.isBusy && linkedPrinterId != null,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pulse ON duration',
                      helperText: '2–510 ms',
                    ),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: TextFormField(
                    controller: _pulseOff,
                    enabled: !state.isBusy && linkedPrinterId != null,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pulse OFF duration',
                      helperText: '2–510 ms',
                    ),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _policy,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Open drawer policy'),
                        items: const [
                          DropdownMenuItem(
                              value: 'never',
                              child: Text(
                                'Never (no manager approval)',
                                overflow: TextOverflow.ellipsis,
                              )),
                          DropdownMenuItem(
                              value: 'always',
                              child: Text('Always (No sale)')),
                          DropdownMenuItem(
                              value: 'approvalRequired',
                              child: Text(
                                'Manager approval required',
                                overflow: TextOverflow.ellipsis,
                              )),
                        ],
                        onChanged: state.isBusy || linkedPrinterId == null
                            ? null
                            : (val) => setState(
                                () => _policy = val ?? 'approvalRequired'),
                      ),
                      const SizedBox(height: TenantAdminSpacing.xs),
                      Text(
                        'Policy controls manager approval for manual open. '
                        'Automatic cash/split/refund open uses the toggles below.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: TenantAdminColors.mutedText,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            Text(
              'Linked Printer: $linkedPrinterName',
              style: TenantAdminTextStyles.muted(context),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cash drawer enabled'),
              value: _enabled,
              onChanged: state.isBusy || linkedPrinterId == null
                  ? null
                  : (val) => setState(() => _enabled = val),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Open on cash sale'),
              value: _openOnCashSale,
              onChanged: state.isBusy || linkedPrinterId == null
                  ? null
                  : (val) => setState(() => _openOnCashSale = val),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Open on cash refund'),
              value: _openOnCashRefund,
              onChanged: state.isBusy || linkedPrinterId == null
                  ? null
                  : (val) => setState(() => _openOnCashRefund = val),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Open on split cash sale'),
              value: _openOnCashSplit,
              onChanged: state.isBusy || linkedPrinterId == null
                  ? null
                  : (val) => setState(() => _openOnCashSplit = val),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Manual no-sale open enabled'),
              value: _manualOpenEnabled,
              onChanged: state.isBusy || linkedPrinterId == null
                  ? null
                  : (val) => setState(() => _manualOpenEnabled = val),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            TextFormField(
              controller: _reason,
              enabled: !state.isBusy && linkedPrinterId != null,
              decoration: const InputDecoration(
                labelText: 'Change reason',
                helperText: 'Required to save configuration changes',
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: state.isBusy || linkedPrinterId == null
                        ? null
                        : () async {
                            final errors = await ref
                                .read(cashDrawerControllerProvider.notifier)
                                .save(
                                  linkedReceiptPrinterId: linkedPrinterId,
                                  drawerPort: _drawerPort,
                                  pulseOnMilliseconds:
                                      int.tryParse(_pulseOn.text.trim()) ?? 100,
                                  pulseOffMilliseconds:
                                      int.tryParse(_pulseOff.text.trim()) ??
                                          200,
                                  policy: _policy,
                                  openOnCashSale: _openOnCashSale,
                                  openOnCashRefund: _openOnCashRefund,
                                  openOnCashSplit: _openOnCashSplit,
                                  manualOpenEnabled: _manualOpenEnabled,
                                  enabled: _enabled,
                                  changeReason: _reason.text,
                                );
                            if (errors.isNotEmpty && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(errors.join('\n'))),
                              );
                            } else {
                              _reason.clear();
                            }
                          },
                    child: const Text('Save configuration'),
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: state.isBusy ||
                            state.config?.enabled != true ||
                            linkedPrinterId == null
                        ? null
                        : () => ref
                            .read(cashDrawerControllerProvider.notifier)
                            .testPulse(),
                    child: const Text('Test drawer pulse'),
                  ),
                ),
              ],
            ),
            if (state.status ==
                CashDrawerUiStatus.awaitingPhysicalConfirmation) ...[
              const SizedBox(height: TenantAdminSpacing.lg),
              Container(
                padding: const EdgeInsets.all(TenantAdminSpacing.md),
                decoration: BoxDecoration(
                  color: TenantAdminColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                  border: Border.all(
                      color: TenantAdminColors.info.withValues(alpha: 0.35)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Did the cash drawer physically open?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: TenantAdminSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          onPressed: () => ref
                              .read(cashDrawerControllerProvider.notifier)
                              .confirmPhysicalOpen(false),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: TenantAdminColors.danger),
                          child: const Text('NO, it failed'),
                        ),
                        FilledButton(
                          onPressed: () => ref
                              .read(cashDrawerControllerProvider.notifier)
                              .confirmPhysicalOpen(true),
                          style: FilledButton.styleFrom(
                              backgroundColor: TenantAdminColors.success),
                          child: const Text('YES, it opened'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (state.config != null && state.config!.manualOpenEnabled) ...[
              const SizedBox(height: TenantAdminSpacing.lg),
              const Divider(),
              const SizedBox(height: TenantAdminSpacing.md),
              Text(
                'Manual No-Sale open',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: TenantAdminSpacing.sm),
              TextFormField(
                controller: _manualReason,
                enabled: !state.isBusy,
                decoration: const InputDecoration(
                  labelText: 'No-sale open reason',
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Trigger manual open'),
                onPressed: state.isBusy
                    ? null
                    : () async {
                        if (_manualReason.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'A reason is required to trigger manual open.')),
                          );
                          return;
                        }
                        if (_policy == 'approvalRequired') {
                          // Show manager credentials modal dialog
                          final credentials =
                              await showDialog<Map<String, String>>(
                            context: context,
                            builder: (ctx) => const _ManagerApprovalDialog(),
                          );
                          if (credentials == null) return;

                          final ok = await ref
                              .read(cashDrawerControllerProvider.notifier)
                              .triggerManualNoSaleOpen(
                                reason: _manualReason.text,
                                managerEmail: credentials['email'],
                                managerPassword: credentials['password'],
                              );
                          if (ok) _manualReason.clear();
                        } else {
                          final ok = await ref
                              .read(cashDrawerControllerProvider.notifier)
                              .triggerManualNoSaleOpen(
                                reason: _manualReason.text,
                              );
                          if (ok) _manualReason.clear();
                        }
                      },
              ),
            ],
            if (state.drawerHistory.isNotEmpty) ...[
              const SizedBox(height: TenantAdminSpacing.xl),
              Text(
                'Recent cash drawer operations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: TenantAdminSpacing.sm),
              ...state.drawerHistory.take(5).map((op) {
                final date =
                    DateTime.tryParse(op['initiatedAt']?.toString() ?? '')
                        ?.toLocal();
                final purpose = op['drawerPurpose']?.toString() ?? 'unknown';
                final status = op['status']?.toString() ?? 'PENDING';
                final reason = op['reason']?.toString() ?? '';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('$purpose — $status'),
                  subtitle: Text(
                      '${date?.toIso8601String() ?? ""} ${reason.isNotEmpty ? "· $reason" : ""}'),
                  leading: const Icon(Icons.history_toggle_off_rounded),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _ManagerApprovalDialog extends StatefulWidget {
  const _ManagerApprovalDialog();

  @override
  State<_ManagerApprovalDialog> createState() => _ManagerApprovalDialogState();
}

class _ManagerApprovalDialogState extends State<_ManagerApprovalDialog> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manager approval required'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'A manager must authorize this manual cash drawer open.'),
            const SizedBox(height: TenantAdminSpacing.md),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Manager email'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Email is required' : null,
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Manager password'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Password is required' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'email': _email.text.trim(),
                'password': _password.text,
              });
            }
          },
          child: const Text('Authorize'),
        ),
      ],
    );
  }
}
