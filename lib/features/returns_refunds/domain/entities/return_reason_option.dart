/// Return reason options for Step 3 of the return flow.
///
/// TODO(returns-refunds): Load from backend when reason-codes API is ready.
class ReturnReasonOption {
  const ReturnReasonOption({
    required this.code,
    required this.title,
    required this.description,
    this.fullWidth = false,
  });

  final String code;
  final String title;
  final String description;
  final bool fullWidth;

  static const sizeIssue = ReturnReasonOption(
    code: 'SIZE_ISSUE',
    title: 'Size Issue',
    description: 'The item size is incorrect or doesn\'t fit.',
  );

  static const damaged = ReturnReasonOption(
    code: 'DAMAGED',
    title: 'Damaged',
    description: 'The item is damaged or arrived in poor condition.',
  );

  static const wrongItem = ReturnReasonOption(
    code: 'WRONG_ITEM',
    title: 'Wrong Item',
    description: 'The item received is different from what was ordered.',
  );

  static const defective = ReturnReasonOption(
    code: 'DEFECTIVE',
    title: 'Defective',
    description: 'The item has a defect or is not working as expected.',
  );

  static const other = ReturnReasonOption(
    code: 'OTHER',
    title: 'Other',
    description: 'Other reason not listed above (requires custom note).',
    fullWidth: true,
  );

  static const List<ReturnReasonOption> options = [
    sizeIssue,
    damaged,
    wrongItem,
    defective,
    other,
  ];

  static ReturnReasonOption? findByCode(String? code) {
    if (code == null || code.isEmpty) {
      return null;
    }

    for (final option in options) {
      if (option.code == code) {
        return option;
      }
    }

    return null;
  }
}
