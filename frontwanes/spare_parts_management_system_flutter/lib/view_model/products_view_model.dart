import 'package:flutter/material.dart';
import '../models/domain/product.dart';
import '../services/product_service.dart';

class ProductsViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _loading = true;
  String _search = '';
  int _currentPage = 1;
  static const int _productsPerPage = 10;
  String? _error;

  // Getters
  List<Product> get products => _products;
  List<Product> get filteredProducts => _filteredProducts;
  bool get loading => _loading;
  String get search => _search;
  int get currentPage => _currentPage;
  int get productsPerPage => _productsPerPage;
  String? get error => _error;

  List<Product> get paginatedProducts {
    final start = (_currentPage - 1) * _productsPerPage;
    final end = (_currentPage * _productsPerPage).clamp(
      0,
      _filteredProducts.length,
    );
    return _filteredProducts.sublist(start, end);
  }

  int get totalPages =>
      (_filteredProducts.length / _productsPerPage).ceil().clamp(1, 999);

  // Statistics
  int get totalProducts => _products.length;
  int get activeProducts => _products.where((p) => p.unitPrice > 0).length;
  int get totalCategories => _products.map((p) => p.category).toSet().length;
  int get totalBrands => _products.map((p) => p.brand).toSet().length;

  Future<void> loadProducts() async {
    _setLoading(true);
    _clearError();

    try {
      final products = await _productService.getProducts();
      _products = products;
      _filteredProducts = products;
      _currentPage = 1;
    } catch (e) {
      _setError('Échec du chargement des produits: $e');
    } finally {
      _setLoading(false);
    }
  }

  void searchProducts(String query) {
    _search = query;
    _filteredProducts =
        _products
            .where(
              (p) =>
                  p.name.toLowerCase().contains(_search.toLowerCase()) ||
                  p.referenceCode.toLowerCase().contains(
                    _search.toLowerCase(),
                  ) ||
                  (p.barcode != null &&
                      p.barcode!.toLowerCase().contains(_search.toLowerCase())),
            )
            .toList();
    _currentPage = 1;
    notifyListeners();
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      _currentPage = page;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _productService.deleteProduct(productId);
      await loadProducts(); // Reload to refresh the list
    } catch (e) {
      _setError('Erreur lors de la suppression: $e');
      rethrow; // propagate to UI so it can show an error toast
    }
  }

  void _setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
