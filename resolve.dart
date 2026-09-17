import 'dart:io';

void main() {
  final files = [
    'lib/core/access/pos_permission_access.dart',
    'lib/core/network/api_endpoints.dart',
    'lib/features/fulfilment_pickup/data/datasources/pos_online_orders_remote_datasource.dart',
    'lib/features/fulfilment_pickup/data/repositories/pos_online_orders_repository_impl.dart',
    'lib/features/fulfilment_pickup/domain/repositories/pos_online_orders_repository.dart',
    'lib/features/fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart',
    'lib/features/fulfilment_pickup/presentation/screens/ready_for_collection_screen.dart',
    'lib/features/fulfilment_pickup/presentation/screens/review_pack_screen.dart'
  ];

  final pattern = RegExp(r'<<<<<<< HEAD\r?\n(.*?)\r?\n=======\r?\n(.*?)\r?\n>>>>>>> origin/main\r?\n?', dotAll: true);

  for (final filepath in files) {
    final file = File(filepath);
    if (!file.existsSync()) continue;
    final content = file.readAsStringSync();
    final newContent = content.replaceAllMapped(pattern, (match) {
      return '${match.group(1)}\n${match.group(2)}\n';
    });
    file.writeAsStringSync(newContent);
    print('Resolved ${filepath}');
  }
}
