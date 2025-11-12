import 'package:flutter/foundation.dart';
import '../models/domain/credit_payment.dart';
import '../services/credit_payments_service.dart';

class CreditPaymentsViewModel extends ChangeNotifier {
  final CreditPaymentsService _creditPaymentsService = CreditPaymentsService();
  
  List<CreditPayment> _payments = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CreditPayment> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Statistics
  double get totalPayments => _payments.fold(0.0, (sum, payment) => sum + payment.amount);
  
  // Methods
  Future<void> loadPayments() async {
    try {
      _setLoading(true);
      _error = null;
      _payments = await _creditPaymentsService.getAllPayments();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createPayment(Map<String, dynamic> paymentData) async {
    try {
      _setLoading(true);
      _error = null;
      final newPayment = await _creditPaymentsService.createCreditPayment(paymentData);
      _payments.add(newPayment);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPaymentsByCreditSale(String creditSaleId) async {
    try {
      _setLoading(true);
      _error = null;
      _payments = await _creditPaymentsService.getPaymentsByCreditSale(creditSaleId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<double> getTotalPaid(String creditSaleId) async {
    try {
      return await _creditPaymentsService.getTotalPaidAmount(creditSaleId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0.0;
    }
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
  List<CreditPayment> filterByCreditSale(int creditSaleId) {
    return _payments.where((payment) => payment.creditSaleId == creditSaleId).toList();
  }

  List<CreditPayment> filterByPaymentMethod(String method) {
    return _payments.where((payment) => payment.paymentMethod == method).toList();
  }

  List<CreditPayment> filterByDateRange(DateTime startDate, DateTime endDate) {
    return _payments.where((payment) => 
      payment.paymentDate.isAfter(startDate) && payment.paymentDate.isBefore(endDate)
    ).toList();
  }
}
