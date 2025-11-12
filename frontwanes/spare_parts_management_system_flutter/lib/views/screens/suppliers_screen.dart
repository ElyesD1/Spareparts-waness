import 'package:flutter/material.dart';
import '../../services/supplier_service.dart';
import '../widgets/sidebar.dart';
import '../widgets/supplier_form.dart';
import '../widgets/app_toast.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({Key? key}) : super(key: key);

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final SupplierService _supplierService = SupplierService();
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _filteredSuppliers = [];
  bool _loading = true;
  String _search = '';
  int _currentPage = 1;
  static const int _suppliersPerPage = 10;
  String _selectedCategory = 'All';

  // Responsive breakpoints
  bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  bool _isTablet(BuildContext context) => MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
  bool _isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1200;

  @override
  void initState() {
    super.initState();
    _fetchSuppliers();
  }

  Future<void> _fetchSuppliers() async {
    setState(() => _loading = true);
    try {
      final suppliers = await _supplierService.getSuppliers();
      setState(() {
        _suppliers = suppliers;
        _filteredSuppliers = suppliers;
        _loading = false;
        _currentPage = 1;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        AppToast.error(context, 'Erreur de chargement: $e');
      }
    }
  }

  void _onSearch(String value) {
    setState(() {
      _search = value;
      _filterSuppliers();
    });
  }

  void _filterSuppliers() {
    setState(() {
      _filteredSuppliers = _suppliers.where((s) {
        final matchesSearch = (s['name'] ?? '').toString().toLowerCase().contains(_search.toLowerCase()) ||
            (s['contact_info'] ?? '').toString().toLowerCase().contains(_search.toLowerCase()) ||
            (s['address'] ?? '').toString().toLowerCase().contains(_search.toLowerCase());
        
        if (_selectedCategory == 'All') return matchesSearch;
        return matchesSearch && (s['category'] ?? 'Other') == _selectedCategory;
      }).toList();
      _currentPage = 1;
    });
  }

  List<Map<String, dynamic>> get _paginatedSuppliers {
    final start = (_currentPage - 1) * _suppliersPerPage;
    final end = (_currentPage * _suppliersPerPage).clamp(0, _filteredSuppliers.length);
    return _filteredSuppliers.sublist(start, end);
  }

  int get _totalPages => (_filteredSuppliers.length / _suppliersPerPage).ceil().clamp(1, 999);

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // ✅ DRAWER FOR MOBILE - SIDEBAR
      drawer: _isMobile(context) ? Drawer(
        child: Sidebar(selected: SidebarSection.suppliers),
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
    final categories = ['All', 'Parts', 'Tools', 'Equipment', 'Services', 'Other'];
    final totalActive = _suppliers.where((s) => s['status'] == 'Active').length;
    final totalInactive = _suppliers.length - totalActive;

    return SafeArea(
      child: Column(
        children: [
          // Mobile Header WITH MENU BUTTON
          _buildMobileHeaderWithMenu(),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Mobile Stats Grid
                    _buildMobileStatsGrid(totalActive, totalInactive),
                    const SizedBox(height: 20),
                    
                    // Search Bar
                    _buildMobileSearchBar(),
                    const SizedBox(height: 16),
                    
                    // Category Chips
                    _buildCategoryChips(categories),
                    const SizedBox(height: 20),
                    
                    // Suppliers List
                    _buildSuppliersCard(isMobile: true),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final categories = ['All', 'Parts', 'Tools', 'Equipment', 'Services', 'Other'];
    final totalActive = _suppliers.where((s) => s['status'] == 'Active').length;
    final totalInactive = _suppliers.length - totalActive;

    return Row(
      children: [
        Sidebar(selected: SidebarSection.suppliers),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1400),
                margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Desktop Stats Row
                    _buildDesktopStatsRow(totalActive, totalInactive),
                    const SizedBox(height: 32),
                    
                    // Main Content Card
                    _buildSuppliersCard(isMobile: false, categories: categories),
                  ],
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
          colors: [Colors.deepPurple, Colors.deepPurple.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
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
                  'Fournisseurs',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Gestion des fournisseurs',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          FloatingActionButton(
            onPressed: () => _showSupplierForm(),
            backgroundColor: Colors.white,
            foregroundColor: Colors.deepPurple,
            elevation: 2,
            mini: true,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStatsGrid(int totalActive, int totalInactive) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildMobileStatCard(
          title: 'Total',
          value: _suppliers.length.toString(),
          subtitle: '$totalActive actifs',
          icon: Icons.business_outlined,
          color: const Color(0xFF6C63FF),
        ),
        _buildMobileStatCard(
          title: 'Lieux',
          value: _suppliers.map((s) => s['address']).toSet().length.toString(),
          subtitle: 'Localisations',
          icon: Icons.location_on_outlined,
          color: const Color(0xFF00C853),
        ),
        _buildMobileStatCard(
          title: 'Catégories',
          value: _suppliers.map((s) => s['category'] ?? 'Other').toSet().length.toString(),
          subtitle: 'Types différents',
          icon: Icons.category_outlined,
          color: const Color(0xFF2196F3),
        ),
        _buildMobileStatCard(
          title: 'Actifs',
          value: totalActive.toString(),
          subtitle: '${_suppliers.length > 0 ? ((totalActive / _suppliers.length) * 100).toInt() : 0}% du total',
          icon: Icons.check_circle_outlined,
          color: const Color(0xFF4CAF50),
        ),
      ],
    );
  }

  Widget _buildMobileStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher des fournisseurs...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        onChanged: _onSearch,
      ),
    );
  }

  Widget _buildCategoryChips(List<String> categories) {
    return Container(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return FilterChip(
            selected: isSelected,
            label: Text(category),
            onSelected: (selected) {
              setState(() {
                _selectedCategory = selected ? category : 'All';
                _filterSuppliers();
              });
            },
            backgroundColor: isSelected ? const Color(0xFF6C63FF).withOpacity(0.1) : Colors.white,
            selectedColor: const Color(0xFF6C63FF).withOpacity(0.1),
            labelStyle: TextStyle(
              color: isSelected ? const Color(0xFF6C63FF) : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildDesktopStatsRow(int totalActive, int totalInactive) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard(
                    title: 'Total Fournisseurs',
                    value: _suppliers.length.toString(),
                    subtitle: '$totalActive Actifs • $totalInactive Inactifs',
                    icon: Icons.business,
                    color: const Color(0xFF6C63FF),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard(
                    title: 'Localisations',
                    value: _suppliers.map((s) => s['address']).toSet().length.toString(),
                    subtitle: 'Lieux uniques des fournisseurs',
                    icon: Icons.location_on,
                    color: const Color(0xFF00C853),
                  )),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatCard(
                    title: 'Catégories',
                    value: _suppliers.map((s) => s['category'] ?? 'Other').toSet().length.toString(),
                    subtitle: 'Types différents de fournisseurs',
                    icon: Icons.category,
                    color: const Color(0xFF2196F3),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: Container()),
                ],
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(child: _buildStatCard(
                title: 'Total Fournisseurs',
                value: _suppliers.length.toString(),
                subtitle: '$totalActive Actifs • $totalInactive Inactifs',
                icon: Icons.business,
                color: const Color(0xFF6C63FF),
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(
                title: 'Localisations',
                value: _suppliers.map((s) => s['address']).toSet().length.toString(),
                subtitle: 'Lieux uniques des fournisseurs',
                icon: Icons.location_on,
                color: const Color(0xFF00C853),
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(
                title: 'Catégories',
                value: _suppliers.map((s) => s['category'] ?? 'Other').toSet().length.toString(),
                subtitle: 'Types différents de fournisseurs',
                icon: Icons.category,
                color: const Color(0xFF2196F3),
              )),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      '+5.2%',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
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
              color: Colors.grey[800],
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuppliersCard({required bool isMobile, List<String>? categories}) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) _buildDesktopHeader(categories!),
          _loading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _filteredSuppliers.isEmpty
                  ? _buildEmptyState()
                  : isMobile
                      ? _buildMobileSuppliersList()
                      : _buildDesktopSuppliersList(),
          if (!_loading && _filteredSuppliers.isNotEmpty) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(List<String> categories) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fournisseurs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Color(0xFF1B3C34),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((c) => _buildCategoryChip(c)).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 300,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher des fournisseurs...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: _onSearch,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _showSupplierForm,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      selected: isSelected,
      label: Text(category),
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : 'All';
          _filterSuppliers();
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
  }

  Widget _buildMobileSuppliersList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _paginatedSuppliers.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE0E0E0)),
      itemBuilder: (context, i) {
        final s = _paginatedSuppliers[i];
        final category = s['category'] ?? 'Other';
        final isActive = s['status'] == 'Active';
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _showSupplierDetails(s),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.business, color: Color(0xFF6C63FF), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B3C34),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6C63FF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isActive ? const Color(0xFF00C853) : Colors.grey).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isActive ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive ? const Color(0xFF00C853) : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          s['contact_info'] ?? '',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          s['address'] ?? '',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF6C63FF), size: 20),
                        onPressed: () => _showSupplierForm(supplier: s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Color(0xFFF44336), size: 20),
                        onPressed: () => _deleteSupplier(s),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopSuppliersList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _paginatedSuppliers.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE8F0EE)),
      itemBuilder: (context, i) {
        final s = _paginatedSuppliers[i];
        final category = s['category'] ?? 'Other';
        final isActive = s['status'] == 'Active';
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showSupplierDetails(s),
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
                    child: const Icon(Icons.business, color: Color(0xFF6C63FF)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              s['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B3C34),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6C63FF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 16, color: Color(0xFF6C63FF)),
                            const SizedBox(width: 4),
                            Text(
                              s['contact_info'] ?? '',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                            ),
                            const SizedBox(width: 16),
                            const Icon(Icons.location_on, size: 16, color: Color(0xFF6C63FF)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                s['address'] ?? '',
                                style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (isActive ? const Color(0xFF00C853) : Colors.grey).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF00C853) : Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isActive ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            fontSize: 14,
                            color: isActive ? const Color(0xFF00C853) : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF6C63FF)),
                        tooltip: 'Modifier',
                        onPressed: () => _showSupplierForm(supplier: s),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Color(0xFFF44336)),
                        tooltip: 'Supprimer',
                        onPressed: () => _deleteSupplier(s),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.business_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun fournisseur trouvé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez d\'ajuster vos filtres de recherche ou de catégorie',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showSupplierForm,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter le premier fournisseur'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE8F0EE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            color: _currentPage > 1 ? const Color(0xFF6C63FF) : Colors.grey[400],
          ),
          ...List.generate(
            _totalPages > 7 ? 7 : _totalPages,
            (i) {
              int page;
              if (_totalPages <= 7) {
                page = i + 1;
              } else if (_currentPage <= 4) {
                page = i + 1;
              } else if (_currentPage >= _totalPages - 3) {
                page = _totalPages - 6 + i;
              } else {
                page = _currentPage - 3 + i;
              }
              
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
            },
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
            color: _currentPage < _totalPages ? const Color(0xFF6C63FF) : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  void _showSupplierForm({Map<String, dynamic>? supplier}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          child: SupplierForm(
            supplier: supplier,
            onSuccess: _fetchSuppliers,
          ),
        ),
      ),
    );
  }

  void _showSupplierDetails(Map<String, dynamic> supplier) {
    // Implement supplier details view
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(supplier['name'] ?? 'Fournisseur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Catégorie: ${supplier['category'] ?? 'N/A'}'),
            Text('Contact: ${supplier['contact_info'] ?? 'N/A'}'),
            Text('Adresse: ${supplier['address'] ?? 'N/A'}'),
            Text('Statut: ${supplier['status'] ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSupplier(Map<String, dynamic> supplier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le fournisseur'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${supplier['name']}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Color(0xFFF44336))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supplierService.deleteSupplier(supplier['id']);
        _fetchSuppliers();
        if (mounted) {
          AppToast.success(context, 'Fournisseur supprimé avec succès');
        }
      } catch (e) {
        if (mounted) {
          AppToast.error(context, 'Erreur lors de la suppression: $e');
        }
      }
    }
  }
}