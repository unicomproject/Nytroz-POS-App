import 'dart:io';

void main() {
  final file = File(r'c:\Users\User\Desktop\pos final wep\Tenantadmin\Nytroz-POS-App\lib\features\tenant_admin\outlets\presentation\widgets\outlet_form.dart');
  final content = file.readAsStringSync();
  
  const startText = 'class _OutletLocationContactStep extends StatelessWidget {';
  const endText = 'class _OutletReviewStep extends StatelessWidget {';
  
  final startIndex = content.indexOf(startText);
  final endIndex = content.indexOf(endText);
  
  if (startIndex == -1 || endIndex == -1) {
    // ignore: avoid_print
    print('Could not find start or end index');
    return;
  }
  
  final text = content.substring(startIndex, endIndex);
  File(r'c:\Users\User\Desktop\scratch_location_step.txt').writeAsStringSync(text);
  // ignore: avoid_print
  print('Saved to scratch_location_step.txt');
}
