# PowerShell script to fix remaining type mismatches

# Fix view_model files
(Get-Content "lib\view_model\credit_sales_view_model.dart") `
    -replace 'sale\.id!', 'sale.id' `
    | Set-Content "lib\view_model\credit_sales_view_model.dart"

(Get-Content "lib\view_model\products_view_model.dart") `
    -replace 'warehouse\.id!', 'warehouse.id' `
    | Set-Content "lib\view_model\products_view_model.dart"

(Get-Content "lib\view_model\sales_view_model.dart") `
    -replace 'sale\.id!', 'sale.id' `
    | Set-Content "lib\view_model\sales_view_model.dart"

# Fix widget files - new_purchase_form.dart
(Get-Content "lib\views\widgets\new_purchase_form.dart") `
    -replace 'value: p\.id as int,', 'value: p.id,' `
    -replace "value: w\['id'\]\?\.toString\(\) as int,", "value: w['id']?.toString()," `
    -replace "value: s\['id'\]\?\.toString\(\) as int,", "value: s['id']?.toString()," `
    | Set-Content "lib\views\widgets\new_purchase_form.dart"

# Fix operational_expense_form.dart - change int variables to String
(Get-Content "lib\views\widgets\operational_expense_form.dart") `
    -replace '  int warehouseId;', '  String warehouseId;' `
    -replace '  int\? createdBy;', '  String? createdBy;' `
    | Set-Content "lib\views\widgets\operational_expense_form.dart"

# Fix product_form.dart
(Get-Content "lib\views\widgets\product_form.dart") `
    -replace 'value: s\.id as int,', 'value: s.id,' `
    | Set-Content "lib\views\widgets\product_form.dart"

# Fix product_transfer_form.dart - add missing dropdown type fixes
(Get-Content "lib\views\widgets\product_transfer_form.dart") `
    -replace '  int\? fromWarehouseId;', '  String? fromWarehouseId;' `
    -replace '  int\? toWarehouseId;', '  String? toWarehouseId;' `
    -replace '  int\? selectedProductId;', '  String? selectedProductId;' `
    -replace 'value: p\.id as int,', 'value: p.id,' `
    -replace "value: w\['id'\]\?\.toString\(\) as int,", "value: w['id']?.toString()," `
    | Set-Content "lib\views\widgets\product_transfer_form.dart"

# Fix purchase_return_form.dart - fix quantity comparison and dropdown types
(Get-Content "lib\views\widgets\purchase_return_form.dart") `
    -replace '  int quantity;', '  String quantity;' `
    -replace 'quantity <= 0', 'int.tryParse(quantity) == null || int.parse(quantity) <= 0' `
    -replace 'DropdownButtonFormField<int>', 'DropdownButtonFormField<String>' `
    -replace 'DropdownMenuItem<int>', 'DropdownMenuItem<String>' `
    -replace "value: p\['id'\]\?\.toString\(\) as int,", "value: p['id']?.toString()," `
    | Set-Content "lib\views\widgets\purchase_return_form.dart"

# Fix sale_item_form.dart
(Get-Content "lib\views\widgets\sale_item_form.dart") `
    -replace 'value: p\.id as int,', 'value: p.id,' `
    -replace "value: w\['id'\]\?\.toString\(\) as int,", "value: w['id']?.toString()," `
    | Set-Content "lib\views\widgets\sale_item_form.dart"

# Fix sales_form.dart
(Get-Content "lib\views\widgets\sales_form.dart") `
    -replace '  int\? selectedWarehouseId;', '  String? selectedWarehouseId;' `
    -replace "value: w\['id'\]\?\.toString\(\) as int,", "value: w['id']?.toString()," `
    | Set-Content "lib\views\widgets\sales_form.dart"

# Fix stock_movement_form_dialog.dart - change variable types
(Get-Content "lib\views\widgets\stock_movement_form_dialog.dart") `
    -replace '  int\? _selectedProductId;', '  String? _selectedProductId;' `
    -replace '  int\? _selectedWarehouseId;', '  String? _selectedWarehouseId;' `
    -replace '  int\? _selectedFromWarehouseId;', '  String? _selectedFromWarehouseId;' `
    -replace '  int\? _selectedToWarehouseId;', '  String? _selectedToWarehouseId;' `
    -replace 'value: p\.id as int,', 'value: p.id,' `
    -replace "value: w\['id'\]\?\.toString\(\) as int,", "value: w['id']?.toString()," `
    | Set-Content "lib\views\widgets\stock_movement_form_dialog.dart"

# Fix payment_form.dart
(Get-Content "lib\views\widgets\payment_form.dart") `
    -replace "value: cs\['id'\]\?\.toString\(\) as int,", "value: cs['id']?.toString()," `
    | Set-Content "lib\views\widgets\payment_form.dart"

Write-Host "Type fixes applied successfully!" -ForegroundColor Green
