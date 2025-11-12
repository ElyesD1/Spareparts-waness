import 'package:flutter/material.dart';
import '../../models/domain/purchase_return.dart';
import '../../services/purchase_return_service.dart';
import '../../services/session_manager.dart';
import '../widgets/purchase_return_form.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_toast.dart';

class PurchaseReturnsScreen extends StatefulWidget {
  const PurchaseReturnsScreen({Key? key}) : super(key: key);

  @override
  State<PurchaseReturnsScreen> createState() => _PurchaseReturnsScreenState();
}

class _PurchaseReturnsScreenState extends State<PurchaseReturnsScreen>
    with TickerProviderStateMixin {
  List<PurchaseReturn> _returns = [];
  List<PurchaseReturn> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  ReturnStatus? _statusFilter;
  Map<String, dynamic>? _currentUser;
  String? _userRole;
  late AnimationController _animationController;

  // Responsive breakpoints
  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;
  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _searchCtrl.addListener(_applyFilter);
    _loadUserAndData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndData() async {
    try {
      final user = await SessionManager.getUser();
      setState(() {
        _currentUser = user;
        _userRole = user?['role']?.toString().toLowerCase();
      });
      await _load();
    } catch (e) {
      print('Error loading user: $e');
      await _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await PurchaseReturnService.getPurchaseReturns(
        status: _statusFilter?.name,
      );
      setState(() {
        _returns = data;
        _filtered = data;
        _loading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _returns;
      } else {
        _filtered =
            _returns
                .where(
                  (r) =>
                      r.reason.toLowerCase().contains(q) ||
                      (r.supplierName?.toLowerCase().contains(q) ?? false) ||
                      (r.warehouseName?.toLowerCase().contains(q) ?? false) ||
                      r.totalAmount.toString().contains(q),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: _isMobile(context) ? Drawer(
        child: Sidebar(selected: SidebarSection.purchaseReturns),
      ) : null,
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
          // Mobile Header
          _buildMobileHeader(),

          // Content
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? _buildErrorState()
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Stats if manager/admin
                          if (_userRole == 'manager' ||
                              _userRole == 'admin') ...[
                            _buildMobileStats(),
                            const SizedBox(height: 20),
                          ],

                          // Search and Filters
                          _buildMobileSearchAndFilters(),
                          const SizedBox(height: 20),

                          // Returns List
                          _buildMobileReturnsList(),
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
        // SIDEBAR - Only on desktop/tablet
        Sidebar(selected: SidebarSection.purchaseReturns),

        // Main Content
        Expanded(
          child:
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _buildErrorState()
                  : AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          20 * (1 - _animationController.value),
                        ),
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
                          // Desktop Header
                          _buildDesktopHeader(),

                          // Main Content
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  // Stats if manager/admin
                                  if (_userRole == 'manager' ||
                                      _userRole == 'admin') ...[
                                    _buildDesktopStats(),
                                    const SizedBox(height: 32),
                                  ],

                                  // Content Area
                                  _buildDesktopContent(),
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

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange, Colors.orange.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Hamburger Menu Button
          Builder(
            builder: (BuildContext context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 24),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menu',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Retours d\'Achat',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _userRole != null
                      ? 'Rôle: ${_userRole!.toUpperCase()}'
                      : 'Gestion des retours',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (_canCreateReturns())
            FloatingActionButton(
              onPressed: () => _openForm(),
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange,
              elevation: 0,
              child: const Icon(Icons.add),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileStats() {
    final totalReturns = _returns.length;
    final pendingReturns =
        _returns.where((r) => r.status == ReturnStatus.PENDING).length;
    final approvedReturns =
        _returns.where((r) => r.status == ReturnStatus.APPROVED).length;
    final totalValue = _returns.fold(0.0, (sum, r) => sum + r.totalAmount);

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
          totalReturns.toString(),
          Icons.assignment_return_outlined,
          Colors.blue,
        ),
        _buildMobileStatCard(
          'En attente',
          pendingReturns.toString(),
          Icons.pending_outlined,
          Colors.orange,
        ),
        _buildMobileStatCard(
          'Approuvés',
          approvedReturns.toString(),
          Icons.check_circle_outlined,
          Colors.green,
        ),
        _buildMobileStatCard(
          'Valeur',
          '${totalValue.toStringAsFixed(0)} DNT',
          Icons.monetization_on_outlined,
          Colors.purple,
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
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Rechercher des retours...',
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
        ),
        const SizedBox(height: 12),

        // Status Filter
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ReturnStatus?>(
              value: _statusFilter,
              isExpanded: true,
              hint: const Text('Tous les statuts'),
              items: [
                const DropdownMenuItem<ReturnStatus?>(
                  value: null,
                  child: Text('Tous'),
                ),
                ...ReturnStatus.values.map(
                  (e) => DropdownMenuItem(value: e, child: Text(e.displayName)),
                ),
              ],
              onChanged: (v) {
                setState(() => _statusFilter = v);
                _load();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileReturnsList() {
    if (_filtered.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children:
          _filtered
              .map((returnItem) => _buildMobileReturnCard(returnItem))
              .toList(),
    );
  }

  Widget _buildMobileReturnCard(PurchaseReturn returnItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: returnItem.status.color.withOpacity(0.2)),
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
                  color: returnItem.status.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.assignment_return,
                  color: returnItem.status.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  returnItem.reason,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusBadge(returnItem.status),
            ],
          ),
          const SizedBox(height: 12),

          // Info Rows
          _buildMobileInfoRow(
            Icons.local_shipping,
            'Fournisseur',
            returnItem.supplierName ?? 'Non défini',
          ),
          const SizedBox(height: 8),

          _buildMobileInfoRow(
            Icons.home_work,
            'Entrepôt',
            returnItem.warehouseName ?? 'Non défini',
          ),
          const SizedBox(height: 8),

          _buildMobileInfoRow(
            Icons.calendar_today,
            'Date de retour',
            returnItem.returnDate.toIso8601String().split('T')[0],
          ),
          const SizedBox(height: 8),

          _buildMobileInfoRow(
            Icons.attach_money,
            'Montant total',
            '${returnItem.totalAmount.toStringAsFixed(2)} DNT',
          ),

          if (returnItem.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _buildMobileInfoRow(Icons.note, 'Notes', returnItem.notes!),
          ],

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openForm(returnItem),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Détails'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Status-based actions
              if (returnItem.status == ReturnStatus.PENDING &&
                  _canApproveReturns())
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveReturn(returnItem),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approuver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                    ),
                  ),
                ),

              if (returnItem.status == ReturnStatus.APPROVED &&
                  _canCompleteReturns())
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _completeReturn(returnItem),
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Compléter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
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
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.assignment_return, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestion des Retours d\'Achat',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (_userRole != null)
                  Text(
                    'Rôle: ${_userRole!.toUpperCase()}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          if (_canCreateReturns())
            ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau Retour'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopStats() {
    final totalReturns = _returns.length;
    final pendingReturns =
        _returns.where((r) => r.status == ReturnStatus.PENDING).length;
    final approvedReturns =
        _returns.where((r) => r.status == ReturnStatus.APPROVED).length;
    final totalValue = _returns.fold(0.0, (sum, r) => sum + r.totalAmount);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Aperçu des Statistiques',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats Row
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 800) {
                return Column(
                  children: [
                    Row(
                      children: [
                        _buildDesktopStatCard(
                          'Total Retours',
                          totalReturns.toString(),
                          Icons.assignment_return,
                          Colors.blue,
                        ),
                        const SizedBox(width: 16),
                        _buildDesktopStatCard(
                          'En Attente',
                          pendingReturns.toString(),
                          Icons.pending,
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildDesktopStatCard(
                          'Approuvés',
                          approvedReturns.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                        const SizedBox(width: 16),
                        _buildDesktopStatCard(
                          'Valeur Totale',
                          '${totalValue.toStringAsFixed(2)} DNT',
                          Icons.attach_money,
                          Colors.purple,
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    _buildDesktopStatCard(
                      'Total Retours',
                      totalReturns.toString(),
                      Icons.assignment_return,
                      Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    _buildDesktopStatCard(
                      'En Attente',
                      pendingReturns.toString(),
                      Icons.pending,
                      Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    _buildDesktopStatCard(
                      'Approuvés',
                      approvedReturns.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _buildDesktopStatCard(
                      'Valeur Totale',
                      '${totalValue.toStringAsFixed(2)} DNT',
                      Icons.attach_money,
                      Colors.purple,
                    ),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 20),

          // Credit Workflow Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workflow des Crédits',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lorsque les retours sont approuvés: Stock réduit → Crédits créés → Crédits appliqués automatiquement aux futurs achats',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 12,
                        ),
                      ),
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

  Widget _buildDesktopStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
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
                  'Liste des Retours',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Spacer(),

                // Search Bar
                Container(
                  width: 250,
                  height: 40,
                  child: TextField(
                    controller: _searchCtrl,
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Status Filter
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ReturnStatus?>(
                      value: _statusFilter,
                      hint: const Text('Statut'),
                      items: [
                        const DropdownMenuItem<ReturnStatus?>(
                          value: null,
                          child: Text('Tous'),
                        ),
                        ...ReturnStatus.values.map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.displayName),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _statusFilter = v);
                        _load();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Container(
            constraints: const BoxConstraints(minHeight: 400),
            child:
                _filtered.isEmpty
                    ? _buildEmptyState()
                    : _buildDesktopReturnsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopReturnsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
      itemBuilder: (context, index) {
        return _buildDesktopReturnRow(_filtered[index]);
      },
    );
  }

  Widget _buildDesktopReturnRow(PurchaseReturn returnItem) {
    return InkWell(
      onTap: () => _openForm(returnItem),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: returnItem.status.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.assignment_return,
                color: returnItem.status.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),

            // Main Info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    returnItem.reason,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        returnItem.supplierName ?? 'Fournisseur',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.home_work, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        returnItem.warehouseName ?? 'Entrepôt',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Date
            Expanded(
              flex: 1,
              child: Text(
                returnItem.returnDate.toIso8601String().split('T')[0],
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),

            // Amount
            Expanded(
              flex: 1,
              child: Text(
                '${returnItem.totalAmount.toStringAsFixed(2)} DNT',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ),

            // Status
            Expanded(flex: 1, child: _buildStatusBadge(returnItem.status)),

            // Actions
            SizedBox(width: 120, child: _buildActionButtons(returnItem)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ReturnStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PurchaseReturn returnItem) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleAction(value, returnItem),
      itemBuilder: (_) {
        final items = <PopupMenuEntry<String>>[];

        // Status-based actions with role permissions
        if (returnItem.status == ReturnStatus.PENDING) {
          if (_canApproveReturns()) {
            items.add(
              const PopupMenuItem(
                value: 'approve',
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text('Approuver'),
                  ],
                ),
              ),
            );
          }
          if (_canRejectReturns()) {
            items.add(
              const PopupMenuItem(
                value: 'reject',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text('Rejeter'),
                  ],
                ),
              ),
            );
          }
        }

        if (returnItem.status == ReturnStatus.APPROVED &&
            _canCompleteReturns()) {
          items.add(
            const PopupMenuItem(
              value: 'complete',
              child: Row(
                children: [
                  Icon(Icons.done_all, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Text('Marquer comme Complété'),
                ],
              ),
            ),
          );
        }

        if (_canEditReturns()) {
          items.add(
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
          );
        }

        return items;
      },
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
                color: Colors.red[300],
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
              _error!,
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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
                Icons.assignment_return_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun retour trouvé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez d\'ajuster vos filtres ou créez un nouveau retour',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            if (_canCreateReturns()) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: const Text('Créer le premier retour'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
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

  // Helper methods
  void _openForm([PurchaseReturn? r]) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 600;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final dialogChild = PurchaseReturnForm(
          returnItem: r,
          onSuccess: () {
            Navigator.pop(context);
            _load();
          },
        );
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 900,
              maxHeight: MediaQuery.of(context).size.height - 80,
            ),
            child: SafeArea(
              child: isSmall
                  ? SingleChildScrollView(child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: dialogChild,
                    ))
                  : SizedBox(width: 800, child: dialogChild),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleAction(String action, PurchaseReturn returnItem) async {
    try {
      switch (action) {
        case 'approve':
          await _approveReturn(returnItem);
          break;
        case 'reject':
          await _rejectReturn(returnItem);
          break;
        case 'complete':
          await _completeReturn(returnItem);
          break;
        case 'edit':
          _openForm(returnItem);
          return; // Don't reload yet
      }
      _load(); // Reload after action
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Action échouée: $e');
      }
    }
  }

  Future<void> _approveReturn(PurchaseReturn returnItem) async {
    try {
      await PurchaseReturnService.approve(returnItem.id!);
      await _load(); // Reload data to update UI
      if (mounted) {
        AppToast.success(context, 'Retour approuvé avec succès!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Échec de l\'approbation: $e');
      }
    }
  }

  Future<void> _rejectReturn(PurchaseReturn returnItem) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) {
        final ctrl = TextEditingController();
        final content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez fournir une raison pour rejeter ce retour:'),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        );
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.of(context).size.height - 80,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Rejeter le Retour', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    content,
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, ctrl.text.trim()),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Rejeter'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await PurchaseReturnService.reject(returnItem.id!, reason);
        await _load(); // Reload data to update UI
        if (mounted) {
          AppToast.success(context, 'Retour rejeté avec succès!');
        }
      } catch (e) {
        if (mounted) {
          AppToast.error(context, 'Échec du rejet: $e');
        }
      }
    }
  }

  Future<void> _completeReturn(PurchaseReturn returnItem) async {
    try {
      await PurchaseReturnService.complete(returnItem.id!);
      await _load(); // Reload data to update UI
      if (mounted) {
        AppToast.success(context, 'Retour complété avec succès! Mouvements de stock créés et stock réduit de ${returnItem.totalAmount.toStringAsFixed(2)} DNT');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Échec de la complétion: $e');
      }
    }
  }

  // Permission methods
  bool _canCreateReturns() {
    return _userRole == 'manager' ||
        _userRole == 'cashier' ||
        _userRole == 'admin';
  }

  bool _canApproveReturns() {
    return _userRole == 'manager' || _userRole == 'admin';
  }

  bool _canRejectReturns() {
    return _userRole == 'manager' || _userRole == 'admin';
  }

  bool _canCompleteReturns() {
    return _userRole == 'manager' ||
        _userRole == 'cashier' ||
        _userRole == 'admin';
  }

  bool _canEditReturns() {
    return _userRole == 'manager' ||
        _userRole == 'cashier' ||
        _userRole == 'admin';
  }
}