import 'package:flutter/material.dart';
import 'package:spare_parts_management_system_flutter/models/domain/purchase_item.dart';
import 'package:spare_parts_management_system_flutter/views/widgets/new_purchase_form.dart';
import '../../services/purchase_service.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_header.dart';
import '../widgets/responsive_profile_button.dart';
import '../widgets/facture_dialog.dart';
import '../../services/user_service.dart';
import '../../services/session_manager.dart';
import '../widgets/app_toast.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({Key? key}) : super(key: key);

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen>
    with TickerProviderStateMixin {
  final PurchaseService _purchaseService = PurchaseService();
  List<dynamic> _purchases = [];
  List<dynamic> _filteredPurchases = [];
  bool _loading = true;
  String _search = '';
  int _currentPage = 1;
  static const int _purchasesPerPage = 10;
  late AnimationController _animationController;
  final TextEditingController unitPriceController = TextEditingController();
  Map<String, dynamic>? _currentUser;
  String? _currentUserRole;

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
    _fetchPurchases();
    _fetchUsers();
    _fetchCurrentUser();
  }

  @override
  void dispose() {
    _animationController.dispose();
    unitPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchPurchases() async {
    setState(() => _loading = true);
    try {
      final purchases = await _purchaseService.fetchPurchases();
      setState(() {
        _purchases = purchases;
        _filteredPurchases = purchases;
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

  Future<void> _fetchUsers() async {
    try {
      await UserService.getUsers();
      // Users data available for other purposes if needed
    } catch (e) {
      // handle error
    }
  }

  Future<void> _fetchCurrentUser() async {
    final user = await SessionManager.getUser();
    setState(() {
      _currentUser = user;
      _currentUserRole = user?['role'];
    });
  }

  Future<void> _confirmDeliveryManager(dynamic purchase) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Confirmation de Livraison',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.business,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Fournisseur',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              purchase.supplier?['name'] ?? 'Non spécifié',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),

                            const SizedBox(height: 16),

                            if (_currentUser != null) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Confirmé par',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _currentUser!['name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text('Confirmer'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && _currentUser != null) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                content: Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 16),
                    const Text('Confirmation en cours...'),
                  ],
                ),
              ),
        );

        await PurchaseService().confirmDelivery(
          purchase.id,
          _currentUser!['id'],
        );

        Navigator.of(context).pop();

        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 24),
                    const SizedBox(width: 8),
                    const Text('Livraison Confirmée'),
                  ],
                ),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('✅ Achat confirmé et livré'),
                    SizedBox(height: 8),
                    Text('📦 Produits ajoutés au stock'),
                    SizedBox(height: 8),
                    Text('📋 Mouvements de stock enregistrés'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );

        _fetchPurchases();
      } catch (e) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 24),
                    const SizedBox(width: 8),
                    const Text('Erreur'),
                  ],
                ),
                content: Text('Échec de la confirmation: $e'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  Future<void> _deletePurchase(dynamic purchase) async {
    // Only allow deletion if purchase is not delivered
    if (purchase.status == 'delivered') {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 24),
                  const SizedBox(width: 8),
                  const Text('Action Non Autorisée'),
                ],
              ),
              content: const Text(
                'Impossible de supprimer un achat qui a déjà été livré.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text('Confirmer la Suppression'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Êtes-vous sûr de vouloir supprimer cet achat ?'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fournisseur: ${purchase.supplier?['name'] ?? 'N/A'}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text('Date: ${purchase.date ?? 'N/A'}'),
                      Text(
                        'Montant: ${purchase.finalAmount?.toStringAsFixed(2) ?? '0.00'} DNT',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cette action est irréversible.',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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

    if (confirmed == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Suppression en cours...'),
                  ],
                ),
              ),
        );

        await PurchaseService().deletePurchase(purchase.id);

        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 24),
                    const SizedBox(width: 8),
                    const Text('Succès'),
                  ],
                ),
                content: const Text('L\'achat a été supprimé avec succès.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );

        _fetchPurchases();
      } catch (e) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 24),
                    const SizedBox(width: 8),
                    const Text('Erreur'),
                  ],
                ),
                content: Text('Échec de la suppression: $e'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  void _editPurchase(dynamic purchase) {
    // Only allow editing if purchase is not delivered
    if (purchase.status == 'delivered') {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 24),
                  const SizedBox(width: 8),
                  const Text('Action Non Autorisée'),
                ],
              ),
              content: const Text(
                'Impossible de modifier un achat qui a déjà été livré.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Modification d\'achat'),
            content: const Text(
              'La fonctionnalité de modification d\'achat sera bientôt disponible.',
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

  void _onSearch(String value) {
    setState(() {
      _search = value;
      _filteredPurchases =
          _purchases
              .where(
                (p) =>
                    (p.supplier?['name'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains(_search.toLowerCase()) ||
                    (p.date ?? '').toLowerCase().contains(
                      _search.toLowerCase(),
                    ),
              )
              .toList();
      _currentPage = 1;
    });
  }

  List<dynamic> get _paginatedPurchases {
    final start = (_currentPage - 1) * _purchasesPerPage;
    final end = (_currentPage * _purchasesPerPage).clamp(
      0,
      _filteredPurchases.length,
    );
    return _filteredPurchases.sublist(start, end);
  }

  int get _totalPages =>
      (_filteredPurchases.length / _purchasesPerPage).ceil().clamp(1, 999);

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // Add drawer for mobile
      drawer:
          _isMobile(context)
              ? Drawer(child: Sidebar(selected: SidebarSection.purchases))
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
          // Mobile Header with context that has access to Scaffold
          _buildMobileHeaderWithMenu(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Stats Row
                  _buildMobileStats(),
                  const SizedBox(height: 20),

                  // Search Bar
                  _buildMobileSearchBar(),
                  const SizedBox(height: 20),

                  // Purchases List
                  _buildMobilePurchasesList(),
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
        Sidebar(selected: SidebarSection.purchases),
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
                  // Header Bar
                  _buildDesktopHeader(),

                  // Main Content
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Controls Bar
                          _buildDesktopControls(),
                          const SizedBox(height: 24),

                          // Table
                          Expanded(child: _buildDesktopTable()),
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

  Widget _buildMobileHeaderWithMenu() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.indigo.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
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
                  'Achats',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Gestion des achats',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (_currentUserRole == 'cashier' || _currentUserRole == 'admin') ...[
            FloatingActionButton(
              onPressed: () => _showNewPurchaseForm(),
              backgroundColor: Colors.white,
              foregroundColor: Colors.indigo,
              elevation: 0,
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: 8),
          ],
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
    final totalPurchases = _purchases.length;
    final deliveredPurchases =
        _purchases.where((p) => p.status == 'delivered').length;
    final pendingPurchases = totalPurchases - deliveredPurchases;

    return Row(
      children: [
        Expanded(
          child: _buildMobileStatCard(
            'Total',
            totalPurchases.toString(),
            Icons.shopping_cart_outlined,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMobileStatCard(
            'Livrés',
            deliveredPurchases.toString(),
            Icons.check_circle_outlined,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMobileStatCard(
            'En attente',
            pendingPurchases.toString(),
            Icons.pending_outlined,
            Colors.orange,
          ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
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
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMobileSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Rechercher des achats...',
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
    );
  }

  Widget _buildMobilePurchasesList() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_filteredPurchases.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        ...(_paginatedPurchases.map(
          (purchase) => _buildMobilePurchaseCard(purchase),
        )),
        if (_totalPages > 1) _buildMobilePagination(),
      ],
    );
  }

  Widget _buildMobilePurchaseCard(dynamic purchase) {
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
              Expanded(
                child: Text(
                  purchase.supplier?['name'] ?? 'Fournisseur inconnu',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              _buildStatusChip(purchase),
            ],
          ),
          const SizedBox(height: 12),

          // Info Rows
          _buildMobileInfoRow(
            Icons.calendar_today,
            'Date',
            purchase.date ?? 'N/A',
          ),
          const SizedBox(height: 8),

          _buildMobileInfoRow(
            Icons.attach_money,
            'Montant',
            '${purchase.finalAmount?.toStringAsFixed(2) ?? '0.00'} DNT',
          ),
          const SizedBox(height: 8),

          _buildMobileInfoRow(
            Icons.person,
            'Créé par',
            purchase.createdBy?['name'] ?? 'Inconnu',
          ),

          if (purchase.status == 'delivered' &&
              purchase.deliveredBy != null) ...[
            const SizedBox(height: 8),
            _buildMobileInfoRow(
              Icons.local_shipping,
              'Livré par',
              purchase.deliveredBy['name'] ?? '',
            ),
          ],

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPurchaseDetails(context, purchase),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Détails'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              if (purchase.status != 'delivered' &&
                  _currentUserRole == 'manager')
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmDeliveryManager(purchase),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Confirmer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(dynamic purchase) {
    final isDelivered = purchase.status == 'delivered';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDelivered ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isDelivered ? 'Livré' : 'En attente',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
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
            onPressed:
                _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('$_currentPage / $_totalPages'),
          IconButton(
            onPressed:
                _currentPage < _totalPages
                    ? () => _goToPage(_currentPage + 1)
                    : null,
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
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: const Row(
        children: [
          Text(
            'Gestion des Achats',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Spacer(),
          AppHeader(isMobile: false),
        ],
      ),
    );
  }

  Widget _buildDesktopControls() {
    return Row(
      children: [
        // Search
        Expanded(
          flex: 2,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher des achats...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            onChanged: _onSearch,
          ),
        ),
        const SizedBox(width: 16),

        // Filter Button
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.filter_list),
          label: const Text('Filtrer'),
        ),
        const SizedBox(width: 16),

        // Add Button
        if (_currentUserRole == 'cashier' || _currentUserRole == 'admin')
          ElevatedButton.icon(
            onPressed: _showNewPurchaseForm,
            icon: const Icon(Icons.add),
            label: const Text('Nouvel Achat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
      ],
    );
  }

  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text(
                    'Fournisseur',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Montant',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Créé par',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Text(
                    'Statut',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(
                  width: 140,
                  child: Text(
                    'Actions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Table Body
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredPurchases.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                      itemCount: _paginatedPurchases.length,
                      separatorBuilder:
                          (_, __) =>
                              Divider(height: 1, color: Colors.grey[200]),
                      itemBuilder: (context, index) {
                        final purchase = _paginatedPurchases[index];
                        return _buildDesktopTableRow(purchase);
                      },
                    ),
          ),

          // Pagination
          if (!_loading && _filteredPurchases.isNotEmpty)
            _buildDesktopPagination(),
        ],
      ),
    );
  }

  Widget _buildDesktopTableRow(dynamic purchase) {
    return InkWell(
      onTap: () => _showPurchaseDetails(context, purchase),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    purchase.supplier?['name'] ?? 'Inconnu',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (purchase.supplier?['email'] != null)
                    Text(
                      purchase.supplier['email'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            ),
            Expanded(flex: 1, child: Text(purchase.date ?? 'N/A')),
            Expanded(
              flex: 1,
              child: Text(
                '${purchase.finalAmount?.toStringAsFixed(2) ?? '0.00'} DNT',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                purchase.createdBy?['name'] ?? 'Inconnu',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Expanded(
              flex: 1,
              child:
                  purchase.status == 'delivered'
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusChip(purchase),
                          if (purchase.deliveredBy != null)
                            Text(
                              'par ${purchase.deliveredBy['name']}',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                        ],
                      )
                      : _currentUserRole == 'manager'
                      ? InkWell(
                        onTap: () => _confirmDeliveryManager(purchase),
                        child: _buildStatusChip(purchase),
                      )
                      : _buildStatusChip(purchase),
            ),
            SizedBox(
              width: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 18),
                    onPressed: () => _showPurchaseDetails(context, purchase),
                    tooltip: 'Voir détails',
                    iconSize: 24,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _editPurchase(purchase),
                    tooltip: 'Modifier',
                    iconSize: 24,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: () => _deletePurchase(purchase),
                    tooltip: 'Supprimer',
                    iconSize: 24,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: const EdgeInsets.all(4),
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
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Affichage ${(_currentPage - 1) * _purchasesPerPage + 1} à ${(_currentPage * _purchasesPerPage).clamp(0, _filteredPurchases.length)} sur ${_filteredPurchases.length} résultats',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed:
                    _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                iconSize: 20,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
              ),
              ...List.generate((_totalPages > 5) ? 5 : _totalPages, (i) {
                final page = i + 1;
                return InkWell(
                  onTap: () => _goToPage(page),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          _currentPage == page
                              ? Colors.indigo
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$page',
                      style: TextStyle(
                        color:
                            _currentPage == page ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
              IconButton(
                onPressed:
                    _currentPage < _totalPages
                        ? () => _goToPage(_currentPage + 1)
                        : null,
                icon: const Icon(Icons.chevron_right),
                iconSize: 20,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
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
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun achat trouvé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez d\'ajuster vos critères de recherche',
              style: TextStyle(color: Colors.grey[500]),
            ),
            if (_currentUserRole == 'cashier') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showNewPurchaseForm,
                icon: const Icon(Icons.add),
                label: const Text('Créer le premier achat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showNewPurchaseForm() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: NewPurchaseForm(onSuccess: _fetchPurchases),
          ),
    );
  }

  void _showPurchaseDetails(BuildContext context, purchase) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Détails de l\'achat',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: FutureBuilder<List<PurchaseItem>>(
                    future: PurchaseService().fetchPurchaseItems(purchase.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text('Erreur: ${snapshot.error}'),
                          ),
                        );
                      }

                      final items = snapshot.data ?? [];

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Purchase info
                            _buildInfoCard(
                              icon: Icons.business,
                              title: 'Fournisseur',
                              value:
                                  purchase.supplier?['name'] ?? 'Non spécifié',
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    icon: Icons.calendar_today,
                                    title: 'Date',
                                    value: purchase.date,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInfoCard(
                                    icon: Icons.attach_money,
                                    title: 'Montant final',
                                    value: '${purchase.finalAmount} DNT',
                                    valueColor: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            _buildInfoCard(
                              icon: Icons.person,
                              title: 'Créé par',
                              value:
                                  purchase.createdBy?['name'] ?? 'Non spécifié',
                            ),

                            if (purchase.status == 'delivered' &&
                                purchase.deliveredBy != null) ...[
                              const SizedBox(height: 12),
                              _buildInfoCard(
                                icon: Icons.verified,
                                title: 'Livré par',
                                value: purchase.deliveredBy['name'] ?? '',
                                valueColor: Colors.green,
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Products section
                            Text(
                              'Produits achetés (${items.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (items.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text('Aucun produit'),
                                ),
                              )
                            else
                              ...items.map((item) => _buildProductItem(item)),

                            if (items.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => FactureDialog(
                                            purchase: purchase,
                                            items: items,
                                          ),
                                    );
                                  },
                                  icon: const Icon(Icons.print, size: 18),
                                  label: const Text('Imprimer'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(PurchaseItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory, color: Colors.indigo, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                Text(
                  'Entrepôt: ${item.warehouseName}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'x ${item.quantity}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${item.unitPrice.toStringAsFixed(2)} DNT',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
