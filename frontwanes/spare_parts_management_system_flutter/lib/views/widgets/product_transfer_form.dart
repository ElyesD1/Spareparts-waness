import 'package:flutter/material.dart';
import '../../models/domain/product.dart';
import '../../services/product_service.dart';
import '../../services/warehouse_service.dart';
import '../../services/product_stock_service.dart';
import '../../services/product_transfer_service.dart';
import '../../services/session_manager.dart';

class ProductTransferForm extends StatefulWidget {
  final VoidCallback? onTransferCreated;

  const ProductTransferForm({Key? key, this.onTransferCreated})
    : super(key: key);

  @override
  State<ProductTransferForm> createState() => _ProductTransferFormState();
}

class _ProductTransferFormState extends State<ProductTransferForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  List<Product> _products = [];
  List<Map<String, dynamic>> _warehouses = [];
  int? _availableStock;

  Product? _selectedProduct;
  String? _selectedFromWarehouse;
  String? _selectedToWarehouse;
  String _selectedPriority = 'normal';

  bool _loading = false;
  bool _loadingStock = false;

  Map<String, dynamic>? _currentUser;
  String? _userRole;
  String? _userWarehouseId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Responsive breakpoint
  bool _isMobile() => MediaQuery.of(context).size.width < 600;

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);

    try {
      // Get current user info
      _currentUser = await SessionManager.getUser();
      if (_currentUser != null) {
        _userRole = _currentUser!['role'];
        _userWarehouseId = _currentUser!['warehouse_id'];
      }

      // Load products and warehouses
      await Future.wait([_loadProducts(), _loadWarehouses()]);

      // Auto-select user's warehouse for FROM if applicable
      if (_userWarehouseId != null &&
          _canSelectFromWarehouse(_userWarehouseId!)) {
        setState(() {
          _selectedFromWarehouse = _userWarehouseId;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ProductService().getProducts();
      setState(() {
        _products = products;
      });
    } catch (e) {
      print('Error loading products: $e');
    }
  }

  Future<void> _loadWarehouses() async {
    try {
      final warehouses = await WarehouseService().getWarehouses();
      setState(() {
        _warehouses = warehouses;
      });
    } catch (e) {
      print('Error loading warehouses: $e');
    }
  }

  Future<void> _loadStockInfo() async {
    if (_selectedProduct == null ||
        _selectedFromWarehouse == null ||
        _selectedProduct!.id == null)
      return;

    setState(() => _loadingStock = true);

    try {
      final stock = await ProductStockService().getCurrentStock(
        _selectedProduct!.id!,
        _selectedFromWarehouse!,
      );
      setState(() {
        _availableStock = stock;
      });
    } catch (e) {
      print('Error loading stock info: $e');
      setState(() => _availableStock = 0);
    } finally {
      setState(() => _loadingStock = false);
    }
  }

  bool _canSelectFromWarehouse(String warehouseId) {
    return ProductTransferService.canCreateTransfer(
      _userRole ?? '',
      _userWarehouseId,
      warehouseId,
    );
  }

  int? _getAvailableStock() {
    return _availableStock;
  }

  Future<void> _submitTransfer() async {
    if (!_formKey.currentState!.validate()) return;

    final quantity = int.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      _showErrorSnackBar('Quantité invalide');
      return;
    }

    final availableStock = _getAvailableStock();
    if (availableStock != null && quantity > availableStock) {
      _showErrorSnackBar('Stock insuffisant (disponible: $availableStock)');
      return;
    }

    setState(() => _loading = true);

    try {
      final transferData = {
        'product_id': _selectedProduct!.id!,
        'from_warehouse_id': _selectedFromWarehouse!,
        'to_warehouse_id': _selectedToWarehouse!,
        'quantity': quantity,
        'reason': _reasonController.text.trim(),
        'priority': _selectedPriority,
        'notes':
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
      };

      await ProductTransferService().createTransfer(transferData);

      _showSuccessSnackBar('Demande de transfert créée avec succès');
      _resetForm();

      if (widget.onTransferCreated != null) {
        widget.onTransferCreated!();
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la création: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _quantityController.clear();
    _reasonController.clear();
    _notesController.clear();
    setState(() {
      _selectedProduct = null;
      _selectedToWarehouse = null;
      if (_userWarehouseId == null ||
          !_canSelectFromWarehouse(_userWarehouseId!)) {
        _selectedFromWarehouse = null;
      }
      _selectedPriority = 'normal';
      _availableStock = null;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.swap_horiz, size: 28, color: Colors.indigo),
                const SizedBox(width: 12),
                const Text(
                  'Nouvelle Demande de Transfert',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Product Selection
              _buildProductDropdown(),
              const SizedBox(height: 16),

              // Warehouse Selection Row
              _isMobile()
                  ? Column(
                    children: [
                      _buildFromWarehouseDropdown(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_downward, color: Colors.grey[600]),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildToWarehouseDropdown(),
                    ],
                  )
                  : Row(
                    children: [
                      Expanded(child: _buildFromWarehouseDropdown()),
                      const SizedBox(width: 16),
                      Icon(Icons.arrow_forward, color: Colors.grey[600]),
                      const SizedBox(width: 16),
                      Expanded(child: _buildToWarehouseDropdown()),
                    ],
                  ),
              const SizedBox(height: 16),

              // Stock Info
              if (_selectedProduct != null && _selectedFromWarehouse != null)
                _buildStockInfo(),

              // Quantity and Priority Row
              _isMobile()
                  ? Column(
                    children: [
                      _buildQuantityField(),
                      const SizedBox(height: 12),
                      _buildPriorityDropdown(),
                    ],
                  )
                  : Row(
                    children: [
                      Expanded(flex: 2, child: _buildQuantityField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildPriorityDropdown()),
                    ],
                  ),
              const SizedBox(height: 16),

              // Reason
              _buildReasonField(),
              const SizedBox(height: 16),

              // Notes (optional)
              _buildNotesField(),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submitTransfer,
                  icon:
                      _loading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.send),
                  label: Text(_loading ? 'Création...' : 'Créer la Demande'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductDropdown() {
    return DropdownButtonFormField<Product>(
      value: _selectedProduct,
      decoration: const InputDecoration(
        labelText: 'Produit',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.inventory),
        isDense: true,
      ),
      isExpanded: true,
      items:
          _products.map((product) {
            return DropdownMenuItem(
              value: product,
              child: Text(
                '${product.name} (${product.referenceCode})',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
      onChanged: (product) {
        setState(() {
          _selectedProduct = product;
          _availableStock = null;
        });
        if (product != null) {
          _loadStockInfo();
        }
      },
      validator: (value) => value == null ? 'Sélectionnez un produit' : null,
    );
  }

  Widget _buildFromWarehouseDropdown() {
    final availableWarehouses =
        _warehouses.where((warehouse) {
          return _canSelectFromWarehouse(warehouse['id'] as String);
        }).toList();

    return DropdownButtonFormField<String>(
      value: _selectedFromWarehouse,
      decoration: const InputDecoration(
        labelText: 'Entrepôt Source',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.warehouse),
        isDense: true,
      ),
      isExpanded: true,
      items:
          availableWarehouses.map((warehouse) {
            return DropdownMenuItem(
              value: warehouse['id'] as String,
              child: Text(
                warehouse['name'] as String,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
      onChanged:
          _userRole == 'cashier'
              ? null
              : (warehouseId) {
                setState(() {
                  _selectedFromWarehouse = warehouseId;
                  _availableStock = null;
                });
                if (warehouseId != null && _selectedProduct != null) {
                  _loadStockInfo();
                }
              },
      validator:
          (value) => value == null ? 'Sélectionnez l\'entrepôt source' : null,
    );
  }

  Widget _buildToWarehouseDropdown() {
    final availableWarehouses =
        _warehouses.where((warehouse) {
          return warehouse['id'] != _selectedFromWarehouse;
        }).toList();

    return DropdownButtonFormField<String>(
      value: _selectedToWarehouse,
      decoration: const InputDecoration(
        labelText: 'Entrepôt Destination',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.place),
        isDense: true,
      ),
      isExpanded: true,
      items:
          availableWarehouses.map((warehouse) {
            return DropdownMenuItem(
              value: warehouse['id'] as String,
              child: Text(
                warehouse['name'] as String,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            );
          }).toList(),
      onChanged: (warehouseId) {
        setState(() {
          _selectedToWarehouse = warehouseId;
        });
      },
      validator:
          (value) =>
              value == null ? 'Sélectionnez l\'entrepôt destination' : null,
    );
  }

  Widget _buildStockInfo() {
    if (_loadingStock) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Chargement du stock...'),
          ],
        ),
      );
    }

    final availableStock = _getAvailableStock();
    final hasStock = availableStock != null && availableStock > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasStock ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasStock ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasStock ? Icons.check_circle : Icons.warning,
            color: hasStock ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasStock
                  ? 'Stock disponible: $availableStock unités'
                  : 'Aucun stock disponible',
              style: TextStyle(
                color: hasStock ? Colors.green[800] : Colors.red[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      decoration: const InputDecoration(
        labelText: 'Quantité',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.numbers),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Entrez la quantité';
        }
        final quantity = int.tryParse(value);
        if (quantity == null || quantity <= 0) {
          return 'Quantité invalide';
        }
        return null;
      },
    );
  }

  Widget _buildPriorityDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPriority,
      decoration: const InputDecoration(
        labelText: 'Priorité',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.priority_high),
        isDense: true,
      ),
      isExpanded: true,
      items: const [
        DropdownMenuItem(value: 'low', child: Text('Faible')),
        DropdownMenuItem(value: 'normal', child: Text('Normale')),
        DropdownMenuItem(value: 'high', child: Text('Élevée')),
        DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
      ],
      onChanged: (priority) {
        setState(() {
          _selectedPriority = priority!;
        });
      },
    );
  }

  Widget _buildReasonField() {
    return TextFormField(
      controller: _reasonController,
      decoration: const InputDecoration(
        labelText: 'Raison du transfert',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
        hintText: 'Ex: Stock épuisé, commande client, rééquilibrage...',
      ),
      maxLines: 2,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Entrez la raison du transfert';
        }
        return null;
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes (optionnel)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.note),
        hintText: 'Informations supplémentaires...',
      ),
      maxLines: 3,
    );
  }
}
