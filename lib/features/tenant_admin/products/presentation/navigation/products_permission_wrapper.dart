import 'package:flutter/material.dart';

class ProductsPermissionWrapper extends StatelessWidget {
  const ProductsPermissionWrapper({
    super.key,
    required this.isVisible,
    required this.child,
  });

  final bool isVisible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return child;
  }
}
