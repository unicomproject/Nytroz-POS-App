import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category.dart';
import '../providers/category_providers.dart';
import 'category_archive_dialog.dart';

Future<void> archiveCategory(
  BuildContext context,
  WidgetRef ref,
  Category category, {
  bool navigateToListOnSuccess = false,
  VoidCallback? onSuccess,
}) async {
  await CategoryArchiveDialog.show(
    context: context,
    category: category,
    navigateToListOnSuccess: navigateToListOnSuccess,
    onSuccess: onSuccess,
  );
}

Future<void> toggleCategoryStatus(
  BuildContext context,
  WidgetRef ref,
  Category category,
) async {
  try {
    final updated =
        await ref.read(categorySaveControllerProvider.notifier).toggleStatus(category);
    ref.invalidate(categoryDetailsProvider(category.id));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated.isActive
                ? 'Category activated successfully.'
                : 'Category inactivated successfully.',
          ),
        ),
      );
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(categoryApiErrorMessage(error))),
      );
    }
    rethrow;
  }
}
