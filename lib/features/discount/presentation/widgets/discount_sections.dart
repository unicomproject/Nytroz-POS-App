import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'discount_state.dart';

const _purple = Color(0xFF7C3AED);
const _purpleSurface = Color(0xFFF7F0FF);

class DiscountScopeSelector extends StatelessWidget {
  const DiscountScopeSelector({
    super.key,
    required this.scope,
    required this.onChanged,
  });
  final PosDiscountScope scope;
  final ValueChanged<PosDiscountScope> onChanged;

  @override
  Widget build(BuildContext context) => _SelectionGrid(
        label: 'DISCOUNT TYPE',
        children: [
          DiscountSelectionCard(
            key: const Key('discount-scope-order'),
            selected: scope == PosDiscountScope.order,
            icon: Icons.inventory_2_outlined,
            title: 'Order Level Discount',
            subtitle: 'Apply to the entire sale',
            onTap: () => onChanged(PosDiscountScope.order),
          ),
          DiscountSelectionCard(
            key: const Key('discount-scope-item'),
            selected: scope == PosDiscountScope.item,
            icon: Icons.shopping_bag_outlined,
            title: 'Item Level Discount',
            subtitle: 'Apply to a specific product',
            onTap: () => onChanged(PosDiscountScope.item),
          ),
        ],
      );
}

class DiscountMethodSelector extends StatelessWidget {
  const DiscountMethodSelector({
    super.key,
    required this.method,
    required this.itemScope,
    required this.onChanged,
  });
  final PosDiscountCalculationMethod method;
  final bool itemScope;
  final ValueChanged<PosDiscountCalculationMethod> onChanged;

  @override
  Widget build(BuildContext context) => _SelectionGrid(
        label: 'DISCOUNT VALUE',
        children: [
          DiscountSelectionCard(
            key: const Key('discount-method-percentage'),
            selected: method == PosDiscountCalculationMethod.percentage,
            icon: Icons.percent,
            title: 'Percentage',
            compact: true,
            onTap: () => onChanged(PosDiscountCalculationMethod.percentage),
          ),
          if (!itemScope)
            DiscountSelectionCard(
              key: const Key('discount-method-fixed'),
              selected: method == PosDiscountCalculationMethod.fixedAmount,
              icon: Icons.credit_card,
              title: 'Fixed Amount',
              compact: true,
              onTap: () => onChanged(PosDiscountCalculationMethod.fixedAmount),
            ),
        ],
      );
}

class DiscountSelectionCard extends StatelessWidget {
  const DiscountSelectionCard({
    super.key,
    required this.selected,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.compact = false,
  });
  final bool selected;
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? _purpleSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: BoxConstraints(minHeight: compact ? 56 : 88),
            padding: EdgeInsets.all(compact ? 12 : 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? _purple : TenantAdminColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? _purple : TenantAdminColors.mutedText,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Icon(icon,
                    color: selected ? _purple : TenantAdminColors.bodyText,
                    size: compact ? 20 : 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color:
                                selected ? _purple : TenantAdminColors.bodyText,
                          )),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(subtitle!,
                            style: const TextStyle(
                                color: TenantAdminColors.mutedText,
                                fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class DiscountValueField extends StatelessWidget {
  const DiscountValueField({
    super.key,
    required this.controller,
    required this.method,
    required this.currencyCode,
    required this.errorText,
    required this.onChanged,
  });
  final TextEditingController controller;
  final PosDiscountCalculationMethod method;
  final String currencyCode;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final percentage = method == PosDiscountCalculationMethod.percentage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(percentage ? 'Discount Percentage' : 'Discount Amount',
            style: const TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 7),
        TextField(
          key: const Key('discount-value-field'),
          controller: controller,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: 'Enter value',
            suffixText: percentage ? '%' : currencyCode,
            errorText: errorText,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          percentage
              ? 'Percentage must be between 0 and 100.'
              : 'Cashier limit will be validated by the server.',
          style:
              const TextStyle(color: TenantAdminColors.mutedText, fontSize: 12),
        ),
      ],
    );
  }
}

