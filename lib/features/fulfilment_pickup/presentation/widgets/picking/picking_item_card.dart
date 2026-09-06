import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_cached_network_image.dart';
import '../../../domain/entities/pos_online_order.dart';
import '../../utils/picking_formatters.dart';
import '../online_order_ui.dart';

class PickingItemCard extends StatelessWidget {
  const PickingItemCard(
      {required this.line,
      this.selected = false,
      this.onPick,
      this.onIssue,
      super.key});
  final PosPickingLine line;
  final bool selected;
  final VoidCallback? onPick;
  final VoidCallback? onIssue;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: onPick != null,
      label:
          'Pick line ${line.lineNumber}, ${line.productName}, ${pickingQuantity(line.pickedQuantity)} of ${pickingQuantity(line.requestedQuantity)} picked',
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    primary.withValues(alpha: .035),
                    Theme.of(context).colorScheme.surfaceContainerLowest,
                  )
                : Theme.of(context).colorScheme.surfaceContainerLowest,
            border: Border.all(
                color: selected ? primary : Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            final imageSize = constraints.hasBoundedHeight
                ? (constraints.maxHeight - 16).clamp(56.0, 76.0).toDouble()
                : 72.0;
            final product = Row(children: [
              Semantics(
                  image: true,
                  label: line.altText ?? line.productName,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: imageSize,
                        height: imageSize,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: AppCachedNetworkImage(
                            imageUrl: line.imageUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: (imageSize * 2).round(),
                            memCacheHeight: (imageSize * 2).round(),
                            errorWidget: const Icon(Icons.inventory_2_outlined,
                                size: 28)),
                      ))),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('${line.lineNumber}. ${line.productName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                    if (line.variantName != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(line.variantName!,
                              style: TextStyle(
                                  fontSize: 12, color: OnlineOrderUi.muted))),
                    if (line.sku != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('SKU: ${line.sku}',
                              style: TextStyle(
                                  fontSize: 12, color: OnlineOrderUi.muted))),
                  ])),
            ]);
            final detail = Row(children: [
              Expanded(child: _LocationBlock(line: line)),
              const SizedBox(width: 8),
              SizedBox(
                  width: 78,
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pick',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 1),
                            Text(
                                '${pickingQuantity(line.pickedQuantity)} / ${pickingQuantity(line.requestedQuantity)}',
                                style: TextStyle(
                                    color: primary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800)),
                            const Text('picked',
                                style: TextStyle(fontSize: 12)),
                          ]))),
              if (onIssue != null && line.hasReportedIssue)
                IconButton(
                    tooltip: 'View reported issue',
                    onPressed: onIssue,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.report_problem_outlined,
                        color: Theme.of(context).colorScheme.error)),
              Icon(Icons.chevron_right,
                  color: onPick == null ? OnlineOrderUi.muted : null),
            ]);
            if (constraints.maxWidth < 620) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      product,
                      const SizedBox(height: 8),
                      detail,
                    ],
                  ),
                ),
              );
            }
            return Row(children: [
              Expanded(flex: 5, child: product),
              const SizedBox(width: 10),
              Expanded(flex: 4, child: detail)
            ]);
          }),
        ),
      ),
    );
  }
}

class _LocationBlock extends StatelessWidget {
  const _LocationBlock({required this.line});
  final PosPickingLine line;
  @override
  Widget build(BuildContext context) => Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Location',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(line.locationName ?? 'Location unavailable',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
            if (line.locationCode != null)
              Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: .07),
                        borderRadius: BorderRadius.circular(7)),
                    child: Text(line.locationCode!,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700)),
                  )),
          ]);
}
