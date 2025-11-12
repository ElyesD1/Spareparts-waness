import 'package:flutter/material.dart';
import '../../services/sales_service.dart';
import '../../services/sale_item_service.dart';
import '../../services/warehouse_service.dart';
import '../../services/auth_service.dart';
import '../../models/domain/sale_item.dart';
import '../widgets/sale_item_form.dart';
import 'package:intl/intl.dart';
import '../../services/customers_service.dart';
import '../../models/domain/customer.dart';
import 'success_toast.dart';
import 'app_toast.dart';

class SalesForm extends StatefulWidget {
  final Map<String, dynamic>? sale;
  final VoidCallback onSuccess;

  const SalesForm({super.key, this.sale, required this.onSuccess});

  @override
  State<SalesForm> createState() => _SalesFormState();
}

class _SalesFormState extends State<SalesForm> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerAddressController = TextEditingController();
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  final _salesService = SalesService();
  final _saleItemService = SaleItemService();
  final _warehouseService = WarehouseService();
  final _authService = AuthService();
  bool _loading = false;
  bool _loadingData = true;
  DateTime _selectedDate = DateTime.now();
  String? _selectedWarehouseId;
  String? _createdBy;
  List<Map<String, dynamic>> _warehouses = [];
  Map<String, dynamic>? _currentUser;
  List<SaleItem> _saleItems = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    print('🔄 [SalesForm] Loading initial data...');
    try {
      // Debug: Print stored data
      await _authService.debugStoredData();

      print(
        '🔄 [SalesForm] Loading warehouses, customers and current user in parallel...',
      );
      // Load warehouses, customers and current user in parallel
      final futures = await Future.wait([
        _warehouseService.getWarehouses(),
        _authService.getCurrentUser(),
        CustomersService.getCustomers(),
      ]);

      print('🔄 [SalesForm] Received data from services');
      print('🔄 [SalesForm] Warehouses count: ${(futures[0] as List).length}');
      print('🔄 [SalesForm] Current user: ${futures[1]}');

      setState(() {
        _warehouses = futures[0] as List<Map<String, dynamic>>;
        _currentUser = futures[1] as Map<String, dynamic>?;
        _customers = futures[2] as List<Customer>;
        _loadingData = false;
      });

      print('🔍 [SalesForm] Loaded warehouses:');
      for (var wh in _warehouses) {
        print(
          '  - Warehouse: ${wh['name']} (id: ${wh['id']}, _id: ${wh['_id']})',
        );
      }

      // Normalize user ID field - MongoDB uses _id, frontend uses id
      if (_currentUser != null) {
        if (_currentUser!['id'] == null && _currentUser!['_id'] != null) {
          _currentUser!['id'] = _currentUser!['_id'];
        }
      }

      // Set default warehouse dynamically
      if (_warehouses.isNotEmpty && _selectedWarehouseId == null) {
        // If current user has a warehouse_id, use it
        if (_currentUser != null && _currentUser!['warehouse_id'] != null) {
          final userWarehouseId = _currentUser!['warehouse_id'].toString();
          final exists = _warehouses.any(
            (w) => w['id'].toString() == userWarehouseId,
          );
          if (exists) {
            _selectedWarehouseId = userWarehouseId;
            print(
              '🔄 [SalesForm] Set default warehouse from user: $_selectedWarehouseId',
            );
          }
        }

        // If still null and only one warehouse, select it automatically
        if (_selectedWarehouseId == null && _warehouses.length == 1) {
          _selectedWarehouseId = _warehouses.first['id']?.toString();
          print(
            '🔄 [SalesForm] Auto-selected only warehouse: $_selectedWarehouseId',
          );
        }
      }

      // Set current user ID if available
      if (_currentUser != null && _currentUser!['id'] != null) {
        _createdBy = _currentUser!['id'].toString();
        print(
          '✅ [SalesForm] Current user loaded: ${_currentUser!['email']} (ID: $_createdBy)',
        );
      } else {
        print('❌ [SalesForm] No current user found or userId missing');
        print('🔍 [SalesForm] Current user data: $_currentUser');
        AppToast.error(
          context,
          'Error: Could not determine current user. Please log in again.',
        );
        setState(() => _loadingData = false);
        return;
      }

      // Load existing sale data if editing
      if (widget.sale != null) {
        print('🔄 [SalesForm] Loading existing sale data for editing...');
        _customerNameController.text = widget.sale!['customer_name'] ?? '';
        _selectedDate = DateTime.parse(widget.sale!['sale_date']);
        _selectedWarehouseId =
            widget.sale!['warehouse_id'] ??
            (_warehouses.isNotEmpty ? _warehouses.first['id'] : null);
        _createdBy = widget.sale!['created_by'] ?? _createdBy;

        // Load sale items
        final items = await _saleItemService.getSaleItems(widget.sale!['id']);
        print('🔍 [SalesForm] Raw sale items from API: $items');
        setState(() {
          _saleItems = items;
        });
        print('✅ [SalesForm] Loaded ${items.length} sale items for editing');
        print('🔍 [SalesForm] Sale items details:');
        for (int i = 0; i < items.length; i++) {
          final item = items[i];
          print(
            '  Item $i: productId=${item.productId}, product=${item.product?.name}, quantity=${item.quantity}, unitPrice=${item.unitPrice}',
          );
        }
      }
    } catch (e) {
      print('❌ [SalesForm] Error loading initial data: $e');
      setState(() => _loadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerAddressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  double get _totalAmount {
    return _saleItems.fold(0, (sum, item) => sum + item.total);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saleItems.isEmpty) {
      AppToast.error(
        context,
        'Veuillez ajouter au moins un article à la vente',
      );
      return;
    }

    // Ensure we have a valid warehouse selected (NOT the string "null")
    if (_selectedWarehouseId == null ||
        _selectedWarehouseId == 'null' ||
        _selectedWarehouseId!.isEmpty) {
      print('❌ [SalesForm] Warehouse validation failed: $_selectedWarehouseId');
      print(
        '🔍 [SalesForm] Available warehouses: ${_warehouses.map((w) => w['id']).toList()}',
      );
      AppToast.error(context, 'Veuillez sélectionner un entrepôt');
      return;
    }

    // Ensure we have a valid created_by value
    if (_createdBy == null || _createdBy!.isEmpty) {
      AppToast.error(
        context,
        'Erreur: Impossible de déterminer l\'utilisateur actuel. Veuillez vous reconnecter.',
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final saleData = {
        'warehouse_id':
            _selectedWarehouseId, // This will now never be "null" string
        'created_by': _createdBy,
        'customer_name': _customerNameController.text.trim(),
        'sale_date': DateFormat(
          'yyyy-MM-dd',
        ).format(_selectedDate), // ISO date format
        'total_amount':
            _totalAmount.toDouble(), // Convert to double for decimal field
      };

      // Debug logging for testing
      print('🔍 [SalesForm] === SALE VALIDATION DEBUG ===');
      print(
        '🔍 [SalesForm] Warehouse ID: $_selectedWarehouseId (type: ${_selectedWarehouseId.runtimeType})',
      );
      print(
        '🔍 [SalesForm] Created By: $_createdBy (type: ${_createdBy.runtimeType})',
      );
      print(
        '🔍 [SalesForm] Customer Name: ${_customerNameController.text.trim()}',
      );
      print(
        '🔍 [SalesForm] Sale Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
      );
      print('🔍 [SalesForm] Total Amount: ${_totalAmount.toDouble()}');
      print('🔍 [SalesForm] Sale Items Count: ${_saleItems.length}');
      print('🔍 [SalesForm] Full sale data: $saleData');
      print('🔍 [SalesForm] ================================');

      print(
        '[SalesForm] Submitting sale with created_by: $_createdBy (type: ${_createdBy.runtimeType})',
      );

      Map<String, dynamic> sale;
      if (widget.sale != null) {
        // Update existing sale
        sale = await _salesService.updateSale(widget.sale!['id'], saleData);

        // Update sale items
        for (final item in _saleItems) {
          if (item.id != null) {
            await _saleItemService.updateSaleItem(item.id!, item);
          } else {
            // Get sale ID as string (MongoDB ObjectId)
            final saleId =
                sale['_id']?.toString() ?? sale['id']?.toString() ?? '';
            final newItem = SaleItem(
              saleId: saleId,
              productId: item.productId,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              product: item.product,
            );
            await _saleItemService.addSaleItem(newItem);
          }
        }

        SuccessToast.show(context, 'Sale updated successfully');
      } else {
        // Add new sale
        sale = await _salesService.createSale(saleData);

        // Create stock movements for each item
        for (final item in _saleItems) {
          // Use product's unit price if item's unit price is null or 0
          double unitPrice = item.unitPrice ?? 0;
          if (unitPrice <= 0 && item.product?.unitPrice != null) {
            unitPrice = item.product!.unitPrice;
          }

          print('➕ [SalesForm] Creating sale item with unit price: $unitPrice');

          // Get sale ID as string (MongoDB ObjectId)
          final saleId =
              sale['_id']?.toString() ?? sale['id']?.toString() ?? '';
          print('🔍 [SalesForm] Sale ID for items: $saleId');

          final newItem = SaleItem(
            saleId: saleId,
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: unitPrice,
            product: item.product,
          );
          await _saleItemService.addSaleItem(newItem);
        }

        SuccessToast.show(context, 'Sale added successfully');
      }

      widget.onSuccess();
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  // _createStockMovement helper removed (unused)

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.sale != null;

    return Container(
      width: 800,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isEditing ? Icons.edit : Icons.point_of_sale,
                  color: const Color(0xFF6C63FF),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing ? 'Edit Sale' : 'Add New Sale',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B3C34),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFFB0B3C7)),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Customer selection + quick add
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<Customer>(
                    value: _selectedCustomer,
                    isExpanded: true,
                    items:
                        _customers
                            .map(
                              (c) => DropdownMenuItem<Customer>(
                                value: c,
                                child: Text('${c.name} (${c.phoneNumber})'),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCustomer = val;
                        _customerNameController.text = val?.name ?? '';
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Customer',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (_) {
                      if (_selectedCustomer == null &&
                          _customerNameController.text.trim().isEmpty) {
                        return 'Select or add a customer';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final created = await showDialog<Customer?>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('New Customer'),
                          content: SizedBox(
                            width: 380,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: _customerNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Name',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _customerPhoneController,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone number',
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _customerEmailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email (optional)',
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _customerAddressController,
                                  decoration: const InputDecoration(
                                    labelText: 'Address (optional)',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, null),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                if (_customerNameController.text
                                        .trim()
                                        .isEmpty ||
                                    _customerPhoneController.text
                                        .trim()
                                        .isEmpty)
                                  return;
                                try {
                                  final payload = {
                                    'name': _customerNameController.text.trim(),
                                    'phone_number':
                                        _customerPhoneController.text.trim(),
                                  };
                                  final email =
                                      _customerEmailController.text.trim();
                                  if (email.isNotEmpty) {
                                    payload['email'] = email;
                                  }
                                  final address =
                                      _customerAddressController.text.trim();
                                  if (address.isNotEmpty) {
                                    payload['address'] = address;
                                  }
                                  final customer =
                                      await CustomersService.createCustomer(
                                        payload,
                                      );
                                  Navigator.pop(context, customer);
                                } catch (e) {
                                  AppToast.error(
                                    context,
                                    'Error creating customer: $e',
                                  );
                                }
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        );
                      },
                    );
                    if (created != null) {
                      setState(() {
                        _customers.insert(0, created);
                        _selectedCustomer = created;
                        _customerNameController.text = created.name;
                        _customerPhoneController.clear();
                        _customerEmailController.clear();
                        _customerAddressController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sale Date field
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8F0EE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF6C63FF)),
                    const SizedBox(width: 12),
                    Text(
                      'Sale Date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1B3C34),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFFB0B3C7)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Warehouse selection dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8F0EE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warehouse, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 12),
                  Expanded(
                    child:
                        _loadingData
                            ? const Text(
                              'Chargement des entrepôts...',
                              style: TextStyle(color: Color(0xFFB0B3C7)),
                            )
                            : DropdownButton<String>(
                              value:
                                  (_selectedWarehouseId != null &&
                                          _selectedWarehouseId != 'null' &&
                                          _warehouses.any(
                                            (w) =>
                                                w['id']?.toString() ==
                                                _selectedWarehouseId,
                                          ))
                                      ? _selectedWarehouseId
                                      : null,
                              isExpanded: true,
                              underline: Container(),
                              hint: const Text('Sélectionner un entrepôt'),
                              items:
                                  _warehouses.map((warehouse) {
                                    final warehouseId =
                                        warehouse['id']?.toString() ?? '';
                                    return DropdownMenuItem<String>(
                                      value: warehouseId,
                                      child: Text(
                                        warehouse['name'] ??
                                            'Entrepôt $warehouseId',
                                        style: const TextStyle(
                                          color: Color(0xFF1B3C34),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                print(
                                  '🔄 [SalesForm] Warehouse dropdown changed to: $value',
                                );
                                if (value != null &&
                                    value != 'null' &&
                                    value.isNotEmpty) {
                                  setState(() {
                                    _selectedWarehouseId = value;
                                  });
                                  print(
                                    '✅ [SalesForm] Warehouse set to: $_selectedWarehouseId',
                                  );
                                }
                              },
                            ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Created By field (read-only)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8F0EE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF6C63FF)),
                  const SizedBox(width: 12),
                  Expanded(
                    child:
                        _loadingData
                            ? const Text(
                              'Loading user...',
                              style: TextStyle(color: Color(0xFFB0B3C7)),
                            )
                            : Text(
                              'Created by: ${_currentUser?['name'] ?? 'Unknown User'}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF1B3C34),
                              ),
                            ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sale Items
            if (!_loadingData) ...[
              SaleItemForm(
                items: _saleItems,
                warehouseId: _selectedWarehouseId,
                onItemsChanged: (items) {
                  setState(() {
                    _saleItems = items;
                  });
                },
              ),
              const SizedBox(height: 32),
            ],

            // Total Amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8F0EE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B3C34),
                    ),
                  ),
                  Text(
                    '${_totalAmount.toStringAsFixed(2)} DNT',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child:
                    _loading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Text(
                          isEditing ? 'Modifier Vente' : 'Ajouter Vente',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
