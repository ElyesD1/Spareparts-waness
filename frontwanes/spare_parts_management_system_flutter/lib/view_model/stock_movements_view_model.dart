import 'package:flutter/foundation.dart';
import '../services/stock_movement_service.dart';

class StockMovementsViewModel extends ChangeNotifier {
  final StockMovementService _service;
  StockMovementsViewModel({StockMovementService? service})
      : _service = service ?? StockMovementService();

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  List<Map<String, dynamic>> _movements = [];
  List<Map<String, dynamic>> get movements => _movements;

  String _filter = 'all';
  String get filter => _filter;
  set filter(String value) {
    if (_filter != value) {
      _filter = value;
      notifyListeners();
    }
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _movements = await _service.fetchMovements();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> get filteredMovements {
    if (_filter == 'all') return _movements;
    return _movements.where((m) => (m['movement_type'] ?? '').toString() == _filter).toList();
  }
}





