import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/product_service.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../models/domain/product.dart';
import '../../services/supplier_service.dart';
import 'app_toast.dart';

String getProductImageUrl(String? image) {
  if (image == null || image.isEmpty) return '';
  if (image.startsWith('http')) return image;

  String cleanImage = image.replaceAll(RegExp(r'^[/\\]+'), '');
  return 'http://localhost:3000/uploads/$cleanImage';
}

class ProductForm extends StatefulWidget {
  final Product? product;
  final void Function()? onSuccess;
  const ProductForm({Key? key, this.product, this.onSuccess}) : super(key: key);

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm>
    with TickerProviderStateMixin {
  final ProductService _productService = ProductService();
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final refController = TextEditingController();
  final barcodeController = TextEditingController();
  String? selectedBrand;
  String? selectedCategory;
  final priceController = TextEditingController();
  final descController = TextEditingController();
  final supplierPriceController = TextEditingController();

  String? selectedSupplierId;
  List<Map<String, dynamic>> _suppliers = [];
  XFile? _pickedImage;
  Uint8List? _imageBytes;
  bool _loading = false;
  bool _success = false;
  late AnimationController _animationController;
  late AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _successController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _initializeForm();
    _fetchSuppliers();
    _animationController.forward();
  }

  void _initializeForm() {
    final product = widget.product;
    if (product != null) {
      nameController.text = product.name;
      refController.text = product.referenceCode;
      barcodeController.text = product.barcode ?? '';
      selectedBrand = product.brand;
      selectedCategory = product.category;
      priceController.text = product.unitPrice.toString();
      descController.text = product.description ?? '';
      supplierPriceController.text = product.supplierPrice?.toString() ?? '';
      selectedSupplierId = product.supplierId;
      if (product.image != null && product.image!.isNotEmpty) {
        _loadNetworkImage(getProductImageUrl(product.image!));
      }
    }
  }

