# Comprehensive fix for remaining 78 errors# PowerShell script to fix remaining 78 errors



Write-Host "Fixing remaining type errors..." -ForegroundColor CyanWrite-Host "Fixing view models..." -ForegroundColor Yellow



# Fix purchase_return_form.dart (20 errors) - revert quantity to int# Fix view_model parameter declarations from int to String

Write-Host "Fixing purchase_return_form.dart..." -ForegroundColor Yellow(Get-Content "lib\view_model\credit_sales_view_model.dart") `

(Get-Content "lib\views\widgets\purchase_return_form.dart") `    -replace 'Future<void> updateStatus\(int id', 'Future<void> updateStatus(String id' `

    -replace 'int\.tryParse\(quantity\) == null \|\| int\.parse\(quantity\) <= 0', 'quantity <= 0' `    -replace 'loadCustomerCreditSales\(int customerId', 'loadCustomerCreditSales(String customerId' `

    -replace '  String quantity;', '  int quantity;' `    -replace 'loadCreditSaleById\(int id', 'loadCreditSaleById(String id' `

    -replace "firstWhere\(\(p\) => p\['id'\] == productId\)", "firstWhere((p) => p['id']?.toString() == productId)" `    -replace 'deleteCreditSale\(int id', 'deleteCreditSale(String id' `

    -replace "firstWhere\(\(item\) => item\.productId == productId\)", "firstWhere((item) => item.productId == productId)" `    | Set-Content "lib\view_model\credit_sales_view_model.dart"

    -replace "removeWhere\(\(item\) => item\.productId == productId\)", "removeWhere((item) => item.productId == productId)" `

    | Set-Content "lib\views\widgets\purchase_return_form.dart"(Get-Content "lib\view_model\products_view_model.dart") `

    -replace 'loadProductsByWarehouse\(int warehouseId', 'loadProductsByWarehouse(String warehouseId' `

# Fix new_purchase_form.dart (8 errors)    | Set-Content "lib\view_model\products_view_model.dart"

Write-Host "Fixing new_purchase_form.dart..." -ForegroundColor Yellow

(Get-Content "lib\views\widgets\new_purchase_form.dart") `(Get-Content "lib\view_model\sales_view_model.dart") `

    -replace "firstWhere\(\(s\) => s\['id'\] == selectedSupplierId\)", "firstWhere((s) => s['id']?.toString() == selectedSupplierId)" `    -replace 'Future<void> updateSale\(int id', 'Future<void> updateSale(String id' `

    -replace "firstWhere\(\(p\) => p\.id == selectedProductId\)", "firstWhere((p) => p.id == selectedProductId)" `    -replace 'deleteSale\(int id', 'deleteSale(String id' `

    -replace "firstWhere\(\(w\) => w\['id'\] == selectedWarehouseId\)", "firstWhere((w) => w['id']?.toString() == selectedWarehouseId)" `    | Set-Content "lib\view_model\sales_view_model.dart"

    | Set-Content "lib\views\widgets\new_purchase_form.dart"

Write-Host "Fixing screen files..." -ForegroundColor Yellow

# Fix operational_expense_form.dart (7 errors)

Write-Host "Fixing operational_expense_form.dart..." -ForegroundColor Yellow# Fix credit_sale_form.dart - change dropdown type and variable

(Get-Content "lib\views\widgets\operational_expense_form.dart") `(Get-Content "lib\views\screens\credit_sale_form.dart") `

    -replace "firstWhere\(\(w\) => w\['id'\] == widget\.expense\.warehouseId\)", "firstWhere((w) => w['id']?.toString() == widget.expense.warehouseId)" `    -replace 'DropdownButtonFormField<int>', 'DropdownButtonFormField<String>' `

    | Set-Content "lib\views\widgets\operational_expense_form.dart"    -replace 'DropdownMenuItem<int>', 'DropdownMenuItem<String>' `

    -replace "value: w\['id'\] as int", "value: w['id']?.toString()" `

# Fix product_transfer_form.dart (7 errors)    -replace '  int\? selectedWarehouseId;', '  String? selectedWarehouseId;' `

Write-Host "Fixing product_transfer_form.dart..." -ForegroundColor Yellow    | Set-Content "lib\views\screens\credit_sale_form.dart"

(Get-Content "lib\views\widgets\product_transfer_form.dart") `

    -replace "firstWhere\(\(p\) => p\.id == selectedProductId\)", "firstWhere((p) => p.id == selectedProductId)" `# Fix market_screen.dart

    -replace "firstWhere\(\(w\) => w\['id'\] == fromWarehouseId\)", "firstWhere((w) => w['id']?.toString() == fromWarehouseId)" `(Get-Content "lib\views\screens\market_screen.dart") `

    -replace "firstWhere\(\(w\) => w\['id'\] == toWarehouseId\)", "firstWhere((w) => w['id']?.toString() == toWarehouseId)" `    -replace 'DropdownButtonFormField<int>', 'DropdownButtonFormField<String>' `

    | Set-Content "lib\views\widgets\product_transfer_form.dart"    -replace 'DropdownMenuItem<int>', 'DropdownMenuItem<String>' `

    -replace "value: w\['id'\] as int", "value: w['id']?.toString()" `

