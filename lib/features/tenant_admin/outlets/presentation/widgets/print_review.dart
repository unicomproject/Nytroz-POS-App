import 'dart:io';

void main() {
  final file = File(r'c:\Users\User\Desktop\pos final wep\Tenantadmin\Nytroz-POS-App\lib\features\tenant_admin\outlets\presentation\widgets\outlet_form.dart');
  final content = file.readAsStringSync();
  
  final startText = 'class _OutletReviewStep extends StatelessWidget {';
  final startIndex = content.indexOf(startText);
  if (startIndex == -1) {
    print('Not found');
    return;
  }
  
  print(content.substring(startIndex, startIndex + 3000));
}
