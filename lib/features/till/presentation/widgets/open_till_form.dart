import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

enum OpenTillFormDensity { regular, compact }

class OpenTillLayoutMetrics {
  const OpenTillLayoutMetrics({
    required this.cardPadding,
    required this.sectionGap,
    required this.fieldGap,
    required this.noteLines,
    required this.buttonHeight,
    required this.amountFontSize,
    required this.titleFontSize,
    required this.summaryLabelWidth,
    required this.compactSummary,
  });

  final EdgeInsets cardPadding;
  final double sectionGap;
  final double fieldGap;
  final int noteLines;
  final double buttonHeight;
  final double amountFontSize;
  final double titleFontSize;
  final double summaryLabelWidth;
  final bool compactSummary;

  factory OpenTillLayoutMetrics.resolve({
    required double height,
    required double width,
    OpenTillFormDensity density = OpenTillFormDensity.regular,
  }) {
    final isCompactDensity = density == OpenTillFormDensity.compact;
    final isTightHeight = height < 640;
    final isCompactHeight = height < 720;

    if (isCompactDensity || isTightHeight) {
      return const OpenTillLayoutMetrics(
        cardPadding: EdgeInsets.fromLTRB(20, 18, 20, 16),
        sectionGap: 14,
        fieldGap: 8,
        noteLines: 2,
        buttonHeight: 50,
        amountFontSize: 24,
        titleFontSize: 24,
        summaryLabelWidth: 92,
        compactSummary: true,
      );
    }

    if (isCompactHeight) {
      return const OpenTillLayoutMetrics(
        cardPadding: EdgeInsets.fromLTRB(24, 20, 24, 18),
        sectionGap: 16,
        fieldGap: 10,
        noteLines: 2,
        buttonHeight: 52,
        amountFontSize: 26,
        titleFontSize: 26,
        summaryLabelWidth: 100,
        compactSummary: true,
      );
    }

    return OpenTillLayoutMetrics(
      cardPadding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
      sectionGap: width >= TenantAdminBreakpoints.tablet ? 20 : 18,
      fieldGap: 10,
      noteLines: 2,
      buttonHeight: 52,
      amountFontSize: 28,
      titleFontSize: 28,
      summaryLabelWidth: 108,
      compactSummary: false,
    );
  }
}

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

  bool get _hasValidAmount {
    final amount = double.tryParse(openingFloatController.text);
    return amount != null && amount >= 0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = OpenTillLayoutMetrics.resolve(
          height: constraints.maxHeight.isFinite ? constraints.maxHeight : 900,
          width: constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width,
          density: density,
        );

        return Form(
          key: formKey,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: TenantAdminColors.surface,
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              border: Border.all(color: TenantAdminColors.border),
              boxShadow: TenantAdminShadows.card,
            ),
            child: Padding(
              padding: metrics.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PageHeading(
                    tillName: tillName,
                    titleFontSize: metrics.titleFontSize,
                  ),
                  SizedBox(height: metrics.sectionGap),
                  _CashAmountSection(
                    openingFloatController: openingFloatController,
                    currencyCode: currencyCode,
                    errorMessage: errorMessage,
                    hasValidAmount: _hasValidAmount,
                    amountFontSize: metrics.amountFontSize,
                    fieldGap: metrics.fieldGap,
                    onChanged: () => (context as Element).markNeedsBuild(),
                  ),
                  SizedBox(height: metrics.sectionGap),
                  _NoteSection(
                    openingNoteController: openingNoteController,
                    noteLines: metrics.noteLines,
                    fieldGap: metrics.fieldGap,
                    onChanged: () => (context as Element).markNeedsBuild(),
                  ),
                  SizedBox(height: metrics.fieldGap + 2),
                  _TillSummaryCard(
                    outletName: outletName,
                    tillName: tillName,
                    deviceName: deviceName,
                    openingBy: openingBy,
                    labelWidth: metrics.summaryLabelWidth,
                    compact: metrics.compactSummary,
                  ),
                  const Spacer(),
                  _OpenTillSubmitButton(
                    isSubmitting: isSubmitting,
                    isEnabled: _hasValidAmount,
                    buttonHeight: metrics.buttonHeight,
                    onSubmit: onSubmit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({
    required this.tillName,
    required this.titleFontSize,
  });

  final String tillName;
  final double titleFontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Open Till',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w900,
                fontSize: titleFontSize,
                height: 1.1,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          'Enter the starting cash amount to open $tillName.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.35,
              ),
        ),
      ],
    );
  }
}

