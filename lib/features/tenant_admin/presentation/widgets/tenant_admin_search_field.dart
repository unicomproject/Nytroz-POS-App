import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

class TenantAdminSearchField extends StatefulWidget {
  const TenantAdminSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.value = '',
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  final String hint;
  final String value;
  final ValueChanged<String> onChanged;
  final Duration debounceDuration;

  @override
  State<TenantAdminSearchField> createState() => _TenantAdminSearchFieldState();
}

class _TenantAdminSearchFieldState extends State<TenantAdminSearchField> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant TenantAdminSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: TenantAdminColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.lg,
          vertical: TenantAdminSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          borderSide: const BorderSide(color: TenantAdminColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          borderSide: const BorderSide(color: TenantAdminColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          borderSide: const BorderSide(color: TenantAdminColors.primary),
        ),
      ),
    );
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onChanged(value);
    });
  }
}
