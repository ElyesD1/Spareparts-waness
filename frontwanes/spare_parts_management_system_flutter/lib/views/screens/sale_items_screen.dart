import 'package:flutter/material.dart';
import '../../models/domain/sale_item.dart';
import '../../services/sale_item_service.dart';
import '../widgets/sidebar.dart';

class SaleItemsScreen extends StatefulWidget {
  @override
  _SaleItemsScreenState createState() => _SaleItemsScreenState();
}

class _SaleItemsScreenState extends State<SaleItemsScreen> with TickerProviderStateMixin {
  List<SaleItem> allItems = [];
  List<SaleItem> filteredItems = [];
  String searchQuery = '';
  bool isLoading = true;
  String? error;
  late AnimationController _animationController;

  // Pagination
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  // Period filter
  String _selectedPeriod = 'All';
  final List<String> _periods = ['All', 'Today', 'This Week', 'This Month', 'This Year'];

  // Responsive breakpoints
  bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  bool _isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
  bool _isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1200;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    fetchItems();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void fetchItems() async {
    setState(() { isLoading = true; error = null; });
    try {
      final items = await SaleItemService().getAllSaleItems();
      setState(() {
        allItems = items;
        applyFilters();
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() { error = e.toString(); isLoading = false; });
    }
  }

  DateTime? _getSaleDate(SaleItem item) {
    final sale = item.sale;
    final dateStr = sale != null ? (sale['sale_date'] ?? sale['created_at']) : null;
    if (dateStr != null) {
      try {
        return DateTime.parse(dateStr);
      } catch (_) {}
    }
    return null;
  }

  void applyFilters() {
    List<SaleItem> items = allItems;
    final now = DateTime.now();
    
    // Period filter
    if (_selectedPeriod != 'All') {
      items = items.where((item) {
        final saleDate = _getSaleDate(item);
        if (saleDate == null) return false;
        switch (_selectedPeriod) {
          case 'Today':
            return saleDate.year == now.year && saleDate.month == now.month && saleDate.day == now.day;
          case 'This Week':
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            return saleDate.isAfter(weekStart.subtract(const Duration(days: 1)));
          case 'This Month':
            return saleDate.year == now.year && saleDate.month == now.month;
          case 'This Year':
            return saleDate.year == now.year;
          default:
            return true;
        }
      }).toList();
    }
    
    // Search filter
    if (searchQuery.isNotEmpty) {
      items = items.where((item) {
        final name = item.product?.name ?? '';
        final idStr = item.id?.toString() ?? '';
        final productIdStr = item.productId?.toString() ?? '';
        return name.toLowerCase().contains(searchQuery.toLowerCase())
            || idStr.contains(searchQuery)
            || productIdStr.contains(searchQuery);
      }).toList();
    }
    
    setState(() {
      filteredItems = items;
      _currentPage = 1;
    });
  }

  List<SaleItem> get _groupedItems {
    final Map<String, SaleItem> grouped = {};
    
    for (final item in filteredItems) {
      final name = item.product?.name ?? '';
      if (name.isEmpty) continue;

      final unitPrice = (item.unitPrice != null && item.unitPrice! > 0)
          ? item.unitPrice!
          : (item.product?.unitPrice ?? 0.0);

      if (grouped.containsKey(name)) {
        final existing = grouped[name]!;
        grouped[name] = SaleItem(
          id: existing.id,
          productId: existing.productId,
          quantity: (existing.quantity ?? 0) + (item.quantity ?? 0),
          unitPrice: unitPrice,
          product: item.product,
          totalPrice: null,
        );
      } else {
        grouped[name] = SaleItem(
          id: item.id,
          productId: item.productId,
          quantity: item.quantity ?? 0,
          unitPrice: unitPrice,
          product: item.product,
          totalPrice: null,
        );
      }
    }

    return grouped.values.toList();
  }

  // Pagination helpers
  List<SaleItem> get _paginatedGroupedItems {
    final items = _groupedItems;
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (_currentPage * _itemsPerPage).clamp(0, items.length);
    return items.sublist(start, end);
  }

  int get _totalPages => (_groupedItems.length / _itemsPerPage).ceil().clamp(1, 999);

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  // Stats
  int get _totalSaleQuantity => _groupedItems.fold(0, (sum, item) => sum + (item.quantity ?? 0));
  double get _totalRevenue => _groupedItems.fold(0.0, (sum, item) => sum + (item.unitPrice ?? 0.0) * (item.quantity ?? 0));

  // Top 3 most sold items
  List<SaleItem> get _top3Items {
    final items = List<SaleItem>.from(_groupedItems);
    items.sort((a, b) => (b.quantity ?? 0).compareTo(a.quantity ?? 0));
    return items.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // ✅ DRAWER FOR MOBILE - SIDEBAR EXISTS HERE!
      drawer: _isMobile(context) ? Drawer(
        child: Sidebar(selected: SidebarSection.saleItems),
      ) : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_isMobile(context)) {
            return _buildMobileLayoutWithSidebar();
          } else {
            return _buildDesktopLayout();
          }
        },
      ),
    );
  }

  Widget _buildMobileLayoutWithSidebar() {
    return SafeArea(
      child: Column(
        children: [
          // Mobile Header WITH MENU BUTTON
          _buildMobileHeaderWithMenu(),
          
          // Content
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? _buildErrorState()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Stats Grid
                            _buildMobileStats(),
                            const SizedBox(height: 20),
                            
                            // Top 3 Items
                            if (_top3Items.isNotEmpty) ...[
                              _buildMobileTop3Items(),
                              const SizedBox(height: 20),
                            ],
                            
                            // Search Bar
                            _buildMobileSearchBar(),
                            const SizedBox(height: 16),
                            
                            // Filter Chips
                            _buildMobileFilterChips(),
                            const SizedBox(height: 20),
                            
                            // Items List
                            _buildMobileSaleItemsList(),
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
        // ✅ SIDEBAR - Always visible on desktop/tablet
        Sidebar(selected: SidebarSection.saleItems),
        
        // Main Content
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? _buildErrorState()
                  : AnimatedBuilder(
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
                        child: SingleChildScrollView(
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 1200),
                              margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Desktop Stats
                                  _buildDesktopStats(),
                                  const SizedBox(height: 32),
                                  
                                  // Top 3 Items
                                  _buildDesktopTop3Items(),
                                  
                                  // Desktop Content
                                  _buildDesktopContent(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildMobileHeaderWithMenu() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6C63FF), const Color(0xFF6C63FF).withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          // ✅ MENU BUTTON TO OPEN SIDEBAR DRAWER
          Builder(
            builder: (context) => Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                tooltip: 'Ouvrir le menu',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Articles Vendus',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Analyse des ventes par article',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStats() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildMobileStatCard(
          title: 'Quantité Totale',
          value: _totalSaleQuantity.toString(),
          icon: Icons.list_alt_outlined,
          color: const Color(0xFF6C63FF),
        ),
        _buildMobileStatCard(
          title: 'Produits Uniques',
          value: _groupedItems.length.toString(),
          icon: Icons.inventory_outlined,
          color: const Color(0xFF00C853),
        ),
        _buildMobileStatCard(
          title: 'Revenus Totaux',
          value: '${_totalRevenue.toStringAsFixed(0)} DNT',
          icon: Icons.attach_money_outlined,
          color: const Color(0xFF2196F3),
        ),
        _buildMobileStatCard(
          title: 'Articles',
          value: allItems.length.toString(),
          icon: Icons.shopping_bag_outlined,
          color: const Color(0xFFFF9800),
        ),
      ],
    );
  }

  Widget _buildMobileStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
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

  Widget _buildMobileTop3Items() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top 3 des Articles les Plus Vendus',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1B3C34),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: _top3Items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final medals = ['🥇', '🥈', '🥉'];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Text(
                    medals[index],
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product?.name ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Qté: ${item.quantity ?? 0}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${((item.unitPrice ?? 0) * (item.quantity ?? 0)).toStringAsFixed(0)} DNT',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF00C853),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMobileSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher des articles...',
          prefixIcon: Icon(Icons.search, color: const Color(0xFF6C63FF).withOpacity(0.7)),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[400]),
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                      applyFilters();
                    });
                  },
                )
              : null,
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onChanged: (val) {
          setState(() {
            searchQuery = val;
            applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildMobileFilterChips() {
    return Container(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _periods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final period = _periods[index];
          final frenchPeriods = ['Tout', 'Aujourd\'hui', 'Cette Semaine', 'Ce Mois', 'Cette Année'];
          final isSelected = _selectedPeriod == period;
          
          return FilterChip(
            selected: isSelected,
            label: Text(frenchPeriods[index]),
            onSelected: (selected) {
              setState(() {
                _selectedPeriod = selected ? period : 'All';
                applyFilters();
              });
            },
            backgroundColor: isSelected ? const Color(0xFF6C63FF).withOpacity(0.1) : Colors.white,
            selectedColor: const Color(0xFF6C63FF).withOpacity(0.1),
            labelStyle: TextStyle(
              color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
            checkmarkColor: const Color(0xFF6C63FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[300]!,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileSaleItemsList() {
    if (_groupedItems.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        ..._paginatedGroupedItems.map((item) => _buildMobileSaleItemCard(item)),
        if (_totalPages > 1) _buildMobilePagination(),
      ],
    );
  }

  Widget _buildMobileSaleItemCard(SaleItem item) {
    final totalPrice = (item.unitPrice ?? 0) * (item.quantity ?? 0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_bag, color: Color(0xFF6C63FF), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.product?.name ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B3C34),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Stats Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.confirmation_number, color: Color(0xFF6C63FF), size: 20),
                      const SizedBox(height: 4),
                      Text(
                        '${item.quantity ?? 0}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                      Text(
                        'Quantité',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.attach_money, color: Color(0xFF00C853), size: 20),
                      const SizedBox(height: 4),
                      Text(
                        '${(item.unitPrice ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00C853),
                        ),
                      ),
                      Text(
                        'Prix Unitaire',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.calculate, color: Color(0xFF2196F3), size: 20),
                      const SizedBox(height: 4),
                      Text(
                        '${totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                      Text(
                        'Total DNT',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePagination() {
    if (_totalPages <= 1) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
            color: _currentPage > 1 ? const Color(0xFF6C63FF) : Colors.grey[400],
          ),
          Text(
            '$_currentPage / $_totalPages',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          IconButton(
            onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
            color: _currentPage < _totalPages ? const Color(0xFF6C63FF) : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopStats() {
    return Row(
      children: [
        Expanded(
          child: _buildDesktopStatCard(
            title: 'Quantité Totale des Ventes',
            value: _totalSaleQuantity.toString(),
            icon: Icons.list_alt,
            color: const Color(0xFF6C63FF),
            subtitle: 'Somme de toutes les quantités',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDesktopStatCard(
            title: 'Produits Uniques',
            value: _groupedItems.length.toString(),
            icon: Icons.confirmation_number,
            color: const Color(0xFF00C853),
            subtitle: 'Nombre de produits',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDesktopStatCard(
            title: 'Revenus Totaux',
            value: '${_totalRevenue.toStringAsFixed(2)} DNT',
            icon: Icons.attach_money,
            color: const Color(0xFF2196F3),
            subtitle: 'Somme de tous les totaux',
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopTop3Items() {
    if (_top3Items.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 3 des Articles les Plus Vendus',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Color(0xFF1B3C34),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _top3Items.map((item) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product?.name ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1B3C34),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.confirmation_number, size: 16, color: Color(0xFF6C63FF)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Qté: ${item.quantity ?? 0}', 
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.attach_money, size: 16, color: Color(0xFF00C853)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${((item.unitPrice ?? 0) * (item.quantity ?? 0)).toStringAsFixed(2)} DNT', 
                            style: const TextStyle(fontSize: 14, color: Color(0xFF00C853)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Articles Vendus',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Color(0xFF1B3C34),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 260,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0EE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher des articles...',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                      onChanged: (val) {
                        setState(() {
                          searchQuery = val;
                          applyFilters();
                        });
                      },
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDesktopFilterBar(),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _groupedItems.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _paginatedGroupedItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE8F0EE)),
                      itemBuilder: (context, idx) {
                        final item = _paginatedGroupedItems[idx];
                        return _buildDesktopListItem(item);
                      },
                    ),
                    if (_totalPages > 1) _buildDesktopPagination(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildDesktopFilterBar() {
    final frenchPeriods = ['Tout', 'Aujourd\'hui', 'Cette Semaine', 'Ce Mois', 'Cette Année'];
    
    return Wrap(
      spacing: 8,
      children: _periods.asMap().entries.map((entry) {
        final index = entry.key;
        final period = entry.value;
        final isSelected = _selectedPeriod == period;
        
        return FilterChip(
          selected: isSelected,
          label: Text(frenchPeriods[index]),
          onSelected: (selected) {
            setState(() {
              _selectedPeriod = selected ? period : 'All';
              applyFilters();
            });
          },
          backgroundColor: isSelected ? const Color(0xFF6C63FF).withOpacity(0.1) : Colors.grey[100],
          selectedColor: const Color(0xFF6C63FF).withOpacity(0.1),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          checkmarkColor: const Color(0xFF6C63FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDesktopListItem(SaleItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_bag, color: Color(0xFF6C63FF)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.product?.name ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B3C34),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.confirmation_number, size: 16, color: Color(0xFF6C63FF)),
                      const SizedBox(width: 4),
                      Text(
                        'Qté: ${item.quantity}', 
                        style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.attach_money, size: 16, color: Color(0xFF00C853)),
                      const SizedBox(width: 4),
                      Text(
                        'Unit: ${(item.unitPrice ?? 0).toStringAsFixed(2)} DNT', 
                        style: const TextStyle(fontSize: 14, color: Color(0xFF00C853)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calculate, size: 16, color: Color(0xFF2196F3)),
                      const SizedBox(width: 4),
                      Text(
                        'Total: ${((item.unitPrice ?? 0) * (item.quantity ?? 0)).toStringAsFixed(2)} DNT', 
                        style: const TextStyle(fontSize: 14, color: Color(0xFF2196F3)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopPagination() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            color: _currentPage > 1 ? const Color(0xFF6C63FF) : Colors.grey[400],
          ),
          ...List.generate(_totalPages, (i) {
            final page = i + 1;
            final isActive = _currentPage == page;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _goToPage(page),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF6C63FF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive ? const Color(0xFF6C63FF) : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(
                      '$page',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
            color: _currentPage < _totalPages ? const Color(0xFF6C63FF) : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error!,
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchItems,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
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
                Icons.list_alt,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun article trouvé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez d\'ajuster votre recherche ou vos filtres de période',
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchItems,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}