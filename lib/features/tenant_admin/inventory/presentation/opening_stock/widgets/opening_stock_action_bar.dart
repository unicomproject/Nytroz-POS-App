import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/inventory_routes.dart';

class OpeningStockActionBar extends StatelessWidget {
  const OpeningStockActionBar({
    super.key,
    required this.canContinue,
    required this.onContinue,
    this.continueLabel = 'Continue to Enter Opening Details',
    this.isLoading = false,
  });

  final bool canContinue;
  final VoidCallback onContinue;
  final String continueLabel;
  final bool isLoading;

  static const primaryOrange = Color(0xFFFF6A00);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            onPressed: () => context.go(InventoryRoutes.currentStock),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: (canContinue && !isLoading) ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              disabledBackgroundColor: const Color(0xFFCBD5E1),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: canContinue ? 2 : 0,
              shadowColor: primaryOrange.withValues(alpha: 0.4),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        continueLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
