import 'package:flutter/material.dart';
import '../../services/sales_service.dart';
import '../../services/warehouse_service.dart';
import '../../services/sale_item_service.dart';
import '../../services/product_service.dart';
import '../../models/domain/sale_item.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_header.dart';
import '../widgets/sales_form.dart';
import '../widgets/sale_items_dialog.dart';
import '../widgets/responsive_screen.dart';
import '../../utils/responsive_helper.dart';
import 'package:intl/intl.dart';
import '../widgets/app_toast.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with TickerProviderStateMixin {
  final SalesService _salesService = SalesService();
  final WarehouseService _warehouseService = WarehouseService();
  final SaleItemService _saleItemService = SaleItemService();
  final ProductService _productService = ProductService();
  List<Map<String, dynamic>> _sales = [];
  List<Map<String, dynamic>> _filteredSales = [];
  List<Map<String, dynamic>> _warehouses = [];
  bool _loading = true;
  String _search = '';
  int _currentPage = 1;
  static const int _salesPerPage = 10;
  String _selectedPeriod = 'Tout';
  late AnimationController _animationController;

  // Responsive breakpoints

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fetchData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final futures = await Future.wait([
        _salesService.getSales(),
        _warehouseService.getWarehouses(),
      ]);
      
      setState(() {
        _sales = futures[0];
        _filteredSales = futures[0];
        _warehouses = futures[1];
        _loading = false;
        _currentPage = 1;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        AppToast.error(context, 'Erreur de chargement: $e');
      }
    }
  }

  Future<void> _fetchSales() async {
    setState(() => _loading = true);
    try {
      final sales = await _salesService.getSales();
      setState(() {
        _sales = sales;
        _filteredSales = sales;
        _loading = false;
        _currentPage = 1;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        AppToast.error(context, 'Erreur de chargement des ventes: $e');
      }
    }
  }

  void _onSearch(String value) {
    setState(() {
      _search = value;
      _filterSales();
    });
  }

  void _filterSales() {
    setState(() {
      final now = DateTime.now();
      final filteredByPeriod = _sales.where((s) {
        if (_selectedPeriod == 'Tout') return true;
        
        final saleDate = DateTime.tryParse(s['sale_date'] ?? '');
        if (saleDate == null) return false;

        switch (_selectedPeriod) {
          case 'Aujourd\'hui':
            return saleDate.year == now.year && 
                   saleDate.month == now.month && 
                   saleDate.day == now.day;
          case 'Cette Semaine':
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            return saleDate.isAfter(weekStart.subtract(const Duration(days: 1)));
          case 'Ce Mois':
            return saleDate.year == now.year && saleDate.month == now.month;
          case 'Cette Année':
            return saleDate.year == now.year;
          default:
            return true;
        }
      }).toList();

      _filteredSales = filteredByPeriod.where((s) =>
        (s['customer_name'] ?? '').toString().toLowerCase().contains(_search.toLowerCase()) ||
        (s['sale_date'] ?? '').toString().toLowerCase().contains(_search.toLowerCase()) ||
        (s['total_amount'] ?? '').toString().toLowerCase().contains(_search.toLowerCase())
      ).toList();
      
      _currentPage = 1;
    });
  }

  List<Map<String, dynamic>> get _paginatedSales {
    final start = (_currentPage - 1) * _salesPerPage;
    final end = (_currentPage * _salesPerPage).clamp(0, _filteredSales.length);
    return _filteredSales.sublist(start, end);
  }

  int get _totalPages => (_filteredSales.length / _salesPerPage).ceil().clamp(1, 999);

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00 DNT';
    try {
      final numAmount = double.parse(amount.toString());
      return '${numAmount.toStringAsFixed(2)} DNT';
    } catch (e) {
      return '0.00 DNT';
    }
  }

  String _getWarehouseName(int? warehouseId) {
    if (warehouseId == null) return 'Aucun entrepôt';
    final warehouse = _warehouses.firstWhere(
      (w) => w['id']?.toString() == warehouseId.toString(),
      orElse: () => {'name': 'Entrepôt inconnu'},
    );
    return warehouse['name'] ?? 'Entrepôt $warehouseId';
  }

  Future<double> _calculateTotalProfit() async {
    double totalProfit = 0;
    Map<String, double> productSupplierPrices = {};
    
    for (final sale in _sales) {
      try {
        final saleId = sale['id'];
        if (saleId != null) {
          final saleItems = await _saleItemService.getSaleItems(saleId);
          
          for (final item in saleItems) {
            double unitPrice = item.unitPrice ?? 0;
            final quantity = item.quantity ?? 0;
            double supplierPrice = 0;
            
            if (unitPrice <= 0 && item.product?.unitPrice != null) {
              unitPrice = item.product!.unitPrice;
            }
            
            if (item.product?.supplierPrice != null) {
              supplierPrice = item.product!.supplierPrice!;
            } else if (item.productId != null) {
              if (productSupplierPrices.containsKey(item.productId)) {
                supplierPrice = productSupplierPrices[item.productId]!;
              } else {
                try {
                  if (productSupplierPrices.isEmpty) {
                    final products = await _productService.getProducts();
                    for (final product in products) {
                      if (product.id != null && product.supplierPrice != null) {
                        productSupplierPrices[product.id!] = product.supplierPrice!;
                      }
                    }
                  }
                  
                  supplierPrice = productSupplierPrices[item.productId] ?? 0;
                } catch (e) {
                  supplierPrice = 0;
                }
              }
            }
            
            if (unitPrice > 0 && quantity > 0) {
              final itemProfit = (unitPrice - supplierPrice) * quantity;
              totalProfit += itemProfit;
            }
          }
        }
      } catch (e) {
        // Continue with other sales even if one fails
      }
    }
    
    return totalProfit;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return ResponsiveScreen(
      selectedSidebarSection: SidebarSection.sales,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        floatingActionButton: isMobile ? FloatingActionButton(
          heroTag: "sales_fab",
          onPressed: () => _showSalesForm(),
          backgroundColor: const Color(0xFF6C63FF),
          child: const Icon(Icons.add, color: Colors.white),
        ) : null,
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (isMobile) {
              return _buildMobileLayout();
            } else {
              return _buildDesktopLayoutContent();
            }
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayoutContent() {
  return AnimatedBuilder(
    animation: _animationController,
    builder: (context, child) {
      return Transform.translate(
        offset: Offset(0, 20 * (1 - _animationController.value)),
        child: Opacity(
          opacity: _animationController.value,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildDesktopHeader(),
                Expanded(
                  child: _buildDesktopContent(),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stats Row
            _buildMobileStats(),
            const SizedBox(height: 20),
            
            // Search and Filters
            _buildMobileSearchAndFilters(),
            const SizedBox(height: 20),
            
            // Sales List
            _buildMobileSalesList(),
          ],
        ),
      ),
    );
  }


  Widget _buildMobileStats() {
    final totalSales = _sales.length;
    double totalRevenue = 0;
    final now = DateTime.now();
    final currentPeriodStart = now.subtract(const Duration(days: 30));
    
    for (final sale in _sales) {
      final amount = double.tryParse(sale['total_amount'].toString()) ?? 0;
      final date = DateTime.tryParse(sale['sale_date'] ?? '');
      if (date != null && date.isAfter(currentPeriodStart)) {
        totalRevenue += amount;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildMobileStatCard(
            'Ventes',
            totalSales.toString(),
            Icons.shopping_cart_outlined,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMobileStatCard(
            'Revenus',
            '${totalRevenue.toStringAsFixed(0)} DNT',
            Icons.trending_up_outlined,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FutureBuilder<double>(
            future: _calculateTotalProfit(),
            builder: (context, snapshot) {
              final profit = snapshot.data ?? 0.0;
              return _buildMobileStatCard(
                'Profit',
                '${profit.toStringAsFixed(0)} DNT',
                Icons.monetization_on_outlined,
                Colors.purple,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSearchAndFilters() {
    final periods = ['Tout', 'Aujourd\'hui', 'Cette Semaine', 'Ce Mois', 'Cette Année'];
    
    return Column(
      children: [
        // Search Bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Rechercher des ventes...',
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
          onChanged: _onSearch,
        ),
        const SizedBox(height: 12),
        
        // Period Filters
        Container(
          height: 45,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: periods.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final period = periods[index];
              return _buildPeriodChip(period);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(String period) {
    final isSelected = _selectedPeriod == period;
    return FilterChip(
      selected: isSelected,
      label: Text(period),
      onSelected: (selected) {
        setState(() {
          _selectedPeriod = selected ? period : 'Tout';
          _filterSales();
        });
      },
      backgroundColor: isSelected ? Colors.indigo.withOpacity(0.1) : Colors.white,
      selectedColor: Colors.indigo.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.indigo : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      checkmarkColor: Colors.indigo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.indigo : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildMobileSalesList() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredSales.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        ...(_paginatedSales.map((sale) => _buildMobileSaleCard(sale))),
        if (_totalPages > 1) _buildMobilePagination(),
      ],
    );
  }

  Widget _buildMobileSaleCard(Map<String, dynamic> sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: Colors.indigo, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  sale['customer_name'] ?? 'Client inconnu',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatAmount(sale['total_amount']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Info Rows
          _buildMobileInfoRow(
            Icons.calendar_today,
            'Date',
            _formatDate(sale['sale_date']),
          ),
          const SizedBox(height: 8),
          
          _buildMobileInfoRow(
            Icons.warehouse,
            'Entrepôt',
            _getWarehouseName(sale['warehouse']?['id']),
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showSaleDetails(sale),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Détails'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showSalesForm(sale: sale),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Modifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _deleteSale(sale),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Supprimer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobilePagination() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('$_currentPage / $_totalPages'),
          IconButton(
            onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
            icon: const Icon(Icons.chevron_right),
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
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.point_of_sale, color: Colors.indigo, size: 28),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestion des Ventes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                'Suivi et gestion des transactions de vente',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          const AppHeader(),
        ],
      ),
    );
  }

  Widget _buildDesktopContent() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            // Header
            _buildDesktopContentHeader(),
            
            // Content
            Expanded(
              child: _loading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _buildDesktopSalesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopContentHeader() {
    final periods = ['Tout', 'Aujourd\'hui', 'Cette Semaine', 'Ce Mois', 'Cette Année'];
    
    return Container(
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
            'Ventes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 16),
          
          // Period Filters
          Wrap(
            spacing: 8,
            children: periods.map((p) => _buildPeriodChip(p)).toList(),
          ),
          
          const Spacer(),
          
          // Search Bar
          Container(
            width: 250,
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: _onSearch,
            ),
          ),
          const SizedBox(width: 16),
          
          // Add Button
          ElevatedButton.icon(
            onPressed: _showSalesForm,
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle Vente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopSalesList() {
    if (_filteredSales.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            children: [
              const Expanded(flex: 2, child: Text('Client', style: TextStyle(fontWeight: FontWeight.bold))),
              const Expanded(flex: 1, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
              const Expanded(flex: 1, child: Text('Entrepôt', style: TextStyle(fontWeight: FontWeight.bold))),
              const Expanded(flex: 1, child: Text('Montant', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(width: 120, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        
        // Table Body - Use Expanded ListView
        Expanded(
          child: ListView.separated(
            itemCount: _paginatedSales.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              return _buildDesktopSaleRow(_paginatedSales[index]);
            },
          ),
        ),
        
        // Pagination
        if (_totalPages > 1) _buildDesktopPagination(),
      ],
    );
  }

  Widget _buildDesktopSaleRow(Map<String, dynamic> sale) {
    return InkWell(
      onTap: () => _showSaleDetails(sale),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Customer
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.person, color: Colors.indigo, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      sale['customer_name'] ?? 'Client inconnu',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Date
            Expanded(
              flex: 1,
              child: Text(
                _formatDate(sale['sale_date']),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Warehouse
            Expanded(
              flex: 1,
              child: Text(
                _getWarehouseName(sale['warehouse']?['id']),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Amount
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatAmount(sale['total_amount']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
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
                    onPressed: () => _showSaleDetails(sale),
                    tooltip: 'Détails',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _showSalesForm(sale: sale),
                    tooltip: 'Modifier',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: () => _deleteSale(sale),
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopPagination() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Affichage ${(_currentPage - 1) * _salesPerPage + 1} à ${(_currentPage * _salesPerPage).clamp(0, _filteredSales.length)} sur ${_filteredSales.length} résultats',
          ),
          Row(
            children: [
              IconButton(
                onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              ...List.generate(
                (_totalPages > 5) ? 5 : _totalPages,
                (i) {
                  final page = i + 1;
                  return InkWell(
                    onTap: () => _goToPage(page),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _currentPage == page ? Colors.indigo : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$page',
                        style: TextStyle(
                          color: _currentPage == page ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
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
                Icons.point_of_sale_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune vente trouvée',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez d\'ajuster vos filtres de recherche ou période',
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showSalesForm,
              icon: const Icon(Icons.add),
              label: const Text('Créer la première vente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSalesForm({Map<String, dynamic>? sale}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          child: SalesForm(
            sale: sale,
            onSuccess: _fetchSales,
          ),
        ),
      ),
    );
  }

  void _showSaleDetails(Map<String, dynamic> sale) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<SaleItem>>(
          future: SaleItemService().getSaleItems(sale['id']),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Dialog(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Chargement des détails...'),
                    ],
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Erreur'),
                content: Text('Échec du chargement: ${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              );
            }
            final items = snapshot.data ?? [];
            return SaleItemsDialog(
              sale: sale,
              items: items,
            );
          },
        );
      },
    );
  }

  Future<void> _deleteSale(Map<String, dynamic> sale) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la vente'),
        content: Text('Êtes-vous sûr de vouloir supprimer la vente de "${sale['customer_name']}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _salesService.deleteSale(sale['id']);
        _fetchSales();
        if (mounted) {
          AppToast.success(context, 'Vente supprimée avec succès');
        }
      } catch (e) {
        if (mounted) {
          AppToast.error(context, 'Erreur lors de la suppression: $e');
        }
      }
    }
  }
}
