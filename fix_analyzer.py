import re
import os

fixes = [
    (r"lib/features/tenant_admin/brands/presentation/widgets/brand_form_dialog.dart", 142, "value:", "initialValue:"),
    (r"lib/features/tenant_admin/inventory/presentation/widgets/current_stock_filter_bar.dart", 199, "value:", "initialValue:"),
    (r"lib/features/tenant_admin/inventory/presentation/widgets/current_stock_filter_bar.dart", 232, "value:", "initialValue:"),
    (r"lib/features/tenant_admin/inventory/presentation/widgets/current_stock_filter_bar.dart", 267, "value:", "initialValue:"),
    (r"lib/features/tenant_admin/inventory/presentation/widgets/stock_in_line_items_panel.dart", 232, "value:", "initialValue:"),
    (r"lib/features/tenant_admin/inventory/presentation/widgets/stock_in_reference_section.dart", 43, "value:", "initialValue:"),
    (r"lib/features/tenant_admin/tills/presentation/widgets/till_form.dart", 280, "value:", "initialValue:"),
    (r"lib/features/tenant_admin/tills/presentation/widgets/till_form.dart", 308, "value:", "initialValue:"),
]

for file_path, line_num, target, replacement in fixes:
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    idx = line_num - 1
    if target in lines[idx]:
        lines[idx] = lines[idx].replace(target, replacement)
        with open(file_path, 'w', encoding='utf-8') as f:
            f.writelines(lines)

# Fix const issues
test_files = [
    r"test/features/tenant_admin/inventory_dto_test.dart",
    r"test/features/tenant_admin/product_create_request_dto_test.dart",
    r"test/features/tenant_admin/product_update_request_dto_test.dart"
]

for file_path in test_files:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    # Add ignore comment at top of file
    if "// ignore_for_file: prefer_const_constructors" not in content:
        content = "// ignore_for_file: prefer_const_constructors\n" + content
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)

# Fix the last const issue in product_dashboard_summary_card.dart:84
f_path = r"lib/features/tenant_admin/products/presentation/dashboard/product_dashboard_summary_card.dart"
with open(f_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()
idx = 84 - 1
if "padding:" in lines[idx] and "const" not in lines[idx]:
    lines[idx] = lines[idx].replace("EdgeInsets", "const EdgeInsets")
    with open(f_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