class DiscountReasonSection extends StatelessWidget {
  const DiscountReasonSection({
    super.key,
    required this.controller,
    required this.onChanged,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('REASON (OPTIONAL)',
              style: TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontSize: 12,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 7),
          TextField(
            key: const Key('discount-reason-field'),
            controller: controller,
            onChanged: onChanged,
            maxLength: 200,
            decoration: const InputDecoration(
              hintText: 'Enter reason',
              counterText: '',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Promo', 'VIP', 'Staff', 'Other']
                .map((reason) => ActionChip(
                      key: Key('discount-reason-${reason.toLowerCase()}'),
                      label: Text(reason),
                      onPressed: () {
                        controller.text = reason;
                        controller.selection = TextSelection.collapsed(
                            offset: controller.text.length);
                        onChanged(reason);
                      },
                    ))
                .toList(growable: false),
          ),
        ],
      );
}

class DiscountSummaryCard extends StatelessWidget {
  const DiscountSummaryCard({
    super.key,
    required this.title,
    required this.rows,
    this.icon = Icons.receipt_long_outlined,
  });
  final String title;
  final List<(String, String)> rows;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFCFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: TenantAdminColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Icon(icon, color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: TenantAdminColors.bodyText)),
              ),
            ]),
            const SizedBox(height: 16),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(rows[i].$1)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(rows[i].$2,
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
}

class DiscountPreviewCard extends StatelessWidget {
  const DiscountPreviewCard({super.key, required this.state});
  final PosDiscountPresentationState state;

  @override
  Widget build(BuildContext context) {
    final base = state.preview.eligibleSubtotal;
    final hasAuthoritativePreview = state.isAuthoritativelyValid &&
        state.preview.discountAmount != null &&
        state.preview.totalAfterDiscount != null;
    final discountValue = hasAuthoritativePreview
        ? '- ${formatLkr(state.preview.discountAmount!)}'
        : '—';
    final totalValue = hasAuthoritativePreview
        ? formatLkr(state.preview.totalAfterDiscount!)
        : formatLkr(base);
    return Container(
      key: const Key('discount-preview-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFCF8FF), Color(0xFFF7F0FF)]),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Row(children: [
          Icon(Icons.sell_outlined, color: _purple),
          SizedBox(width: 8),
          Text('DISCOUNT PREVIEW',
              style: TextStyle(
                  color: _purple, fontWeight: FontWeight.w900, fontSize: 12)),
        ]),
        const SizedBox(height: 18),
        _PreviewRow(label: 'Discount', value: discountValue, danger: true),
        const Divider(height: 26),
        _PreviewRow(
          label: state.scope == PosDiscountScope.item
              ? 'Line Total After Discount'
              : 'Total After Discount',
          value: totalValue,
          emphasis: true,
        ),
        const SizedBox(height: 10),
        Text(
          hasAuthoritativePreview
              ? 'Validated by the server.'
              : 'Final values will appear after server validation.',
          style:
              const TextStyle(color: TenantAdminColors.mutedText, fontSize: 11),
        ),
      ]),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    this.danger = false,
    this.emphasis = false,
  });
  final String label;
  final String value;
  final bool danger;
  final bool emphasis;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: Text(label)),
        Text(value,
            style: TextStyle(
              color: danger
                  ? TenantAdminColors.posNewSaleAccent
                  : emphasis
                      ? _purple
                      : TenantAdminColors.bodyText,
              fontWeight: FontWeight.w900,
            )),
      ]);
}

class _SelectionGrid extends StatelessWidget {
  const _SelectionGrid({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label,
              style: const TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontSize: 12,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            if (children.length == 1 || constraints.maxWidth < 620) {
              return Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    SizedBox(width: double.infinity, child: children[i]),
                  ],
                ],
              );
            }
            return Row(children: [
              Expanded(child: children[0]),
              const SizedBox(width: 12),
              Expanded(child: children[1]),
            ]);
          }),
        ],
      );
}
