import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/domain/customer.dart';
import '../../models/domain/product.dart';
import '../../services/customers_service.dart';
import '../../services/credit_sales_service.dart';
import '../../services/product_service.dart';
import '../../services/warehouse_service.dart';

class CreditSaleFormDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const CreditSaleFormDialog({super.key, required this.onSuccess});

  @override
  State<CreditSaleFormDialog> createState() => _CreditSaleFormDialogState();
}

class _CreditSaleFormDialogState extends State<CreditSaleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final WarehouseService _warehouseService = WarehouseService();
  final ProductService _productService = ProductService();
  final CreditSalesService _creditSalesService = CreditSalesService();

  // Form controllers
  final TextEditingController _downPaymentController = TextEditingController();
  final TextEditingController _installmentCountController =
      TextEditingController(text: '12');
  final TextEditingController _notesController = TextEditingController();

  // Data
  List<Customer> _customers = [];
  List<Map<String, dynamic>> _warehouses = [];
  List<Product> _products = [];
  List<ProductItem> _selectedItems = [];

  Customer? _selectedCustomer;
  Map<String, dynamic>? _selectedWarehouse;
  DateTime _firstPaymentDate = DateTime.now().add(const Duration(days: 30));

  bool _loading = false;
  bool _loadingData = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _downPaymentController.dispose();
    _installmentCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final customers = await CustomersService.getCustomers();
      final warehouses = await _warehouseService.getWarehouses();

      if (mounted) {
        setState(() {
          _customers = customers;
          _warehouses = warehouses;
          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loadingData = false;
        });
      }
    }
  }

  Future<void> _loadProductsForWarehouse(String warehouseId) async {
    try {
      final products = await _productService.getProducts();

      if (mounted) {
        setState(() {
          _products = products;
          _selectedItems.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  double get _totalAmount {
    return _selectedItems.fold(
      0.0,
      (sum, item) => sum + (item.product.unitPrice * item.quantity),
    );
  }

  double get _downPayment {
    final text = _downPaymentController.text;
    return text.isEmpty ? 0.0 : double.tryParse(text) ?? 0.0;
  }

  double get _creditAmount {
    return _totalAmount - _downPayment;
  }

  double get _monthlyPayment {
    final installmentCount =
        int.tryParse(_installmentCountController.text) ?? 1;
    return installmentCount > 0 ? _creditAmount / installmentCount : 0.0;
  }

  void _addProductItem() {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord sélectionner un entrepôt'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => _ProductSelectionDialog(
            products: _products,
            onSelect: (product, quantity) {
              setState(() {
                _selectedItems.add(
                  ProductItem(product: product, quantity: quantity),
                );
              });
            },
          ),
    );
  }

  void _removeProductItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un client')),
      );
      return;
    }

    if (_selectedWarehouse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un entrepôt')),
      );
      return;
    }

    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins un produit')),
      );
      return;
    }

    if (_downPayment < 0 || _downPayment > _totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le paiement initial doit être entre 0 et le total'),
        ),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final creditSaleData = {
        'customer_id': _selectedCustomer!.id,
        'warehouse_id': _selectedWarehouse!['id'],
        'sale_date': DateTime.now().toIso8601String(),
        'total_amount': _totalAmount,
        'down_payment': _downPayment,
        'credit_amount': _creditAmount,
        'installment_count': int.parse(_installmentCountController.text),
        'monthly_payment': _monthlyPayment,
        'first_payment_date': _firstPaymentDate.toIso8601String(),
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'items':
            _selectedItems
                .map(
                  (item) => {
                    'product_id': item.product.id,
                    'quantity': item.quantity,
                    'unit_price': item.product.unitPrice,
                    'total_price': item.product.unitPrice * item.quantity,
                  },
                )
                .toList(),
      };

      await _creditSalesService.createCreditSale(creditSaleData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vente à crédit créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child:
            _loadingData
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_error != null) _buildErrorMessage(),
                              _buildCustomerSelection(),
                              const SizedBox(height: 16),
                              _buildWarehouseSelection(),
                              const SizedBox(height: 24),
                              _buildProductsSection(),
                              const SizedBox(height: 24),
                              _buildPaymentSection(),
                              const SizedBox(height: 16),
                              _buildNotesField(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildFooter(),
                  ],
                ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Text(
            'Nouvelle Vente à Crédit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSelection() {
    return DropdownButtonFormField<Customer>(
      value: _selectedCustomer,
      decoration: const InputDecoration(
        labelText: 'Client',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
      ),
      items:
          _customers.map((customer) {
            return DropdownMenuItem(
              value: customer,
              child: Text(customer.name),
            );
          }).toList(),
      onChanged: (customer) {
        setState(() {
          _selectedCustomer = customer;
        });
      },
      validator:
          (value) => value == null ? 'Veuillez sélectionner un client' : null,
    );
  }

  Widget _buildWarehouseSelection() {
    return DropdownButtonFormField<Map<String, dynamic>>(
      value: _selectedWarehouse,
      decoration: const InputDecoration(
        labelText: 'Entrepôt',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.warehouse),
      ),
      items:
          _warehouses.map((warehouse) {
            return DropdownMenuItem(
              value: warehouse,
              child: Text(warehouse['name'] ?? ''),
            );
          }).toList(),
      onChanged: (warehouse) {
        setState(() {
          _selectedWarehouse = warehouse;
          if (warehouse != null) {
            _loadProductsForWarehouse(warehouse['id'] ?? '');
          }
        });
      },
      validator:
          (value) => value == null ? 'Veuillez sélectionner un entrepôt' : null,
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'Produits',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _addProductItem,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un produit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Aucun produit ajouté',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._selectedItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.inventory_2),
                title: Text(item.product.name),
                subtitle: Text(
                  'Quantité: ${item.quantity} × ${item.product.unitPrice} DA',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(item.product.unitPrice * item.quantity).toStringAsFixed(2)} DA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeProductItem(index),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        if (_selectedItems.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_totalAmount.toStringAsFixed(2)} DA',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Conditions de paiement',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _downPaymentController,
          decoration: const InputDecoration(
            labelText: 'Paiement initial (DA)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.payment),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          onChanged: (value) => setState(() {}),
          validator: (value) {
            if (value == null || value.isEmpty) return null;
            final amount = double.tryParse(value);
            if (amount == null) return 'Montant invalide';
            if (amount < 0) return 'Le montant doit être positif';
            if (amount > _totalAmount) return 'Montant supérieur au total';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _installmentCountController,
          decoration: const InputDecoration(
            labelText: 'Nombre de mensualités',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) => setState(() {}),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer le nombre de mensualités';
            }
            final count = int.tryParse(value);
            if (count == null || count < 1) {
              return 'Le nombre doit être au moins 1';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.event),
          title: const Text('Date du premier paiement'),
          subtitle: Text(
            '${_firstPaymentDate.day}/${_firstPaymentDate.month}/${_firstPaymentDate.year}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _firstPaymentDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                _firstPaymentDate = date;
              });
            }
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Montant du crédit:'),
                  Text(
                    '${_creditAmount.toStringAsFixed(2)} DA',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Paiement mensuel:'),
                  Text(
                    '${_monthlyPayment.toStringAsFixed(2)} DA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes (optionnel)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.notes),
      ),
      maxLines: 3,
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _loading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child:
                _loading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                    : const Text('Créer la vente'),
          ),
        ],
      ),
    );
  }
}

class ProductItem {
  final Product product;
  final int quantity;

  ProductItem({required this.product, required this.quantity});
}

class _ProductSelectionDialog extends StatefulWidget {
  final List<Product> products;
  final Function(Product, int) onSelect;

  const _ProductSelectionDialog({
    required this.products,
    required this.onSelect,
  });

  @override
  State<_ProductSelectionDialog> createState() =>
      _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<_ProductSelectionDialog> {
  Product? _selectedProduct;
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner un produit'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Product>(
              value: _selectedProduct,
              decoration: const InputDecoration(
                labelText: 'Produit',
                border: OutlineInputBorder(),
              ),
              items:
                  widget.products.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text('${product.name} (${product.unitPrice} DA)'),
                    );
                  }).toList(),
              onChanged: (product) {
                setState(() {
                  _selectedProduct = product;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantité',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedProduct == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Veuillez sélectionner un produit'),
                ),
              );
              return;
            }
            final quantity = int.tryParse(_quantityController.text) ?? 0;
            if (quantity < 1) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('La quantité doit être au moins 1'),
                ),
              );
              return;
            }
            widget.onSelect(_selectedProduct!, quantity);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
