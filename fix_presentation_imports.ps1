$files = Get-ChildItem -Path "c:\POS_PROPJECT\Nytroz-POS-App\lib\features\tenant_admin\inventory\presentation" -Recurse -Filter "*.dart" | Select-Object -ExpandProperty FullName

foreach ($file in $files) {
    $content = Get-Content $file -Raw
    $newContent = $content -replace "'../../../presentation/theme/tenant_admin_theme.dart'", "'../../../../presentation/theme/tenant_admin_theme.dart'"
    $newContent = $newContent -replace "'../../../presentation/widgets/tenant_admin_states.dart'", "'../../../../presentation/widgets/tenant_admin_states.dart'"
    $newContent = $newContent -replace "'../../../presentation/widgets/tenant_admin_page_scaffold.dart'", "'../../../../presentation/widgets/tenant_admin_page_scaffold.dart'"
    $newContent = $newContent -replace "'../../../presentation/widgets/tenant_admin_loading_state.dart'", "'../../../../presentation/widgets/tenant_admin_loading_state.dart'"
    $newContent = $newContent -replace "'../../../presentation/widgets/tenant_admin_error_state.dart'", "'../../../../presentation/widgets/tenant_admin_error_state.dart'"

    $newContent = $newContent -replace "'../providers/inventory_providers.dart'", "'../providers/current_stock_providers.dart'"
    $newContent = $newContent -replace "'../providers/inventory_dashboard_providers.dart'", "'../providers/inventory_dashboard_providers.dart'"

    $newContent = $newContent -replace "'../../domain/entities/inventory_entities.dart'", "'../../../domain/entities/current_stock_entities.dart'"
    $newContent = $newContent -replace "'../../data/models/inventory_dto.dart'", "'../../../data/models/current_stock_dtos.dart'"
    $newContent = $newContent -replace "'../../data/models/inventory_dashboard_models.dart'", "'../../../data/models/inventory_dashboard_models.dart'"
    
    if ($content -ne $newContent) {
        Set-Content $file $newContent
    }
}
