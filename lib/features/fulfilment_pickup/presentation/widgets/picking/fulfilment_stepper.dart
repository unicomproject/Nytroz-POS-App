import 'package:flutter/material.dart';

import '../online_order_ui.dart';

class FulfilmentStepper extends StatelessWidget {
  const FulfilmentStepper({required this.status, super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const labels = ['Pick Items', 'Review & Pack', 'Ready for Collection'];
    return Semantics(
      label: 'Fulfilment progress. Step 1 of 3, Pick Items',
      child: Row(
        children: List.generate(
            labels.length,
            (index) => Expanded(
                  child: Row(children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor:
                          index == 0 ? primary : Colors.blueGrey.shade100,
                      foregroundColor:
                          index == 0 ? Colors.white : OnlineOrderUi.muted,
                      child: Text('${index + 1}',
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                        child: Text(labels[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: index == 0
                                    ? primary
                                    : OnlineOrderUi.muted))),
                    if (index < 2)
                      const Expanded(child: Divider(indent: 8, endIndent: 8)),
                  ]),
                )),
      ),
    );
  }
}
