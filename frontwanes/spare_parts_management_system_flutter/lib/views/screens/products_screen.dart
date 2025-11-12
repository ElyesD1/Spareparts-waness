import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/products_view_model.dart';
import '../widgets/sidebar.dart';
import '../../models/domain/product.dart';
import '../widgets/product_form.dart';
import '../../utils/responsive_helper.dart';
import '../widgets/product_details_modal.dart';
import '../widgets/app_toast.dart';

String getProductImageUrl(String? image) {
  if (image == null || image.isEmpty) {
    return '';
  }

  if (image.startsWith('http')) {
    return image;
  }

  String cleanImage = image.replaceAll(RegExp(r'^[/\\]+'), '');
  return 'http://localhost:3000/uploads/$cleanImage';
}

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductsViewModel>().loadProducts();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar:
          ResponsiveHelper.isMobile(context)
              ? AppBar(
                title: const Text(
                  'Produits',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: const Color(0xFF1E40AF),
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
              )
              : null,
      drawer:
          ResponsiveHelper.isMobile(context)
              ? Drawer(child: Sidebar(selected: SidebarSection.products))
              : null,
      floatingActionButton:
          ResponsiveHelper.isMobile(context) ? _buildMobileFAB() : null,
      body:
          ResponsiveHelper.isMobile(context)
              ? _buildMobileLayout()
              : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _openProductModal,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nouveau Produit',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Consumer<ProductsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMobileStats(viewModel),
                const SizedBox(height: 24),
                _buildMobileSearchBar(viewModel),
                const SizedBox(height: 24),
                _buildMobileProductsList(viewModel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Sidebar(selected: SidebarSection.products),
        Expanded(
          child: Consumer<ProductsViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              return AnimatedBuilder(
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
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDesktopHeader(),
                        const SizedBox(height: 32),
                        _buildDesktopStats(viewModel),
                        const SizedBox(height: 32),
                        _buildDesktopSearchAndActions(viewModel),
                        const SizedBox(height: 24),
                        _buildDesktopTable(viewModel),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestion des Produits',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gérez votre inventaire et optimisez vos stocks',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up, color: Colors.green.shade300, size: 20),
                const SizedBox(width: 8),
                Text(
                  '+12% ce mois',
                  style: TextStyle(
                    color: Colors.green.shade300,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStats(ProductsViewModel viewModel) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      padding: EdgeInsets.zero,
      children: [
        _buildStatCard(
          'Total',
          viewModel.totalProducts.toString(),
          Icons.inventory_2_rounded,
          const Color(0xFF3B82F6),
          const Color(0xFFEBF8FF),
        ),
        _buildStatCard(
          'Actifs',
          viewModel.activeProducts.toString(),
          Icons.check_circle_rounded,
          const Color(0xFF10B981),
          const Color(0xFFD1FAE5),
        ),
        _buildStatCard(
          'Catégories',
          viewModel.totalCategories.toString(),
          Icons.category_rounded,
          const Color(0xFFF59E0B),
          const Color(0xFFFEF3C7),
        ),
        _buildStatCard(
          'Marques',
          viewModel.totalBrands.toString(),
          Icons.branding_watermark_rounded,
          const Color(0xFF8B5CF6),
          const Color(0xFFF3E8FF),
        ),
      ],
    );
  }

  Widget _buildDesktopStats(ProductsViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Produits',
            viewModel.totalProducts.toString(),
            Icons.inventory_2_rounded,
            const Color(0xFF3B82F6),
            const Color(0xFFEBF8FF),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            'Produits Actifs',
            viewModel.activeProducts.toString(),
            Icons.check_circle_rounded,
            const Color(0xFF10B981),
            const Color(0xFFD1FAE5),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            'Catégories',
            viewModel.totalCategories.toString(),
            Icons.category_rounded,
            const Color(0xFFF59E0B),
            const Color(0xFFFEF3C7),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildStatCard(
            'Marques',
            viewModel.totalBrands.toString(),
            Icons.branding_watermark_rounded,
            const Color(0xFF8B5CF6),
            const Color(0xFFF3E8FF),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
  ) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: isMobile ? 20 : 24),
              ),
              const Spacer(),
              if (!isMobile) // Hide trend indicator on mobile to save space
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Colors.green.shade600,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+8%',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: isMobile ? 2 : 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSearchBar(ProductsViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher des produits...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onChanged: viewModel.searchProducts,
      ),
    );
  }

  Widget _buildDesktopSearchAndActions(ProductsViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher des produits...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey[400],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onChanged: viewModel.searchProducts,
              ),
            ),
          ),
          const SizedBox(width: 20),
          _buildAddButton(),
          const SizedBox(width: 12),
          _buildRefreshButton(viewModel),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _openProductModal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Nouveau Produit',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton(ProductsViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: viewModel.loadProducts,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(
              Icons.refresh_rounded,
              color: Colors.grey[600],
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileProductsList(ProductsViewModel viewModel) {
    if (viewModel.filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children:
          viewModel.paginatedProducts
              .map((product) => _buildMobileProductCard(product, viewModel))
              .toList(),
    );
  }

  Widget _buildDesktopTable(ProductsViewModel viewModel) {
    if (viewModel.filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Produit',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                      fontSize: 14,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Référence',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                      fontSize: 14,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Prix',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                      fontSize: 14,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Catégorie',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 120,
                  child: Text(
                    'Actions',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table Body
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: viewModel.paginatedProducts.length,
            separatorBuilder:
                (context, index) =>
                    Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              return _buildDesktopTableRow(
                viewModel.paginatedProducts[index],
                viewModel,
              );
            },
          ),
          // Pagination
          if (viewModel.totalPages > 1) _buildPagination(viewModel),
        ],
      ),
    );
  }

  Widget _buildMobileProductCard(Product product, ProductsViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    product.image != null && product.image!.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            getProductImageUrl(product.image),
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Icon(
                                  Icons.inventory_2_rounded,
                                  color: Colors.blue.shade600,
                                  size: 24,
                                ),
                          ),
                        )
                        : Icon(
                          Icons.inventory_2_rounded,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.referenceCode,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${product.unitPrice.toStringAsFixed(2)} TND',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (product.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product.getCategoryDisplayName(),
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                onSelected: (value) {
                  if (value == 'edit') {
                    _openProductModal(product: product);
                  } else if (value == 'delete') {
                    _deleteProduct(product, viewModel);
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Supprimer',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
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

  Widget _buildDesktopTableRow(Product product, ProductsViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Product Info
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      product.image != null && product.image!.isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              getProductImageUrl(product.image),
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => Icon(
                                    Icons.inventory_2_rounded,
                                    color: Colors.blue.shade600,
                                    size: 20,
                                  ),
                            ),
                          )
                          : Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (product.brand != null)
                        Text(
                          product.getBrandDisplayName(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Reference
          Expanded(
            flex: 1,
            child: Text(
              product.referenceCode,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          // Price
          Expanded(
            flex: 1,
            child: Text(
              '${product.unitPrice.toStringAsFixed(2)} TND',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          // Category
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.category != null
                    ? product.getCategoryDisplayName()
                    : 'Non catégorisé',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // Actions
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, size: 18),
                  onPressed: () => _showProductDetails(product),
                  tooltip: 'Détails',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _openProductModal(product: product),
                  tooltip: 'Modifier',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () => _deleteProduct(product, viewModel),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(ProductsViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Affichage ${(viewModel.currentPage - 1) * viewModel.productsPerPage + 1} à ${(viewModel.currentPage * viewModel.productsPerPage).clamp(0, viewModel.filteredProducts.length)} sur ${viewModel.filteredProducts.length} résultats',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Row(
            children: [
              IconButton(
                onPressed:
                    viewModel.currentPage > 1
                        ? () => viewModel.goToPage(viewModel.currentPage - 1)
                        : null,
                icon: const Icon(Icons.chevron_left),
              ),
              ...List.generate(
                (viewModel.totalPages > 5) ? 5 : viewModel.totalPages,
                (i) {
                  final page = i + 1;
                  return InkWell(
                    onTap: () => viewModel.goToPage(page),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            viewModel.currentPage == page
                                ? const Color(0xFF3B82F6)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$page',
                        style: TextStyle(
                          color:
                              viewModel.currentPage == page
                                  ? Colors.white
                                  : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                onPressed:
                    viewModel.currentPage < viewModel.totalPages
                        ? () => viewModel.goToPage(viewModel.currentPage + 1)
                        : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun produit trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par ajouter votre premier produit',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openProductModal,
              icon: const Icon(Icons.add),
              label: const Text('Créer le premier produit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProductModal({Product? product}) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: SingleChildScrollView(
              child: ProductForm(
                product: product,
                onSuccess: () {
                  context.read<ProductsViewModel>().loadProducts();
                },
              ),
            ),
          ),
    );
  }

  void _showProductDetails(Product product) {
    showDialog(
      context: context,
      builder:
          (context) => ProductDetailsModal(
            product: product,
            onEdit: () {
              Navigator.pop(context);
              _openProductModal(product: product);
            },
          ),
    );
  }

  Future<void> _deleteProduct(
    Product product,
    ProductsViewModel viewModel,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.warning, color: Colors.red.shade600),
                ),
                const SizedBox(width: 12),
                const Text('Supprimer le Produit'),
              ],
            ),
            content: Text(
              'Êtes-vous sûr de vouloir supprimer "${product.name}" ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await viewModel.deleteProduct(product.id!);
        if (mounted) {
          AppToast.success(context, 'Produit supprimé avec succès');
        }
      } catch (e) {
        if (mounted) {
          AppToast.error(context, 'Erreur lors de la suppression: $e');
        }
      }
    }
  }
}
