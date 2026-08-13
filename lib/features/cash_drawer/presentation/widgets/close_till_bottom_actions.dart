import 'package:flutter/material.dart';

import '../../../sale/presentation/widgets/payment/pos_bottom_action_buttons.dart';

class CloseTillBottomActions extends StatelessWidget {
  const CloseTillBottomActions({
    super.key,
    required this.canCloseTill,
    required this.isLoading,
    required this.onCloseTill,
  });

  final bool canCloseTill;
  final bool isLoading;
  final VoidCallback onCloseTill;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: PosBottomFilledButton(
        label: 'Close Till',
        onPressed: canCloseTill && !isLoading ? onCloseTill : null,
        isLoading: isLoading,
      ),
    );
  }
}
