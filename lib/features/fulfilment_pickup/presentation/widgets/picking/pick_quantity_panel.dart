import 'package:flutter/material.dart';

import '../../utils/picking_formatters.dart';

class PickQuantityPanel extends StatelessWidget {
  const PickQuantityPanel({
    required this.requested,
    required this.picked,
    super.key,
  });
  final double requested;
  final double picked;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          Text('Requested: ${pickingQuantity(requested)}'),
          Text('Already picked: ${pickingQuantity(picked)}'),
          Text(
              'This pick: ${pickingQuantity((requested - picked).clamp(0, requested))}'),
        ],
      );
}
