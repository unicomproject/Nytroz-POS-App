import 'package:flutter/foundation.dart';

import '../models/pos_device_printer_config.dart';

const int localPrintAgentMinimumTimeoutMs = 1000;
const int localPrintAgentMaximumTimeoutMs = 30000;
const int localPrintAgentMinimumApiKeyLength = 24;

List<String> validateLocalPrintAgentConfig(PosDevicePrinterConfig config) {
  final errors = <String>[];
  final rawUrl = config.agentBaseUrl?.trim() ?? '';
  final uri = Uri.tryParse(rawUrl);
  if (rawUrl.isEmpty) {
    errors.add('Agent URL is required.');
  } else if (uri == null ||
      !uri.hasAuthority ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    errors.add('Agent URL must be a valid http or https URL.');
  } else if (uri.path.toLowerCase().endsWith('/api/print/receipt')) {
    errors.add('Enter the agent base URL, not the receipt endpoint.');
  } else if (kReleaseMode && uri.scheme != 'https') {
    errors.add(
      'Production release requires a trusted HTTPS Print Agent URL.',
    );
  }
  if ((config.localApiKey ?? '').length < localPrintAgentMinimumApiKeyLength) {
    errors.add('API key must contain at least 24 characters.');
  }
  if (config.connectionTimeoutMs < localPrintAgentMinimumTimeoutMs ||
      config.connectionTimeoutMs > localPrintAgentMaximumTimeoutMs) {
    errors.add('Timeout must be between 1 and 30 seconds.');
  }
  return errors;
}

String normalizeLocalPrintAgentUrl(String value) {
  var normalized = value.trim();
  while (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final uri = Uri.tryParse(normalized);
    if (uri != null) {
      final host = uri.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
        final port = uri.hasPort ? ':${uri.port}' : '';
        normalized = '${uri.scheme}://10.0.2.2$port${uri.path}';
        while (normalized.endsWith('/')) {
          normalized = normalized.substring(0, normalized.length - 1);
        }
      }
    }
  }
  return normalized;
}

bool isLoopbackAgentUrl(String value) {
  final host = Uri.tryParse(value.trim())?.host.toLowerCase();
  return host == 'localhost' || host == '127.0.0.1' || host == '::1';
}

String maskLocalPrintAgentApiKey(String? value) {
  final key = value ?? '';
  if (key.isEmpty) return '';
  if (key.length <= 4) return '••••';
  return '${List.filled(key.length - 4, '•').join()}${key.substring(key.length - 4)}';
}

String? physicalAndroidLoopbackWarning(String value) {
  if (!kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      isLoopbackAgentUrl(value)) {
    return 'localhost points to this phone. Use the Windows laptop LAN IP.';
  }
  return null;
}
