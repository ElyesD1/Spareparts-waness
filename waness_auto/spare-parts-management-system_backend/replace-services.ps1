# MongoDB Migration - Replace Old Service Files Script
# Run this after all .NEW.ts files are created and verified

$backupFolder = ".\backup_sql_services"

# Create backup folder if it doesn't exist
if (-not (Test-Path $backupFolder)) {
    New-Item -ItemType Directory -Path $backupFolder
    Write-Host "Created backup folder: $backupFolder" -ForegroundColor Green
}

# List of services to replace
$services = @(
    "src\users\users.service.ts",
    "src\warehouses\warehouse.service.ts",
    "src\suppliers\suppliers.service.ts",
    "src\products\products.service.ts",
    "src\purchases\purchases.service.ts",
    "src\purchase-item\purchase-item.service.ts",
    "src\sales\sales.service.ts",
    "src\sale-item\sale-item.service.ts",
    "src\product-stocks\product-stocks.service.ts",
    "src\stock-movement\stock-movement.service.ts",
    "src\customers\customers.service.ts",
    "src\credit-sales\credit-sales.service.ts",
    "src\credit-payments\credit-payments.service.ts",
    "src\supplier-credits\supplier-credits.service.ts",
    "src\purchase-returns\purchase-returns.service.ts",
    "src\product-transfers\product-transfers.service.ts",
    "src\operational_expenses\operational-expenses.service.ts",
    "src\otp\otp.service.ts",
    "src\auth\auth.service.ts",
    "src\auth\jwt.strategy.ts"
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "MongoDB Service Migration Script" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

foreach ($service in $services) {
    $oldFile = $service
    $newFile = $service.Replace(".ts", ".NEW.ts")
    
    if (Test-Path $newFile) {
        Write-Host "Processing: $service" -ForegroundColor Yellow
        
        # Backup old file
        $backupPath = Join-Path $backupFolder (Split-Path $service -Leaf)
        Copy-Item $oldFile $backupPath -Force
        Write-Host "  ✓ Backed up to: $backupPath" -ForegroundColor Gray
        
        # Replace with new file
        Copy-Item $newFile $oldFile -Force
        Write-Host "  ✓ Replaced with MongoDB version" -ForegroundColor Green
        
        # Optionally remove .NEW file
        # Remove-Item $newFile
    } else {
        Write-Host "⚠ Skipping $service - .NEW.ts file not found" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Migration Complete!" -ForegroundColor Green
Write-Host "Old files backed up to: $backupFolder" -ForegroundColor Gray
Write-Host "========================================`n" -ForegroundColor Cyan
Write-Host "Next step: Run 'npm run start:dev' to test" -ForegroundColor Yellow