  Future<void> _loadNetworkImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() => _imageBytes = response.bodyBytes);
      }
    } catch (e) {
      // Ignore image loading errors
    }
  }

  Future<void> _fetchSuppliers() async {
    try {
      final suppliers = await SupplierService().getSuppliers();
      setState(() => _suppliers = suppliers);
    } catch (e) {
      // Ignore supplier loading errors
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedImage = image;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final product = Product(
      id: widget.product?.id,
      name: nameController.text,
      referenceCode: refController.text,
      barcode: barcodeController.text.isEmpty ? null : barcodeController.text,
      brand: selectedBrand,
      category: selectedCategory,
      image: widget.product?.image,
      unitPrice: double.tryParse(priceController.text) ?? 0.0,
      description: descController.text.isEmpty ? null : descController.text,
      supplierPrice:
          supplierPriceController.text.isEmpty
              ? null
              : double.tryParse(supplierPriceController.text),
      supplierId: selectedSupplierId,
    );

    try {
      if (widget.product != null) {
        await _productService.updateProductWithImage(
          product.id!,
          product,
          _pickedImage,
        );
      } else {
        await _productService.addProductWithImage(product, _pickedImage);
      }

      setState(() => _success = true);
      _successController.forward();

      await Future.delayed(const Duration(milliseconds: 1500));

      if (widget.onSuccess != null) widget.onSuccess!();
      Navigator.of(context).pop();
    } catch (e) {
      AppToast.error(context, 'Erreur: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade400),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    // Ensure selectedSupplierId is valid
    final validSupplierIds = _suppliers.map((s) => s['_id']).toList();
    String? dropdownValue = selectedSupplierId;
    if (dropdownValue != null && !validSupplierIds.contains(dropdownValue)) {
      dropdownValue = null;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: dropdownValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Fournisseur',
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_shipping,
              color: Color(0xFF6C63FF),
              size: 20,
            ),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Sélectionner un fournisseur'),
          ),
          ..._suppliers
              .where((s) => s['_id'] != null)
              .map<DropdownMenuItem<String>>(
                (supplier) => DropdownMenuItem<String>(
                  value: supplier['_id'].toString(),
                  child: Text(
                    supplier['name'] ?? 'Fournisseur sans nom',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
        ],
        onChanged: (val) => setState(() => selectedSupplierId = val),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.image,
                  color: Color(0xFF6C63FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Image du Produit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: _loading ? null : _pickImage,
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      _imageBytes != null
                          ? const Color(0xFF6C63FF)
                          : Colors.grey[300]!,
                  width: _imageBytes != null ? 2 : 1,
                ),
              ),
              child:
                  _imageBytes != null
                      ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              _imageBytes!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                      : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.cloud_upload,
                              color: Color(0xFF6C63FF),
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Cliquez pour sélectionner une image',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PNG, JPG jusqu\'à 10MB',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return AnimatedBuilder(
        animation: _successController,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * _successController.value),
            child: Opacity(
              opacity: _successController.value,
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.product != null
                          ? 'Produit mis à jour!'
                          : 'Produit ajouté!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'L\'opération s\'est déroulée avec succès',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _animationController.value)),
          child: Opacity(
            opacity: _animationController.value,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6C63FF),
                          const Color(0xFF6C63FF).withOpacity(0.8),
                        ],
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.inventory,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product != null
                                    ? 'Modifier le Produit'
                                    : 'Ajouter un Produit',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                widget.product != null
                                    ? 'Mettre à jour les informations'
                                    : 'Créer un nouveau produit',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Form Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImagePicker(),
                            _buildTextField(
                              controller: nameController,
                              label: 'Nom du Produit',
                              icon: Icons.inventory_2,
                              hint: 'Ex: iPhone 13 Pro',
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? 'Veuillez saisir le nom'
                                          : null,
                            ),
                            _buildTextField(
                              controller: refController,
                              label: 'Code de Référence',
                              icon: Icons.qr_code,
                              hint: 'Ex: IPH13P-256-BLU',
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? 'Veuillez saisir le code de référence'
                                          : null,
                            ),
                            _buildTextField(
                              controller: barcodeController,
                              label: 'Code-barres',
                              icon: Icons.barcode_reader,
                              hint: 'Ex: 1234567890123',
                              validator: null, // Optional field
                            ),
                            _buildBrandDropdown(),
                            _buildCategoryDropdown(),
                            _buildTextField(
                              controller: priceController,
                              label: 'Prix Unitaire (DNT)',
                              icon: Icons.attach_money,
                              hint: 'Ex: 1299.99',
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Veuillez saisir le prix';
                                if (double.tryParse(v) == null)
                                  return 'Prix invalide';
                                return null;
                              },
                            ),
                            _buildTextField(
                              controller: supplierPriceController,
                              label: 'Prix Fournisseur (DNT)',
                              icon: Icons.price_change,
                              hint: 'Ex: 999.99',
                              keyboardType: TextInputType.number,
                            ),
                            _buildDropdownField(),
                            _buildTextField(
                              controller: descController,
                              label: 'Description',
                              icon: Icons.description,
                              hint: 'Description détaillée du produit...',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Actions
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _loading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            child: const Text(
                              'Annuler',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              foregroundColor: Colors.white,
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
                                        color: Colors.white,
                                      ),
                                    )
                                    : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          widget.product != null
                                              ? Icons.update
                                              : Icons.add,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          widget.product != null
                                              ? 'Mettre à jour'
                                              : 'Ajouter',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
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
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _successController.dispose();
    nameController.dispose();
    refController.dispose();
    barcodeController.dispose();
    priceController.dispose();
    descController.dispose();
    supplierPriceController.dispose();
    super.dispose();
  }

  Widget _buildBrandDropdown() {
    const brands = [
      'BOSCH',
      'CONTINENTAL',
      'VALEO',
      'MANN',
      'MAHLE',
      'NGK',
      'DENSO',
      'DELPHI',
      'SKF',
      'TIMKEN',
      'GATES',
      'DAYCO',
      'BREMBO',
      'SACHS',
      'LUK',
      'ZF',
      'BILSTEIN',
      'KYB',
      'MONROE',
      'KONI',
      'MOBIL',
      'CASTROL',
      'SHELL',
      'TOTAL',
      'ELF',
      'MOTUL',
      'LIQUI_MOLY',
      'MILLERS',
      'RED_LINE',
      'AMSOIL',
      'ROYAL_PURPLE',
      'PENNZOIL',
      'VALVOLINE',
      'QUAKER_STATE',
      'HAVOLINE',
      'OTHER',
    ];

    // Ensure selectedBrand is valid
    String? dropdownValue = selectedBrand;
    if (dropdownValue != null && !brands.contains(dropdownValue)) {
      dropdownValue = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: dropdownValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Marque',
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.business,
              color: Color(0xFF6C63FF),
              size: 20,
            ),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Sélectionner une marque'),
          ),
          ...brands.map(
            (brand) => DropdownMenuItem<String>(
              value: brand,
              child: Text(brand.replaceAll('_', ' ')),
            ),
          ),
        ],
        onChanged: (val) => setState(() => selectedBrand = val),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    const categories = [
      'ELECTRONICS',
      'AUTOMOTIVE',
      'MECHANICAL',
      'ELECTRICAL',
      'PLUMBING',
      'HVAC',
      'TOOLS',
      'SAFETY_EQUIPMENT',
      'LUBRICANTS',
      'FILTERS',
      'BELTS',
      'BRAKES',
      'ENGINE_PARTS',
      'TRANSMISSION',
      'SUSPENSION',
      'OTHER',
    ];

    // Ensure selectedCategory is valid
    String? dropdownValue = selectedCategory;
    if (dropdownValue != null && !categories.contains(dropdownValue)) {
      dropdownValue = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: dropdownValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Catégorie',
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.category,
              color: Color(0xFF6C63FF),
              size: 20,
            ),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Sélectionner une catégorie'),
          ),
          ...categories.map(
            (cat) => DropdownMenuItem<String>(
              value: cat,
              child: Text(cat.replaceAll('_', ' ')),
            ),
          ),
        ],
        onChanged: (val) => setState(() => selectedCategory = val),
      ),
    );
  }
}
