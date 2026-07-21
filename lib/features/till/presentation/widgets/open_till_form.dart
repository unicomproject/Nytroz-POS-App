import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/widgets/pos_action_buttons.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

enum OpenTillFormDensity { regular, compact }

class OpenTillForm extends StatefulWidget {
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
  State<OpenTillForm> createState() => _OpenTillFormState();
}

class _OpenTillFormState extends State<OpenTillForm> {
  static const quickAmounts = <int>[100, 500, 1000];

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
    final whole = current.split('.').first.replaceAll(RegExp(r'[^0-9]'), '');
    final next = whole == '0' ? digit : '$whole$digit';
    _setAmount(double.tryParse(next) ?? 0);
  }

  void _backspace() {
    final whole = widget.openingFloatController.text.split('.').first;
    if (whole.length <= 1) return _setAmount(0);
    _setAmount(double.tryParse(whole.substring(0, whole.length - 1)) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final content = wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: _detailsCard(context)),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _keypadCard(context)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _detailsCard(context),
                  const SizedBox(height: 16),
                  SizedBox(height: 600, child: _keypadCard(context)),
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
                    _bottomAction(),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [content, const SizedBox(height: 16), _bottomAction()],
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
    );
  }

  Widget _detailsCard(BuildContext context) {
    return _SurfaceCard(
      child: SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Open Till',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: TenantAdminColors.navy,
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
          const SizedBox(height: 20),
          const _FieldHeading(
            title: 'Starting Cash Amount',
            description: 'Enter the cash amount you have in the drawer to start.',
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: const Key('opening-cash-field'),
            controller: widget.openingFloatController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Opening cash is required.';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount < 0) {
                return 'Enter a valid non-negative amount.';
              }
              return null;
            },
            style: const TextStyle(
              color: TenantAdminColors.navy,
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
              enabledBorder: _border(TenantAdminColors.primary, 2),
              focusedBorder: _border(TenantAdminColors.primary, 2),
              errorBorder: _border(Colors.red, 1.5),
              focusedErrorBorder: _border(Colors.red, 2),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.errorMessage != null) ...[
            _StatusMessage(
              icon: Icons.error_outline,
              color: Colors.red,
              message: widget.errorMessage!,
            ),
          ] else if (_hasValidAmount) ...[
            const _StatusMessage(
              icon: Icons.check_circle_outline,
              color: Color(0xff16a34a),
              message: 'Amount is valid',
            ),
          ],
          const SizedBox(height: 18),
          const _FieldHeading(
            title: 'Till Note (Optional)',
            description: 'Add a note for this till opening.',
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: widget.openingNoteController,
            maxLength: 100,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter note (optional)...',
              alignLabelWithHint: true,
              enabledBorder: _border(TenantAdminColors.border, 1),
              focusedBorder: _border(TenantAdminColors.primary, 1.5),
            ),
          ),
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

  Widget _keypadCard(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Quick Amounts',
            style: TextStyle(
              color: TenantAdminColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < quickAmounts.length; i++) ...[
                Expanded(
                  child: _QuickAmountButton(
                    amount: quickAmounts[i],
                    onPressed: () => _setAmount(quickAmounts[i]),
                  ),
                ),
                if (i != quickAmounts.length - 1) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 18),
          for (var row = 0; row < 3; row++) ...[
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < 3; column++) ...[
                    Expanded(
                      child: _KeypadButton(
                        label: keys[(row * 3) + column],
                        onPressed: () =>
                            _enterDigit(keys[(row * 3) + column]),
                      ),
                    ),
                    if (column != 2) const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _KeypadButton(
                    icon: Icons.backspace_outlined,
                    semanticLabel: 'Delete digit',
                    onPressed: _backspace,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KeypadButton(
                    label: '0',
                    onPressed: () => _enterDigit('0'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KeypadButton(
                    label: 'C',
                    labelColor: const Color(0xffef3158),
                    onPressed: () => _setAmount(0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const Key('set-exact-amount'),
            onPressed: () => FocusScope.of(context).unfocus(),
            icon: const Icon(Icons.point_of_sale_outlined),
            label: const Text('Set Exact'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: TenantAdminColors.primary,
              backgroundColor: const Color(0xffeef3ff),
              side: BorderSide.none,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomAction() {
    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: PosPrimaryActionButton(
        key: const Key('open-till-button'),
        onPressed: _hasValidAmount && !widget.isSubmitting
            ? widget.onSubmit
            : null,
        isLoading: widget.isSubmitting,
        fullWidth: true,
        minimumHeight: 64,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_open_outlined, size: 23),
            SizedBox(width: 14),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Open Till', style: TextStyle(fontWeight: FontWeight.w900)),
                Text(
                  'The till will be opened and ready for transactions.',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
              color: TenantAdminColors.navy,
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
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800),
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
          color: const Color(0xfff8faff),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: TenantAdminColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Till Summary',
              style: TextStyle(color: TenantAdminColors.navy, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            _SummaryRow(icon: Icons.store_outlined, label: 'Outlet', value: outletName),
            _SummaryRow(icon: Icons.point_of_sale_outlined, label: 'Till', value: tillName),
            _SummaryRow(icon: Icons.developer_board_outlined, label: 'Device', value: deviceName),
            _SummaryRow(icon: Icons.person_outline, label: 'Opening By', value: openingBy),
          ],
        ),
      );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.label, required this.value});
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
              child: Text(label, style: const TextStyle(color: TenantAdminColors.mutedText, fontSize: 12)),
            ),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: TenantAdminColors.navy, fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
}

class _QuickAmountButton extends StatelessWidget {
  const _QuickAmountButton({required this.amount, required this.onPressed});
  final int amount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: TenantAdminColors.primary,
          side: const BorderSide(color: TenantAdminColors.border),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        child: Text(amount == 1000 ? '1,000' : '$amount'),
      );
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.onPressed,
    this.label,
    this.icon,
    this.semanticLabel,
    this.labelColor = TenantAdminColors.navy,
  });
  final VoidCallback onPressed;
  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final Color labelColor;

  @override
  Widget build(BuildContext context) => Semantics(
        label: semanticLabel,
        button: true,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(60, 58),
            foregroundColor: labelColor,
            side: const BorderSide(color: TenantAdminColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: icon != null
              ? Icon(icon, size: 24)
              : Text(
                  label!,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: labelColor),
                ),
        ),
      );
}

OutlineInputBorder _border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
