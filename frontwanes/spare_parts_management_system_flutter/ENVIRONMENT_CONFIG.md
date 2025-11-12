# Environment Configuration Guide

## Overview
This Flutter application uses environment variables to configure the API endpoints. This allows you to easily switch between different environments (development, staging, production) without modifying the code.

## Configuration File
The application uses `lib/config/app_config.dart` to centralize all API endpoint configurations.

## Setting Environment Variables

### Development Environment
For local development, the default value is `http://localhost:3000`.

### Production/Staging Environment
To override the default API URL, use the `--dart-define` flag when building or running the app:

```bash
# For development with custom API URL
flutter run --dart-define=API_BASE_URL=http://your-dev-server:3000

# For staging
flutter run --dart-define=API_BASE_URL=https://staging.example.com

# For production
flutter build apk --dart-define=API_BASE_URL=https://api.example.com
flutter build ios --dart-define=API_BASE_URL=https://api.example.com
flutter build web --dart-define=API_BASE_URL=https://api.example.com
```

### Multiple Environment Variables
You can pass multiple environment variables:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=OTHER_VAR=value
```

## Available Configuration

### AppConfig Class
Located at `lib/config/app_config.dart`, this class provides:

- `baseUrl`: Base URL for the API (default: http://localhost:3000)
- `authUrl`: Authentication endpoints
- `usersUrl`: User management endpoints
- `productsUrl`: Product management endpoints
- `warehousesUrl`: Warehouse management endpoints
- `customersUrl`: Customer management endpoints
- `suppliersUrl`: Supplier management endpoints
- `purchasesUrl`: Purchase management endpoints
- `salesUrl`: Sales management endpoints
- `movementsUrl`: Stock movement endpoints
- `productStocksUrl`: Product stock endpoints
- `productTransfersUrl`: Product transfer endpoints
- `purchaseReturnsUrl`: Purchase return endpoints
- `supplierCreditsUrl`: Supplier credit endpoints
- `operationalExpensesUrl`: Operational expense endpoints
- `purchaseItemUrl`: Purchase item endpoints
- `saleItemUrl`: Sale item endpoints
- `otpUrl`: OTP/verification endpoints
- `uploadsUrl`: File upload base URL

## VS Code Configuration (Optional)
You can create a launch configuration in `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter (Development)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=API_BASE_URL=http://localhost:3000"
      ]
    },
    {
      "name": "Flutter (Staging)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=API_BASE_URL=https://staging.example.com"
      ]
    },
    {
      "name": "Flutter (Production)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=API_BASE_URL=https://api.example.com"
      ]
    }
  ]
}
```

## Backend Configuration
Make sure your backend server is properly configured in:
- Path: `waness_auto/spare-parts-management-system_backend/.env`
- See `.env.example` for required variables

## Testing Different Environments
1. **Local Development**: No changes needed, uses localhost:3000 by default
2. **Testing with Different Server**: Use `--dart-define=API_BASE_URL=http://your-test-server:3000`
3. **Production Build**: Always specify production URL with `--dart-define`

## Important Notes
- The `--dart-define` values are compiled into the app at build time
- You must rebuild the app when changing environment variables
- Do not commit actual API URLs to version control
- Use `.env.example` as a template for your `.env` file