# Fix stock_movement_form_dialog.dart (4 errors)    -replace '  int\? _selectedWarehouseId;', '  String? _selectedWarehouseId;' `

Write-Host "Fixing stock_movement_form_dialog.dart..." -ForegroundColor Yellow    | Set-Content "lib\views\screens\market_screen.dart"

(Get-Content "lib\views\widgets\stock_movement_form_dialog.dart") `

    -replace "firstWhere\(\(p\) => p\.id == _selectedProductId\)", "firstWhere((p) => p.id == _selectedProductId)" `# Fix product_transfer_screen.dart

    -replace "firstWhere\(\(w\) => w\['id'\] == _selectedWarehouseId\)", "firstWhere((w) => w['id']?.toString() == _selectedWarehouseId)" `(Get-Content "lib\views\screens\product_transfer_screen.dart") `

    -replace "firstWhere\(\(w\) => w\['id'\] == _selectedFromWarehouseId\)", "firstWhere((w) => w['id']?.toString() == _selectedFromWarehouseId)" `    -replace 'DropdownButtonFormField<int>', 'DropdownButtonFormField<String>' `

    -replace "firstWhere\(\(w\) => w\['id'\] == _selectedToWarehouseId\)", "firstWhere((w) => w['id']?.toString() == _selectedToWarehouseId)" `    -replace 'DropdownMenuItem<int>', 'DropdownMenuItem<String>' `

    | Set-Content "lib\views\widgets\stock_movement_form_dialog.dart"    -replace "value: w\['id'\] as int", "value: w['id']?.toString()" `

    -replace '  int\? selectedWarehouseId;', '  String? selectedWarehouseId;' `

# Fix sale_item_form.dart (4 errors)    | Set-Content "lib\views\screens\product_transfer_screen.dart"

Write-Host "Fixing sale_item_form.dart..." -ForegroundColor Yellow

(Get-Content "lib\views\widgets\sale_item_form.dart") `# Fix products_screen.dart

    -replace "firstWhere\(\(p\) => p\.id == _selectedProductId\)", "firstWhere((p) => p.id == _selectedProductId)" `(Get-Content "lib\views\screens\products_screen.dart") `

    -replace "firstWhere\(\(w\) => w\['id'\] == _selectedWarehouseId\)", "firstWhere((w) => w['id']?.toString() == _selectedWarehouseId)" `    -replace 'DropdownButtonFormField<int>', 'DropdownButtonFormField<String>' `

    | Set-Content "lib\views\widgets\sale_item_form.dart"    -replace 'DropdownMenuItem<int>', 'DropdownMenuItem<String>' `

    -replace "value: w\['id'\] as int", "value: w['id']?.toString()" `

# Fix product_form.dart (4 errors)    -replace '  int\? _selectedWarehouseId;', '  String? _selectedWarehouseId;' `

Write-Host "Fixing product_form.dart..." -ForegroundColor Yellow    | Set-Content "lib\views\screens\products_screen.dart"

(Get-Content "lib\views\widgets\product_form.dart") `

    -replace "firstWhere\(\(s\) => s\['id'\] == widget\.product\.supplierId\)", "firstWhere((s) => s['id']?.toString() == widget.product.supplierId)" `# Fix sales_screen.dart

    -replace "firstWhere\(\(s\) => s\['id'\] == _selectedSupplierId\)", "firstWhere((s) => s['id']?.toString() == _selectedSupplierId)" `(Get-Content "lib\views\screens\sales_screen.dart") `

    | Set-Content "lib\views\widgets\product_form.dart"    -replace 'DropdownButtonFormField<int>', 'DropdownButtonFormField<String>' `

    -replace 'DropdownMenuItem<int>', 'DropdownMenuItem<String>' `

# Fix edit_purchase_form.dart    -replace "value: w\['id'\] as int", "value: w['id']?.toString()" `

