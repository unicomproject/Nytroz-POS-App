import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/effective_permission_set.dart';
import '../../../../core/access/permission_access_providers.dart';
import '../../../../core/access/pos_cash_drawer_till_visibility.dart';
import '../../../../shared/widgets/pos_action_buttons.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

enum OpenTillFormDensity { regular, compact }

/// Open Till form with Chunk 2 fine-grained opening.* visibility.
///
/// Input semantics (cash-payment parity):
/// - `starting_cash_entry` authorizes mutations
/// - `starting_cash_view` authorizes displaying amount / seeded default float
/// - Individual `key_*` / backspace / clear gate keypad chrome AND physical keys
/// - Direct TextField typing is read-only; all mutations share [_authorize*] paths
class OpenTillForm extends ConsumerStatefulWidget {
  const OpenTillForm({
    super.key,
    required this.formKey,
    required this.openingFloatController,
    required this.openingNoteController,
    required this.isSubmitting,
    required this.outletName,
    required this.tillName,
    required this.deviceName,
    required this.currencyCode,
    required this.openingBy,
    required this.onSubmit,
    this.errorMessage,
    this.density = OpenTillFormDensity.regular,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController openingFloatController;
  final TextEditingController openingNoteController;
  final bool isSubmitting;
  final String outletName;
  final String tillName;
  final String deviceName;
  final String currencyCode;
  final String openingBy;
  final VoidCallback onSubmit;
  final String? errorMessage;
  final OpenTillFormDensity density;

  @override
  ConsumerState<OpenTillForm> createState() => _OpenTillFormState();
}

class _OpenTillFormState extends ConsumerState<OpenTillForm> {
  /// Canonical digit/special order for dynamic reflow (denied keys omitted).
  static const _keyOrder = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '00',
    '0',
    '.',
  ];

  bool get _hasValidAmount {
    final amount = double.tryParse(widget.openingFloatController.text);
    return amount != null && amount >= 0;
  }

  @override
  void initState() {
    super.initState();
    widget.openingFloatController.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant OpenTillForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openingFloatController != widget.openingFloatController) {
      oldWidget.openingFloatController.removeListener(_refresh);
      widget.openingFloatController.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.openingFloatController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _setAmount(num amount) {
    widget.openingFloatController.text = amount.toStringAsFixed(2);
    widget.openingFloatController.selection = TextSelection.collapsed(
      offset: widget.openingFloatController.text.length,
    );
  }

  void _enterDigit(String digit) {
    final current = widget.openingFloatController.text;
    final parts = current.split('.');
    final whole = parts.first.replaceAll(RegExp(r'[^0-9]'), '');
    if (digit == '.') {
      if (current.contains('.')) return;
      widget.openingFloatController.text = '$whole.';
      widget.openingFloatController.selection = TextSelection.collapsed(
        offset: widget.openingFloatController.text.length,
      );
      return;
    }
    if (digit == '00') {
      final next = whole == '0' || whole.isEmpty ? '0' : '${whole}00';
      _setAmount(double.tryParse(next) ?? 0);
      return;
    }
    final next = whole == '0' || whole.isEmpty ? digit : '$whole$digit';
    _setAmount(double.tryParse(next) ?? 0);
  }

  void _backspace() {
    final whole = widget.openingFloatController.text.split('.').first;
    if (whole.length <= 1) return _setAmount(0);
    _setAmount(double.tryParse(whole.substring(0, whole.length - 1)) ?? 0);
  }

  bool _authorizeDigit(EffectivePermissionSet p, String digit) {
    if (!PosCashDrawerTillVisibility.canAuthorizeOpenTillKeyInput(p, digit)) {
      return false;
    }
    _enterDigit(digit);
    return true;
  }

  bool _authorizeBackspace(EffectivePermissionSet p) {
    if (!PosCashDrawerTillVisibility.canAuthorizeOpenTillBackspace(p)) {
      return false;
    }
    _backspace();
    return true;
  }

  bool _authorizeClear(EffectivePermissionSet p) {
    if (!PosCashDrawerTillVisibility.canAuthorizeOpenTillClear(p)) {
      return false;
    }
    _setAmount(0);
    return true;
  }

  bool _authorizeQuickAmount(EffectivePermissionSet p, int amount) {
    if (!PosCashDrawerTillVisibility.canAuthorizeOpenTillQuickAmount(
      p,
      amount,
    )) {
      return false;
    }
    _setAmount(amount);
    return true;
  }

  KeyEventResult _onKeyEvent(
    EffectivePermissionSet permissions,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final canEnter =
        PosCashDrawerTillVisibility.canShowStartingCashEntry(permissions);
    if (!canEnter) {
      if (_isAmountMutatingKey(event.logicalKey)) {
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      _authorizeBackspace(permissions);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _authorizeClear(permissions);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (PosCashDrawerTillVisibility.canOpenTill(permissions) &&
          _hasValidAmount &&
          !widget.isSubmitting) {
        widget.onSubmit();
      }
      return KeyEventResult.handled;
    }

    final digit = _digitFromKey(key);
    if (digit == null) return KeyEventResult.ignored;
    _authorizeDigit(permissions, digit);
    return KeyEventResult.handled;
  }

  static bool _isAmountMutatingKey(LogicalKeyboardKey key) {
    return _digitFromKey(key) != null ||
        key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
  }

  static String? _digitFromKey(LogicalKeyboardKey key) {
    final map = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.digit0: '0',
      LogicalKeyboardKey.digit1: '1',
      LogicalKeyboardKey.digit2: '2',
      LogicalKeyboardKey.digit3: '3',
      LogicalKeyboardKey.digit4: '4',
      LogicalKeyboardKey.digit5: '5',
      LogicalKeyboardKey.digit6: '6',
      LogicalKeyboardKey.digit7: '7',
      LogicalKeyboardKey.digit8: '8',
      LogicalKeyboardKey.digit9: '9',
      LogicalKeyboardKey.numpad0: '0',
      LogicalKeyboardKey.numpad1: '1',
      LogicalKeyboardKey.numpad2: '2',
      LogicalKeyboardKey.numpad3: '3',
      LogicalKeyboardKey.numpad4: '4',
      LogicalKeyboardKey.numpad5: '5',
      LogicalKeyboardKey.numpad6: '6',
      LogicalKeyboardKey.numpad7: '7',
      LogicalKeyboardKey.numpad8: '8',
      LogicalKeyboardKey.numpad9: '9',
      LogicalKeyboardKey.period: '.',
      LogicalKeyboardKey.numpadDecimal: '.',
    };
    return map[key];
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(effectivePermissionSetProvider);

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) => _onKeyEvent(permissions, event),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final showNumpad =
              PosCashDrawerTillVisibility.canShowOpenTillNumpad(permissions);
          final showQuick = PosCashDrawerTillVisibility
              .filterOpenTillQuickAmounts(permissions)
              .isNotEmpty;
          final showBackspaceChrome =
              PosCashDrawerTillVisibility.canShowOpenTillBackspace(permissions);
          final showClearChrome =
              PosCashDrawerTillVisibility.canShowOpenTillClear(permissions);
          final showKeypadSurface = showNumpad ||
              showQuick ||
              showBackspaceChrome ||
              showClearChrome;
          final content = wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: _detailsCard(context, permissions)),
                    if (showKeypadSurface) ...[
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: _keypadCard(context, permissions),
                      ),
                    ],
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _detailsCard(context, permissions),
                    if (showKeypadSurface) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 600,
                        child: _keypadCard(context, permissions),
                      ),
                    ],
                  ],
                );

          final body = Form(
            key: widget.formKey,
            child: wide
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: content),
                      const SizedBox(height: 14),
                      _bottomAction(permissions),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      content,
                      const SizedBox(height: 16),
                      _bottomAction(permissions),
                    ],
                  ),
          );

          return wide
              ? body
              : SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: body,
                );
        },
      ),
    );
  }

  Widget _detailsCard(
    BuildContext context,
    EffectivePermissionSet permissions,
  ) {
    final showView =
        PosCashDrawerTillVisibility.canShowStartingCashView(permissions);
    final showEntry =
        PosCashDrawerTillVisibility.canShowStartingCashEntry(permissions);
    final showAmountField = showView || showEntry;
    final showNoteView =
        PosCashDrawerTillVisibility.canShowOpenTillNoteView(permissions);
    final showNoteEntry =
        PosCashDrawerTillVisibility.canShowOpenTillNoteEntry(permissions);
    final showNote = showNoteView || showNoteEntry;
    final showValidation =
        PosCashDrawerTillVisibility.canShowOpenTillValidation(permissions);

    return _SurfaceCard(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Open Till',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter the starting cash amount to open ${widget.tillName}.',
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (showAmountField) ...[
              const SizedBox(height: 20),
              const _FieldHeading(
                title: 'Starting Cash Amount',
                description:
                    'Enter the cash amount you have in the drawer to start.',
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: const Key('opening-cash-field'),
                controller: widget.openingFloatController,
                readOnly: true,
                enableInteractiveSelection: showView || showEntry,
                // Per-key + entry govern mutations via Focus/keypad — not OS typing.
                keyboardType: TextInputType.none,
                showCursor: showEntry,
                validator: (value) {
                  if (!showEntry && !showView) return null;
                  if (value == null || value.trim().isEmpty) {
                    return 'Opening cash is required.';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount < 0) {
                    return 'Enter a valid non-negative amount.';
                  }
                  return null;
                },
                style: TextStyle(
                  color: showView || showEntry
                      ? TenantAdminColors.bodyText
                      : TenantAdminColors.mutedText,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
                decoration: InputDecoration(
                  prefixText: '${widget.currencyCode}  ',
                  prefixStyle: const TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  // When view denied but entry allowed: do not leak prior float
                  // via semantics of a "known" value — field still shows what
                  // the cashier just entered (their own entry, not protected prior).
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
                  enabledBorder:
                      _border(TenantAdminColors.posHomeAccentOrange, 2),
                  focusedBorder:
                      _border(TenantAdminColors.posHomeAccentOrange, 2),
                  errorBorder: _border(TenantAdminColors.danger, 1.5),
                  focusedErrorBorder: _border(TenantAdminColors.danger, 2),
                ),
              ),
              if (showValidation) ...[
                const SizedBox(height: 8),
                if (widget.errorMessage != null)
                  _StatusMessage(
                    icon: Icons.error_outline,
                    color: TenantAdminColors.danger,
                    message: widget.errorMessage!,
                  )
                else if (_hasValidAmount)
                  const _StatusMessage(
                    icon: Icons.check_circle_outline,
                    color: TenantAdminColors.success,
                    message: 'Amount is valid',
                  ),
              ],
            ],
            if (showNote) ...[
              const SizedBox(height: 18),
              const _FieldHeading(
                title: 'Till Note (Optional)',
                description: 'Add a note for this till opening.',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: widget.openingNoteController,
                readOnly: !showNoteEntry,
                maxLength: showNoteEntry ? 100 : null,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: showNoteEntry
                      ? 'Enter note (optional)...'
                      : null,
                  alignLabelWithHint: true,
                  enabledBorder: _border(TenantAdminColors.border, 1),
                  focusedBorder:
                      _border(TenantAdminColors.posHomeAccentOrange, 1.5),
                ),
              ),
            ],
            const SizedBox(height: 8),
            _TillSummaryCard(
              outletName: widget.outletName,
              tillName: widget.tillName,
              deviceName: widget.deviceName,
              openingBy: widget.openingBy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _keypadCard(
    BuildContext context,
    EffectivePermissionSet permissions,
  ) {
    final quickAmounts =
        PosCashDrawerTillVisibility.filterOpenTillQuickAmounts(permissions);
    final showNumpad =
        PosCashDrawerTillVisibility.canShowOpenTillNumpad(permissions);
    final visibleKeys = showNumpad
        ? _keyOrder
            .where(
              (k) => PosCashDrawerTillVisibility.canShowOpenTillNumpadKey(
                permissions,
                k,
              ),
            )
            .toList(growable: false)
        : const <String>[];
    final showBackspace =
        PosCashDrawerTillVisibility.canShowOpenTillBackspace(permissions);
    final showClear =
        PosCashDrawerTillVisibility.canShowOpenTillClear(permissions);

    if (quickAmounts.isEmpty &&
        visibleKeys.isEmpty &&
        !showBackspace &&
        !showClear) {
      return const SizedBox.shrink();
    }

    final digitRows = <List<String>>[];
    for (var i = 0; i < visibleKeys.length; i += 3) {
      digitRows.add(
        visibleKeys.sublist(i, (i + 3).clamp(0, visibleKeys.length)),
      );
    }

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (quickAmounts.isNotEmpty) ...[
            const Text(
              'Quick Amounts',
              style: TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < quickAmounts.length; i++) ...[
                  Expanded(
                    child: _QuickAmountButton(
                      key: ValueKey('open-till-quick-${quickAmounts[i]}'),
                      amount: quickAmounts[i],
                      onPressed: () =>
                          _authorizeQuickAmount(permissions, quickAmounts[i]),
                    ),
                  ),
                  if (i != quickAmounts.length - 1) const SizedBox(width: 10),
                ],
              ],
            ),
            if (showNumpad &&
                (visibleKeys.isNotEmpty || showBackspace || showClear))
              const SizedBox(height: 18),
          ],
          if (visibleKeys.isNotEmpty || showBackspace || showClear)
            Expanded(
              child: Column(
                children: [
                  for (var row = 0; row < digitRows.length; row++) ...[
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var column = 0;
                              column < digitRows[row].length;
                              column++) ...[
                            Expanded(
                              child: _KeypadButton(
                                key: ValueKey(
                                  'open-till-key-${digitRows[row][column]}',
                                ),
                                label: digitRows[row][column],
                                onPressed: () => _authorizeDigit(
                                  permissions,
                                  digitRows[row][column],
                                ),
                              ),
                            ),
                            if (column != digitRows[row].length - 1)
                              const SizedBox(width: 10),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (showBackspace || showClear)
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showBackspace)
                            Expanded(
                              child: _KeypadButton(
                                key: const ValueKey('open-till-key-backspace'),
                                icon: Icons.backspace_outlined,
                                semanticLabel: 'Delete digit',
                                onPressed: () =>
                                    _authorizeBackspace(permissions),
                              ),
                            ),
                          if (showBackspace && showClear)
                            const SizedBox(width: 10),
                          if (showClear)
                            Expanded(
                              child: _KeypadButton(
                                key: const ValueKey('open-till-key-clear'),
                                label: 'C',
                                labelColor: TenantAdminColors.danger,
                                onPressed: () => _authorizeClear(permissions),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottomAction(EffectivePermissionSet permissions) {
    final canSubmit = PosCashDrawerTillVisibility.canOpenTill(permissions);
    final showConfirmMessage =
        PosCashDrawerTillVisibility.canShowOpenTillConfirmMessage(permissions);
    if (!canSubmit) {
      return const SizedBox.shrink();
    }

    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: PosPrimaryActionButton(
        key: const Key('open-till-button'),
        onPressed: _hasValidAmount && !widget.isSubmitting
            ? () {
                if (!PosCashDrawerTillVisibility.canOpenTill(
                  ref.read(effectivePermissionSetProvider),
                )) {
                  return;
                }
                widget.onSubmit();
              }
            : null,
        isLoading: widget.isSubmitting,
        fullWidth: true,
        minimumHeight: 64,
        backgroundColor: TenantAdminColors.posHomeAccentOrange,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_open_outlined, size: 23),
            const SizedBox(width: 14),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Open Till',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                if (showConfirmMessage)
                  const Text(
                    'The till will be opened and ready for transactions.',
                    style:
                        TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          border: Border.all(color: TenantAdminColors.border),
          boxShadow: TenantAdminShadows.card,
        ),
        child: Padding(padding: padding, child: child),
      );
}

class _FieldHeading extends StatelessWidget {
  const _FieldHeading({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
}

class _TillSummaryCard extends StatelessWidget {
  const _TillSummaryCard({
    required this.outletName,
    required this.tillName,
    required this.deviceName,
    required this.openingBy,
  });

  final String outletName;
  final String tillName;
  final String deviceName;
  final String openingBy;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TenantAdminColors.expectedCashSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: TenantAdminColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Till Summary',
              style: TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              icon: Icons.store_outlined,
              label: 'Outlet',
              value: outletName,
            ),
            _SummaryRow(
              icon: Icons.point_of_sale_outlined,
              label: 'Till',
              value: tillName,
            ),
            _SummaryRow(
              icon: Icons.developer_board_outlined,
              label: 'Device',
              value: deviceName,
            ),
            _SummaryRow(
              icon: Icons.person_outline,
              label: 'Opening By',
              value: openingBy,
            ),
          ],
        ),
      );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 17, color: TenantAdminColors.mutedText),
            const SizedBox(width: 9),
            SizedBox(
              width: 88,
              child: Text(
                label,
                style: const TextStyle(
                  color: TenantAdminColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      );
}

class _QuickAmountButton extends StatelessWidget {
  const _QuickAmountButton({
    super.key,
    required this.amount,
    required this.onPressed,
  });
  final int amount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: TenantAdminColors.posHomeAccentOrange,
          side: const BorderSide(
            color: TenantAdminColors.posHomeAccentOrange,
            width: 1.5,
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        child: Text(amount == 1000 ? '1,000' : '$amount'),
      );
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.semanticLabel,
    this.labelColor = TenantAdminColors.bodyText,
  });
  final VoidCallback onPressed;
  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final Color labelColor;

  @override
  Widget build(BuildContext context) => Semantics(
        label: semanticLabel ?? label,
        button: true,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(60, 58),
            foregroundColor: labelColor,
            side: const BorderSide(color: TenantAdminColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: icon != null
              ? Icon(icon, size: 24)
              : Text(
                  label!,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: labelColor,
                  ),
                ),
        ),
      );
}

OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
