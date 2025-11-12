import 'package:flutter/material.dart';
import '../../services/warehouse_service.dart';

class WarehouseForm extends StatefulWidget {
  final Map<String, dynamic>? warehouse;
  final void Function()? onSuccess;
  const WarehouseForm({Key? key, this.warehouse, this.onSuccess}) : super(key: key);

  @override
  State<WarehouseForm> createState() => _WarehouseFormState();
}

class _WarehouseFormState extends State<WarehouseForm> {
  final WarehouseService _warehouseService = WarehouseService();
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final locationController = TextEditingController();
  bool _loading = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    if (widget.warehouse != null) {
      nameController.text = widget.warehouse!['name'] ?? '';
      locationController.text = widget.warehouse!['location'] ?? '';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; });
    final data = {
      'name': nameController.text,
      'location': locationController.text,
    };
    try {
      if (widget.warehouse != null) {
        // Edit mode
        await _warehouseService.updateWarehouse(widget.warehouse!['id'], data);
      } else {
        // Add mode
        await _warehouseService.addWarehouse(data);
      }
      setState(() { _success = true; });
      if (widget.onSuccess != null) widget.onSuccess!();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 32, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(widget.warehouse != null ? 'Warehouse updated successfully!' : 'Warehouse added successfully!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 32, offset: const Offset(0, 8))],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.warehouse != null ? 'Edit Warehouse' : 'Add Warehouse', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF1B3C34))),
            const SizedBox(height: 24),
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Warehouse Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                fillColor: Colors.grey[50],
                filled: true,
              ),
              validator: (v) => v == null || v.isEmpty ? 'Enter warehouse name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: locationController,
              decoration: InputDecoration(
                labelText: 'Location',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                fillColor: Colors.grey[50],
                filled: true,
              ),
              validator: (v) => v == null || v.isEmpty ? 'Enter location' : null,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(widget.warehouse != null ? 'Update Warehouse' : 'Add Warehouse'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 