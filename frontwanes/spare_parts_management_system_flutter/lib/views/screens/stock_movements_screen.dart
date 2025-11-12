import 'package:flutter/material.dart';
import '../../services/stock_movement_service.dart';
import '../../models/domain/stock_movement.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_header.dart';
import 'package:intl/intl.dart';

class StockMovementsScreen extends StatefulWidget {
  const StockMovementsScreen({super.key});

  @override
  State<StockMovementsScreen> createState() => _StockMovementsScreenState();
}

class _StockMovementsScreenState extends State<StockMovementsScreen> {
  final StockMovementService _stockMovementService = StockMovementService();
  List<StockMovement> _stockMovements = [];
  List<StockMovement> _filteredMovements = [];
  bool _loading = true;
  bool _hasError = false;
  String _search = '';
  String _selectedType = 'all';
  int _currentPage = 1;
  static const int _movementsPerPage = 20;

  // Responsive breakpoints
  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  @override
  void initState() {
    super.initState();
    _fetchStockMovements();
  }

  Future<void> _fetchStockMovements() async {
    setState(() => _loading = true);
    try {
      final movements = await _stockMovementService.fetchStockMovements();
      setState(() {
        _stockMovements = movements;
        _filteredMovements = movements;
        _loading = false;
        _hasError = false;
        _currentPage = 1;
      });
      _applyFilters();
    } catch (e) {
      setState(() {
        _loading = false;
        _hasError = true;
      });
      if (mounted) {
        String errorMessage = 'Erreur lors du chargement des mouvements';

        if (e.toString().contains('JSON')) {
          errorMessage = 'Erreur de format des données reçues du serveur';
        } else if (e.toString().contains('HTTP')) {
          errorMessage = 'Erreur de communication avec le serveur';
        } else if (e.toString().contains('Exception')) {
          errorMessage =
              'Erreur inattendue: ${e.toString().split(':').last.trim()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: Colors.white,
              onPressed: _fetchStockMovements,
            ),
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredMovements =
          _stockMovements.where((movement) {
            // Filter by type
            if (_selectedType != 'all' &&
                movement.movementType != _selectedType) {
              return false;
            }

            // Filter by search
            if (_search.isNotEmpty) {
              final searchLower = _search.toLowerCase();
              return movement.note?.toLowerCase().contains(searchLower) ==
                      true ||
                  movement.displayProductName.toLowerCase().contains(
                    searchLower,
                  ) ||
                  movement.displayUserName.toLowerCase().contains(searchLower);
            }

            return true;
          }).toList();

      _currentPage = 1;
    });
  }

  void _onSearch(String value) {
    setState(() {
      _search = value;
      _applyFilters();
    });
  }

  void _onTypeChanged(String? value) {
    if (value != null) {
      setState(() {
        _selectedType = value;
        _applyFilters();
      });
    }
  }

