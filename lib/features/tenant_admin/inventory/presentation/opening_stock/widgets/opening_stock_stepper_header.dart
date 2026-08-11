import 'package:flutter/material.dart';
import '../../../../presentation/theme/tenant_admin_theme.dart';

class OpeningStockStepperHeader extends StatelessWidget {
  const OpeningStockStepperHeader({
    super.key,
    required this.currentStep,
  });

  final int currentStep;

  static const List<String> _stepTitles = [
    'Select Product & Outlet',
    'Enter Opening Details',
    'Review',
    'Success',
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 750;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < _stepTitles.length; i++) ...[
                _StepItem(
                  stepNumber: i + 1,
                  title: _stepTitles[i],
                  isActive: i == currentStep,
                  isCompleted: i < currentStep,
                  isCompact: isCompact,
                ),
                if (i < _stepTitles.length - 1)
                  _DottedConnector(
                    isCompleted: i < currentStep,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.stepNumber,
    required this.title,
    required this.isActive,
    required this.isCompleted,
    required this.isCompact,
  });

  final int stepNumber;
  final String title;
  final bool isActive;
  final bool isCompleted;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF6A00);

    Color badgeBg;
    Color badgeTextColor;
    Color labelColor;
    FontWeight fontWeight;

    if (isActive) {
      badgeBg = primaryOrange;
      badgeTextColor = Colors.white;
      labelColor = TenantAdminColors.bodyText;
      fontWeight = FontWeight.w700;
    } else if (isCompleted) {
      badgeBg = const Color(0xFF10B981);
      badgeTextColor = Colors.white;
      labelColor = TenantAdminColors.bodyText;
      fontWeight = FontWeight.w600;
    } else {
      badgeBg = const Color(0xFFE2E8F0);
      badgeTextColor = const Color(0xFF64748B);
      labelColor = const Color(0xFF94A3B8);
      fontWeight = FontWeight.w500;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: badgeBg,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isCompleted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '$stepNumber',
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        if (!isCompact || isActive) ...[
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: labelColor,
              fontSize: 13,
              fontWeight: fontWeight,
            ),
          ),
        ],
      ],
    );
  }
}

class _DottedConnector extends StatelessWidget {
  const _DottedConnector({required this.isCompleted});

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        width: 32,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(4, (index) {
            return Container(
              width: 4,
              height: 2,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF10B981)
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }),
        ),
      ),
    );
  }
}