class _CashAmountSection extends StatelessWidget {
  const _CashAmountSection({
    required this.openingFloatController,
    required this.currencyCode,
    required this.errorMessage,
    required this.hasValidAmount,
    required this.amountFontSize,
    required this.fieldGap,
    required this.onChanged,
  });

  final TextEditingController openingFloatController;
  final String currencyCode;
  final String? errorMessage;
  final bool hasValidAmount;
  final double amountFontSize;
  final double fieldGap;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel(
          title: 'Starting Cash Amount',
          description: 'Enter the cash amount you have in the drawer to start.',
        ),
        SizedBox(height: fieldGap),
        TextFormField(
          controller: openingFloatController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
          ],
          onChanged: (_) => onChanged(),
          style: TextStyle(
            color: TenantAdminColors.bodyText,
            fontSize: amountFontSize,
            fontWeight: FontWeight.w900,
          ),
          decoration: InputDecoration(
            prefixText: '${currencyCode.trim()} ',
            suffixIcon: hasValidAmount
                ? const Icon(
                    Icons.check_circle,
                    color: TenantAdminColors.success,
                  )
                : null,
            errorText: errorMessage,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: _inputBorder(TenantAdminColors.border, 1),
            enabledBorder: _inputBorder(
              hasValidAmount
                  ? const Color(0xFF1B5BFF)
                  : TenantAdminColors.border,
              hasValidAmount ? 1.5 : 1,
            ),
            focusedBorder: _inputBorder(const Color(0xFF1B5BFF), 1.5),
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
        if (hasValidAmount) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          const Text(
            'Amount is valid',
            style: TextStyle(
              color: TenantAdminColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _NoteSection extends StatelessWidget {
  const _NoteSection({
    required this.openingNoteController,
    required this.noteLines,
    required this.fieldGap,
    required this.onChanged,
  });

  final TextEditingController openingNoteController;
  final int noteLines;
  final double fieldGap;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel(
          title: 'Till Note (Optional)',
          description: 'Add a note for this till opening.',
        ),
        SizedBox(height: fieldGap),
        TextFormField(
          controller: openingNoteController,
          minLines: noteLines,
          maxLines: noteLines,
          maxLength: 100,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            counterText: '${openingNoteController.text.length}/100',
            contentPadding: const EdgeInsets.all(12),
            border: _inputBorder(TenantAdminColors.border, 1),
            enabledBorder: _inputBorder(TenantAdminColors.border, 1),
            focusedBorder: _inputBorder(const Color(0xFF1B5BFF), 1.5),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          description,
          style: const TextStyle(
            color: TenantAdminColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

class _OpenTillSubmitButton extends StatelessWidget {
  const _OpenTillSubmitButton({
    required this.isSubmitting,
    required this.isEnabled,
    required this.buttonHeight,
    required this.onSubmit,
  });

  final bool isSubmitting;
  final bool isEnabled;
  final double buttonHeight;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: buttonHeight,
      child: FilledButton(
        onPressed: isSubmitting || !isEnabled ? null : onSubmit,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF034BFF),
          disabledBackgroundColor:
              const Color(0xFF034BFF).withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 18),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Open Till',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Till will be opened and ready for transactions.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.92),
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
}

class _TillSummaryCard extends StatelessWidget {
  const _TillSummaryCard({
    required this.outletName,
    required this.tillName,
    required this.deviceName,
    required this.openingBy,
    required this.labelWidth,
    required this.compact,
  });

  final String outletName;
  final String tillName;
  final String deviceName;
  final String openingBy;
  final double labelWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Till Summary',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            SizedBox(height: compact ? 6 : TenantAdminSpacing.sm),
            _SummaryLine(
              label: 'Outlet',
              value: outletName,
              labelWidth: labelWidth,
              compact: compact,
            ),
            _SummaryLine(
              label: 'Till',
              value: tillName,
              labelWidth: labelWidth,
              compact: compact,
            ),
            _SummaryLine(
              label: 'Device',
              value: deviceName,
              labelWidth: labelWidth,
              compact: compact,
            ),
            if (openingBy.trim().isNotEmpty)
              _SummaryLine(
                label: 'Opening By',
                value: openingBy,
                labelWidth: labelWidth,
                compact: compact,
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    required this.labelWidth,
    required this.compact,
  });

  final String label;
  final String value;
  final double labelWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: compact ? 4 : TenantAdminSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TenantAdminColors.bodyText,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

OutlineInputBorder _inputBorder(Color color, double width) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(6),
    borderSide: BorderSide(color: color, width: width),
  );
}
