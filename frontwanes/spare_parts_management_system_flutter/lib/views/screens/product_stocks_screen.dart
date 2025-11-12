import 'package:flutter/material.dart';
import '../../views/widgets/sidebar.dart';
import '../../views/widgets/responsive_profile_button.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/domain/product_stock.dart';
import '../../models/domain/product.dart';
import '../../config/app_config.dart';
import '../../services/session_manager.dart';
import '../../services/product_service.dart';

class ProductStocksScreen extends StatefulWidget {
  const ProductStocksScreen({Key? key}) : super(key: key);

  @override
  State<ProductStocksScreen> createState() => _ProductStocksScreenState();
}

class _ProductStocksScreenState extends State<ProductStocksScreen>
    with TickerProviderStateMixin {
  List<ProductStock> _stocks = [];
  List<Product> _products = [];
  List<dynamic> _warehouses = [];
  bool _loading = true;
  String _search = '';
  final int _lowStockThreshold = 5;
  String _selectedFilter = 'Tous';
  late AnimationController _animationController;
  final ProductService _productService = ProductService();
  String? _userRole;

  // Responsive breakpoints
  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadUserData();
    _fetchAll();
  }

  Future<void> _loadUserData() async {
    final user = await SessionManager.getUser();
    setState(() {
      _userRole = user?['role'];
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    try {
      final stocksResp = await http.get(Uri.parse(AppConfig.productStocksUrl));
      final productsResp = await http.get(Uri.parse(AppConfig.productsUrl));
      final warehousesResp = await http.get(Uri.parse(AppConfig.warehousesUrl));

      if (stocksResp.statusCode == 200 &&
          productsResp.statusCode == 200 &&
          warehousesResp.statusCode == 200) {
        final stocks =
            (jsonDecode(stocksResp.body) as List)
                .map((e) => ProductStock.fromJson(e))
                .toList();
        final products =
            (jsonDecode(productsResp.body) as List)
                .map((e) => Product.fromJson(e))
                .toList();
        final warehouses = jsonDecode(warehousesResp.body) as List;

        setState(() {
          _stocks = stocks;
          _products = products;
          _warehouses = warehouses;
          _loading = false;
        });
        _animationController.forward();
      } else {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur de chargement des données'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _searchByBarcode(String barcode) async {
    if (barcode.isEmpty) return;

    try {
      final product = await _productService.getProductByBarcode(barcode);
      if (product != null) {
        // Filter stocks to show only this product
        setState(() {
          _search = product.name;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produit trouvé: ${product.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aucun produit trouvé avec le code-barres: $barcode'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la recherche: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _canAddStock() {
    return _userRole == 'admin' || _userRole == 'manager';
  }

  void _showAddStockDialog() {
    showDialog(
      context: context,
      builder:
          (context) => _AddStockDialog(
            products: _products,
            warehouses: _warehouses,
            onStockAdded: () {
              _fetchAll();
              Navigator.of(context).pop();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // Add drawer for mobile
      drawer:
          _isMobile(context)
              ? Drawer(child: Sidebar(selected: SidebarSection.productStocks))
              : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_isMobile(context)) {
            return _buildMobileLayout();
          } else {
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Column(
        children: [
          // Mobile Header
          _buildMobileHeader(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Stats Grid
                  _buildMobileStats(),
                  const SizedBox(height: 20),

                  // Search and Filters
                  _buildMobileSearchAndFilters(),
                  const SizedBox(height: 20),

                  // Stocks List
                  _buildMobileStocksList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Sidebar(selected: SidebarSection.productStocks),
        Expanded(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - _animationController.value)),
                child: Opacity(
                  opacity: _animationController.value,
                  child: child,
                ),
              );
            },
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Header
                  _buildDesktopHeader(),

                  // Main Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Stats Row
                          _buildDesktopStats(),
                          const SizedBox(height: 32),

                          // Content Area
                          _buildDesktopContent(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.deepPurple.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Hamburger Menu Button
              Builder(
                builder:
                    (BuildContext context) => Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: 'Ouvrir le menu',
                      ),
                    ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.inventory_2, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stock Produits',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Gestion des stocks par entrepôt',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (_canAddStock()) ...[
                    GestureDetector(
                      onTap: _showAddStockDialog,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  GestureDetector(
                    onTap: _fetchAll,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.refresh, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Profile Button
                  ResponsiveProfileButton(
                    isMobile: true,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStats() {
    final totalProducts = _products.length;
    final totalWarehouses = _warehouses.length;
    final dedupedStocks = _getDedupedStocks();
    final totalQuantity = dedupedStocks.fold<int>(
      0,
      (sum, s) => sum + s.quantity,
    );
    final lowStockCount =
        dedupedStocks.where((s) => s.quantity < _lowStockThreshold).length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildMobileStatCard(
          'Produits',
          totalProducts.toString(),
          Icons.category_outlined,
          Colors.blue,
        ),
        _buildMobileStatCard(
          'Entrepôts',
          totalWarehouses.toString(),
          Icons.warehouse_outlined,
          Colors.green,
        ),
        _buildMobileStatCard(
          'Stock Total',
          totalQuantity.toString(),
          Icons.inventory_outlined,
          Colors.orange,
        ),
        _buildMobileStatCard(
          'Stock Faible',
          lowStockCount.toString(),
          Icons.warning_outlined,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildMobileStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSearchAndFilters() {
    return Column(
      children: [
        // Search Bar with Barcode Search
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom, référence, code-barres...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                if (_search.isNotEmpty) {
                  _searchByBarcode(_search);
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
        const SizedBox(height: 12),

        // Filter Chips
        Container(
          height: 45,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFilterChip('Tous'),
              const SizedBox(width: 8),
              _buildFilterChip('Stock Normal'),
              const SizedBox(width: 8),
              _buildFilterChip('Stock Faible'),
              const SizedBox(width: 8),
              _buildFilterChip('Rupture'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    return FilterChip(
      selected: isSelected,
      label: Text(filter),
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? filter : 'Tous';
        });
      },
      backgroundColor:
          isSelected ? Colors.deepPurple.withOpacity(0.1) : Colors.white,
      selectedColor: Colors.deepPurple.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.deepPurple : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      checkmarkColor: Colors.deepPurple,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildMobileStocksList() {
    final filteredStocks = _getFilteredStocks();

    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (filteredStocks.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children:
          filteredStocks.map((stock) => _buildMobileStockCard(stock)).toList(),
    );
  }

  Widget _buildMobileStockCard(ProductStock stock) {
    final isLowStock = stock.quantity < _lowStockThreshold;
    final isEmpty = stock.quantity == 0;

    Color statusColor;
    String statusText;

    if (isEmpty) {
      statusColor = Colors.red;
      statusText = 'Rupture';
    } else if (isLowStock) {
      statusColor = Colors.orange;
      statusText = 'Stock Faible';
    } else {
      statusColor = Colors.green;
      statusText = 'Stock Normal';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.inventory_2, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock.product?.name ?? 'Produit inconnu',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stock.warehouse?['name'] ?? 'Entrepôt inconnu',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (stock.product?.category != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Catégorie: ${stock.product?.category}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      stock.quantity.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2, color: Colors.deepPurple, size: 28),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stocks des Produits',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'Vue d\'ensemble des stocks par entrepôt',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
          if (_canAddStock()) ...[
            ElevatedButton.icon(
              onPressed: _showAddStockDialog,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter Stock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          IconButton(
            onPressed: _fetchAll,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
          const SizedBox(width: 12),
          // Profile Button
          ResponsiveProfileButton(isMobile: false, textColor: Colors.black87),
        ],
      ),
    );
  }

  Widget _buildDesktopStats() {
    final totalProducts = _products.length;
    final totalWarehouses = _warehouses.length;
    final dedupedStocks = _getDedupedStocks();
    final totalQuantity = dedupedStocks.fold<int>(
      0,
      (sum, s) => sum + s.quantity,
    );
    final lowStockCount =
        dedupedStocks.where((s) => s.quantity < _lowStockThreshold).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDesktopStatCard(
                      'Produits Totaux',
                      totalProducts.toString(),
                      Icons.category,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDesktopStatCard(
                      'Entrepôts',
                      totalWarehouses.toString(),
                      Icons.warehouse,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDesktopStatCard(
                      'Unités en Stock',
                      totalQuantity.toString(),
                      Icons.inventory,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDesktopStatCard(
                      'Articles en Rupture',
                      lowStockCount.toString(),
                      Icons.warning,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(
                child: _buildDesktopStatCard(
                  'Produits Totaux',
                  totalProducts.toString(),
                  Icons.category,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDesktopStatCard(
                  'Entrepôts',
                  totalWarehouses.toString(),
                  Icons.warehouse,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDesktopStatCard(
                  'Unités en Stock',
                  totalQuantity.toString(),
                  Icons.inventory,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDesktopStatCard(
                  'Articles en Rupture',
                  lowStockCount.toString(),
                  Icons.warning,
                  Colors.red,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildDesktopStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      '+2.5%',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Stocks des Produits',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const Spacer(),

                // Search Bar
                Container(
                  width: 300,
                  height: 40,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) => setState(() => _search = value),
                  ),
                ),
                const SizedBox(width: 16),

                // Filter Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      items:
                          ['Tous', 'Stock Normal', 'Stock Faible', 'Rupture']
                              .map(
                                (filter) => DropdownMenuItem(
                                  value: filter,
                                  child: Text(
                                    filter,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedFilter = value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Container(
            constraints: const BoxConstraints(minHeight: 400),
            child:
                _loading
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                    : _buildDesktopStocksList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopStocksList() {
    final filteredStocks = _getFilteredStocks();

    if (filteredStocks.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredStocks.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
      itemBuilder: (context, index) {
        return _buildDesktopStockRow(filteredStocks[index]);
      },
    );
  }

  Widget _buildDesktopStockRow(ProductStock stock) {
    final isLowStock = stock.quantity < _lowStockThreshold;
    final isEmpty = stock.quantity == 0;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isEmpty) {
      statusColor = Colors.red;
      statusText = 'Rupture';
      statusIcon = Icons.error;
    } else if (isLowStock) {
      statusColor = Colors.orange;
      statusText = 'Stock Faible';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.green;
      statusText = 'Stock Normal';
      statusIcon = Icons.check_circle;
    }

    return InkWell(
      onTap: () {
        // Handle stock item click
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 800),
            child: Row(
              children: [
                // Product Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),

                // Product Info
                SizedBox(
                  width: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.product?.name ?? 'Produit inconnu',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (stock.product?.category != null)
                        Text(
                          'Catégorie: ${stock.product?.category}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Warehouse
                SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warehouse,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              stock.warehouse?['name'] ?? 'Inconnu',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      if (stock.warehouse?['location'] != null)
                        Text(
                          stock.warehouse?['location'] ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Quantity
                SizedBox(
                  width: 100,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        stock.quantity.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Status
                SizedBox(
                  width: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Actions
                SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () {
                          // Edit stock
                        },
                        tooltip: 'Modifier',
                      ),
                      IconButton(
                        icon: const Icon(Icons.visibility, size: 18),
                        onPressed: () {
                          // View details
                        },
                        tooltip: 'Détails',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun stock trouvé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez d\'ajuster vos filtres de recherche',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<ProductStock> _getDedupedStocks() {
    final Map<String, ProductStock> dedupedMap = {};
    for (final stock in _stocks) {
      final key = '${stock.productId}_${stock.warehouseId}';
      if (dedupedMap.containsKey(key)) {
        final existing = dedupedMap[key]!;
        dedupedMap[key] = ProductStock(
          id: existing.id,
          productId: existing.productId,
          warehouseId: existing.warehouseId,
          quantity: existing.quantity + stock.quantity,
          product: existing.product ?? stock.product,
          warehouse: existing.warehouse ?? stock.warehouse,
        );
      } else {
        dedupedMap[key] = stock;
      }
    }
    return dedupedMap.values.toList();
  }

  List<ProductStock> _getFilteredStocks() {
    final dedupedStocks = _getDedupedStocks();

    return dedupedStocks.where((stock) {
      // Search filter
      final product = (stock.product?.name ?? '').toLowerCase();
      final warehouse =
          (stock.warehouse?['name']?.toString() ?? '').toLowerCase();
      final referenceCode = (stock.product?.referenceCode ?? '').toLowerCase();
      final barcode = (stock.product?.barcode ?? '').toLowerCase();
      final matchesSearch =
          _search.isEmpty ||
          product.contains(_search.toLowerCase()) ||
          warehouse.contains(_search.toLowerCase()) ||
          referenceCode.contains(_search.toLowerCase()) ||
          barcode.contains(_search.toLowerCase());

      if (!matchesSearch) return false;

      // Status filter
      switch (_selectedFilter) {
        case 'Stock Normal':
          return stock.quantity >= _lowStockThreshold;
        case 'Stock Faible':
          return stock.quantity > 0 && stock.quantity < _lowStockThreshold;
        case 'Rupture':
          return stock.quantity == 0;
        default:
          return true;
      }
    }).toList();
  }
}

class _AddStockDialog extends StatefulWidget {
  final List<Product> products;
  final List<dynamic> warehouses;
  final VoidCallback onStockAdded;

  const _AddStockDialog({
    required this.products,
    required this.warehouses,
    required this.onStockAdded,
  });

  @override
  State<_AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<_AddStockDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  Product? _selectedProduct;
  Map<String, dynamic>? _selectedWarehouse;
  bool _loading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _addStock() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null || _selectedWarehouse == null) return;

    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse(AppConfig.productStocksUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'product_id': _selectedProduct!.id,
          'warehouse_id': _selectedWarehouse!['id'],
          'quantity': int.parse(_quantityController.text),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock ajouté avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onStockAdded();
      } else {
        throw Exception('Erreur lors de l\'ajout du stock');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter du Stock'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Selection
            DropdownButtonFormField<Product>(
              value: _selectedProduct,
              decoration: const InputDecoration(
                labelText: 'Produit',
                border: OutlineInputBorder(),
              ),
              items:
                  widget.products.map((product) {
                    return DropdownMenuItem<Product>(
                      value: product,
                      child: Text(
                        '${product.name} (${product.referenceCode})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() => _selectedProduct = value);
              },
              validator: (value) {
                if (value == null) return 'Veuillez sélectionner un produit';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Warehouse Selection
            DropdownButtonFormField<Map<String, dynamic>>(
              value: _selectedWarehouse,
              decoration: const InputDecoration(
                labelText: 'Entrepôt',
                border: OutlineInputBorder(),
              ),
              items:
                  widget.warehouses.map((warehouse) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: warehouse,
                      child: Text(warehouse['name'] ?? ''),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() => _selectedWarehouse = value);
              },
              validator: (value) {
                if (value == null) return 'Veuillez sélectionner un entrepôt';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Quantity Input
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantité',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir une quantité';
                }
                final quantity = int.tryParse(value);
                if (quantity == null || quantity <= 0) {
                  return 'Veuillez saisir une quantité valide';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _addStock,
          child:
              _loading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Ajouter'),
        ),
      ],
    );
  }
}
