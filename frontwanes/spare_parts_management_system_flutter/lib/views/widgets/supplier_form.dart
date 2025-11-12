import 'package:flutter/material.dart';
import '../../services/supplier_service.dart';

class SupplierForm extends StatefulWidget {
  final Map<String, dynamic>? supplier;
  final VoidCallback onSuccess;

  const SupplierForm({
    Key? key,
    this.supplier,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends State<SupplierForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _addressController = TextEditingController();
  final _supplierService = SupplierService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _nameController.text = widget.supplier!['name'] ?? '';
      _contactInfoController.text = widget.supplier!['contact_info'] ?? '';
      _addressController.text = widget.supplier!['address'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactInfoController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final supplierData = {
        'name': _nameController.text.trim(),
        'contact_info': _contactInfoController.text.trim(),
        'address': _addressController.text.trim(),
      };

      if (widget.supplier != null) {
        // Update existing supplier
        await _supplierService.updateSupplier(widget.supplier!['id'], supplierData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supplier updated successfully')),
        );
      } else {
        // Add new supplier
        await _supplierService.addSupplier(supplierData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supplier added successfully')),
        );
      }

      widget.onSuccess();
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.supplier != null;
    
    return Container(
      width: 500,
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
                  isEditing ? Icons.edit : Icons.add_business,
                  color: const Color(0xFF6C63FF),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing ? 'Edit Supplier' : 'Add New Supplier',
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
            
            // Name field
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Supplier Name *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8F0EE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8F0EE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Supplier name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            // Contact Info field
            TextFormField(
              controller: _contactInfoController,
              decoration: InputDecoration(
                labelText: 'Contact Information',
                hintText: 'Phone, email, or other contact details',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8F0EE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8F0EE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            
            // Address field
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                hintText: 'Physical address or location',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8F0EE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8F0EE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFFE8F0EE)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFFB0B3C7),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
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
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isEditing ? 'Update Supplier' : 'Add Supplier',
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
          ],
        ),
      ),
    );
  }
} 