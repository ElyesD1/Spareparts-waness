import 'package:flutter/material.dart';
import '../../services/supplier_service.dart';
import '../../services/product_service.dart';
import '../../services/purchase_service.dart';
import '../../services/user_service.dart';
import '../../models/domain/user.dart';
import '../../models/domain/purchase_item.dart';
import '../../services/warehouse_service.dart';
import '../../models/domain/product.dart';

class EditPurchaseForm extends StatefulWidget {
  final dynamic purchase;
  final VoidCallback? onSuccess;
  const EditPurchaseForm({Key? key, this.purchase, this.onSuccess})
    : super(key: key);

  @override
  State<EditPurchaseForm> createState() => _EditPurchaseFormState();
}

class _EditPurchaseFormState extends State<EditPurchaseForm> {
  String? selectedSupplierId;
  String? createdById;
  DateTime? selectedDate;
  double totalAmount = 0.0;

  List<Map<String, dynamic>> suppliers = [];
  List<User> users = [];
  List<Product> products = [];
  List<Map<String, dynamic>> warehouses = [];
  List<PurchaseItem> items = [];
  bool loading = true;

  String? tempProductId;
  String? tempWarehouseId;
  int tempQuantity = 1;
  double tempUnitPrice = 0.0;

  final TextEditingController unitPriceController = TextEditingController();

  void _resetTempProductFields() {
    tempProductId = null;
    tempWarehouseId = null;
    tempQuantity = 1;
    tempUnitPrice = 0.0;
  }

  @override
  void initState() {
    super.initState();
    if (widget.purchase != null) {
      if (widget.purchase is Map) {
        selectedSupplierId = widget.purchase['supplier_id'];
        selectedDate =
            widget.purchase['date'] != null
                ? DateTime.parse(widget.purchase['date'])
                : null;
        createdById = widget.purchase['created_by'];
        totalAmount =
            double.tryParse(widget.purchase['total_amount'].toString()) ?? 0.0;
      } else {
        selectedSupplierId =
            widget.purchase.supplier != null
                ? (widget.purchase.supplier is Map
                    ? widget.purchase.supplier['id']
                    : widget.purchase.supplier.id)
                : null;
        selectedDate =
            widget.purchase.date != null
                ? DateTime.parse(widget.purchase.date)
                : null;
        createdById =
            widget.purchase.createdBy != null
                ? (widget.purchase.createdBy is Map
                    ? widget.purchase.createdBy['id']
                    : widget.purchase.createdBy.id)
                : null;
        totalAmount = widget.purchase.totalAmount?.toDouble() ?? 0.0;
      }
    }
    _fetchData();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur chargement: $e')));
    }
  }

  void _recalculateTotal() {
    setState(() {
      totalAmount = items.fold(
        0.0,
        (sum, item) => sum + item.quantity * item.unitPrice,
      );
    });
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
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter un produit'),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Produit'),
                  items:
                      products
                          .map<DropdownMenuItem<String>>(
                            (p) => DropdownMenuItem<String>(
                              value: p.id,
                              child: Text(p.name),
                            ),
                          )
                          .toList(),
                  onChanged: (val) => selectedProductId = val,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Entrepôt'),
                  items:
                      warehouses
                          .map<DropdownMenuItem<String>>(
                            (w) => DropdownMenuItem<String>(
                              value: w['id']?.toString(),
                              child: Text(w['name']),
                            ),
                          )
                          .toList(),
                  onChanged: (val) => selectedWarehouseId = val,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Quantité'),
                  keyboardType: TextInputType.number,
                  initialValue: '1',
                  onChanged: (val) => quantity = int.tryParse(val) ?? 1,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Prix unitaire'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) => unitPrice = double.tryParse(val) ?? 0.0,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
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
        );
      },
    );
  }

  Future<void> _submit() async {
    if (selectedSupplierId == null ||
        selectedDate == null ||
        createdById == null)
      return;
    final purchaseData = {
      'supplier_id': selectedSupplierId,
      'date': selectedDate!.toIso8601String().substring(0, 10),
      'total_amount': totalAmount,
      'created_by': createdById,
    };
    try {
      final id =
          widget.purchase is Map ? widget.purchase['id'] : widget.purchase.id;
      await PurchaseService().updatePurchase(id, purchaseData);
      // (Optionnel) Envoi des items modifiés si tu veux gérer l'édition des lignes
      if (widget.onSuccess != null) widget.onSuccess!();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur édition: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      width: 500,
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
              'Modifier achat',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Fournisseur'),
              value: selectedSupplierId,
              items:
                  suppliers
                      .map<DropdownMenuItem<String>>(
                        (s) => DropdownMenuItem<String>(
                          value: s['id']?.toString(),
                          child: Text(s['name']),
                        ),
                      )
                      .toList(),
              onChanged: (val) => setState(() => selectedSupplierId = val),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Date'),
              readOnly: true,
              controller: TextEditingController(
                text:
                    selectedDate != null
                        ? selectedDate!.toIso8601String().substring(0, 10)
                        : '',
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
            ),
            const SizedBox(height: 20),
            // (Optionnel) Affichage des items si tu veux permettre l'édition des lignes
            // Total calculé
            TextFormField(
              decoration: const InputDecoration(labelText: 'Total'),
              readOnly: true,
              controller: TextEditingController(
                text: totalAmount.toStringAsFixed(2),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Créé par'),
              value: createdById,
              items:
                  users
                      .map<DropdownMenuItem<String>>(
                        (u) => DropdownMenuItem<String>(
                          value: u.id,
                          child: Text(u.name),
                        ),
                      )
                      .toList(),
              onChanged: (val) => setState(() => createdById = val),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Enregistrer les modifications'),
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
    );
  }
}
