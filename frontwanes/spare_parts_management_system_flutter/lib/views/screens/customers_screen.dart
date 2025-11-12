import 'package:flutter/material.dart';
import '../../services/customers_service.dart';
import '../../models/domain/customer.dart';
import '../widgets/sidebar.dart';
import '../widgets/responsive_profile_button.dart';
import '../widgets/app_header.dart';
import '../widgets/customer_form.dart';
import '../widgets/app_toast.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({Key? key}) : super(key: key);

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> with TickerProviderStateMixin {
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  bool _loading = true;
  String _search = '';
  int _currentPage = 1;
  static const int _customersPerPage = 10;
  String _selectedStatus = 'All'; // All, Active, Inactive
  late AnimationController _animationController;

  // Responsive breakpoints
  bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fetchCustomers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _loading = true);
    try {
      final customers = await CustomersService.getCustomers();
      setState(() {
        _customers = customers;
        _filteredCustomers = customers;
        _loading = false;
        _currentPage = 1;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _loading = false);
      AppToast.error(context, 'Échec du chargement des clients: $e');
    }
  }

  void _onSearch(String value) {
    setState(() {
      _search = value;
      _filterCustomers();
    });
  }

  void _filterCustomers() {
    setState(() {
      _filteredCustomers = _customers.where((c) {
        final matchesSearch = (c.name).toLowerCase().contains(_search.toLowerCase()) ||
            (c.phoneNumber).toLowerCase().contains(_search.toLowerCase()) ||
            (c.email).toLowerCase().contains(_search.toLowerCase()) ||
            (c.address ?? '').toLowerCase().contains(_search.toLowerCase());

        if (_selectedStatus == 'All') return matchesSearch;
        final isActive = _selectedStatus == 'Active';
        return matchesSearch && c.isActive == isActive;
      }).toList();
      _currentPage = 1;
    });
  }

  List<Customer> get _paginatedCustomers {
    final start = (_currentPage - 1) * _customersPerPage;
    final end = (_currentPage * _customersPerPage).clamp(0, _filteredCustomers.length);
    return _filteredCustomers.sublist(start, end);
  }

  int get _totalPages => (_filteredCustomers.length / _customersPerPage).ceil().clamp(1, 999);

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // ✅ DRAWER FOR MOBILE - SIDEBAR EXISTS HERE!
      drawer: _isMobile(context) ? Drawer(
        child: Sidebar(selected: SidebarSection.customers),
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
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Stats Grid
                        _buildMobileStats(),
                        const SizedBox(height: 20),
                        
                        // Search and Filters
                        _buildMobileSearchAndFilters(),
                        const SizedBox(height: 20),
                        
                        // Customers List
                        _buildMobileCustomersList(),
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
        Sidebar(selected: SidebarSection.customers),
        
        // Main Content
        Expanded(
          child: Column(
            children: [
              // Desktop Header
              _buildDesktopHeader(),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
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
                                margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Desktop Stats
                                    _buildDesktopStats(),
                                    const SizedBox(height: 32),
                                    
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
          ),
        ),
      ],
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
          const Text(
            'Gestion des Clients',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          AppHeader(isMobile: false),
        ],
      ),
    );
  }

  Widget _buildMobileHeaderWithMenu() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6C63FF), const Color(0xFFB3B0FF)],
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
                  'Clients',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Gestion des clients',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => _showCustomerForm(),
              icon: const Icon(Icons.add, color: Colors.white, size: 24),
              tooltip: 'Ajouter client',
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
    );
  }

  Widget _buildMobileStats() {
    final totalActive = _customers.where((c) => c.isActive).length;
    final totalBalance = _customers.fold<double>(0.0, (sum, c) => sum + c.currentBalance);
    final companiesCount = _customers.map((c) => c.companyName ?? '').where((c) => c.isNotEmpty).toSet().length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildMobileStatCard(
          'Total',
          _customers.length.toString(),
          Icons.people_outlined,
          const Color(0xFF6C63FF),
        ),
        _buildMobileStatCard(
          'Actifs',
          totalActive.toString(),
          Icons.verified_user_outlined,
          const Color(0xFF00C853),
        ),
        _buildMobileStatCard(
          'Solde',
          '${totalBalance.toStringAsFixed(0)} DNT',
          Icons.account_balance_wallet_outlined,
          const Color(0xFF2196F3),
        ),
        _buildMobileStatCard(
          'Entreprises',
          companiesCount.toString(),
          Icons.business_outlined,
          const Color(0xFFFF9800),
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

  Widget _buildMobileSearchAndFilters() {
    return Column(
      children: [
        // Search Bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
              hintText: 'Rechercher des clients...',
              prefixIcon: Icon(Icons.search, color: Color(0xFFB3B0FF)),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[400]),
                      onPressed: () {
                        setState(() {
                          _search = '';
                          _filterCustomers();
                        });
                      },
                    )
                  : null,
              filled: false,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: _onSearch,
          ),
        ),
        const SizedBox(height: 16),
        
        // Status Filters
        Row(
          children: [
            Text(
              'Statut: ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Expanded(
              child: Wrap(
                spacing: 8,
                children: ['Tous', 'Actifs', 'Inactifs'].asMap().entries.map((entry) {
                  final index = entry.key;
                  final status = entry.value;
                  final englishStatus = ['All', 'Active', 'Inactive'][index];
                  return _buildMobileStatusChip(status, englishStatus);
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileStatusChip(String displayText, String value) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      selected: isSelected,
      label: Text(displayText),
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? value : 'All';
          _filterCustomers();
        });
      },
      backgroundColor: isSelected ? const Color(0xFF6C63FF).withOpacity(0.1) : Colors.grey[100],
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
          color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildMobileCustomersList() {
    if (_filteredCustomers.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        ..._paginatedCustomers.map((customer) => _buildMobileCustomerCard(customer)),
        if (_totalPages > 1) _buildMobilePagination(),
      ],
    );
  }

  Widget _buildMobileCustomerCard(Customer customer) {
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
                child: const Icon(Icons.person, color: Color(0xFF6C63FF), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B3C34),
                      ),
                    ),
                    if ((customer.companyName ?? '').isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          customer.companyName!,
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
              _buildStatusBadge(customer.isActive),
            ],
          ),
          const SizedBox(height: 16),
          
          // Info Rows
          _buildMobileInfoRow(Icons.phone_outlined, 'Téléphone', customer.phoneNumber),
          if (customer.email.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildMobileInfoRow(Icons.email_outlined, 'Email', customer.email),
          ],
          if ((customer.address ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildMobileInfoRow(Icons.location_on_outlined, 'Adresse', customer.address!),
          ],
          const SizedBox(height: 12),
          _buildMobileInfoRow(
            Icons.account_balance_wallet_outlined,
            'Solde actuel',
            '${customer.currentBalance.toStringAsFixed(2)} DNT',
          ),
          _buildMobileInfoRow(Icons.person_outline, 'CIN', customer.cin?.toString() ?? ''),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCustomerDetails(customer),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Détails'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Color(0xFFB3B0FF)),
                    foregroundColor: const Color(0xFF6C63FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showCustomerForm(customer),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Modifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF6C63FF)),
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
    final totalActive = _customers.where((c) => c.isActive).length;
    final totalInactive = _customers.length - totalActive;
    final totalBalance = _customers.fold<double>(0.0, (sum, c) => sum + c.currentBalance);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Clients',
            value: _customers.length.toString(),
            subtitle: '$totalActive Actifs • $totalInactive Inactifs',
            icon: Icons.people,
            color: const Color(0xFF6C63FF),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Solde Total',
            value: totalBalance.toStringAsFixed(2),
            subtitle: 'Crédit en cours',
            icon: Icons.account_balance_wallet,
            color: const Color(0xFF00C853),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Entreprises',
            value: _customers.map((c) => c.companyName ?? '').where((c) => c.isNotEmpty).toSet().length.toString(),
            subtitle: 'Noms d\'entreprises uniques',
            icon: Icons.business,
            color: const Color(0xFF2196F3),
          ),
        ),
      ],
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
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
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
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopContent() {
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Clients',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Color(0xFF1B3C34),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Tous', 'Actifs', 'Inactifs'].asMap().entries.map((entry) {
                        final index = entry.key;
                        final displayText = entry.value;
                        final value = ['All', 'Active', 'Inactive'][index];
                        return _buildStatusChip(displayText, value);
                      }).toList(),
                    ),
                  ],
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
                      hintText: 'Rechercher des clients...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    onChanged: _onSearch,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showCustomerForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter Client'),
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
          ),
          _filteredCustomers.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _paginatedCustomers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE8F0EE)),
                  itemBuilder: (context, i) {
                    final c = _paginatedCustomers[i];
                    return _buildDesktopCustomerRow(c);
                  },
                ),
          if (_filteredCustomers.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFE8F0EE)),
            _buildDesktopPagination(),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopCustomerRow(Customer customer) {
    final isActive = customer.isActive;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCustomerDetails(customer),
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
                child: const Icon(Icons.person, color: Color(0xFF6C63FF)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Text(
                            customer.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B3C34),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if ((customer.companyName ?? '').isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6C63FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                customer.companyName!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6C63FF),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.phone, size: 16, color: Color(0xFF6C63FF)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                customer.phoneNumber, 
                                style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (customer.email.isNotEmpty) Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.email, size: 16, color: Color(0xFF6C63FF)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                customer.email, 
                                style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if ((customer.address ?? '').isNotEmpty) Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Color(0xFF6C63FF)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                customer.address!, 
                                style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildStatusBadge(isActive),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF6C63FF)),
                    tooltip: 'Modifier',
                    onPressed: () => _showCustomerForm(customer),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Color(0xFFF44336)),
                    tooltip: 'Supprimer',
                    onPressed: () => _deleteCustomer(customer),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
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

  Widget _buildStatusChip(String displayText, String value) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      selected: isSelected,
      label: Text(displayText),
      onSelected: (selected) {
        setState(() {
          _selectedStatus = selected ? value : 'All';
          _filterCustomers();
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
                Icons.people_outline,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun client trouvé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez d\'ajuster votre recherche ou vos filtres de statut',
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCustomerForm(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter Client'),
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

  void _showCustomerForm([Customer? customer]) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          child: CustomerForm(
            customer: customer,
            onSuccess: _fetchCustomers,
          ),
        ),
      ),
    );
  }

  void _showCustomerDetails(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, color: Color(0xFF6C63FF)),
            ),
            const SizedBox(width: 12),
            const Text('Détails du Client'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Nom', customer.name),
            _buildDetailRow('Téléphone', customer.phoneNumber),
            if (customer.email.isNotEmpty) _buildDetailRow('Email', customer.email),
            if ((customer.address ?? '').isNotEmpty) _buildDetailRow('Adresse', customer.address!),
            if ((customer.companyName ?? '').isNotEmpty) _buildDetailRow('Entreprise', customer.companyName!),
            _buildDetailRow('Solde actuel', '${customer.currentBalance.toStringAsFixed(2)} DNT'),
            _buildDetailRow('Statut', customer.isActive ? 'Actif' : 'Inactif'),
            _buildDetailRow('CIN', customer.cin?.toString() ?? ''),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showCustomerForm(customer);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B3C34),
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            const Text('Supprimer Client'),
          ],
        ),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce client ?'),
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
        await CustomersService.deleteCustomer(customer.id);
        _fetchCustomers();
        AppToast.success(context, 'Client supprimé avec succès');
      } catch (e) {
        AppToast.error(context, 'Erreur lors de la suppression: $e');
      }
    }
  }
}