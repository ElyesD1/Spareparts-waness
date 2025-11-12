import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/domain/customer.dart';
import '../../models/domain/product.dart';
import '../../models/domain/credit_sale.dart';
import '../../services/customers_service.dart';
import '../../services/product_service.dart';
import '../../services/warehouse_service.dart';
import '../../services/credit_sales_service.dart';
import '../../view_model/credit_sales_view_model.dart';
import '../../services/session_manager.dart';

class CreditSaleForm extends StatefulWidget {
  final Function(Map<String, dynamic> data) onSubmit;
  final CreditSale? creditSale; // Pour l'édition

  const CreditSaleForm({Key? key, required this.onSubmit, this.creditSale})
    : super(key: key);

  @override
  _CreditSaleFormState createState() => _CreditSaleFormState();
}

class _CreditSaleFormState extends State<CreditSaleForm> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  List<Customer> _customers = [];
  List<Product> _products = [];
  List<Map<String, dynamic>> _warehouses = [];
  bool _loading = false;
  bool _isEditMode = false;
  String? _userRole;

  final Map<String, dynamic> _formData = {
    'customerId': null,
    'warehouseId': null,
    'products': [],
    'downPayment': 0.0,
    'installments': 1,
    'notes': '',
  };

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.creditSale != null;
    _loadData();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = await SessionManager.getUser();
    setState(() {
      _userRole = user?['role'] as String?;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
    });

    try {
      final customers = await CustomersService.getCustomers();
      final products = await ProductService().getProducts();
      final warehouses = await WarehouseService().getWarehouses();

      setState(() {
        _customers = customers;
        _products = products;
        _warehouses = warehouses;
        _loading = false;
      });

      // Si c'est le mode édition, pré-remplir les données
      if (_isEditMode && widget.creditSale != null) {
        _populateFormData();
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _populateFormData() async {
    final creditSale = widget.creditSale!;

    setState(() {
      _formData['customerId'] = creditSale.customer.id;
      _formData['warehouseId'] = creditSale.warehouseId;
      _formData['downPayment'] = creditSale.downPayment;
      _formData['installments'] = creditSale.installmentCount;
      _formData['notes'] = creditSale.notes ?? '';

      // Load products from items
      if (creditSale.items.isNotEmpty) {
        _formData['products'] =
            creditSale.items
                .map(
                  (item) => {
                    'productId': item.productId,
                    'quantity': item.quantity,
                    'price': item.unitPrice,
                  },
                )
                .toList();
      } else {
        _formData['products'] = [];
      }
    });
  }

  void _addProduct() {
    showDialog(
      context: context,
      builder:
          (context) => _ProductSelectionDialog(
            products: _products,
            onProductSelected: (product, quantity) {
              setState(() {
                _formData['products'].add({
                  'productId': product.id,
                  'quantity': quantity,
                  'price': product.unitPrice,
                });
              });
            },
          ),
    );
  }

  void _removeProduct(int index) {
    setState(() {
      _formData['products'].removeAt(index);
    });
  }

  void _updateProduct(int index, String key, dynamic value) {
    setState(() {
      _formData['products'][index][key] = value;
    });
  }

  double get _totalAmount {
    return _formData['products'].fold(0.0, (sum, product) {
      return sum + (product['price'] * product['quantity']);
    });
  }

  double get _creditAmount {
    return _totalAmount - (_formData['downPayment'] ?? 0.0);
  }

  double get _monthlyPayment {
    final installments = _formData['installments'] ?? 1;
    return installments > 0 ? _creditAmount / installments : 0.0;
  }

  String get _monthlyPaymentText {
    final installments = _formData['installments'] ?? 1;
    if (installments <= 1) {
      return '${_creditAmount.toStringAsFixed(2)} DNT (Full payment)';
    } else {
      return '${_monthlyPayment.toStringAsFixed(2)} DNT × $installments months';
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    if (widget.creditSale == null) return;

    try {
      await CreditSalesService().updateStatus(widget.creditSale!.id, newStatus);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Status updated to $newStatus')));
      // Refresh the credit sales list
      if (mounted) {
        context.read<CreditSalesViewModel>().loadCreditSales();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'active':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'overdue':
        return Icons.warning;
      case 'active':
        return Icons.schedule;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            // Modern Header with Gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isEditMode ? Icons.edit : Icons.add_shopping_cart,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditMode
                              ? 'Modifier Vente à Crédit'
                              : 'Nouvelle Vente à Crédit',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isEditMode
                              ? 'Mettre à jour les informations'
                              : 'Créer une nouvelle transaction',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                        if (_isEditMode && widget.creditSale != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    widget.creditSale!.status,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getStatusColor(
                                      widget.creditSale!.status,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getStatusIcon(widget.creditSale!.status),
                                      size: 14,
                                      color: _getStatusColor(
                                        widget.creditSale!.status,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.creditSale!.status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(
                                          widget.creditSale!.status,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_userRole == 'admin')
                                PopupMenuButton<String>(
                                  onSelected: _updateStatus,
                                  itemBuilder:
                                      (context) =>
                                          [
                                                'pending',
                                                'active',
                                                'completed',
                                                'overdue',
                                              ]
                                              .map(
                                                (status) => PopupMenuItem(
                                                  value: status,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        _getStatusIcon(status),
                                                        color: _getStatusColor(
                                                          status,
                                                        ),
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        status.toUpperCase(),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Area - Scrollable
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Modern Stepper
                        Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: Colors.blue.shade600,
                            ),
                          ),
                          child: Stepper(
                            currentStep: _currentStep,
                            onStepTapped: (step) {
                              setState(() {
                                _currentStep = step;
                              });
                            },
                            controlsBuilder: (context, details) {
                              return Container(
                                margin: const EdgeInsets.only(top: 20),
                                child: Row(
                                  children: [
                                    if (_currentStep > 0)
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _currentStep--;
                                            });
                                          },
                                          icon: const Icon(Icons.arrow_back),
                                          label: const Text('Précédent'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                            side: BorderSide(
                                              color: Colors.grey.shade400,
                                            ),
                                            foregroundColor:
                                                Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    if (_currentStep > 0)
                                      const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _currentStep < 3
                                                ? () {
                                                  setState(() {
                                                    _currentStep++;
                                                  });
                                                }
                                                : _submitForm,
                                        icon: Icon(
                                          _currentStep < 3
                                              ? Icons.arrow_forward
                                              : Icons.save,
                                        ),
                                        label: Text(
                                          _currentStep < 3
                                              ? 'Suivant'
                                              : (_isEditMode
                                                  ? 'Mettre à jour'
                                                  : 'Créer'),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade600,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            steps: [
                              Step(
                                title: const Text('Client'),
                                content: _buildCustomerStep(),
                                isActive: _currentStep >= 0,
                              ),
                              Step(
                                title: const Text('Entrepôt'),
                                content: _buildWarehouseStep(),
                                isActive: _currentStep >= 1,
                              ),
                              Step(
                                title: const Text('Produits'),
                                content: _buildProductsStep(),
                                isActive: _currentStep >= 2,
                              ),
                              Step(
                                title: const Text('Conditions de paiement'),
                                content: _buildPaymentStep(),
                                isActive: _currentStep >= 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerStep() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.blue.shade600),
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement des clients...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isTight = constraints.maxWidth < 220;
              final title = const Text(
                'Sélection du client',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              );
              if (isTight) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(child: title),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: title),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _formData['customerId'],
            decoration: InputDecoration(
              labelText: 'Choisir un client',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
              ),
              prefixIcon: Icon(
                Icons.person_outline,
                color: Colors.blue.shade600,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            isExpanded: true,
            items:
                _customers.map((customer) {
                  return DropdownMenuItem(
                    value: customer.id,
                    child: Text('${customer.name} (${customer.phoneNumber})'),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _formData['customerId'] = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Veuillez sélectionner un client';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          if (_customers.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_customers.length} clients disponibles',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWarehouseStep() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _formData['warehouseId'],
          decoration: const InputDecoration(
            labelText: 'Select Warehouse',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.warehouse),
          ),
          items:
              _warehouses.map((warehouse) {
                return DropdownMenuItem(
                  value: warehouse['id'] as String,
                  child: Text(
                    '${warehouse['name']} - ${warehouse['location'] ?? 'No location'}',
                  ),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _formData['warehouseId'] = value;
            });
          },
          validator: (value) {
            if (value == null) {
              return 'Please select a warehouse';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        if (_warehouses.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_warehouses.length} warehouses available',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProductsStep() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Selected Products',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (!_isEditMode) // Seulement en mode création
              ElevatedButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_formData['products'].isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No products selected',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add products to continue',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _formData['products'].length,
              itemBuilder: (context, index) {
                final productData = _formData['products'][index];
                final product = _products.firstWhere(
                  (p) => p.id == productData['productId'],
                  orElse:
                      () => Product(
                        id: '',
                        name: 'Unknown',
                        referenceCode: '',
                        unitPrice: 0,
                        description: '',
                        category: '',
                        brand: '',
                      ),
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${productData['quantity']} x ${productData['price']} DNT',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${(productData['quantity'] * productData['price']).toStringAsFixed(2)} DNT',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (!_isEditMode) // Seulement en mode création
                          IconButton(
                            onPressed: () => _removeProduct(index),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            constraints: const BoxConstraints(minWidth: 40),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.calculate, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Total Amount: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${_totalAmount.toStringAsFixed(2)} DNT',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      children: [
        TextFormField(
          initialValue: _formData['downPayment']?.toString() ?? '0',
          decoration: const InputDecoration(
            labelText: 'Down Payment (DNT)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.payment),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (value) {
            final parsed = double.tryParse(value);
            setState(() {
              _formData['downPayment'] = parsed ?? 0.0;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter down payment amount';
            }
            final amount = double.tryParse(value);
            if (amount == null) {
              return 'Please enter a valid number';
            }
            if (amount < 0) {
              return 'Down payment cannot be negative';
            }
            if (amount > _totalAmount) {
              return 'Down payment cannot exceed total amount';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _formData['installments']?.toString() ?? '1',
          decoration: const InputDecoration(
            labelText: 'Number of Installments',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.repeat),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final parsed = int.tryParse(value);
            setState(() {
              _formData['installments'] = parsed ?? 1;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter number of installments';
            }
            final installments = int.tryParse(value);
            if (installments == null) {
              return 'Please enter a valid number';
            }
            if (installments < 1) {
              return 'Must have at least 1 installment';
            }
            if (installments > 60) {
              return 'Maximum 60 installments allowed';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _formData['notes'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Notes (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 3,
          onChanged: (value) {
            _formData['notes'] = value;
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            children: [
              _buildSummaryRow(
                'Total Amount',
                '${_totalAmount.toStringAsFixed(2)} DNT',
              ),
              _buildSummaryRow(
                'Down Payment',
                '${_formData['downPayment']?.toStringAsFixed(2) ?? '0.00'} DNT',
              ),
              _buildSummaryRow(
                'Credit Amount',
                '${_creditAmount.toStringAsFixed(2)} DNT',
              ),
              _buildSummaryRow(
                'Installments',
                '${_formData['installments'] ?? 1}',
              ),
              _buildSummaryRow('Monthly Payment', _monthlyPaymentText),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the validation errors'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formData['products'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formData['customerId'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formData['warehouseId'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a warehouse'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate and sanitize all numeric values
    final downPayment = _formData['downPayment'] ?? 0.0;
    final installments = _formData['installments'] ?? 1;
    final totalAmount = _totalAmount;

    // Check for NaN values
    if (downPayment.isNaN || installments.isNaN || totalAmount.isNaN) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid numeric values detected. Please check your input.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate down payment
    if (downPayment < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Down payment cannot be negative'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (downPayment > totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Down payment cannot exceed total amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate installments
    if (installments < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Must have at least 1 installment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate products
    for (int i = 0; i < _formData['products'].length; i++) {
      final product = _formData['products'][i];
      final price = product['price'] ?? 0.0;
      final quantity = product['quantity'] ?? 0;

      if (price.isNaN || quantity.isNaN || price < 0 || quantity < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid product data at position ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Prepare data in backend format
    final now = DateTime.now();
    final firstPaymentDate = now.add(const Duration(days: 30));

    final cleanData = {
      'customer_id': _formData['customerId'],
      'warehouse_id': _formData['warehouseId'],
      'sale_date': now.toIso8601String().split('T')[0],
      'total_amount': totalAmount.toDouble(),
      'down_payment': downPayment.toDouble(),
      'installment_count': installments.toInt(),
      'first_payment_date': firstPaymentDate.toIso8601String().split('T')[0],
      'notes': _formData['notes'] ?? '',
      'items':
          _formData['products']
              .map(
                (product) => {
                  'product_id': product['productId'],
                  'quantity': (product['quantity'] as num).toInt(),
                  'unit_price': (product['price'] as num).toDouble(),
                },
              )
              .toList(),
    };

    // Submit the form
    widget.onSubmit(cleanData);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Text(
                  _isEditMode
                      ? 'Updating credit sale...'
                      : 'Creating credit sale...',
                ),
              ],
            ),
          ),
    );

    // Submit the form
    try {
      widget.onSubmit(cleanData);
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error ${_isEditMode ? 'updating' : 'creating'} credit sale: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _ProductSelectionDialog extends StatefulWidget {
  final List<Product> products;
  final Function(Product product, int quantity) onProductSelected;

  const _ProductSelectionDialog({
    required this.products,
    required this.onProductSelected,
  });

  @override
  _ProductSelectionDialogState createState() => _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<_ProductSelectionDialog> {
  Product? selectedProduct;
  int quantity = 1;
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );

  @override
  void initState() {
    super.initState();
    _quantityController.text = '1';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Product'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Product>(
              value: selectedProduct,
              decoration: const InputDecoration(
                labelText: 'Product',
                border: OutlineInputBorder(),
              ),
              items:
                  widget.products.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text('${product.name} - ${product.unitPrice} DNT'),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedProduct = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final parsed = int.tryParse(value);
                if (parsed != null && parsed > 0) {
                  quantity = parsed;
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                final parsed = int.tryParse(value);
                if (parsed == null) {
                  return 'Please enter a valid number';
                }
                if (parsed < 1) {
                  return 'Quantity must be at least 1';
                }
                if (parsed > 1000) {
                  return 'Quantity cannot exceed 1000';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              selectedProduct == null
                  ? null
                  : () {
                    final parsedQuantity = int.tryParse(
                      _quantityController.text,
                    );
                    if (parsedQuantity != null && parsedQuantity > 0) {
                      widget.onProductSelected(
                        selectedProduct!,
                        parsedQuantity,
                      );
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid quantity'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
