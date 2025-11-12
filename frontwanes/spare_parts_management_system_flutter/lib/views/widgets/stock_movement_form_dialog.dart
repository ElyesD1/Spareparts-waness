import 'package:flutter/material.dart';
import '../../models/domain/product.dart';
import '../../models/domain/warehouse.dart';
import '../../models/domain/user.dart';
import '../../services/product_service.dart';
import '../../services/warehouse_service.dart';
import '../../services/user_service.dart';

class StockMovementFormDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const StockMovementFormDialog({required this.onSuccess, Key? key})
    : super(key: key);

  @override
  State<StockMovementFormDialog> createState() =>
      _StockMovementFormDialogState();
}

class _StockMovementFormDialogState extends State<StockMovementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? productId, fromWarehouseId, toWarehouseId, userId;
  int? quantity;
  String? movementType, note;
  final List<String> movementTypes = ['transfer', 'purchase'];
  List<Product> produits = [];
  List<Warehouse> entrepots = [];
  List<User> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final produitsList = await ProductService().getProducts();
    final entrepotsList = await WarehouseService().getWarehouses();
    final usersList = await UserService.getUsers();
    setState(() {
      produits =
          produitsList
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
      entrepots = entrepotsList.map((e) => Warehouse.fromJson(e)).toList();
      users =
          usersList
              .map((e) => User.fromJson(e as Map<String, dynamic>))
              .toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return AlertDialog(
      title: const Text('Ajouter un mouvement de stock'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Produit'),
                  items:
                      produits
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p.id,
                              child: Text(p.name),
                            ),
                          )
                          .toList(),
                  validator: (value) => value == null ? 'Champ requis' : null,
                  onChanged: (value) => productId = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Type de mouvement',
                  ),
                  items:
                      movementTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                  validator: (value) => value == null ? 'Champ requis' : null,
                  onChanged: (value) => movementType = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Entrepôt source',
                  ),
                  items:
                      entrepots
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e.id,
                              child: Text(e.name),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => fromWarehouseId = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Entrepôt destination',
                  ),
                  items:
                      entrepots
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e.id,
                              child: Text(e.name),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => toWarehouseId = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Utilisateur'),
                  items:
                      users
                          .map(
                            (u) => DropdownMenuItem<String>(
                              value: u.id,
                              child: Text(u.name),
                            ),
                          )
                          .toList(),
                  validator: (value) => value == null ? 'Champ requis' : null,
                  onChanged: (value) => userId = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Quantité'),
                  keyboardType: TextInputType.number,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Champ requis'
                              : null,
                  onSaved: (value) => quantity = int.tryParse(value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Note'),
                  onSaved: (value) => note = value,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              // Appel API pour ajouter le mouvement ici
              widget.onSuccess();
              Navigator.of(context).pop();
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
