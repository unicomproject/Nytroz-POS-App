import 'dart:io';

void main() {
  final file = File(
      r'c:\Users\User\Desktop\pos final wep\Tenantadmin\Nytroz-POS-App\lib\features\tenant_admin\outlets\presentation\widgets\outlet_form.dart');
  final content = file.readAsStringSync();

  const startText = 'class _OutletReviewStep extends StatelessWidget {';
  final startIndex = content.indexOf(startText);
  if (startIndex == -1) {
    // ignore: avoid_print
    print('Not found');
    return;
  }

  // ignore: avoid_print
  print(content.substring(startIndex, startIndex + 3000));
}
