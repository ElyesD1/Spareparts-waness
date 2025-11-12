import 'package:flutter/material.dart';
import '../../services/supplier_service.dart';
import '../../services/product_service.dart';
import '../../services/purchase_service.dart';
import '../../services/user_service.dart';
import '../../models/domain/user.dart';
import '../../models/domain/purchase_item.dart';
import '../../services/warehouse_service.dart';
import '../../services/supplier_credit_service.dart';
import '../../models/domain/product.dart';
import '../../models/domain/supplier_credit.dart';
import '../../services/session_manager.dart';
import 'success_toast.dart';
import 'app_toast.dart';

class NewPurchaseForm extends StatefulWidget {
  final VoidCallback? onSuccess;
  const NewPurchaseForm({Key? key, this.onSuccess}) : super(key: key);

  @override
  State<NewPurchaseForm> createState() => _NewPurchaseFormState();
}

class _NewPurchaseFormState extends State<NewPurchaseForm> {
  String? selectedSupplierId;
  String? createdById;
  DateTime? selectedDate;
  double totalAmount = 0.0;
  double availableCredit = 0.0;
  double finalAmount = 0.0;
  bool loadingCredits = false;

  List<Map<String, dynamic>> suppliers = [];
  List<User> users = [];
  List<Product> products = [];
  List<Map<String, dynamic>> warehouses = [];
  List<PurchaseItem> items = [];
  bool loading = true;

  // Variables pour le mini-formulaire d'ajout de produit
  String? tempProductId;
  String? tempWarehouseId;
  int tempQuantity = 1;
  double tempUnitPrice = 0.0;

  final TextEditingController unitPriceController = TextEditingController();

  Map<String, dynamic>? _currentUser;

  void _resetTempProductFields() {
    tempProductId = null;
    tempWarehouseId = null;
    tempQuantity = 1;
    tempUnitPrice = 0.0;
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchCurrentUser();
  }

