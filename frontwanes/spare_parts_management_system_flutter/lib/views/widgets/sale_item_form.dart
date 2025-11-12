import 'package:flutter/material.dart';
import '../../models/domain/sale_item.dart';
import '../../services/product_service.dart';
import '../../models/domain/product.dart';

class SaleItemForm extends StatefulWidget {
  final List<SaleItem> items;
  final Function(List<SaleItem>) onItemsChanged;
  final String? warehouseId;

  const SaleItemForm({
    super.key,
    required this.items,
    required this.onItemsChanged,
    this.warehouseId,
  });

  @override
  State<SaleItemForm> createState() => _SaleItemFormState();
}

class _SaleItemFormState extends State<SaleItemForm> {
  final _productService = ProductService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SaleItemForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.warehouseId != widget.warehouseId) {
      _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => _loading = true);
      final products = await _productService.getProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      _searchQuery = query;
      _filterProducts();
    });
  }

  void _filterProducts() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = _products;
    } else {
      _filteredProducts =
          _products.where((product) {
            final name = product.name.toLowerCase();
            final reference = product.referenceCode.toLowerCase();
            final barcode = product.barcode?.toLowerCase() ?? '';
            final searchLower = _searchQuery.toLowerCase();

            return name.contains(searchLower) ||
                reference.contains(searchLower) ||
                barcode.contains(searchLower);
          }).toList();
    }
  }

  void _searchByBarcode(String barcode) async {
    try {
      final product = await _productService.getProductByBarcode(barcode);
      if (product != null) {
        _addProductToSale(product);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found with this barcode')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching by barcode: $e')));
    }
  }

  void _addProductToSale(Product product) {
    final price = _parsePrice(product.unitPrice);

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid product price. Please check the product data.',
          ),
        ),
      );
      return;
    }

    final newItems = List<SaleItem>.from(widget.items);
    final newItem = SaleItem(
      productId: product.id ?? '',
      quantity: 1,
      unitPrice: price,
      product: product,
    );
    newItems.add(newItem);
    widget.onItemsChanged(newItems);

    // Clear search
    _searchController.clear();
  }

  double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    try {
      if (price is num) return price.toDouble();
      if (price is String) {
        // Remove any currency symbols and trim whitespace
        final cleanPrice = price.replaceAll(RegExp(r'[^\d.]'), '').trim();
        if (cleanPrice.isEmpty) return 0.0;
        return double.parse(cleanPrice);
      }
      return 0.0;
    } catch (e) {
      print('Error parsing price: $price');
      return 0.0;
    }
  }

  Widget _buildResponsiveItemRow(SaleItem item, int index) {
    final displayUnitPrice =
        (item.unitPrice != null && item.unitPrice! > 0)
            ? item.unitPrice!
            : (item.product?.unitPrice ?? 0.0);
    final totalPrice = displayUnitPrice * (item.quantity ?? 1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.of(context).size.width < 768;

        if (isMobile) {
          // Mobile layout - vertical stack
          return Column(
            children: [
              // Product dropdown - full width
              DropdownButtonFormField<String>(
                value: item.productId,
                decoration: InputDecoration(
                  labelText: 'Product',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                isExpanded: true,
                menuMaxHeight: 200,
                dropdownColor: Colors.white,
                items:
                    _filteredProducts.map((product) {
                      final price = _parsePrice(product.unitPrice);
                      return DropdownMenuItem<String>(
                        value: product.id,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  product.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${price.toStringAsFixed(2)} DNT',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateItem(index, productId: value);
                  }
                },
              ),
              const SizedBox(height: 12),
              // Quantity and Price row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: item.quantity.toString(),
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final quantity = int.tryParse(value);
                        if (quantity != null && quantity > 0) {
                          _updateItem(index, quantity: quantity);
                        }
                      },
                      validator: (value) {
                        final quantity = int.tryParse(value ?? '');
                        if (quantity == null || quantity <= 0) {
                          return 'Enter a valid quantity';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: displayUnitPrice.toStringAsFixed(2),
                      decoration: InputDecoration(
                        labelText: 'Unit Price',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixText: 'DNT',
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (value) {
                        final price = double.tryParse(value);
                        if (price != null && price > 0) {
                          _updateItem(index, unitPrice: price);
                        }
                      },
                      validator: (value) {
                        final price = double.tryParse(value ?? '');
                        if (price == null || price <= 0) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Total and Delete button row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${totalPrice.toStringAsFixed(2)} DNT',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B3C34),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Color(0xFFF44336)),
                    onPressed: () => _removeItem(index),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Desktop/Tablet layout - horizontal row with proper constraints
          return Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  value: item.productId,
                  decoration: InputDecoration(
                    labelText: 'Product',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  isExpanded: true,
                  menuMaxHeight: 200,
                  dropdownColor: Colors.white,
                  items:
                      _filteredProducts.map((product) {
                        final price = _parsePrice(product.unitPrice);
                        return DropdownMenuItem<String>(
                          value: product.id,
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  product.name,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${price.toStringAsFixed(2)} DNT',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _updateItem(index, productId: value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final quantity = int.tryParse(value);
                    if (quantity != null && quantity > 0) {
                      _updateItem(index, quantity: quantity);
                    }
                  },
                  validator: (value) {
                    final quantity = int.tryParse(value ?? '');
                    if (quantity == null || quantity <= 0) {
                      return 'Enter a valid quantity';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: displayUnitPrice.toStringAsFixed(2),
                  decoration: InputDecoration(
                    labelText: 'Unit Price',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixText: 'DNT',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    final price = double.tryParse(value);
                    if (price != null && price > 0) {
                      _updateItem(index, unitPrice: price);
                    }
                  },
                  validator: (value) {
                    final price = double.tryParse(value ?? '');
                    if (price == null || price <= 0) {
                      return 'Enter a valid price';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Total and Delete button
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${totalPrice.toStringAsFixed(2)} DNT',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B3C34),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Color(0xFFF44336),
                        size: 20,
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      onPressed: () => _removeItem(index),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
      },
    );
  }

  void _updateItem(
    int index, {
    String? productId,
    int? quantity,
    double? unitPrice,
  }) {
    final newItems = List<SaleItem>.from(widget.items);
    final item = newItems[index];

    if (productId != null) {
      final product = _products.firstWhere((p) => p.id == productId);
      newItems[index] = SaleItem(
        productId: productId,
        product: product,
        quantity: item.quantity,
        unitPrice:
            unitPrice ?? item.unitPrice ?? _parsePrice(product.unitPrice),
      );
    } else {
      newItems[index] = SaleItem(
        productId: item.productId,
        product: item.product,
        quantity: quantity ?? item.quantity,
        unitPrice: unitPrice ?? item.unitPrice,
      );
    }

    widget.onItemsChanged(newItems);
  }

  void _removeItem(int index) {
    final newItems = List<SaleItem>.from(widget.items);
    newItems.removeAt(index);
    widget.onItemsChanged(newItems);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    print('🔍 [SaleItemForm] Building with ${widget.items.length} items');
    for (int i = 0; i < widget.items.length; i++) {
      final item = widget.items[i];
      print(
        '  SaleItemForm Item $i: productId=${item.productId}, product=${item.product?.name}, quantity=${item.quantity}, unitPrice=${item.unitPrice}',
      );
    }

    return Column(
      children: [
        // Search Products Section
        Card(
          elevation: 0,
          color: const Color(0xFFF8F9FB),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE8F0EE)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Search Products',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B3C34),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by name, reference, or barcode...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF6C63FF),
                          ),
                          suffixIcon:
                              _searchQuery.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Color(0xFF666666),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                  : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8F0EE),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE8F0EE),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_searchController.text.isNotEmpty) {
                          _searchByBarcode(_searchController.text);
                        }
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Found ${_filteredProducts.length} product(s)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                  if (_filteredProducts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final price = _parsePrice(product.unitPrice);
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.inventory,
                              color: Color(0xFF6C63FF),
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${product.referenceCode}${product.barcode != null ? ' | ${product.barcode}' : ''}',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              '${price.toStringAsFixed(2)} DNT',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B3C34),
                              ),
                            ),
                            onTap: () {
                              _addProductToSale(product);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ] else ...[
                  // Show all products when no search query
                  const SizedBox(height: 8),
                  Text(
                    'All Products (${_filteredProducts.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                  if (_filteredProducts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final price = _parsePrice(product.unitPrice);
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.inventory,
                              color: Color(0xFF6C63FF),
                            ),
                            title: Text(
                              product.name,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${product.referenceCode}${product.barcode != null ? ' | ${product.barcode}' : ''}',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              '${price.toStringAsFixed(2)} DNT',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B3C34),
                              ),
                            ),
                            onTap: () {
                              _addProductToSale(product);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Column headers (only for desktop)
        if (widget.items.isNotEmpty) ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = MediaQuery.of(context).size.width < 768;
              if (isMobile) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 600),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 280,
                          child: Text(
                            'Product',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const SizedBox(
                          width: 100,
                          child: Text(
                            'Quantity',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const SizedBox(
                          width: 120,
                          child: Text(
                            'Unit Price',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 120,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              SizedBox(width: 48), // Space for delete button
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const Divider(),
        ],
        // Items List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = widget.items[index];

            return Card(
              elevation: 0,
              color: const Color(0xFFF8F9FB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE8F0EE)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _buildResponsiveItemRow(item, index),
              ),
            );
          },
        ),
        if (widget.items.isEmpty) ...[
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: const [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 48,
                  color: Color(0xFFB0B3C7),
                ),
                SizedBox(height: 16),
                Text(
                  'No items added yet',
                  style: TextStyle(fontSize: 16, color: Color(0xFF666666)),
                ),
                Text(
                  'Search for products above and click on them to add to sale',
                  style: TextStyle(fontSize: 14, color: Color(0xFFB0B3C7)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
