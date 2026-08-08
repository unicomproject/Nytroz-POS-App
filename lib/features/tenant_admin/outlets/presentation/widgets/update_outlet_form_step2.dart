import 'dart:io';

void main() {
  final file = File(r'c:\Users\User\Desktop\pos final wep\Tenantadmin\Nytroz-POS-App\lib\features\tenant_admin\outlets\presentation\widgets\outlet_form.dart');
  final content = file.readAsStringSync();
  
  final startText = '2 => TenantAdminFormSection(';
  final endText = '_ => _OutletReviewStep(';
  
  final startIndex = content.indexOf(startText);
  final endIndex = content.indexOf(endText);
  
  if (startIndex == -1 || endIndex == -1) {
    print('Indices not found!');
    return;
  }
  
  final replacement = '''2 => BusinessHoursEditor(
          hours: _openingHours,
          errors: _businessHourErrors,
          onChanged: () => setState(_businessHourErrors.clear),
          onApplyMondayToWeekdays: _applyMondayToWeekdays,
        ),
      ''';
      
  final newContent = content.replaceRange(startIndex, endIndex, replacement);
  file.writeAsStringSync(newContent);
  print('Successfully updated step 2 in outlet_form.dart');
}
