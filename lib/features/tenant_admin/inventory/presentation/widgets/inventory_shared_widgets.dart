import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class InventorySectionCard extends StatelessWidget {
  const InventorySectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFDDE4EE)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class InventoryStatCard extends StatelessWidget {
  const InventoryStatCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor = TenantAdminColors.primary,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InventorySectionCard(
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF53617C))),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InventoryStepper extends StatelessWidget {
  const InventoryStepper({
    super.key,
    required this.steps,
    required this.currentIndex,
  });

  final List<String> steps;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _StepChip(
              index: i + 1,
              label: steps[i],
              done: i < currentIndex,
              active: i == currentIndex,
            ),
            if (i < steps.length - 1)
              Container(
                width: 28,
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: i < currentIndex
                    ? const Color(0xFF62D57E)
                    : const Color(0xFFD9DFEB),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.index,
    required this.label,
    required this.done,
    required this.active,
  });

  final int index;
  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = done
        ? const Color(0xFF20BE4D)
        : active
            ? TenantAdminColors.primary
            : const Color(0xFFCFD8E7);
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color,
          child: Text(
            done ? '✓' : '$index',
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? TenantAdminColors.primary : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class InventorySuccessState extends StatelessWidget {
  const InventorySuccessState({
    super.key,
    required this.title,
    required this.message,
    this.details = const {},
    this.actions = const [],
  });

  final String title;
  final String message;
  final Map<String, String> details;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: InventorySectionCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF18BB50), width: 4),
                ),
                child: const Icon(Icons.check, color: Color(0xFF18BB50), size: 40),
              ),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF65758D))),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 16),
                for (final e in details.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(e.key,
                                style: const TextStyle(
                                    color: Color(0xFF64748B)))),
                        Text(e.value,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(spacing: 10, runSpacing: 10, children: actions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class InventoryPrimaryButton extends StatelessWidget {
  const InventoryPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: TenantAdminColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(140, 42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class InventoryGhostButton extends StatelessWidget {
  const InventoryGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(120, 42),
        foregroundColor: const Color(0xFF17345E),
        side: const BorderSide(color: Color(0xFFD5DCE7)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}

class InventorySearchField extends StatefulWidget {
  const InventorySearchField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint = 'Search by name, SKU or barcode',
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  State<InventorySearchField> createState() => _InventorySearchFieldState();
}

class _InventorySearchFieldState extends State<InventorySearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant InventorySearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
    );
  }
}

class InventoryStatusBadge extends StatelessWidget {
  const InventoryStatusBadge({super.key, required this.label, this.tone});

  final String label;
  final String? tone;

  @override
  Widget build(BuildContext context) {
    final t = (tone ?? label).toLowerCase();
    Color fg = const Color(0xFF5F6B7D);
    Color bg = const Color(0xFFF1F3F6);
    if (t.contains('high') || t.contains('out')) {
      fg = const Color(0xFFE42525);
      bg = const Color(0xFFFFF0F0);
    } else if (t.contains('low') || t.contains('medium') || t.contains('draft')) {
      fg = const Color(0xFFF27600);
      bg = const Color(0xFFFFF3E6);
    } else if (t.contains('posted') ||
        t.contains('in stock') ||
        t.contains('success')) {
      fg = const Color(0xFF08A53C);
      bg = const Color(0xFFEBFAEF);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
