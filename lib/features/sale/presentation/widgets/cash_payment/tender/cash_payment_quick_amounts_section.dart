import 'package:flutter/material.dart';
import '../../../providers/pos_checkout_summary_provider.dart';
import '../../payment_method/payment_method_style.dart';

class CashPaymentQuickAmountsSection extends StatelessWidget {
  const CashPaymentQuickAmountsSection({
    super.key,
    required this.amounts,
    required this.selectedAmount,
    required this.onAmountSelected,
    required this.exactAmount,
    required this.currency,
  });

  final List<int> amounts;
  final int? selectedAmount;
  final ValueChanged<int> onAmountSelected;
  final int exactAmount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (amounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK CASH',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: amounts.map((amount) {
              final isSelected = amount == selectedAmount;
              final isExact = amount == exactAmount;
              final formattedAmount = formatCashQuickAmount(currency, amount);

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onAmountSelected(amount),
                    borderRadius: BorderRadius.circular(10),
                    child: isExact
                        ? _ExactCashCard(
                            amountText: formattedAmount,
                            isSelected: isSelected,
                            primaryColor: colors.primary,
                          )
                        : _StandardQuickAmountCard(
                            amountText: formattedAmount,
                            isSelected: isSelected,
                            primaryColor: colors.primary,
                          ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ExactCashCard extends StatelessWidget {
  const _ExactCashCard({
    required this.amountText,
    required this.isSelected,
    required this.primaryColor,
  });

  final String amountText;
  final bool isSelected;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      constraints: const BoxConstraints(minWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? primaryColor : PaymentMethodStyle.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.centerLeft,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.payments_outlined,
                size: 24,
                color: isSelected ? primaryColor : const Color(0xFF64748B),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXACT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color:
                          isSelected ? primaryColor : const Color(0xFF64748B),
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    amountText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color:
                          isSelected ? primaryColor : PaymentMethodStyle.navy,
                    ),
                  ),
                ],
              ),
              if (isSelected) const SizedBox(width: 24),
            ],
          ),
          if (isSelected)
            Positioned(
              top: -2,
              right: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StandardQuickAmountCard extends StatelessWidget {
  const _StandardQuickAmountCard({
    required this.amountText,
    required this.isSelected,
    required this.primaryColor,
  });

  final String amountText;
  final bool isSelected;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      constraints: const BoxConstraints(minWidth: 110),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? primaryColor.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? primaryColor : PaymentMethodStyle.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        amountText,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isSelected ? primaryColor : PaymentMethodStyle.navy,
        ),
      ),
    );
  }
}

String formatCashQuickAmount(String currency, int amount) {
  return formatCheckoutMoney(currency, amount).replaceAll('.00', '');
}
