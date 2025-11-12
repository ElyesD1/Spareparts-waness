import 'package:flutter/material.dart';
import '../../models/domain/product_transfer.dart';
import '../../services/product_transfer_service.dart';
import '../../services/session_manager.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_header.dart';
import '../widgets/product_transfer_form.dart';
import 'package:intl/intl.dart';

class ProductTransferScreen extends StatefulWidget {
  const ProductTransferScreen({Key? key}) : super(key: key);

  @override
  State<ProductTransferScreen> createState() => _ProductTransferScreenState();
}

class _ProductTransferScreenState extends State<ProductTransferScreen>
    with TickerProviderStateMixin {
  final ProductTransferService _transferService = ProductTransferService();
  List<ProductTransfer> _transfers = [];
  List<ProductTransfer> _filteredTransfers = [];
  bool _loading = true;
  bool _showCreateForm = false;
  String _search = '';
  String _selectedStatus = 'all';
  String _selectedPriority = 'all';

  Map<String, dynamic>? _currentUser;
  String? _userRole;
  String? _userWarehouseId;

  late AnimationController _animationController;

  // Responsive breakpoints
  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadUserAndTransfers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndTransfers() async {
    setState(() => _loading = true);

    try {
      // Get current user info
      _currentUser = await SessionManager.getUser();
      if (_currentUser != null) {
        _userRole = _currentUser!['role'];
        _userWarehouseId = _currentUser!['warehouse_id'];
      }

      await _loadTransfers();
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement: $e');
    } finally {
      setState(() => _loading = false);
      _animationController.forward();
    }
  }

  Future<void> _loadTransfers() async {
    try {
      List<ProductTransfer> transfers;

      if (ProductTransferService.canViewAllTransfers(_userRole ?? '')) {
        // Admin can see all transfers
        transfers = await _transferService.getTransfers();
      } else if (_userRole == 'manager' && _userWarehouseId != null) {
        // Manager sees transfers involving their warehouse
        transfers = await _transferService.getTransfersByWarehouse(
          _userWarehouseId!,
        );
      } else if (_userRole == 'cashier' && _currentUser != null) {
        // Cashier sees only their own transfer requests
        transfers = await _transferService.getUserTransfers(
          _currentUser!['id'],
        );
      } else {
        transfers = [];
      }

      setState(() {
        _transfers = transfers;
        _applyFilters();
      });
    } catch (e) {
      print('Error loading transfers: $e');
      _showErrorSnackBar('Erreur lors du chargement des transferts');
    }
  }

  void _applyFilters() {
    var filtered = _transfers;

    // Search filter
    if (_search.isNotEmpty) {
      filtered =
          filtered.where((transfer) {
            return transfer.productName?.toLowerCase().contains(
                      _search.toLowerCase(),
                    ) ==
                    true ||
                transfer.productReference?.toLowerCase().contains(
                      _search.toLowerCase(),
                    ) ==
                    true ||
                transfer.fromWarehouseName?.toLowerCase().contains(
                      _search.toLowerCase(),
                    ) ==
                    true ||
                transfer.toWarehouseName?.toLowerCase().contains(
                      _search.toLowerCase(),
                    ) ==
                    true ||
                transfer.reason.toLowerCase().contains(_search.toLowerCase());
          }).toList();
    }

    // Status filter
    if (_selectedStatus != 'all') {
      filtered =
          filtered
              .where((transfer) => transfer.status == _selectedStatus)
              .toList();
    }

    // Priority filter
    if (_selectedPriority != 'all') {
      filtered =
          filtered
              .where((transfer) => transfer.priority == _selectedPriority)
              .toList();
    }

    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _filteredTransfers = filtered;
    });
  }

  void _onSearch(String value) {
    setState(() {
      _search = value;
    });
    _applyFilters();
  }

  void _onStatusFilter(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _applyFilters();
  }

  void _onPriorityFilter(String priority) {
    setState(() {
      _selectedPriority = priority;
    });
    _applyFilters();
  }

  Future<void> _approveTransfer(ProductTransfer transfer) async {
    try {
      // First check if transfer is already completed
      if (transfer.status == 'completed' || transfer.status == 'approved') {
        _showSuccessDialog(
          'Transfert déjà traité',
          '✅ Ce transfert a déjà été approuvé et traité.\n'
              '📦 Les quantités ont été transférées avec succès.\n'
              '📋 Le mouvement de stock a été enregistré.',
        );
        return;
      }

      await _transferService.approveTransfer(transfer.id!);

      _showSuccessDialog(
        'Transfert approuvé avec succès',
        '✅ Le transfert a été approuvé et le stock a été automatiquement transféré.\n'
            '📦 Les quantités ont été mises à jour dans les entrepôts.\n'
            '📋 Un mouvement de stock a été enregistré.',
      );

      await _loadTransfers();
    } catch (e) {
      String errorMessage = e.toString();
      print('Approval error: $errorMessage'); // For debugging

      // Check if it's already processed based on the error message
      if (errorMessage.contains('completed') ||
          errorMessage.contains('approved') ||
          errorMessage.contains('already') ||
          errorMessage.contains('déjà') ||
          errorMessage.contains('status') &&
              errorMessage.contains('completed')) {
        _showSuccessDialog(
          'Transfert déjà traité',
          '✅ Ce transfert a déjà été approuvé et traité.\n'
              '📦 Les quantités ont été transférées avec succès.\n'
              '📋 Le mouvement de stock a été enregistré.',
        );
        await _loadTransfers();
      } else {
        // For other errors, show them but in a more user-friendly way
        _showErrorDialog(
          'Erreur d\'approbation',
          'Une erreur s\'est produite lors de l\'approbation du transfert.\n\n'
              'Veuillez vérifier que:\n'
              '• Le transfert n\'a pas déjà été traité\n'
              '• Vous avez les permissions nécessaires\n'
              '• La connexion au serveur fonctionne\n\n'
              'Détails: ${errorMessage.replaceAll('Exception: ', '')}',
        );
      }
    }
  }

  Future<void> _rejectTransfer(ProductTransfer transfer, String reason) async {
    try {
      await _transferService.rejectTransfer(transfer.id!, reason);
      _showSuccessSnackBar('Transfert rejeté');
      await _loadTransfers();
    } catch (e) {
      _showErrorSnackBar('Erreur lors du rejet: $e');
    }
  }

  Future<void> _processTransfer(ProductTransfer transfer) async {
    try {
      await _transferService.processTransfer(transfer.id!);
      _showSuccessSnackBar('Transfert traité avec succès');
      await _loadTransfers();
    } catch (e) {
      _showErrorSnackBar('Erreur lors du traitement: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessDialog(String title, String content) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(content)],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(content)],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showAddTransferDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width:
                  _isMobile(context)
                      ? MediaQuery.of(context).size.width * 0.9
                      : 500,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth:
                    _isMobile(context)
                        ? MediaQuery.of(context).size.width * 0.9
                        : 500,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.add_box, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Nouveau Transfert',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: Colors.white),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  // Form content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: ProductTransferForm(
                        onTransferCreated: () {
                          Navigator.pop(context);
                          _loadTransfers();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer:
          _isMobile(context)
              ? const Sidebar(selected: SidebarSection.productTransfers)
              : null,
      body: Row(
        children: [
          if (!_isMobile(context))
            const Sidebar(selected: SidebarSection.productTransfers),
          Expanded(
            child: Column(
              children: [
                if (!_isMobile(context))
                  const AppHeader(isMobile: false)
                else
                  _buildMobileHeader(),

                Expanded(
                  child:
                      _isMobile(context)
                          ? _buildMobileLayout()
                          : _buildDesktopLayout(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton:
          _canCreateTransfer()
              ? (_isMobile(context)
                  ? FloatingActionButton(
                    onPressed: () => _showAddTransferDialog(),
                    backgroundColor: Color(0xFF1E40AF),
                    foregroundColor: Colors.white,
                    child: Icon(Icons.add),
                  )
                  : FloatingActionButton.extended(
                    onPressed: () => _showAddTransferDialog(),
                    icon: Icon(Icons.add),
                    label: Text('Nouveau Transfert'),
                    backgroundColor: Color(0xFF1E40AF),
                    foregroundColor: Colors.white,
                    elevation: 4,
                  ))
              : null,
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                Builder(
                  builder:
                      (context) => IconButton(
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transferts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Gestion des mouvements',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!_showCreateForm) ...[
              const SizedBox(height: 12),
              // Mini stats row in header
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStatCard(
                      'En attente',
                      '${_transfers.where((t) => t.isPending).length}',
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniStatCard(
                      'Approuvés',
                      '${_transfers.where((t) => t.isApproved).length}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniStatCard(
                      'Terminés',
                      '${_transfers.where((t) => t.isCompleted).length}',
                      Icons.done_all,
                      Colors.teal,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Search and Filters - Compact mobile version
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 0,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: _onSearch,
                ),
              ),

              // Quick filter chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'Tous',
                        _selectedStatus == 'all',
                        () => _onStatusFilter('all'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'En attente',
                        _selectedStatus == 'pending',
                        () => _onStatusFilter('pending'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Approuvés',
                        _selectedStatus == 'approved',
                        () => _onStatusFilter('approved'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Terminés',
                        _selectedStatus == 'completed',
                        () => _onStatusFilter('completed'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Urgents',
                        _selectedPriority == 'urgent',
                        () => _onPriorityFilter('urgent'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Transfers list
        Expanded(child: _buildMobileTransfersList()),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF1E40AF) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFF1E40AF) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTransfersList() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des transferts...'),
          ],
        ),
      );
    }

    if (_filteredTransfers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.swap_horiz, size: 48, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun transfert trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Modifiez vos filtres ou créez un nouveau transfert',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredTransfers.length,
      itemBuilder: (context, index) {
        final transfer = _filteredTransfers[index];
        return _buildMobileTransferCard(transfer);
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildFiltersSection(),
          const SizedBox(height: 16),
          _buildStatsCards(),
          const SizedBox(height: 24),
          Expanded(child: _buildTransfersTable()),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: _isMobile(context) ? const EdgeInsets.all(16) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher par produit, entrepôt, raison...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: _onSearch,
          ),
          const SizedBox(height: 16),

          // Filters row
          _isMobile(context)
              ? Column(
                children: [
                  _buildStatusFilter(),
                  const SizedBox(height: 12),
                  _buildPriorityFilter(),
                ],
              )
              : Row(
                children: [
                  Expanded(child: _buildStatusFilter()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPriorityFilter()),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: const InputDecoration(
        labelText: 'Statut',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Tous les statuts')),
        DropdownMenuItem(value: 'pending', child: Text('En attente')),
        DropdownMenuItem(value: 'approved', child: Text('Approuvé')),
        DropdownMenuItem(value: 'rejected', child: Text('Rejeté')),
        DropdownMenuItem(value: 'in_transit', child: Text('En transit')),
        DropdownMenuItem(value: 'completed', child: Text('Terminé')),
        DropdownMenuItem(value: 'cancelled', child: Text('Annulé')),
      ],
      onChanged: (value) => _onStatusFilter(value!),
    );
  }

  Widget _buildPriorityFilter() {
    return DropdownButtonFormField<String>(
      value: _selectedPriority,
      decoration: const InputDecoration(
        labelText: 'Priorité',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('Toutes les priorités')),
        DropdownMenuItem(value: 'low', child: Text('Faible')),
        DropdownMenuItem(value: 'normal', child: Text('Normale')),
        DropdownMenuItem(value: 'high', child: Text('Élevée')),
        DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
      ],
      onChanged: (value) => _onPriorityFilter(value!),
    );
  }

  Widget _buildStatsCards() {
    final pending = _transfers.where((t) => t.isPending).length;
    final approved = _transfers.where((t) => t.isApproved).length;
    final completed = _transfers.where((t) => t.isCompleted).length;
    final urgent = _transfers.where((t) => t.isUrgent).length;

    return Container(
      margin:
          _isMobile(context)
              ? const EdgeInsets.symmetric(horizontal: 16)
              : EdgeInsets.zero,
      child:
          _isMobile(context)
              ? Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'En attente',
                          '$pending',
                          Colors.orange,
                          Icons.pending,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Approuvés',
                          '$approved',
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Terminés',
                          '$completed',
                          Colors.blue,
                          Icons.done_all,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Urgents',
                          '$urgent',
                          Colors.red,
                          Icons.priority_high,
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'En attente',
                      '$pending',
                      Colors.orange,
                      Icons.pending,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Approuvés',
                      '$approved',
                      Colors.green,
                      Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Terminés',
                      '$completed',
                      Colors.blue,
                      Icons.done_all,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Urgents',
                      '$urgent',
                      Colors.red,
                      Icons.priority_high,
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTransferCard(ProductTransfer transfer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showTransferDetails(transfer),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with product and status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E40AF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      color: Color(0xFF1E40AF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transfer.productName ?? 'Produit inconnu',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (transfer.productReference != null)
                          Text(
                            'Réf: ${transfer.productReference}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusChip(transfer.status),
                ],
              ),

              const SizedBox(height: 16),

              // Transfer route with visual arrow
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    // From warehouse
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.warehouse,
                                size: 14,
                                color: Colors.red[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'DE',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.red[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            transfer.fromWarehouseName ?? 'Inconnu',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Arrow
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Color(0xFF1E40AF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),

                    // To warehouse
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'VERS',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.warehouse,
                                size: 14,
                                color: Colors.green[600],
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            transfer.toWarehouseName ?? 'Inconnu',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Details row
              Row(
                children: [
                  // Quantity
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.numbers, size: 12, color: Colors.blue[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${transfer.quantity}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Priority
                  _buildPriorityChip(transfer.priority),

                  const Spacer(),

                  // Date
                  Text(
                    DateFormat('dd/MM/yy').format(transfer.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Reason
              if (transfer.reason.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.description,
                        size: 14,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          transfer.reason,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[800],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showTransferDetails(transfer),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Détails'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Conditional action buttons
                  if (transfer.canBeApproved &&
                      ProductTransferService.canApproveTransfer(
                        _userRole ?? '',
                        _userWarehouseId,
                        transfer.toWarehouseId,
                      )) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveTransfer(transfer),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approuver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ] else if (transfer.canBeProcessed &&
                      ProductTransferService.canProcessTransfer(
                        _userRole ?? '',
                      )) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _processTransfer(transfer),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Traiter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1E40AF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransfersTable() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredTransfers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun transfert trouvé',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Produit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'De → Vers',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Quantité',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Priorité',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Statut',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Table body
          Expanded(
            child: ListView.separated(
              itemCount: _filteredTransfers.length,
              separatorBuilder:
                  (_, __) => Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, index) {
                final transfer = _filteredTransfers[index];
                return _buildTableRow(transfer);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(ProductTransfer transfer) {
    return InkWell(
      onTap: () => _showTransferDetails(transfer),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Product
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transfer.productName ?? 'Produit inconnu',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (transfer.productReference != null)
                    Text(
                      transfer.productReference!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // From → To
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${transfer.fromWarehouseName ?? 'Inconnu'} →',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    transfer.toWarehouseName ?? 'Inconnu',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Quantity
            Expanded(
              flex: 1,
              child: Text(
                '${transfer.quantity}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),

            // Priority
            Expanded(flex: 1, child: _buildPriorityChip(transfer.priority)),

            // Status
            Expanded(flex: 1, child: _buildStatusChip(transfer.status)),

            // Date
            Expanded(
              flex: 1,
              child: Text(
                DateFormat('dd/MM/yy').format(transfer.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),

            // Actions
            SizedBox(width: 120, child: _buildActionButtons(transfer)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'En attente';
        break;
      case 'approved':
        color = Colors.green;
        text = 'Approuvé';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejeté';
        break;
      case 'in_transit':
        color = Colors.blue;
        text = 'En transit';
        break;
      case 'completed':
        color = Colors.teal;
        text = 'Terminé';
        break;
      case 'cancelled':
        color = Colors.grey;
        text = 'Annulé';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    String text;

    switch (priority) {
      case 'low':
        color = Colors.grey;
        text = 'Faible';
        break;
      case 'normal':
        color = Colors.blue;
        text = 'Normale';
        break;
      case 'high':
        color = Colors.orange;
        text = 'Élevée';
        break;
      case 'urgent':
        color = Colors.red;
        text = 'Urgente';
        break;
      default:
        color = Colors.grey;
        text = priority;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons(ProductTransfer transfer) {
    final canApprove = ProductTransferService.canApproveTransfer(
      _userRole ?? '',
      _userWarehouseId,
      transfer.toWarehouseId,
    );

    final canProcess = ProductTransferService.canProcessTransfer(
      _userRole ?? '',
    );

    List<Widget> actions = [];

    if (transfer.canBeApproved && canApprove) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
          onPressed: () => _approveTransfer(transfer),
          tooltip: 'Approuver',
        ),
      );
      actions.add(
        IconButton(
          icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
          onPressed: () => _showRejectDialog(transfer),
          tooltip: 'Rejeter',
        ),
      );
    }

    if (transfer.canBeProcessed && canProcess) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.play_arrow, color: Colors.blue, size: 20),
          onPressed: () => _processTransfer(transfer),
          tooltip: 'Traiter',
        ),
      );
    }

    actions.add(
      IconButton(
        icon: const Icon(Icons.visibility, color: Colors.grey, size: 20),
        onPressed: () => _showTransferDetails(transfer),
        tooltip: 'Détails',
      ),
    );

    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }

  void _showTransferDetails(ProductTransfer transfer) {
    // Calculate duration if transfer is completed
    String? duration;
    if (transfer.processedAt != null) {
      final diff = transfer.processedAt!.difference(transfer.createdAt);
      if (diff.inDays > 0) {
        duration = '${diff.inDays} jour(s) ${diff.inHours % 24} heure(s)';
      } else if (diff.inHours > 0) {
        duration = '${diff.inHours} heure(s) ${diff.inMinutes % 60} minute(s)';
      } else {
        duration = '${diff.inMinutes} minute(s)';
      }
    }

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width:
                  _isMobile(context)
                      ? MediaQuery.of(context).size.width * 0.95
                      : 600,
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(context).size.height *
                    (_isMobile(context) ? 0.90 : 0.85),
                maxWidth:
                    _isMobile(context)
                        ? MediaQuery.of(context).size.width * 0.95
                        : 600,
              ),
              padding: const EdgeInsets.all(0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with icon and title
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.transfer_within_a_station,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Détails du Transfert',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                'Transfert #${transfer.id}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  // Content - Scrollable
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product info container
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF1E40AF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.inventory_2,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            transfer.productName ??
                                                'Produit Inconnu',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'Réf: ${transfer.productReference ?? 'N/A'}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        'Qté: ${transfer.quantity}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Transfer Route Section
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.route,
                                      color: Colors.blue.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Route de Transfert',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.red.shade200,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.warehouse,
                                              color: Colors.red.shade600,
                                              size: 24,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'DE',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.red.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              transfer.fromWarehouseName ??
                                                  'Inconnu',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward,
                                        color: Colors.blue.shade600,
                                        size: 24,
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.green.shade200,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.warehouse,
                                              color: Colors.green.shade600,
                                              size: 24,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'VERS',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              transfer.toWarehouseName ??
                                                  'Inconnu',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Status and Priority Section
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.flag,
                                  title: 'Priorité',
                                  value: _getPriorityLabel(transfer.priority),
                                  color: _getPriorityColor(transfer.priority),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildInfoCard(
                                  icon: Icons.info,
                                  title: 'Statut',
                                  value: _getStatusLabel(transfer.status),
                                  color: _getStatusColor(transfer.status),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Duration if available
                          if (duration != null)
                            _buildInfoCard(
                              icon: Icons.schedule,
                              title: 'Durée de traitement',
                              value: duration,
                              color: Colors.purple,
                            ),

                          if (duration != null) const SizedBox(height: 16),

                          // Timeline Section
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timeline,
                                      color: Colors.grey.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Chronologie du Transfert',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildTimelineItem(
                                  icon: Icons.add_circle,
                                  title: 'Demande créée',
                                  subtitle:
                                      'Par ${transfer.requestedByName ?? 'Inconnu'}',
                                  time: DateFormat(
                                    'dd/MM/yyyy à HH:mm',
                                  ).format(transfer.createdAt),
                                  isCompleted: true,
                                ),
                                if (transfer.approvedAt != null)
                                  _buildTimelineItem(
                                    icon: Icons.check_circle,
                                    title: 'Transfert approuvé',
                                    subtitle:
                                        'Par ${transfer.approvedByName ?? 'Inconnu'}',
                                    time: DateFormat(
                                      'dd/MM/yyyy à HH:mm',
                                    ).format(transfer.approvedAt!),
                                    isCompleted: true,
                                  ),
                                if (transfer.processedAt != null)
                                  _buildTimelineItem(
                                    icon: Icons.done_all,
                                    title: 'Transfert terminé',
                                    subtitle:
                                        'Par ${transfer.processedByName ?? 'Inconnu'}',
                                    time: DateFormat(
                                      'dd/MM/yyyy à HH:mm',
                                    ).format(transfer.processedAt!),
                                    isCompleted: true,
                                    isLast: true,
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Additional Details
                          _buildDetailRow('📝 Raison', transfer.reason),
                          if (transfer.notes != null &&
                              transfer.notes!.isNotEmpty)
                            _buildDetailRow('� Notes', transfer.notes!),
                        ],
                      ),
                    ),
                  ),

                  // Footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Fermer'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(ProductTransfer transfer) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Rejeter le Transfert'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Pourquoi rejetez-vous ce transfert ?'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Raison du rejet',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (reasonController.text.trim().isNotEmpty) {
                    Navigator.of(context).pop();
                    _rejectTransfer(transfer, reasonController.text.trim());
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Rejeter'),
              ),
            ],
          ),
    );
  }

  bool _canCreateTransfer() {
    return _userRole != null &&
        ProductTransferService.canCreateTransfer(
          _userRole!,
          _userWarehouseId,
          _userWarehouseId ?? '',
        );
  }

  // Helper methods for enhanced transfer details dialog
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required bool isCompleted,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 20,
                  color: isCompleted ? Colors.green : Colors.grey,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPriorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return 'Faible';
      case 'normal':
        return 'Normale';
      case 'high':
        return 'Élevée';
      case 'urgent':
        return 'Urgente';
      default:
        return priority;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'normal':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      case 'in_transit':
        return 'En transit';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'in_transit':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
