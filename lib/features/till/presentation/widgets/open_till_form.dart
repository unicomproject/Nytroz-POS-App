import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OpenTillForm extends StatelessWidget {
  const OpenTillForm({
    super.key,
    required this.formKey,
    required this.openingFloatController,
    required this.openingNoteController,
    required this.isSubmitting,
    required this.outletName,
    required this.tillName,
    required this.deviceName,
    required this.onBack,
    required this.onSubmit,
    required this.onPresetSelected,
    this.errorMessage,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController openingFloatController;
  final TextEditingController openingNoteController;
  final bool isSubmitting;
  final String outletName;
  final String tillName;
  final String deviceName;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final ValueChanged<double> onPresetSelected;
  final String? errorMessage;

  bool get _hasValidAmount {
    final amount = double.tryParse(openingFloatController.text);
    return amount != null && amount >= 0;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE4E9F3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 42,
                  height: 42,
                  child: OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.arrow_back),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Open Till',
                        style: TextStyle(
                          color: Color(0xFF050A30),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter the starting cash amount to open $tillName.',
                        style: const TextStyle(
                          color: Color(0xFF5E6A82),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Starting Cash Amount',
                    style: TextStyle(
                      color: Color(0xFF050A30),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter the cash amount you have in the drawer to start.',
                    style: TextStyle(
                      color: Color(0xFF5E6A82),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: openingFloatController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^-?\d*\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (_) {
                      (context as Element).markNeedsBuild();
                    },
                    style: const TextStyle(
                      color: Color(0xFF050A30),
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      prefixText: 'LKR ',
                      suffixIcon: _hasValidAmount
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF16A34A),
                            )
                          : null,
                      errorText: errorMessage,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: _amountBorder(const Color(0xFFDCE4F2), 1),
                      enabledBorder: _amountBorder(
                        _hasValidAmount
                            ? const Color(0xFF1B5BFF)
                            : const Color(0xFFDCE4F2),
                        _hasValidAmount ? 1.5 : 1,
                      ),
                      focusedBorder: _amountBorder(
                        const Color(0xFF1B5BFF),
                        1.5,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Opening cash is required.';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null) {
                        return 'Opening cash must be a valid number.';
                      }
                      if (amount < 0) {
                        return 'Opening cash must be zero or more.';
                      }
                      return null;
                    },
                  ),
                  if (_hasValidAmount) ...[
                    const SizedBox(height: 5),
                    const Text(
                      'Amount is valid',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  const Text(
                    'Quick Amount Presets',
                    style: TextStyle(
                      color: Color(0xFF050A30),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    children: [
                      _PresetButton(
                        label: 'LKR 50',
                        selected: openingFloatController.text == '50.00',
                        onPressed: () => onPresetSelected(50),
                      ),
                      _PresetButton(
                        label: 'LKR 100',
                        selected: openingFloatController.text == '100.00',
                        onPressed: () => onPresetSelected(100),
                      ),
                      _PresetButton(
                        label: 'LKR 150',
                        selected: openingFloatController.text == '150.00',
                        onPressed: () => onPresetSelected(150),
                      ),
                      _PresetButton(
                        label: 'LKR 200',
                        selected: openingFloatController.text == '200.00',
                        onPressed: () => onPresetSelected(200),
                      ),
                      _PresetButton(
                        label: 'LKR 250',
                        selected: openingFloatController.text == '250.00',
                        onPressed: () => onPresetSelected(250),
                      ),
                      _PresetButton(
                        label: 'Custom',
                        selected: false,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Till Note (Optional)',
                    style: TextStyle(
                      color: Color(0xFF050A30),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add a note for this till opening.',
                    style: TextStyle(
                      color: Color(0xFF5E6A82),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: openingNoteController,
                    minLines: 3,
                    maxLines: 3,
                    maxLength: 100,
                    decoration: InputDecoration(
                      counterText: '${openingNoteController.text.length}/100',
                      contentPadding: const EdgeInsets.all(14),
                      border: _amountBorder(const Color(0xFFDCE4F2), 1),
                      enabledBorder: _amountBorder(const Color(0xFFDCE4F2), 1),
                      focusedBorder: _amountBorder(
                        const Color(0xFF1B5BFF),
                        1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _TillSummaryCard(
                    outletName: outletName,
                    tillName: tillName,
                    deviceName: deviceName,
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: isSubmitting ? null : onSubmit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF034BFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.lock_outline, size: 16),
                      label: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Open Till',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Till will be opened and ready for transactions.',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _amountBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E9F3)),
      ),
      child: child,
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 94,
      height: 34,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: selected ? const Color(0xFF034BFF) : const Color(0xFFDCE4F2),
            width: selected ? 1.5 : 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF034BFF) : const Color(0xFF050A30),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TillSummaryCard extends StatelessWidget {
  const _TillSummaryCard({
    required this.outletName,
    required this.tillName,
    required this.deviceName,
  });

  final String outletName;
  final String tillName;
  final String deviceName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E9F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Till Summary',
            style: TextStyle(
              color: Color(0xFF050A30),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _SummaryLine(label: 'Outlet', value: outletName),
          _SummaryLine(label: 'Till', value: tillName),
          _SummaryLine(label: 'Device', value: deviceName),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5E6A82),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF050A30),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
