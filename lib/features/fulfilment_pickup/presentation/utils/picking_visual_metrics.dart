import 'package:flutter/material.dart';

/// Compact layout metrics for the Online Order picking workspace.
/// Tuned so the right sidebar fits fixed landscape viewports without scroll.
class PickingVisualMetrics {
  const PickingVisualMetrics._({required this.compact});

  factory PickingVisualMetrics.forHeight(double height) =>
      PickingVisualMetrics._(compact: height < 540);

  final bool compact;

  double get gap => compact ? 6 : 8;

  double get lineHeight => compact ? 100 : 112;

  double get progressHeight => compact ? 132 : 152;

  double get progressRing => compact ? 82 : 98;

  double get tipsHeight => compact ? 88 : 104;

  double get noteHeight => compact ? 40 : 44;

  double get ctaHeight => compact ? 42 : 46;

  double get scanHeight => compact ? 46 : 50;
}

BoxDecoration pickingCardDecoration(BuildContext context) => BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(12),
    );