  Color _getMovementTypeColor(String movementType) {
    switch (movementType.toLowerCase()) {
      case 'vente':
        return Colors.red;
      case 'achat':
        return Colors.green;
      case 'return':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getMovementTypeIcon(String movementType) {
    switch (movementType.toLowerCase()) {
      case 'vente':
        return Icons.shopping_cart;
      case 'achat':
        return Icons.inventory;
      case 'return':
        return Icons.undo;
      default:
        return Icons.swap_horiz;
    }
  }

  String _getMovementTypeText(String movementType) {
    switch (movementType.toLowerCase()) {
      case 'vente':
        return 'Vente';
      case 'achat':
        return 'Achat';
      case 'return':
        return 'Retour';
      default:
        return movementType;
    }
  }

  List<StockMovement> get _paginatedMovements {
    final startIndex = (_currentPage - 1) * _movementsPerPage;
    final endIndex = startIndex + _movementsPerPage;
    return _filteredMovements.sublist(
      startIndex,
      endIndex > _filteredMovements.length
          ? _filteredMovements.length
          : endIndex,
    );
  }

  int get _totalPages => (_filteredMovements.length / _movementsPerPage).ceil();

  // NEW METHOD: Show movement details dialog
  void _showMovementDetails(StockMovement movement) {
    final movementColor = _getMovementTypeColor(movement.movementType);
    final movementIcon = _getMovementTypeIcon(movement.movementType);

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth:
                    _isMobile(context)
                        ? MediaQuery.of(context).size.width * 0.95
                        : 700,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [movementColor, movementColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            movementIcon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Détails du Mouvement',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _getMovementTypeText(movement.movementType),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Movement Type Badge
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: movementColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: movementColor,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    movementIcon,
                                    color: movementColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getMovementTypeText(movement.movementType),
                                    style: TextStyle(
                                      color: movementColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Product Information
                          _buildDetailSection(
                            'Informations Produit',
                            Icons.inventory_2,
                            Colors.blue,
                            [
                              _buildDetailRow(
                                'Nom du Produit',
                                movement.displayProductName,
                              ),
                              _buildDetailRow(
                                'Marque',
                                movement.productBrand ?? 'N/A',
                              ),
                              _buildDetailRow(
                                'Quantité',
                                '${movement.quantity}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Warehouse Information
                          _buildDetailSection(
                            'Informations Entrepôt',
                            Icons.warehouse,
                            Colors.orange,
                            [
                              _buildDetailRow(
                                'Entrepôt Source',
                                movement.displayFromWarehouseName,
                              ),
                              _buildDetailRow(
                                'Entrepôt Destination',
                                movement.displayToWarehouseName,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // User Information - ENHANCED FOR PURCHASES
                          _buildDetailSection(
                            'Informations Utilisateurs',
                            Icons.people,
                            Colors.purple,
                            [
                              _buildDetailRow(
                                'Utilisateur Principal',
                                movement.displayUserName,
                              ),
                              _buildDetailRow('Rôle', movement.displayUserRole),

                              // NEW: Purchase-specific user information
                              if (movement.movementType.toLowerCase() ==
                                  'achat') ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.shopping_cart,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Détails de l\'Achat',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDetailRow(
                                        'Créé par',
                                        movement.displayUserName,
                                        isHighlighted: true,
                                      ),
                                      _buildDetailRow(
                                        'Livré par',
                                        _getDeliveryUser(movement),
                                        isHighlighted: true,
                                      ),
                                      _buildDetailRow(
                                        'Status de Livraison',
                                        _getDeliveryStatus(movement),
                                        statusColor: _getDeliveryStatusColor(
                                          movement,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Date and Time Information
                          _buildDetailSection(
                            'Informations Temporelles',
                            Icons.schedule,
                            Colors.indigo,
                            [
                              _buildDetailRow(
                                'Date de Création',
                                DateFormat(
                                  'dd/MM/yyyy à HH:mm:ss',
                                ).format(movement.createdAt),
                              ),
                              _buildDetailRow(
                                'Heure Exacte',
                                DateFormat(
                                  'EEEE, dd MMMM yyyy',
                                  'fr_FR',
                                ).format(movement.createdAt),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Notes
                          if (movement.note != null &&
                              movement.note!.isNotEmpty)
                            _buildDetailSection(
                              'Notes',
                              Icons.note,
                              Colors.teal,
                              [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Text(
                                    movement.note!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF374151),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close, size: 18),
                            label: const Text('Fermer'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // Could add functionality to view related documents
                            },
                            icon: const Icon(Icons.visibility, size: 18),
                            label: const Text('Voir Plus'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: movementColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
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

  Widget _buildDetailSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlighted = false,
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color:
                    isHighlighted ? Colors.green[700] : const Color(0xFF6B7280),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color:
                    statusColor ??
                    (isHighlighted
                        ? Colors.green[800]
                        : const Color(0xFF374151)),
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Get delivery user information
  String _getDeliveryUser(StockMovement movement) {
    // This would typically come from your API data
    // For now, we'll simulate based on the current user or movement data
    if (movement.movementType.toLowerCase() == 'achat') {
      // You might have delivery user info in the movement data
      // For now, we'll show current user or a placeholder
      return 'MedAzizAbidii'; // Current user from your context
    }
    return 'N/A';
  }

  // NEW: Get delivery status
  String _getDeliveryStatus(StockMovement movement) {
    // This would typically come from your API data
    // For demo purposes, we'll simulate delivery status
    final now = DateTime.now();
    final movementDate = movement.createdAt;
    final daysDiff = now.difference(movementDate).inDays;

    if (daysDiff == 0) {
      return 'Livré Aujourd\'hui';
    } else if (daysDiff == 1) {
      return 'Livré Hier';
    } else if (daysDiff < 7) {
      return 'Livré il y a $daysDiff jours';
    } else {
      return 'Livré le ${DateFormat('dd/MM/yyyy').format(movementDate)}';
    }
  }

  // NEW: Get delivery status color
  Color _getDeliveryStatusColor(StockMovement movement) {
    final now = DateTime.now();
    final daysDiff = now.difference(movement.createdAt).inDays;

    if (daysDiff <= 1) {
      return Colors.green;
    } else if (daysDiff <= 7) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // Add drawer for mobile
      drawer:
          _isMobile(context)
              ? Drawer(
                child: const Sidebar(selected: SidebarSection.stockMovements),
              )
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
          // Mobile Header with Menu Button
          _buildMobileHeader(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Stats
                  _buildMobileStats(),
                  const SizedBox(height: 20),

                  // Search and Filter
                  _buildMobileFilters(),
                  const SizedBox(height: 20),

                  // Movements List
                  _buildMobileMovementsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blue.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Builder(
            builder:
                (context) => Container(
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
                  'Mouvements de Stock',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Historique des mouvements',
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
    final totalMovements = _stockMovements.length;
    final salesCount =
        _stockMovements.where((m) => m.movementType == 'vente').length;
    final purchasesCount =
        _stockMovements.where((m) => m.movementType == 'achat').length;
    final returnsCount =
        _stockMovements.where((m) => m.movementType == 'return').length;

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
          totalMovements.toString(),
          Icons.analytics,
          Colors.blue,
        ),
        _buildMobileStatCard(
          'Ventes',
          salesCount.toString(),
          Icons.shopping_cart,
          Colors.red,
        ),
        _buildMobileStatCard(
          'Achats',
          purchasesCount.toString(),
          Icons.inventory,
          Colors.green,
        ),
        _buildMobileStatCard(
          'Retours',
          returnsCount.toString(),
          Icons.undo,
          Colors.orange,
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
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilters() {
    return Column(
      children: [
        // Search Bar
        TextField(
          onChanged: _onSearch,
          decoration: InputDecoration(
            hintText: 'Rechercher...',
            prefixIcon: Icon(Icons.search, color: Colors.blue.shade300),
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Type Filter
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tous les types')),
                DropdownMenuItem(value: 'vente', child: Text('Ventes')),
                DropdownMenuItem(value: 'achat', child: Text('Achats')),
                DropdownMenuItem(value: 'retour', child: Text('Retours')),
              ],
              onChanged: _onTypeChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileMovementsList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return _buildErrorState();
    }

    if (_filteredMovements.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        ..._paginatedMovements.map(
          (movement) => _buildMobileMovementCard(movement),
        ),
        if (_totalPages > 1) ...[
          const SizedBox(height: 20),
          _buildMobilePagination(),
        ],
      ],
    );
  }

  Widget _buildMobileMovementCard(StockMovement movement) {
    final movementColor = _getMovementTypeColor(movement.movementType);
    final movementIcon = _getMovementTypeIcon(movement.movementType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: movementColor.withOpacity(0.2)),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: movementColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(movementIcon, color: movementColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.displayProductName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _getMovementTypeText(movement.movementType),
                      style: TextStyle(
                        color: movementColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // NEW: Details button
              IconButton(
                onPressed: () => _showMovementDetails(movement),
                icon: const Icon(Icons.visibility, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  foregroundColor: Colors.blue,
                ),
                tooltip: 'Voir détails',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Info Grid
          Row(
            children: [
              Expanded(
                child: _buildMobileInfoBox(
                  'Quantité',
                  '${movement.quantity}',
                  movementColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMobileInfoBox(
                  'Utilisateur',
                  movement.displayUserName,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _buildMobileInfoBox(
                  'Date',
                  DateFormat('dd/MM/yyyy').format(movement.createdAt),
                  Colors.indigo,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMobileInfoBox(
                  'Heure',
                  DateFormat('HH:mm').format(movement.createdAt),
                  Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInfoBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed:
              _currentPage > 1 ? () => setState(() => _currentPage--) : null,
          icon: const Icon(Icons.chevron_left),
          color: _currentPage > 1 ? Colors.blue : Colors.grey,
        ),
        Text(
          'Page $_currentPage sur $_totalPages',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        IconButton(
          onPressed:
              _currentPage < _totalPages
                  ? () => setState(() => _currentPage++)
                  : null,
          icon: const Icon(Icons.chevron_right),
          color: _currentPage < _totalPages ? Colors.blue : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        const Sidebar(selected: SidebarSection.stockMovements),
        Expanded(
          child: Column(
            children: [
              const AppHeader(),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with stats
                      _buildStatsHeader(),
                      const SizedBox(height: 24),

                      // Filters and search
                      _buildFiltersAndSearch(),
                      const SizedBox(height: 24),

                      // Movements table
                      Expanded(
                        child:
                            _loading
                                ? const Center(
                                  child: CircularProgressIndicator(),
                                )
                                : _hasError
                                ? _buildErrorState()
                                : _filteredMovements.isEmpty
                                ? _buildEmptyState()
                                : _buildMovementsTable(),
                      ),

                      // Pagination
                      if (_totalPages > 1) ...[
                        const SizedBox(height: 24),
                        _buildPagination(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader() {
    final totalMovements = _stockMovements.length;
    final salesCount =
        _stockMovements.where((m) => m.movementType == 'vente').length;
    final purchasesCount =
        _stockMovements.where((m) => m.movementType == 'achat').length;
    final returnsCount =
        _stockMovements.where((m) => m.movementType == 'return').length;

    return Row(
      children: [
        _buildStatCard(
          'Total',
          totalMovements.toString(),
          Icons.analytics,
          Colors.blue,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Ventes',
          salesCount.toString(),
          Icons.shopping_cart,
          Colors.red,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Achats',
          purchasesCount.toString(),
          Icons.inventory,
          Colors.green,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          'Retours',
          returnsCount.toString(),
          Icons.undo,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersAndSearch() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search field
          Expanded(
            flex: 2,
            child: TextField(
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Rechercher par produit, utilisateur ou note...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Type filter
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Type de mouvement',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tous les types')),
                DropdownMenuItem(value: 'vente', child: Text('Ventes')),
                DropdownMenuItem(value: 'achat', child: Text('Achats')),
                DropdownMenuItem(value: 'retour', child: Text('Retours')),
              ],
              onChanged: _onTypeChanged,
            ),
          ),

          const SizedBox(width: 16),

          // Refresh button
          ElevatedButton.icon(
            onPressed: _fetchStockMovements,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Table header
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
                Expanded(flex: 2, child: _buildHeaderCell('Type')),
                Expanded(flex: 3, child: _buildHeaderCell('Produit')),
                Expanded(flex: 2, child: _buildHeaderCell('Quantité')),
                Expanded(flex: 2, child: _buildHeaderCell('Entrepôt')),
                Expanded(flex: 2, child: _buildHeaderCell('Utilisateur')),
                Expanded(flex: 2, child: _buildHeaderCell('Date')),
                Expanded(flex: 3, child: _buildHeaderCell('Note')),
                const SizedBox(
                  width: 80,
                  child: Text(
                    'Actions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table body
          Expanded(
            child: ListView.builder(
              itemCount: _paginatedMovements.length,
              itemBuilder: (context, index) {
                final movement = _paginatedMovements[index];
                return _buildMovementRow(movement, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        fontSize: 14,
      ),
    );
  }

  Widget _buildMovementRow(StockMovement movement, int index) {
    final isEven = index % 2 == 0;

    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.white : Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Type
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getMovementTypeColor(
                    movement.movementType,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getMovementTypeColor(movement.movementType),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getMovementTypeIcon(movement.movementType),
                      size: 16,
                      color: _getMovementTypeColor(movement.movementType),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _getMovementTypeText(movement.movementType),
                        style: TextStyle(
                          color: _getMovementTypeColor(movement.movementType),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movement.displayProductName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    'Marque: ${movement.productBrand}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Quantity
            Expanded(
              flex: 2,
              child: Text(
                '${movement.quantity}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

            // Warehouse
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'De: ${movement.displayFromWarehouseName}',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Vers: ${movement.displayToWarehouseName}',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // User
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movement.displayUserName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    movement.displayUserRole,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Date
            Expanded(
              flex: 2,
              child: Text(
                DateFormat('dd/MM/yyyy\nHH:mm').format(movement.createdAt),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),

            // Note
            Expanded(
              flex: 3,
              child: Text(
                movement.note ?? 'Aucune note',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // NEW: Actions column with details button
            SizedBox(
              width: 80,
              child: IconButton(
                onPressed: () => _showMovementDetails(movement),
                icon: const Icon(Icons.visibility, size: 18),
                tooltip: 'Voir détails',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  foregroundColor: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Impossible de charger les mouvements de stock',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchStockMovements,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun mouvement de stock trouvé',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les mouvements apparaîtront ici après avoir créé des ventes, achats ou retours',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed:
              _currentPage > 1 ? () => setState(() => _currentPage--) : null,
          icon: const Icon(Icons.chevron_left),
          color: _currentPage > 1 ? Colors.blue : Colors.grey,
        ),
        const SizedBox(width: 16),
        Text(
          'Page $_currentPage sur $_totalPages',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed:
              _currentPage < _totalPages
                  ? () => setState(() => _currentPage++)
                  : null,
          icon: const Icon(Icons.chevron_right),
          color: _currentPage < _totalPages ? Colors.blue : Colors.grey,
        ),
      ],
    );
  }
}
