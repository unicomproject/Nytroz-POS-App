$files = Get-ChildItem -Path "c:\POS_PROPJECT\Nytroz-POS-App\test" -Recurse -Filter "*.dart" | Select-Object -ExpandProperty FullName

foreach ($file in $files) {
    $content = Get-Content $file -Raw
    $newContent = $content -replace "inventory/domain/entities/inventory_entities.dart", "inventory/domain/entities/current_stock_entities.dart"
    $newContent = $newContent -replace "inventory/presentation/providers/inventory_providers.dart", "inventory/presentation/current_stock/providers/current_stock_providers.dart"
    $newContent = $newContent -replace "inventory/presentation/screens/current_stock_screen.dart", "inventory/presentation/current_stock/screens/current_stock_screen.dart"
    $newContent = $newContent -replace "inventory/data/models/inventory_dto.dart", "inventory/data/models/current_stock_dtos.dart"
    
    if ($content -ne $newContent) {
        Set-Content $file $newContent
    }
}
