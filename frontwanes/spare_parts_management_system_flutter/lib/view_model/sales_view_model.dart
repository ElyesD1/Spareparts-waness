import 'package:flutter/foundation.dart';
import '../services/sales_service.dart';

class SalesViewModel extends ChangeNotifier {
  final SalesService _service;
  SalesViewModel({SalesService? service})
    : _service = service ?? SalesService();

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> get sales => _sales;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _sales = await _service.getSales();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> create(Map<String, dynamic> payload) async {
    try {
      final sale = await _service.createSale(payload);
      _sales.insert(0, sale);
      notifyListeners();
      return sale;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> update(
    String id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final updated = await _service.updateSale(id, payload);
      final idx = _sales.indexWhere(
        (s) => (s['id'] ?? s['sale_id'])?.toString() == id,
      );
      if (idx != -1) {
        _sales[idx] = updated;
        notifyListeners();
      }
      return updated;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> remove(String id) async {
    try {
      await _service.deleteSale(id);
      _sales.removeWhere((s) => (s['id'] ?? s['sale_id'])?.toString() == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
