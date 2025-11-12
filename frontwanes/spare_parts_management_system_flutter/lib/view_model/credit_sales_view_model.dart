import 'package:flutter/foundation.dart';
import '../models/domain/credit_sale.dart';
import '../services/credit_sales_service.dart';

class CreditSalesViewModel extends ChangeNotifier {
  final CreditSalesService _creditSalesService = CreditSalesService();

  List<CreditSale> _creditSales = [];
  bool _isLoading = false;
  String? _error;
  CreditSale? _selectedCreditSale;

  // Getters
  List<CreditSale> get creditSales => _creditSales;
  bool get isLoading => _isLoading;
  String? get error => _error;
  CreditSale? get selectedCreditSale => _selectedCreditSale;

  // Statistics
  double get totalCredits =>
      _creditSales.fold(0.0, (sum, sale) => sum + sale.creditAmount);
  double get totalPaid =>
      _creditSales.fold(0.0, (sum, sale) => sum + sale.paidAmount);
  double get totalRemaining =>
      _creditSales.fold(0.0, (sum, sale) => sum + sale.remainingAmount);
  double get totalOverdue => _creditSales
      .where((sale) => sale.isOverdue)
      .fold(0.0, (sum, sale) => sum + sale.remainingAmount);

  // Filtered lists
  List<CreditSale> get activeCredits =>
      _creditSales.where((sale) => sale.status == 'active').toList();
  List<CreditSale> get pendingCredits =>
      _creditSales.where((sale) => sale.status == 'pending').toList();
  List<CreditSale> get completedCredits =>
      _creditSales.where((sale) => sale.status == 'completed').toList();
  List<CreditSale> get overdueCredits =>
      _creditSales.where((sale) => sale.isOverdue).toList();

  // Methods
  Future<void> loadCreditSales() async {
    try {
      _setLoading(true);
      _error = null;
      _creditSales = await _creditSalesService.getAllCreditSales();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createCreditSale(Map<String, dynamic> creditSaleData) async {
    try {
      _setLoading(true);
      _error = null;
      final newCreditSale = await _creditSalesService.createCreditSale(
        creditSaleData,
      );
      _creditSales.add(newCreditSale);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      _setLoading(true);
      _error = null;
      final updatedCreditSale = await _creditSalesService
          .updateCreditSaleStatus(id, status);
      final index = _creditSales.indexWhere((sale) => sale.id == id);
      if (index != -1) {
        _creditSales[index] = updatedCreditSale;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCustomerCreditSales(String customerId) async {
    try {
      _setLoading(true);
      _error = null;
      _creditSales = await _creditSalesService.getCreditSalesByCustomer(
        customerId,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCreditSaleById(String id) async {
    try {
      _setLoading(true);
      _error = null;
      _selectedCreditSale = await _creditSalesService.getCreditSaleById(id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshCreditSale(String id) async {
    try {
      final updatedCreditSale = await _creditSalesService.getCreditSaleById(id);
      final index = _creditSales.indexWhere((sale) => sale.id == id);
      if (index != -1) {
        _creditSales[index] = updatedCreditSale;
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing credit sale: $e');
    }
  }

  void selectCreditSale(CreditSale creditSale) {
    _selectedCreditSale = creditSale;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Filter methods
  List<CreditSale> filterByStatus(String status) {
    if (status == 'all') return _creditSales;
    return _creditSales.where((sale) => sale.status == status).toList();
  }

  List<CreditSale> searchByCustomer(String searchTerm) {
    if (searchTerm.isEmpty) return _creditSales;
    return _creditSales
        .where(
          (sale) => sale.customer.name.toLowerCase().contains(
            searchTerm.toLowerCase(),
          ),
        )
        .toList();
  }
}
