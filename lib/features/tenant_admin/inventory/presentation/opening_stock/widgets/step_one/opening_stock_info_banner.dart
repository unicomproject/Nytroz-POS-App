import 'package:flutter/material.dart';

class OpeningStockInfoBanner extends StatelessWidget {
  const OpeningStockInfoBanner({super.key});

  static const primaryOrange = Color(0xFFFF6A00);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: primaryOrange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryOrange.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline, color: primaryOrange, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Opening stock will be added to the selected outlet. Ensure current stock is 0 before adding opening stock.',
              style: TextStyle(
                color: Color(0xFFC2410C),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
