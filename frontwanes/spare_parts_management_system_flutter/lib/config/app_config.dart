/// Environment configuration for the application
/// This class manages API base URLs and other environment-specific settings
class AppConfig {
  // API Base URL - Change this based on your environment
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // Alternative: You can also read from a config file or use different values for debug/release
  static String get baseUrl {
    // In production, you might want to use a different URL
    // You can check if running in debug or release mode
    return apiBaseUrl;
  }

  // Helper methods for common endpoints
  static String get authUrl => '$baseUrl/auth';
  static String get productsUrl => '$baseUrl/products';
  static String get warehousesUrl => '$baseUrl/warehouses';
  static String get suppliersUrl => '$baseUrl/suppliers';
  static String get customersUrl => '$baseUrl/customers';
  static String get purchasesUrl => '$baseUrl/purchases';
  static String get salesUrl => '$baseUrl/sales';
  static String get usersUrl => '$baseUrl/users';
  static String get productStocksUrl => '$baseUrl/product-stocks';
  static String get movementsUrl => '$baseUrl/movements';
  static String get creditSalesUrl => '$baseUrl/credit-sales';
  static String get creditPaymentsUrl => '$baseUrl/credit-payments';
  static String get operationalExpensesUrl => '$baseUrl/operational-expenses';
  static String get purchaseReturnsUrl => '$baseUrl/purchase-returns';
  static String get supplierCreditsUrl => '$baseUrl/supplier-credits';
  static String get productTransfersUrl => '$baseUrl/product-transfers';
  static String get saleItemUrl => '$baseUrl/sale-item';
  static String get purchaseItemUrl => '$baseUrl/purchase-item';
  static String get otpUrl => '$baseUrl/otp';

  // Upload URLs
  static String uploadsUrl(String path) => '$baseUrl/uploads/$path';
  static String uploadsProductsUrl(String path) =>
      '$baseUrl/uploads/products/$path';
  static String imagesUrl(String path) => '$baseUrl/images/$path';
}
