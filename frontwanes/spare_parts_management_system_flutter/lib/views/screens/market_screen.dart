import 'package:flutter/material.dart';
import '../../models/domain/product_stock.dart';
import '../../models/domain/product.dart';
import '../../services/product_stock_service.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_header.dart';
import 'package:intl/intl.dart';

// Class to group products from different warehouses
class GroupedProduct {
  final Product product;
  final List<ProductStock> stockEntries;
  final int totalQuantity;
  final List<String> warehouseNames;

  GroupedProduct({
    required this.product,
    required this.stockEntries,
    required this.totalQuantity,
    required this.warehouseNames,
  });
}

class MarketScreen extends StatefulWidget {
  const MarketScreen({Key? key}) : super(key: key);

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final ProductStockService _productStockService = ProductStockService();
  List<GroupedProduct> _groupedProducts = [];
  List<GroupedProduct> _filteredGroupedProducts = [];
  bool _loading = true;
  String _search = '';
  String _selectedCategory = 'all';

  // Debug flag - set to true to see image loading debug info
  static const bool _debugImages = false;

  bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;

  @override
  void initState() {
    super.initState();
    _loadProductStocks();
  }

  Future<void> _loadProductStocks() async {
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      final productStocks = await _productStockService.getAllProductStocks();
      final productsInStock = productStocks.where((productStock) =>
        productStock.quantity > 0 && productStock.product != null
      ).toList();

      // Group products by product ID
      final grouped = _groupProductsByProduct(productsInStock);

      setState(() {
        _groupedProducts = grouped;
        _filteredGroupedProducts = grouped;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  List<GroupedProduct> _groupProductsByProduct(List<ProductStock> productStocks) {
    final Map<String, List<ProductStock>> grouped = {};
    
    for (final stock in productStocks) {
      if (stock.product != null && stock.product!.id != null) {
        final productId = stock.product!.id!;
        if (grouped[productId] == null) {
          grouped[productId] = [];
        }
        grouped[productId]!.add(stock);
      }
    }

    return grouped.entries.map((entry) {
      final stockEntries = entry.value;
      final product = stockEntries.first.product!;
      final totalQuantity = stockEntries.fold(0, (sum, stock) => sum + stock.quantity);
      final warehouseNames = stockEntries
          .map((stock) => stock.warehouse?['name']?.toString() ?? 'Warehouse ${stock.warehouseId}')
          .cast<String>()
          .toList();

      return GroupedProduct(
        product: product,
        stockEntries: stockEntries,
        totalQuantity: totalQuantity,
        warehouseNames: warehouseNames,
      );
    }).toList();
  }

  void _filterProducts() {
    setState(() {
      // Filter grouped products
      _filteredGroupedProducts = _groupedProducts.where((groupedProduct) {
        final product = groupedProduct.product;

        final matchesSearch = _search.isEmpty ||
          product.name.toLowerCase().contains(_search.toLowerCase()) ||
          product.referenceCode.toLowerCase().contains(_search.toLowerCase());

        final matchesCategory = _selectedCategory == 'all' ||
          (product.category != null && product.category!.toLowerCase() == _selectedCategory.toLowerCase());

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  List<String> _getCategories() {
    final categories = _groupedProducts
        .where((gp) => gp.product.category != null)
        .map((gp) => gp.product.category!)
        .toSet()
        .toList();
    categories.sort();
    return ['all', ...categories];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: _isMobile(context) ? const Sidebar(selected: SidebarSection.market) : null,
      body: Row(
        children: [
          if (!_isMobile(context)) const Sidebar(selected: SidebarSection.market),
          Expanded(
            child: Column(
              children: [
                if (!_isMobile(context))
                  const AppHeader(isMobile: false)
                else
                  _buildMobileHeader(),
                if (_debugImages) _buildDebugPanel(),
                Expanded(
                  child: _isMobile(context)
                      ? _buildMobileLayout()
                      : _buildDesktopLayout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        border: Border.all(color: Colors.orange[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.orange[700], size: 16),
              const SizedBox(width: 8),
              Text(
                'DEBUG MODE - Image Loading Info',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Check console for detailed image loading logs.\nIf images don\'t load, check:\n'
            '• Backend server is running (localhost:3000)\n'
            '• Image files exist in uploads/products/\n'
            '• Image URLs in database are correct',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black87),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shop',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Marché des produits',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // User profile section
            GestureDetector(
              onTap: () => _showUserProfile(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green[400],
                      radius: 16,
                      child: const Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Invité',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Guest',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildUserProfileModal(),
    );
  }

  Widget _buildUserProfileModal() {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.8,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.green[400]!, Colors.green[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // User Info
                      const Text(
                        'Maram',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Profile Options
                      _buildProfileOption(
                        icon: Icons.person_outline,
                        title: 'Informations du profil',
                        subtitle: 'Voir les détails du compte',
                        onTap: () {},
                      ),
                      _buildProfileOption(
                        icon: Icons.history,
                        title: 'Historique',
                        subtitle: 'Voir l\'activité récente',
                        onTap: () {},
                      ),
                      _buildProfileOption(
                        icon: Icons.settings,
                        title: 'Paramètres',
                        subtitle: 'Configurer l\'application',
                        onTap: () {},
                      ),
                      _buildProfileOption(
                        icon: Icons.help_outline,
                        title: 'Aide & Support',
                        subtitle: 'Obtenir de l\'aide',
                        onTap: () {},
                      ),
                      _buildProfileOption(
                        icon: Icons.info_outline,
                        title: 'À propos',
                        subtitle: 'Version et informations',
                        onTap: () {},
                      ),
                      const SizedBox(height: 20),
                      
                      // Logout Button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, color: Colors.red[600], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Se déconnecter',
                              style: TextStyle(
                                color: Colors.red[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.green[600], size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: Icon(Icons.search, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() => _search = value);
                    _filterProducts();
                  },
                ),
              ),
              Container(
                height: 40,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _getCategories().map((category) {
                    final isSelected = _selectedCategory == category;
                    final displayName = category == 'all' ? 'Tous' : category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(displayName, isSelected, () {
                        setState(() => _selectedCategory = category);
                        _filterProducts();
                      }),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading ? _buildLoadingState() : _buildProductsShopList(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildDesktopHeader(),
          const SizedBox(height: 24),
          _buildFiltersSection(),
          const SizedBox(height: 24),
          Expanded(
            child: _loading ? _buildLoadingState() : _buildProductsShopGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Marketplace',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showUserProfile,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.green,
                  child: const Text(
                    'M',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Maram',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(Icons.search, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() => _search = value);
                _filterProducts();
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Catégorie',
                prefixIcon: Icon(Icons.category, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _getCategories().map((category) {
                final displayName = category == 'all' ? 'Toutes les catégories' : category;
                return DropdownMenuItem(value: category, child: Text(displayName));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value!);
                _filterProducts();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildProductsShopList() {
    if (_filteredGroupedProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_basket, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun produit disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier vos filtres',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: _filteredGroupedProducts.length,
      itemBuilder: (context, index) {
        final groupedProduct = _filteredGroupedProducts[index];
        return _buildShopProductCard(groupedProduct);
      },
    );
  }

  Widget _buildProductsShopGrid() {
    if (_filteredGroupedProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_basket, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun produit disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier vos filtres',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.75,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
      ),
      itemCount: _filteredGroupedProducts.length,
      itemBuilder: (context, index) {
        final groupedProduct = _filteredGroupedProducts[index];
        return _buildShopProductCard(groupedProduct, desktop: true);
      },
    );
  }

  Widget _buildShopProductCard(GroupedProduct groupedProduct, {bool desktop = false}) {
    final product = groupedProduct.product;

    return Container(
      margin: desktop ? null : const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (_isMobile(context)) {
            _showProductProfile(groupedProduct);
          }
        },
        child: Padding(
          padding: desktop ? const EdgeInsets.all(20) : const EdgeInsets.all(14),
          child: SizedBox(
            height: desktop ? 320 : 240, // Increased height to accommodate warehouse info
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: desktop ? 120 : 70,
                    height: desktop ? 120 : 70,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _buildProductImageWithFallback(product, desktop),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  product.name.isEmpty ? 'Produit sans nom' : product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: desktop ? 18 : 15,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.category ?? 'Sans catégorie',
                  style: TextStyle(
                    fontSize: desktop ? 13 : 11,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Réf: ${product.referenceCode.isEmpty ? 'N/A' : product.referenceCode}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                // Warehouse information
                _buildWarehouseInfo(groupedProduct, desktop),
                const Spacer(),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.11),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${NumberFormat.currency(locale: 'fr', symbol: ' TND').format(product.unitPrice)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: groupedProduct.totalQuantity > 0
                            ? Colors.green.withOpacity(0.08)
                            : Colors.red.withOpacity(0.11),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        groupedProduct.totalQuantity > 0 ? 'IN STOCK' : 'ÉPUISÉ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: groupedProduct.totalQuantity > 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarehouseInfo(GroupedProduct groupedProduct, bool desktop) {
    if (groupedProduct.warehouseNames.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.store, size: 14, color: Colors.blueGrey[600]),
            const SizedBox(width: 4),
            Text(
              'Disponible dans:',
              style: TextStyle(
                fontSize: desktop ? 12 : 10,
                color: Colors.blueGrey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 2,
          children: groupedProduct.warehouseNames.map((warehouseName) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                warehouseName,
                style: TextStyle(
                  fontSize: desktop ? 10 : 9,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showProductProfile(GroupedProduct groupedProduct) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProductProfileModal(groupedProduct),
    );
  }

  Widget _buildProductProfileModal(GroupedProduct groupedProduct) {
    final product = groupedProduct.product;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      Center(
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: _buildProductImageWithFallback(product, true),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Product Name
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Category and Reference
                      Row(
                        children: [
                          Icon(Icons.category, size: 16, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            product.category ?? 'Sans catégorie',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Réf: ${product.referenceCode}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Price
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.monetization_on, color: Colors.green[700]),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prix unitaire',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(locale: 'fr', symbol: ' TND').format(product.unitPrice),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Stock Status
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: groupedProduct.totalQuantity > 0 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              groupedProduct.totalQuantity > 0 ? Icons.check_circle : Icons.cancel,
                              color: groupedProduct.totalQuantity > 0 ? Colors.green[700] : Colors.red[700],
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Statut du stock',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  groupedProduct.totalQuantity > 0 ? 'EN STOCK' : 'ÉPUISÉ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: groupedProduct.totalQuantity > 0 ? Colors.green[700] : Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Warehouse Details
                      const Text(
                        'Disponibilité par entrepôt',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      ...groupedProduct.stockEntries.map((stockEntry) {
                        final warehouseName = stockEntry.warehouse?['name'] ?? 'Entrepôt ${stockEntry.warehouseId}';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.store, color: Colors.blue[600]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  warehouseName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: stockEntry.quantity > 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  stockEntry.quantity > 0 ? 'Disponible' : 'Épuisé',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: stockEntry.quantity > 0 ? Colors.green[700] : Colors.red[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      if (product.description != null && product.description!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Add a method to try multiple URL variations
  Widget _buildProductImageWithFallback(dynamic product, bool desktop) {
    final hasValidImage = product.image != null && 
                         product.image!.isNotEmpty && 
                         product.image!.trim().isNotEmpty;

    if (!hasValidImage) {
      return _buildFallbackIcon(desktop, 'No image available');
    }

    final imagePath = product.image!.trim();
    
    // Check if the image path is already a full URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      if (_debugImages) {
      }
      return _buildImageWithMultipleUrls(product, desktop, [imagePath], 0);
    }
    
    // For relative paths, try different URL patterns in order of priority
    final urlsToTry = [
      'http://localhost:3000/uploads/$imagePath',              // Try uploads/ first
      'http://localhost:3000/uploads/products/$imagePath',     // Then uploads/products/
      'http://localhost:3000/images/$imagePath',               // Then images/
      'http://localhost:3000/$imagePath',                      // Finally root
    ];

    return _buildImageWithMultipleUrls(product, desktop, urlsToTry, 0);
  }

  Widget _buildImageWithMultipleUrls(dynamic product, bool desktop, List<String> urls, int currentIndex) {
    if (currentIndex >= urls.length) {
      return _buildFallbackIcon(desktop, 'All URLs failed');
    }

    final currentUrl = urls[currentIndex];
    
    if (_debugImages) {
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        currentUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            if (_debugImages) {
              print('✅ Successfully loaded: $currentUrl');
            }
            return child;
          }
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          if (_debugImages) {
          }
          
          // Try the next URL in the list
          return _buildImageWithMultipleUrls(product, desktop, urls, currentIndex + 1);
        },
      ),
    );
  }

  Widget _buildFallbackIcon(bool desktop, [String? message]) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag,
            color: Colors.green,
            size: desktop ? 40 : 28,
          ),
          if (desktop && message != null) ...[
            const SizedBox(height: 4),
            Text(
              message,
              style: TextStyle(
                fontSize: 9,
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