  @override
  void dispose() {
    unitPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => loading = true);
    try {
      suppliers = await SupplierService().getSuppliers();
      users = await UserService.getUsers();
      products = await ProductService().getProducts();
      warehouses = await WarehouseService().getWarehouses();
      setState(() => loading = false);
    } catch (e) {
      setState(() => loading = false);
      AppToast.error(context, 'Erreur chargement: $e');
    }
  }

  Future<void> _fetchCurrentUser() async {
    final user = await SessionManager.getUser();
    setState(() {
      _currentUser = user;
      // Get user ID from SessionManager (saved as 'id')
      createdById = user?['id'];
    });
    print(
      '[NewPurchaseForm] Current user loaded: ${user?['email']} (ID: $createdById, type: ${createdById.runtimeType})',
    );
  }

  void _recalculateTotal() {
    setState(() {
      totalAmount = items.fold(
        0.0,
        (sum, item) => sum + item.quantity * item.unitPrice,
      );
      _calculateFinalAmount();
    });
  }

  void _calculateFinalAmount() {
    finalAmount =
        (totalAmount - availableCredit).clamp(0.0, double.infinity).toDouble();
  }

  Future<void> _fetchAvailableCredits() async {
    if (selectedSupplierId == null) return;

    print('Fetching credits for supplier ID: $selectedSupplierId');

    setState(() {
      loadingCredits = true;
    });

    try {
      final credit = await SupplierCreditService.getTotalAvailableCredit(
        selectedSupplierId!,
      );
      print('Credit fetched successfully: \$${credit.toStringAsFixed(2)}');

      setState(() {
        availableCredit = credit;
        _calculateFinalAmount();
        loadingCredits = false;
      });

      print(
        'State updated - availableCredit: \$${availableCredit.toStringAsFixed(2)}',
      );
      print('State updated - finalAmount: \$${finalAmount.toStringAsFixed(2)}');
    } catch (e) {
      print('Error fetching available credits: $e');
      setState(() {
        availableCredit = 0.0;
        _calculateFinalAmount();
        loadingCredits = false;
      });
    }
  }

  void _showCreditDetails() {
    if (selectedSupplierId == null) return;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: MediaQuery.of(context).size.height - 80,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.credit_card, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Credit Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<SupplierCredit>>(
                        future: SupplierCreditService.getAllCredits(
                          supplierId: selectedSupplierId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Text(
                              'Error loading credits: ${snapshot.error}',
                            );
                          }

                          final credits = snapshot.data ?? [];
                          if (credits.isEmpty) {
                            return const Text(
                              'No credits found for this supplier.',
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Credits: \$${availableCredit.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Total Credits: ${credits.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...credits.map(
                                (credit) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Credit #${credit.id ?? 'N/A'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  credit.status ==
                                                          CreditStatus.ACTIVE
                                                      ? Colors.green.shade100
                                                      : credit.status ==
                                                          CreditStatus.EXPIRED
                                                      ? Colors.red.shade100
                                                      : Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                color:
                                                    credit.status ==
                                                            CreditStatus.ACTIVE
                                                        ? Colors.green.shade300
                                                        : credit.status ==
                                                            CreditStatus.EXPIRED
                                                        ? Colors.red.shade300
                                                        : Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Text(
                                              credit.status.name.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    credit.status ==
                                                            CreditStatus.ACTIVE
                                                        ? Colors.green.shade700
                                                        : credit.status ==
                                                            CreditStatus.EXPIRED
                                                        ? Colors.red.shade700
                                                        : Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Original Amount:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            '\$${credit.creditAmount.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Remaining:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            '\$${credit.remainingAmount.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color:
                                                  credit.remainingAmount > 0
                                                      ? Colors.green.shade700
                                                      : Colors.grey.shade600,
                                              fontWeight:
                                                  credit.remainingAmount > 0
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Source: ${credit.sourceType.name.replaceAll('_', ' ').toUpperCase()}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      if (credit.expiryDate != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Expires: ${credit.expiryDate!.toIso8601String().split('T')[0]}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                      if (credit.notes?.isNotEmpty == true) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Notes: ${credit.notes}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  void _addItem(PurchaseItem item) {
    setState(() {
      items.add(item);
      _recalculateTotal();
    });
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
      _recalculateTotal();
    });
  }

  Future<void> _showAddItemDialog() async {
    String? selectedProductId;
    String? selectedWarehouseId;
    int quantity = 1;
    double unitPrice = 0.0;
    final TextEditingController unitPriceController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: MediaQuery.of(context).size.height - 80,
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Ajouter un produit',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Produit',
                          ),
                          isExpanded: true,
                          value: selectedProductId,
                          items:
                              products
                                  .where((p) => p.id != null)
                                  .map<DropdownMenuItem<String>>(
                                    (p) => DropdownMenuItem<String>(
                                      value: p.id!,
                                      child: Text(p.name),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedProductId = val;
                              if (val == null) {
                                unitPriceController.text = '';
                                unitPrice = 0;
                                print('DEBUG: No product selected');
                              } else {
                                final product = products.firstWhere(
                                  (p) => p.id == val,
                                );
                                print(
                                  'DEBUG: Selected product: ${product.name}, supplierPrice: ${product.supplierPrice}',
                                );
                                if (product.supplierPrice != null) {
                                  unitPriceController.text =
                                      product.supplierPrice.toString();
                                  unitPrice = product.supplierPrice!;
                                } else {
                                  unitPriceController.text = '';
                                  unitPrice = 0;
                                }
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Entrepôt',
                          ),
                          isExpanded: true,
                          value: selectedWarehouseId,
                          items:
                              warehouses
                                  .where((w) => w['_id'] != null)
                                  .map<DropdownMenuItem<String>>(
                                    (w) => DropdownMenuItem<String>(
                                      value: w['_id'].toString(),
                                      child: Text(w['name']),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) =>
                                  setState(() => selectedWarehouseId = val),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Quantité',
                          ),
                          keyboardType: TextInputType.number,
                          initialValue: '1',
                          onChanged: (val) => quantity = int.tryParse(val) ?? 1,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: unitPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Prix unitaire',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged:
                              (val) => unitPrice = double.tryParse(val) ?? 0.0,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annuler'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                if (selectedProductId != null &&
                                    selectedWarehouseId != null &&
                                    quantity > 0 &&
                                    unitPrice > 0) {
                                  final product = products.firstWhere(
                                    (p) => p.id == selectedProductId,
                                  );
                                  final warehouse = warehouses.firstWhere(
                                    (w) => w['id'] == selectedWarehouseId,
                                  );
                                  _addItem(
                                    PurchaseItem(
                                      productId: selectedProductId!,
                                      productName: product.name,
                                      warehouseId: selectedWarehouseId!,
                                      warehouseName: warehouse['name'],
                                      quantity: quantity,
                                      unitPrice: unitPrice,
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text('Ajouter'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (selectedSupplierId == null ||
        selectedDate == null ||
        createdById == null ||
        items.isEmpty)
      return;
    final purchaseData = {
      'supplier_id': selectedSupplierId,
      'date': selectedDate!.toIso8601String().substring(0, 10),
      'total_amount': totalAmount,
      'created_by': createdById,
    };
    print(
      '[NewPurchaseForm] Submitting purchase with created_by: $createdById (type: ${createdById.runtimeType})',
    );
    print('[NewPurchaseForm] Purchase data: $purchaseData');
    try {
      final purchaseId = await PurchaseService().createPurchase(purchaseData);
      // Envoi des items
      for (final item in items) {
        final itemData = item.toJson();
        itemData['purchase_id'] = purchaseId;
        await PurchaseService().createPurchaseItem(itemData);

        // REMOVED: Stock movement creation - this will only happen when purchase is delivered
        // await _createStockMovement(item, purchaseId);
      }
      // Auto-apply available supplier credits to this purchase
      try {
        await SupplierCreditService.autoApplyCreditsToPurchase(purchaseId);
        // ignore: use_build_context_synchronously
        AppToast.success(context, 'Supplier credits applied');
      } catch (e) {
        // ignore: use_build_context_synchronously
        AppToast.error(context, 'Credit auto-apply failed: $e');
      }
      if (widget.onSuccess != null) widget.onSuccess!();
      Navigator.pop(context);
      SuccessToast.show(context, 'Purchase created successfully');
    } catch (e) {
      AppToast.error(context, 'Erreur création: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;
        final maxWidth = isSmall ? constraints.maxWidth - 32 : 720;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth.toDouble()),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Nouvel achat',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Fournisseur',
                      ),
                      isExpanded: true,
                      value: selectedSupplierId,
                      items:
                          suppliers
                              .where((s) => s['_id'] != null)
                              .map<DropdownMenuItem<String>>(
                                (s) => DropdownMenuItem<String>(
                                  value: s['_id'].toString(),
                                  child: Text(s['name']),
                                ),
                              )
                              .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedSupplierId = val;
                          // Reset credits when supplier changes
                          if (val == null) {
                            availableCredit = 0.0;
                            finalAmount = totalAmount;
                          }
                        });
                        if (val != null) {
                          _fetchAvailableCredits();
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Date'),
                      readOnly: true,
                      controller: TextEditingController(
                        text:
                            selectedDate != null
                                ? selectedDate!.toIso8601String().substring(
                                  0,
                                  10,
                                )
                                : '',
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null)
                          setState(() => selectedDate = picked);
                      },
                    ),
                    const SizedBox(height: 20),
                    // Section items
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lignes d\'achat',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Mini-formulaire inline pour ajouter un produit
                    Card(
                      color: const Color(0xFFF8FAFC),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Produit',
                                    ),
                                    isExpanded: true,
                                    value: tempProductId,
                                    items:
                                        products
                                            .where((p) => p.id != null)
                                            .map<DropdownMenuItem<String>>(
                                              (p) => DropdownMenuItem<String>(
                                                value: p.id!,
                                                child: Text(p.name),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        tempProductId = val;
                                        if (val == null) {
                                          unitPriceController.text = '';
                                          tempUnitPrice = 0;
                                          print(
                                            'DEBUG: No product selected (inline)',
                                          );
                                        } else {
                                          final product = products.firstWhere(
                                            (p) => p.id == val,
                                          );
                                          print(
                                            'DEBUG: [INLINE] Selected product: ${product.name}, supplierPrice: ${product.supplierPrice}',
                                          );
                                          if (product.supplierPrice != null) {
                                            unitPriceController.text =
                                                product.supplierPrice
                                                    .toString();
                                            tempUnitPrice =
                                                product.supplierPrice!;
                                          } else {
                                            unitPriceController.text = '';
                                            tempUnitPrice = 0;
                                          }
                                        }
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Entrepôt',
                                    ),
                                    isExpanded: true,
                                    value: tempWarehouseId,
                                    items:
                                        warehouses
                                            .where((w) => w['_id'] != null)
                                            .map<DropdownMenuItem<String>>(
                                              (w) => DropdownMenuItem<String>(
                                                value: w['_id'].toString(),
                                                child: Text(w['name']),
                                              ),
                                            )
                                            .toList(),
                                    onChanged:
                                        (val) => setState(
                                          () => tempWarehouseId = val,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LayoutBuilder(
                              builder: (context, c) {
                                final tight = c.maxWidth < 480;

                                final quantityField = Expanded(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Quantité',
                                    ),
                                    initialValue: tempQuantity.toString(),
                                    keyboardType: TextInputType.number,
                                    onChanged:
                                        (val) => setState(
                                          () =>
                                              tempQuantity =
                                                  int.tryParse(val) ?? 1,
                                        ),
                                  ),
                                );

                                final priceField = Expanded(
                                  child: TextFormField(
                                    controller: unitPriceController,
                                    decoration: const InputDecoration(
                                      labelText: 'Prix unitaire',
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    onChanged:
                                        (val) => setState(
                                          () =>
                                              tempUnitPrice =
                                                  double.tryParse(val) ?? 0.0,
                                        ),
                                  ),
                                );

                                final addButton = ElevatedButton(
                                  onPressed: () {
                                    if (tempProductId != null &&
                                        tempWarehouseId != null &&
                                        tempQuantity > 0 &&
                                        tempUnitPrice > 0) {
                                      final product = products.firstWhere(
                                        (p) => p.id == tempProductId,
                                      );
                                      final warehouse = warehouses.firstWhere(
                                        (w) => w['_id'] == tempWarehouseId,
                                      );
                                      setState(() {
                                        items.add(
                                          PurchaseItem(
                                            productId: tempProductId!,
                                            productName: product.name,

                                            warehouseId: tempWarehouseId!,
                                            warehouseName: warehouse['name'],
                                            quantity: tempQuantity,
                                            unitPrice: tempUnitPrice,
                                          ),
                                        );
                                        _recalculateTotal();
                                        _resetTempProductFields();
                                        unitPriceController.clear();
                                      });
                                    } else {}
                                  },
                                  child: const Text('Ajouter'),
                                );

                                if (tight) {
                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          quantityField,
                                          const SizedBox(width: 8),
                                          priceField,
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      addButton,
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    quantityField,
                                    const SizedBox(width: 8),
                                    priceField,
                                    const SizedBox(width: 8),
                                    addButton,
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (items.isEmpty)
                      const Text('Aucun produit ajouté.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              title: Text(
                                '${item.productName} (x${item.quantity})',
                              ),
                              subtitle: Text(
                                'Entrepôt: ${item.warehouseName} | Prix unitaire: ${item.unitPrice}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeItem(i),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),

                    // Credit Information Section
                    if (selectedSupplierId != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              availableCredit > 0
                                  ? Colors.green.shade50
                                  : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                availableCredit > 0
                                    ? Colors.green.shade200
                                    : Colors.blue.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  availableCredit > 0
                                      ? Icons.credit_card
                                      : Icons.info_outline,
                                  color:
                                      availableCredit > 0
                                          ? Colors.green.shade700
                                          : Colors.blue.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  availableCredit > 0
                                      ? 'Available Supplier Credits'
                                      : 'No Available Credits',
                                  style: TextStyle(
                                    color:
                                        availableCredit > 0
                                            ? Colors.green.shade700
                                            : Colors.blue.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _fetchAvailableCredits(),
                                      icon: Icon(
                                        Icons.refresh,
                                        size: 16,
                                        color: Colors.blue.shade700,
                                      ),
                                      tooltip: 'Refresh Credits',
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _showCreditDetails(),
                                      icon: Icon(
                                        Icons.info,
                                        size: 16,
                                        color: Colors.blue.shade700,
                                      ),
                                      label: Text(
                                        'View All Credits',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (loadingCredits) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Loading credits...',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (availableCredit > 0) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Original Total:',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  Text(
                                    '\$${totalAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Credit Applied:',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  Text(
                                    '-\$${availableCredit.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.green, height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Final Amount:',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '\$${finalAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (!loadingCredits) ...[
                              Text(
                                'This supplier has no available credits to apply.',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),
                    // Total calculé
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Total Amount',
                        labelStyle: TextStyle(
                          color:
                              availableCredit > 0
                                  ? Colors.grey.shade600
                                  : Colors.black87,
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color:
                                availableCredit > 0
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade400,
                          ),
                        ),
                        filled: true,
                        fillColor:
                            availableCredit > 0
                                ? Colors.grey.shade50
                                : Colors.white,
                      ),
                      readOnly: true,
                      controller: TextEditingController(
                        text: totalAmount.toStringAsFixed(2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Final Amount After Credits
                    if (availableCredit > 0 && !loadingCredits)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.savings,
                                  color: Colors.green.shade700,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Credit Applied Successfully!',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Final Amount (After Credits)',
                                labelStyle: TextStyle(
                                  color: Colors.green.shade700,
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.green.shade300,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: Icon(
                                  Icons.attach_money,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              readOnly: true,
                              controller: TextEditingController(
                                text: finalAmount.toStringAsFixed(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Créé par'),
                      readOnly: true,
                      controller: TextEditingController(
                        text:
                            _currentUser != null
                                ? _currentUser!['name'] ?? ''
                                : '',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Valider'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _createTestCredit() async {
    if (selectedSupplierId == null) return;

    try {
      final success = await SupplierCreditService.createTestCredit(
        selectedSupplierId!,
        50.0,
      );
      if (success) {
        AppToast.success(context, 'Test credit created successfully!');
        // Refresh the credits
        await _fetchAvailableCredits();
      } else {
        AppToast.error(context, 'Failed to create test credit');
      }
    } catch (e) {
      AppToast.error(context, 'Error: $e');
    }
  }

  Future<void> _fixExistingCredit() async {
    if (selectedSupplierId == null) return;

    try {
      // Get all credits for the supplier
      final credits = await SupplierCreditService.getAllCredits(
        supplierId: selectedSupplierId,
      );
      if (credits.isEmpty) {
        AppToast.error(context, 'No credits found for this supplier');
        return;
      }

      // Find credits with remaining_amount = 0 but credit_amount > 0
      final creditsToFix =
          credits
              .where((c) => c.remainingAmount == 0 && c.creditAmount > 0)
              .toList();

      if (creditsToFix.isEmpty) {
        AppToast.error(context, 'No credits need fixing');
        return;
      }

      // Fix each credit
      int fixedCount = 0;
      for (final credit in creditsToFix) {
        if (credit.id != null) {
          final success =
              await SupplierCreditService.updateCreditRemainingAmount(
                credit.id!,
                credit.creditAmount,
              );
          if (success) fixedCount++;
        }
      }

      if (fixedCount > 0) {
        AppToast.success(context, 'Fixed $fixedCount credit(s)!');
        // Refresh the credits
        await _fetchAvailableCredits();
      } else {
        AppToast.error(context, 'Failed to fix credits');
      }
    } catch (e) {
      AppToast.error(context, 'Error: $e');
    }
  }

  Future<void> _fixDatabaseCredits() async {
    if (selectedSupplierId == null) return;

    try {
      final success = await SupplierCreditService.fixDatabaseCredits(
        selectedSupplierId!,
      );
      if (success) {
        AppToast.success(context, 'Database credits fixed successfully!');
        // Refresh the credits
        await _fetchAvailableCredits();
      } else {
        AppToast.error(context, 'Failed to fix database credits');
      }
    } catch (e) {
      AppToast.error(context, 'Error: $e');
    }
  }
}
