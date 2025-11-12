import 'package:flutter/material.dart';
import '../../models/domain/purchase_return.dart';
import '../../models/domain/product.dart';
import '../../services/product_service.dart';
import '../../services/purchase_return_service.dart';
import '../../services/supplier_service.dart';
import '../../services/warehouse_service.dart';
import '../../services/session_manager.dart';
import 'app_toast.dart';

class PurchaseReturnForm extends StatefulWidget {
  final PurchaseReturn? returnItem;
  final VoidCallback onSuccess;

  const PurchaseReturnForm({Key? key, this.returnItem, required this.onSuccess})
    : super(key: key);

  @override
  State<PurchaseReturnForm> createState() => _PurchaseReturnFormState();
}

class _PurchaseReturnFormState extends State<PurchaseReturnForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedSupplierId;
  String? _selectedWarehouseId;

  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _warehouses = [];
  List<Product> _products = [];
  List<PurchaseReturnItem> _items = [];

  bool _loadingData = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.returnItem != null) {
      _reasonController.text = widget.returnItem!.reason;
      _notesController.text = widget.returnItem!.notes ?? '';
      _selectedDate = widget.returnItem!.returnDate;
      _selectedSupplierId = widget.returnItem!.supplierId;
      _selectedWarehouseId = widget.returnItem!.warehouseId;
      // Clear any existing items and load from the return item
      _items.clear();
      if (widget.returnItem!.items != null) {
        _items.addAll(widget.returnItem!.items!);
      }
    } else {
      // For new returns, ensure we start with a clean state
      _items.clear();
      _reasonController.clear();
      _notesController.clear();
      _selectedDate = DateTime.now();
      _selectedSupplierId = null;
      _selectedWarehouseId = null;
    }
  }

  Future<void> _loadData() async {
    setState(() => _loadingData = true);
    try {
      final suppliers = await SupplierService().getSuppliers();
      final warehouses = await WarehouseService().getWarehouses();
      final products = await ProductService().getProducts();
      setState(() {
        _suppliers = suppliers;
        _warehouses = warehouses;
        _products = products;
      });
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error loading data: $e');
      }
    } finally {
      setState(() => _loadingData = false);
    }
  }

  double get _totalAmount => _items.fold(0.0, (sum, it) => sum + it.totalPrice);

  void _addItemDialog([PurchaseReturnItem? existing]) {
    Product? selectedProduct =
        existing != null
            ? _products.firstWhere(
              (p) => p.id == existing.productId,
              orElse: () => _products.first,
            )
            : null;
    int quantity = existing?.quantity ?? 1;
    double unitPrice = existing?.unitPrice ?? 0.0;

    final qtyCtrl = TextEditingController(text: quantity.toString());
    final priceCtrl = TextEditingController(
      text: unitPrice == 0.0 ? '' : unitPrice.toString(),
    );

    // Check if product is already in the list (for new items only)
    bool isProductAlreadyAdded = false;
    if (existing == null && selectedProduct != null) {
      isProductAlreadyAdded = _items.any(
        (item) => item.productId == selectedProduct!.id,
      );
    }

    // Opening dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  existing == null ? Icons.add_circle : Icons.edit,
                  color: const Color(0xFF6C63FF),
                ),
                const SizedBox(width: 8),
                Text(
                  existing == null ? 'Add Return Item' : 'Edit Return Item',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Selection
                  DropdownButtonFormField<Product>(
                    value: selectedProduct,
                    items:
                        _products
                            .where((p) {
                              // For new items, filter out already added products
                              if (existing == null) {
                                return !_items.any(
                                  (item) => item.productId == p.id,
                                );
                              }
                              return true; // For editing, show all products
                            })
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text('${p.name} (${p.referenceCode})'),
                              ),
                            )
                            .toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedProduct = v;
                        // Auto-fill supplier price when product is selected (for returns)
                        if (v != null) {
                          if (v.supplierPrice != null && v.supplierPrice! > 0) {
                            priceCtrl.text = v.supplierPrice.toString();
                          } else if (v.unitPrice > 0) {
                            priceCtrl.text = v.unitPrice.toString();
                          } else {
                            priceCtrl.text = '';
                          }
                        }
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Product *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.inventory_2),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator:
                        (v) => v == null ? 'Please select a product' : null,
                  ),

                  // Warning if product is already added
                  if (isProductAlreadyAdded && existing == null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Colors.orange.shade700,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This product is already in the return list. Adding it again will update the existing item.',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Quantity and Unit Price Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: qtyCtrl,
                          decoration: InputDecoration(
                            labelText: 'Quantity *',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.numbers),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final qty = int.tryParse(v ?? '');
                            if (qty == null || qty <= 0) {
                              return 'Please enter a valid quantity';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: priceCtrl,
                          decoration: InputDecoration(
                            labelText: 'Supplier Price *',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.attach_money),
                            prefixText: '\$',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            helperText:
                                'Price to be credited back from supplier',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) {
                            final price = double.tryParse(v ?? '');
                            if (price == null || price <= 0) {
                              return 'Please enter a valid supplier price greater than 0';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  // Total Price Display
                  if (selectedProduct != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Price:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '\$${_calculateTotal(qtyCtrl.text, priceCtrl.text).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    // Dialog closed
                  });
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedProduct == null) {
                    AppToast.error(context, 'Please select a product');
                    return;
                  }

                  final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                  final unitPrice =
                      double.tryParse(priceCtrl.text.trim()) ?? 0.0;

                  if (qty > 0 && unitPrice > 0) {
                    final item = PurchaseReturnItem(
                      id: existing?.id,
                      purchaseReturnId: existing?.purchaseReturnId ?? '',
                      productId: selectedProduct!.id!,
                      quantity: qty,
                      unitPrice: unitPrice,
                      totalPrice: (qty * unitPrice).toDouble(),
                      productName: selectedProduct!.name,
                      productReference: selectedProduct!.referenceCode,
                    );

                    setState(() {
                      if (existing == null) {
                        // For new items, check if product already exists and update it
                        final existingIndex = _items.indexWhere(
                          (i) => i.productId == item.productId,
                        );
                        if (existingIndex != -1) {
                          // Update existing item instead of adding duplicate
                          _items[existingIndex] = item;
                        } else {
                          // Add new item only if it doesn't exist
                          _items.add(item);
                        }
                      } else {
                        // For editing existing items
                        final idx = _items.indexOf(existing);
                        if (idx != -1) {
                          _items[idx] = item;
                        } else {
                          // Fallback: check if item with same product ID exists
                          final existingIndex = _items.indexWhere(
                            (i) => i.productId == item.productId,
                          );
                          if (existingIndex != -1) {
                            _items[existingIndex] = item;
                          } else {
                            _items.add(item);
                          }
                        }
                      }

                      // AGGRESSIVE DUPLICATE REMOVAL
                      final seen = <String>{};
                      final uniqueItems = <PurchaseReturnItem>[];

                      for (int i = 0; i < _items.length; i++) {
                        final currentItem = _items[i];

                        if (!seen.contains(currentItem.productId)) {
                          seen.add(currentItem.productId);
                          uniqueItems.add(currentItem);
                        } else {}
                      }

                      if (uniqueItems.length != _items.length) {
                        _items.clear();
                        _items.addAll(uniqueItems);
                      } else {}
                    });

                    Navigator.pop(context);

                    // Add a small delay to prevent form submission
                    await Future.delayed(const Duration(milliseconds: 100));

                    setState(() {
                      // Dialog closed
                    });

                    // Dialog closed

                    // Show success message
                    AppToast.success(
                      context,
                      existing == null
                          ? 'Item added successfully'
                          : 'Item updated successfully',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                ),
                child: Text(existing == null ? 'Add Item' : 'Update Item'),
              ),
            ],
          ),
    );
  }

  double _calculateTotal(String qty, String price) {
    final q = int.tryParse(qty) ?? 0;
    final p = double.tryParse(price) ?? 0.0;
    return (q * p).toDouble();
  }

  Future<void> _submit() async {
    // Basic validation
    if (_submitting) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSupplierId == null || _selectedWarehouseId == null) {
      AppToast.error(context, 'Please select supplier and warehouse');
      return;
    }

    if (_items.isEmpty) {
      AppToast.error(context, 'Please add at least one item');
      return;
    }

    setState(() => _submitting = true);

    try {
      await SessionManager.getUser();

      // Deduplicate items by productId (merge quantities) to avoid duplicate rows server-side
      final Map<String, PurchaseReturnItem> productIdToItem = {};
      for (final item in _items) {
        final existing = productIdToItem[item.productId];
        if (existing == null) {
          productIdToItem[item.productId] = item;
        } else {
          final mergedQuantity = existing.quantity + item.quantity;
          final mergedUnitPrice = item.unitPrice; // prefer latest entered price
          final mergedTotalPrice =
              (mergedQuantity * mergedUnitPrice).toDouble();
          productIdToItem[item.productId] = PurchaseReturnItem(
            id: existing.id,
            purchaseReturnId: existing.purchaseReturnId,
            productId: existing.productId,
            quantity: mergedQuantity,
            unitPrice: mergedUnitPrice,
            totalPrice: mergedTotalPrice,
            productName: existing.productName,
            productReference: existing.productReference,
          );
        }
      }
      final uniqueItems = productIdToItem.values.toList();

      // Keep UI state consistent with what we submit
      setState(() {
        _items
          ..clear()
          ..addAll(uniqueItems);
      });

      // Validate and format items data
      final formattedItems =
          uniqueItems.map((e) {
            if (e.quantity <= 0 || e.unitPrice <= 0) {
              throw Exception(
                'Invalid item data: Product ID: ${e.productId}, Quantity: ${e.quantity}, Unit Price: ${e.unitPrice}',
              );
            }
            return {
              'product_id': e.productId,
              'quantity': e.quantity,
              'unit_price': e.unitPrice.toDouble(),
              'total_price': e.totalPrice.toDouble(),
            };
          }).toList();

      final payload = {
        'supplier_id': _selectedSupplierId,
        'warehouse_id': _selectedWarehouseId,
        'return_date': _selectedDate.toIso8601String().split('T')[0],
        'reason': _reasonController.text.trim(),
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
        'items': formattedItems,
      };

      if (widget.returnItem == null) {
        await PurchaseReturnService.createPurchaseReturn(payload);
        AppToast.success(context, 'Purchase return created successfully!');
      } else {
        await PurchaseReturnService.updatePurchaseReturn(
          widget.returnItem!.id!,
          payload,
        );
        AppToast.success(context, 'Purchase return updated successfully!');
      }

      // Call success callback (parent will handle closing the dialog)
      if (mounted) {
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error submitting: $e');
      }
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) {
      return Dialog(
        child: Container(
          width: 400,
          height: 200,
          padding: const EdgeInsets.all(32),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF6C63FF)),
                SizedBox(height: 16),
                Text('Loading data...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }

    final isEditing = widget.returnItem != null;

    return Dialog(
      child: Container(
        width: 900,
        constraints: const BoxConstraints(maxHeight: 900),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
          onChanged: () {},
          onWillPop: () async {
            return true;
          },
          autovalidateMode: AutovalidateMode.disabled,
          child: Column(
            children: [
              // Enhanced Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment_return,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing
                                ? 'Edit Purchase Return'
                                : 'Create Purchase Return',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEditing
                                ? 'Update return details and items'
                                : 'Record products being returned to supplier for credit',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Section
                      _buildSection('Basic Information', Icons.info_outline, [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isTight = constraints.maxWidth < 600;
                            if (isTight) {
                              return Column(
                                children: [
                                  _buildDropdownField(
                                    'Supplier *',
                                    _selectedSupplierId,
                                    _suppliers
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s['id']?.toString(),
                                            child: Text(s['name'] as String),
                                          ),
                                        )
                                        .toList(),
                                    (v) =>
                                        setState(() => _selectedSupplierId = v),
                                    validator:
                                        (v) =>
                                            v == null
                                                ? 'Supplier is required'
                                                : null,
                                    icon: Icons.local_shipping,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDropdownField(
                                    'Warehouse *',
                                    _selectedWarehouseId,
                                    _warehouses
                                        .map(
                                          (w) => DropdownMenuItem(
                                            value: w['id']?.toString(),
                                            child: Text(w['name'] as String),
                                          ),
                                        )
                                        .toList(),
                                    (v) => setState(
                                      () => _selectedWarehouseId = v,
                                    ),
                                    validator:
                                        (v) =>
                                            v == null
                                                ? 'Warehouse is required'
                                                : null,
                                    icon: Icons.home_work,
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: _buildDropdownField(
                                    'Supplier *',
                                    _selectedSupplierId,
                                    _suppliers
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s['id']?.toString(),
                                            child: Text(s['name'] as String),
                                          ),
                                        )
                                        .toList(),
                                    (v) =>
                                        setState(() => _selectedSupplierId = v),
                                    validator:
                                        (v) =>
                                            v == null
                                                ? 'Supplier is required'
                                                : null,
                                    icon: Icons.local_shipping,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDropdownField(
                                    'Warehouse *',
                                    _selectedWarehouseId,
                                    _warehouses
                                        .map(
                                          (w) => DropdownMenuItem(
                                            value: w['id']?.toString(),
                                            child: Text(w['name'] as String),
                                          ),
                                        )
                                        .toList(),
                                    (v) => setState(
                                      () => _selectedWarehouseId = v,
                                    ),
                                    validator:
                                        (v) =>
                                            v == null
                                                ? 'Warehouse is required'
                                                : null,
                                    icon: Icons.home_work,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                'Return Reason *',
                                _reasonController,
                                maxLines: 2,
                                validator:
                                    (v) =>
                                        v?.trim().isEmpty == true
                                            ? 'Reason is required'
                                            : null,
                                icon: Icons.description,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDateField()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Notes',
                          _notesController,
                          maxLines: 3,
                          icon: Icons.note,
                        ),
                      ]),

                      const SizedBox(height: 24),

                      // Items Section
                      _buildSection('Return Items', Icons.inventory_2, [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isTight = constraints.maxWidth < 400;
                            if (isTight) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Items (${_items.length})',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1B3C34),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () {
                                      print(
                                        'Add Item button pressed - opening dialog',
                                      );
                                      _addItemDialog();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6C63FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Add Item',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Items (${_items.length})',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1B3C34),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    print(
                                      'Add Item button pressed - opening dialog',
                                    );
                                    _addItemDialog();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6C63FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Add Item',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        if (_items.isEmpty)
                          _buildEmptyState()
                        else ...[
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Items (${_items.length})',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Debug buttons removed
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildItemsList(),
                        ],

                        if (_items.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildTotalAmount(),
                        ],
                      ]),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed:
                          _submitting
                              ? null
                              : () async {
                                print(
                                  'Submit button pressed - manual submission',
                                );
                                await _submit();
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _submitting
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
                                isEditing ? 'Update Return' : 'Create Return',
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3C34),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<DropdownMenuItem<String>> items,
    ValueChanged<String?> onChanged, {
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Return Date *',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        child: Text(
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No items added yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click "Add Item" to start adding products to return',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children:
            _items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == _items.length - 1;

              return Container(
                decoration: BoxDecoration(
                  color: index.isEven ? Colors.grey.shade50 : Colors.white,
                  border: Border(
                    bottom:
                        isLast
                            ? BorderSide.none
                            : BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 420;
                    final leading = Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.inventory_2,
                        color: const Color(0xFF6C63FF),
                        size: 20,
                      ),
                    );

                    final title = Text(
                      item.productName ?? 'Product #${item.productId}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      softWrap: true,
                    );

                    final subtitle = Text(
                      'Ref: ${item.productReference ?? 'N/A'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    );

                    final chipsAndActions = Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip('Qty', item.quantity.toString()),
                        _buildInfoChip(
                          'Supplier',
                          '\$${item.unitPrice.toStringAsFixed(2)}',
                        ),
                        _buildInfoChip(
                          'Total',
                          '\$${item.totalPrice.toStringAsFixed(2)}',
                          isTotal: true,
                        ),
                        IconButton(
                          onPressed: () => _addItemDialog(item),
                          icon: const Icon(Icons.edit, size: 18),
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => _items.remove(item));
                            AppToast.success(context, 'Item removed');
                          },
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
                            color: Colors.red,
                          ),
                          tooltip: 'Delete',
                        ),
                      ],
                    );

                    if (isCompact) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                leading,
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      title,
                                      const SizedBox(height: 2),
                                      subtitle,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            chipsAndActions,
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          leading,
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                title,
                                const SizedBox(height: 2),
                                subtitle,
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: chipsAndActions,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, {bool isTotal = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            isTotal
                ? const Color(0xFF6C63FF).withOpacity(0.1)
                : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              isTotal
                  ? const Color(0xFF6C63FF).withOpacity(0.3)
                  : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isTotal ? const Color(0xFF6C63FF) : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmount() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Credit Amount:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Amount to be credited from supplier',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            '\$${_totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