Write-Host "Fixing edit_purchase_form.dart..." -ForegroundColor Yellow    -replace '  int\? _selectedWarehouseId;', '  String? _selectedWarehouseId;' `

(Get-Content "lib\views\widgets\edit_purchase_form.dart") `    | Set-Content "lib\views\screens\sales_screen.dart"

    -replace "firstWhere\(\(p\) => p\.id == selectedProductId\)", "firstWhere((p) => p.id == selectedProductId)" `

    -replace "firstWhere\(\(w\) => w\['id'\] == selectedWarehouseId\)", "firstWhere((w) => w['id']?.toString() == selectedWarehouseId)" `# Fix stock_movement_listscreen.dart - change dropdown types

    -replace "firstWhere\(\(s\) => s\['id'\] == selectedSupplierId\)", "firstWhere((s) => s['id']?.toString() == selectedSupplierId)" `(Get-Content "lib\views\screens\stock_movement_listscreen.dart") `

    | Set-Content "lib\views\widgets\edit_purchase_form.dart"    -replace 'DropdownButtonFormField<int\?>', 'DropdownButtonFormField<String?>' `

    -replace 'DropdownMenuItem<int\?>', 'DropdownMenuItem<String?>' `

# Fix sales_form.dart (2 errors)    -replace "value: p\['id'\] as int\?", "value: p['id']?.toString()" `

Write-Host "Fixing sales_form.dart..." -ForegroundColor Yellow    -replace "value: w\['id'\] as int\?", "value: w['id']?.toString()" `

(Get-Content "lib\views\widgets\sales_form.dart") `    -replace '  int\? _selectedProductId;', '  String? _selectedProductId;' `

    -replace "firstWhere\(\(w\) => w\['id'\] == selectedWarehouseId\)", "firstWhere((w) => w['id']?.toString() == selectedWarehouseId)" `    -replace '  int\? _selectedWarehouseId;', '  String? _selectedWarehouseId;' `

    | Set-Content "lib\views\widgets\sales_form.dart"    | Set-Content "lib\views\screens\stock_movement_listscreen.dart"



# Fix payment_form.dart (1 error)Write-Host "Fixing widget files..." -ForegroundColor Yellow

Write-Host "Fixing payment_form.dart..." -ForegroundColor Yellow

(Get-Content "lib\views\widgets\payment_form.dart") `# Fix edit_purchase_form.dart - local variables in methods

    -replace "firstWhere\(\(cs\) => cs\['id'\] == selectedCreditSaleId\)", "firstWhere((cs) => cs['id']?.toString() == selectedCreditSaleId)" `(Get-Content "lib\views\widgets\edit_purchase_form.dart") `

    | Set-Content "lib\views\widgets\payment_form.dart"    -replace '    int\? selectedProductId;', '    String? selectedProductId;' `

    -replace '    int\? selectedWarehouseId;', '    String? selectedWarehouseId;' `

# Fix credit_sale_form.dart (2 errors)    -replace 'int quantity = 1;', 'int quantity = 1;' `

Write-Host "Fixing credit_sale_form.dart..." -ForegroundColor Yellow    | Set-Content "lib\views\widgets\edit_purchase_form.dart"

(Get-Content "lib\views\screens\credit_sale_form.dart") `

    -replace "firstWhere\(\(w\) => w\['id'\] == _selectedWarehouseId\)", "firstWhere((w) => w['id']?.toString() == _selectedWarehouseId)" `# Fix new_purchase_form.dart - more comprehensive fixes

    | Set-Content "lib\views\screens\credit_sale_form.dart"(Get-Content "lib\views\widgets\new_purchase_form.dart") `

    -replace '    int\? tempProductId;', '    String? tempProductId;' `

Write-Host "All fixes applied!" -ForegroundColor Green    -replace '    int\? tempWarehouseId;', '    String? tempWarehouseId;' `

    -replace 'int tempQuantity = 1;', 'int tempQuantity = 1;' `
    | Set-Content "lib\views\widgets\new_purchase_form.dart"

# Fix operational_expense_form.dart - constructor parameters and state variables
(Get-Content "lib\views\widgets\operational_expense_form.dart") `
    -replace 'required this\.warehouseId,', 'required this.warehouseId,' `
    -replace 'this\.createdBy,', 'this.createdBy,' `
    | Set-Content "lib\views\widgets\operational_expense_form.dart"

# Fix purchase_return_form.dart - quantity type and comparisons
(Get-Content "lib\views\widgets\purchase_return_form.dart") `
    -replace 'final int quantity;', 'final String quantity;' `
    | Set-Content "lib\views\widgets\purchase_return_form.dart"

# Fix sale_item_form.dart - local variables
(Get-Content "lib\views\widgets\sale_item_form.dart") `
    -replace '    int\? selectedProductId;', '    String? selectedProductId;' `
    -replace '    int\? selectedWarehouseId;', '    String? selectedWarehouseId;' `
    | Set-Content "lib\views\widgets\sale_item_form.dart"

# Fix payment_form.dart - dropdown items
(Get-Content "lib\views\widgets\payment_form.dart") `
    -replace "value: cs\['id'\] as int", "value: cs['id']?.toString()" `
    | Set-Content "lib\views\widgets\payment_form.dart"

Write-Host "Type fixes applied! Running analyze..." -ForegroundColor Green
flutter analyze --no-pub 2>&1 | Select-String "error -" | Measure-Object -Line
