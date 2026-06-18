import 'package:flutter/material.dart';

class TenantAdminErrorScreen extends StatelessWidget {
  const TenantAdminErrorScreen({
    super.key,
    this.message = 'Unable to load Tenant Admin. Please try again.',
    this.actionLabel = 'Retry',
    this.onRetry,
  });

  final String message;
  final String actionLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: onRetry,
                    child: Text(actionLabel),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
