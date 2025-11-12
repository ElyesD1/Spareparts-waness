import 'package:flutter/material.dart';
import '../../services/warehouse_service.dart';
import '../widgets/sidebar.dart';
import '../widgets/responsive_screen.dart';
import '../../utils/responsive_helper.dart';
import '../widgets/warehouse_form.dart';
import '../widgets/app_toast.dart';

class WarehousesScreen extends StatefulWidget {
  const WarehousesScreen({Key? key}) : super(key: key);

  @override
  State<WarehousesScreen> createState() => _WarehousesScreenState();
}

class _WarehousesScreenState extends State<WarehousesScreen> with TickerProviderStateMixin {
  final WarehouseService _warehouseService = WarehouseService();
  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _filteredWarehouses = [];
  bool _loading = true;
  String _search = '';
  int _currentPage = 1;
  static const int _warehousesPerPage = 10;
  late AnimationController _animationController;
  
  // Search and filter controllers
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fetchWarehouses();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWarehouses() async {
    setState(() => _loading = true);
    try {
      final warehouses = await _warehouseService.getWarehouses();
      setState(() {
        _warehouses = warehouses;
        _filteredWarehouses = warehouses;
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

  List<Map<String, dynamic>> get _paginatedWarehouses {
    final start = (_currentPage - 1) * _warehousesPerPage;
    final end = (_currentPage * _warehousesPerPage).clamp(0, _filteredWarehouses.length);
    return _filteredWarehouses.sublist(start, end);
  }

  int get _totalPages => (_filteredWarehouses.length / _warehousesPerPage).ceil().clamp(1, 999);

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScreen(
      selectedSidebarSection: SidebarSection.warehouses,
      title: 'Entrepôts',
      actions: [
        IconButton(
          onPressed: _fetchWarehouses,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Rafraîchir',
        ),
        IconButton(
          onPressed: () => _showWarehouseForm(),
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Ajouter',
        ),
      ],
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern Page Header
            _buildModernHeader(),
            const SizedBox(height: 32),
            
            // Stats Cards
            _buildModernStats(),
            const SizedBox(height: 32),
            
            // Search and Actions Section
            _buildSearchAndActions(),
            const SizedBox(height: 24),
            
            // Warehouses Grid/List
            _buildModernWarehousesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
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
              Icons.warehouse_rounded,
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
                  'Gestion des Entrepôts',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gérez vos entrepôts et optimisez votre stockage',
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
                Icon(
                  Icons.trending_up,
                  color: Colors.green.shade300,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '+15% ce mois',
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

  Widget _buildModernStats() {
    final totalWarehouses = _warehouses.length;
    final activeLocations = _warehouses.map((w) => w['location']).toSet().length;
    final totalCapacity = totalWarehouses * 1000;

    return ResponsiveHelper.isMobile(context)
        ? Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildModernStatCard(
                    'Total Entrepôts',
                    totalWarehouses.toString(),
                    Icons.warehouse_rounded,
                    const Color(0xFF3B82F6),
                    const Color(0xFFEBF8FF),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _buildModernStatCard(
                    'Emplacements',
                    activeLocations.toString(),
                    Icons.location_on_rounded,
                    const Color(0xFFF59E0B),
                    const Color(0xFFFEF3C7),
                  )),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildModernStatCard(
                    'Capacité Totale',
                    '${totalCapacity} m²',
                    Icons.inventory_rounded,
                    const Color(0xFF10B981),
                    const Color(0xFFD1FAE5),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: Container()), // Empty space
                ],
              ),
            ],
          )
        : Row(
            children: [
              Expanded(child: _buildModernStatCard(
                'Total Entrepôts',
                totalWarehouses.toString(),
                Icons.warehouse_rounded,
                const Color(0xFF3B82F6),
                const Color(0xFFEBF8FF),
              )),
              const SizedBox(width: 20),
              Expanded(child: _buildModernStatCard(
                'Emplacements Actifs',
                activeLocations.toString(),
                Icons.location_on_rounded,
                const Color(0xFFF59E0B),
                const Color(0xFFFEF3C7),
              )),
              const SizedBox(width: 20),
              Expanded(child: _buildModernStatCard(
                'Capacité Totale',
                '${totalCapacity} m²',
                Icons.inventory_rounded,
                const Color(0xFF10B981),
                const Color(0xFFD1FAE5),
              )),
              const SizedBox(width: 20),
              Expanded(child: Container()), // Empty space
            ],
          );
  }

  Widget _buildModernStatCard(String title, String value, IconData icon, Color color, Color bgColor) {
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
        border: Border.all(
          color: Colors.grey.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
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
                    Icon(
                      Icons.trending_up,
                      color: Colors.green.shade600,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+12%',
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
          const SizedBox(height: 20),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndActions() {
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
      child: ResponsiveHelper.isMobile(context)
          ? Column(
              children: [
                _buildModernSearchBar(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildFilterDropdown()),
                    const SizedBox(width: 12),
                    _buildMobileAddButton(),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 2, child: _buildModernSearchBar()),
                const SizedBox(width: 20),
                Expanded(child: _buildFilterDropdown()),
                const SizedBox(width: 20),
                _buildAddButton(),
                const SizedBox(width: 12),
                _buildRefreshButton(),
              ],
            ),
    );
  }

  Widget _buildModernSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un entrepôt...',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilter,
          hint: Text('Filtrer', style: TextStyle(color: Colors.grey[500])),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[400]),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Tous')),
            DropdownMenuItem(value: 'active', child: Text('Actifs')),
            DropdownMenuItem(value: 'inactive', child: Text('Inactifs')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedFilter = value ?? 'all';
            });
            _onSearchChanged(_searchController.text);
          },
        ),
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
          onTap: () => _showWarehouseForm(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                if (!ResponsiveHelper.isMobile(context)) ...[
                  const SizedBox(width: 8),
                  const Text(
                    'Ajouter',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileAddButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showWarehouseForm(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(Icons.add_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _fetchWarehouses,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(Icons.refresh_rounded, color: Colors.grey[600], size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildModernWarehousesList() {
    if (_loading) {
      return Container(
        padding: const EdgeInsets.all(60),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des entrepôts...'),
            ],
          ),
        ),
      );
    }

    if (_filteredWarehouses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(60),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.warehouse_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun entrepôt trouvé',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Commencez par ajouter votre premier entrepôt',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
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
      child: ResponsiveHelper.isMobile(context)
          ? _buildMobileWarehouseGrid()
          : _buildDesktopWarehouseTable(),
    );
  }

  Widget _buildMobileWarehouseGrid() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vos Entrepôts (${_filteredWarehouses.length})',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _filteredWarehouses.length,
            itemBuilder: (context, index) {
              return _buildModernWarehouseCard(_filteredWarehouses[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopWarehouseTable() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Vos Entrepôts (${_filteredWarehouses.length})',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_filteredWarehouses.length} entrepôts',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Nom',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Emplacement',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      Container(
                        width: 80,
                        alignment: Alignment.center,
                        child: const Text(
                          'Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Table Rows
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredWarehouses.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    return _buildModernWarehouseRow(_filteredWarehouses[index]);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernWarehouseCard(Map<String, dynamic> warehouse) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.warehouse_rounded,
                color: Colors.blue.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    warehouse['name'] ?? 'Sans nom',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    warehouse['location'] ?? 'Emplacement non défini',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Entrepôt disponible',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
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
                  _showWarehouseForm(warehouse: warehouse);
                } else if (value == 'delete') {
                  _deleteWarehouse(warehouse);
                }
              },
              itemBuilder: (context) => [
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
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernWarehouseRow(Map<String, dynamic> warehouse) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.warehouse_rounded,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    warehouse['name'] ?? 'Sans nom',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              warehouse['location'] ?? 'Non défini',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Container(
            width: 80,
            alignment: Alignment.center,
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 18),
              onSelected: (value) {
                if (value == 'edit') {
                  _showWarehouseForm(warehouse: warehouse);
                } else if (value == 'delete') {
                  _deleteWarehouse(warehouse);
                }
              },
              itemBuilder: (context) => [
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
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final totalWarehouses = _warehouses.length;
    final activeLocations = _warehouses.map((w) => w['location']).toSet().length;
    final totalCapacity = totalWarehouses * 1000;

    return ResponsiveHelper.isMobile(context)
        ? Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total',
                      totalWarehouses.toString(),
                      Icons.warehouse_outlined,
                      Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Emplacements',
                      activeLocations.toString(),
                      Icons.location_on_outlined,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Capacité',
                      '${totalCapacity} m²',
                      Icons.area_chart_outlined,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Container()),
                ],
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Entrepôts',
                  totalWarehouses.toString(),
                  Icons.warehouse,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Emplacements Actifs',
                  activeLocations.toString(),
                  Icons.location_on,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Capacité Totale',
                  '${totalCapacity} m²',
                  Icons.area_chart,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Container()),
            ],
          );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehousesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search and Filter Bar
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[400]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Rechercher un entrepôt...',
                          border: InputBorder.none,
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  hint: const Text('Filtrer par...'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tous')),
                    DropdownMenuItem(value: 'active', child: Text('Actifs')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactifs')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value ?? 'all';
                    });
                    _onSearchChanged(_searchController.text);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Warehouses List/Grid
        ResponsiveHelper.isMobile(context)
            ? _buildMobileWarehousesList()
            : _buildDesktopWarehousesList(),
      ],
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _search = value;
      _filteredWarehouses = _warehouses.where((warehouse) {
        final matchesSearch = warehouse['name']
            .toString()
            .toLowerCase()
            .contains(value.toLowerCase()) ||
            warehouse['location']
                .toString()
                .toLowerCase()
                .contains(value.toLowerCase());
        
        final matchesFilter = _selectedFilter == 'all' ||
            (_selectedFilter == 'active' && warehouse['status'] == 'active') ||
            (_selectedFilter == 'inactive' && warehouse['status'] != 'active');
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Widget _buildMobileWarehousesList() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredWarehouses.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        ...(_paginatedWarehouses.map((warehouse) => _buildMobileWarehouseCard(warehouse))),
        if (_totalPages > 1) _buildMobilePagination(),
      ],
    );
  }

  Widget _buildMobileWarehouseCard(Map<String, dynamic> warehouse) {
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
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.warehouse, color: Colors.teal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  warehouse['name'] ?? 'Entrepôt sans nom',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Actif',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Location Info
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  warehouse['location'] ?? 'Emplacement non défini',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          
          if (warehouse['capacity'] != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.area_chart, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Capacité: ${warehouse['capacity']} m²',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showWarehouseDetails(warehouse),
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
                  onPressed: () => _showWarehouseForm(warehouse: warehouse),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Modifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
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

  Widget _buildDesktopStats() {
    final totalWarehouses = _warehouses.length;
    final activeLocations = _warehouses.map((w) => w['location']).toSet().length;
    final totalCapacity = totalWarehouses * 1000;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDesktopStatCard(
                      'Total Entrepôts',
                      totalWarehouses.toString(),
                      Icons.warehouse,
                      Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDesktopStatCard(
                      'Emplacements Actifs',
                      activeLocations.toString(),
                      Icons.location_on,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDesktopStatCard(
                      'Capacité Totale',
                      '${totalCapacity} m²',
                      Icons.area_chart,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Container()),
                ],
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(
                child: _buildDesktopStatCard(
                  'Total Entrepôts',
                  totalWarehouses.toString(),
                  Icons.warehouse,
                  Colors.teal,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDesktopStatCard(
                  'Emplacements Actifs',
                  activeLocations.toString(),
                  Icons.location_on,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDesktopStatCard(
                  'Capacité Totale',
                  '${totalCapacity} m²',
                  Icons.area_chart,
                  Colors.blue,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildDesktopStatCard(String title, String value, IconData icon, Color color) {
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
                      '+5.2%',
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
              color: Colors.grey[800],
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
                  'Liste des Entrepôts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Add Button
                ElevatedButton.icon(
                  onPressed: _showWarehouseForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvel Entrepôt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Container(
            constraints: const BoxConstraints(minHeight: 400),
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _buildDesktopWarehousesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopWarehousesList() {
    if (_filteredWarehouses.isEmpty) {
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
              const Expanded(flex: 2, child: Text('Nom', style: TextStyle(fontWeight: FontWeight.bold))),
              const Expanded(flex: 2, child: Text('Emplacement', style: TextStyle(fontWeight: FontWeight.bold))),
              const Expanded(flex: 1, child: Text('Capacité', style: TextStyle(fontWeight: FontWeight.bold))),
              const Expanded(flex: 1, child: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(width: 120, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        
        // Table Body
        Container(
          height: 400, // Fixed height to avoid unbounded constraints
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _paginatedWarehouses.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              return _buildDesktopWarehouseRow(_paginatedWarehouses[index]);
            },
          ),
        ),
        
        // Pagination
        if (_totalPages > 1) _buildDesktopPagination(),
      ],
    );
  }

  Widget _buildDesktopWarehouseRow(Map<String, dynamic> warehouse) {
    return InkWell(
      onTap: () => _showWarehouseDetails(warehouse),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Name
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.warehouse, color: Colors.teal, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      warehouse['name'] ?? 'Entrepôt sans nom',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            
            // Location
            Expanded(
              flex: 2,
              child: Text(warehouse['location'] ?? 'Non défini'),
            ),
            
            // Capacity
            Expanded(
              flex: 1,
              child: Text('${warehouse['capacity'] ?? 1000} m²'),
            ),
            
            // Status
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Actif',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
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
                    onPressed: () => _showWarehouseDetails(warehouse),
                    tooltip: 'Détails',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _showWarehouseForm(warehouse: warehouse),
                    tooltip: 'Modifier',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: () => _deleteWarehouse(warehouse),
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
            'Affichage ${(_currentPage - 1) * _warehousesPerPage + 1} à ${(_currentPage * _warehousesPerPage).clamp(0, _filteredWarehouses.length)} sur ${_filteredWarehouses.length} résultats',
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
                        color: _currentPage == page ? Colors.teal : Colors.transparent,
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
                Icons.warehouse_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun entrepôt trouvé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez d\'ajuster votre recherche ou créez un nouvel entrepôt',
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showWarehouseForm,
              icon: const Icon(Icons.add),
              label: const Text('Créer le premier entrepôt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWarehouseForm({Map<String, dynamic>? warehouse}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          child: WarehouseForm(
            warehouse: warehouse,
            onSuccess: _fetchWarehouses,
          ),
        ),
      ),
    );
  }

  void _showWarehouseDetails(Map<String, dynamic> warehouse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(warehouse['name'] ?? 'Détails de l\'entrepôt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nom: ${warehouse['name'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Emplacement: ${warehouse['location'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Capacité: ${warehouse['capacity'] ?? 1000} m²'),
            const SizedBox(height: 8),
            Text('Statut: Actif'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showWarehouseForm(warehouse: warehouse);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWarehouse(Map<String, dynamic> warehouse) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'entrepôt'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${warehouse['name']}" ?'),
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
        await _warehouseService.deleteWarehouse(warehouse['id']);
        _fetchWarehouses();
        if (mounted) {
          AppToast.success(context, 'Entrepôt supprimé avec succès');
        }
      } catch (e) {
        if (mounted) {
          AppToast.error(context, 'Erreur lors de la suppression: $e');
        }
      }
    }
  }
}