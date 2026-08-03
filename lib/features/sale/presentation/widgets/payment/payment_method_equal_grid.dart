import 'package:flutter/material.dart';

class PaymentMethodEqualGrid extends StatelessWidget {
  const PaymentMethodEqualGrid({
    super.key,
    required this.children,
    this.gap = 16,
    this.cardHeight = 174,
  });

  final List<Widget> children;
  final double gap;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = children.length.clamp(0, 5);
        if (count == 0) return const SizedBox.shrink();
        final columns = count <= 2 ? count : (count == 4 ? 2 : 3);
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        final rows = <Widget>[];
        var index = 0;
        while (index < count) {
          final remaining = count - index;
          final rowCount = remaining >= columns ? columns : remaining;
          final rowWidth = rowCount * width + (rowCount - 1) * gap;
          rows.add(
            Center(
              child: SizedBox(
                width: rowWidth,
                child: Row(
                  children: [
                    for (var column = 0; column < rowCount; column++) ...[
                      if (column > 0) SizedBox(width: gap),
                      SizedBox(
                        width: width,
                        height: cardHeight,
                        child: children[index + column],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
          index += rowCount;
          if (index < count) rows.add(SizedBox(height: gap));
        }
        return Column(mainAxisSize: MainAxisSize.min, children: rows);
      },
    );
  }
}
