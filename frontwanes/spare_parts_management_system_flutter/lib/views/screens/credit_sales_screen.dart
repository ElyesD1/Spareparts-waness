import 'package:flutter/material.dart';
import '../../models/domain/credit_sale.dart';
import '../../services/credit_sales_service.dart';
import '../../services/session_manager.dart';
import '../widgets/sidebar.dart';
import '../widgets/credit_sale_form_dialog.dart';
import '../widgets/credit_payment_form_dialog.dart';

class CreditSalesScreen extends StatefulWidget {
  const CreditSalesScreen({super.key});

  @override
  State<CreditSalesScreen> createState() => _CreditSalesScreenState();
}

class _CreditSalesScreenState extends State<CreditSalesScreen>
    with SingleTickerProviderStateMixin {
  List<CreditSale> _creditSales = [];
  List<CreditSale> _filteredCreditSales = [];
  bool _loading = true;
  String? _error;
  String? _currentUserRole;
  final TextEditingController _searchController = TextEditingController();
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
    _searchController.addListener(_filterCreditSales);
    _loadUserRole();
    _loadCreditSales();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final user = await SessionManager.getUser();
    if (user != null && mounted) {
      setState(() {
        _currentUserRole = user['role'] as String?;
      });
    }
  }

  Future<void> _loadCreditSales() async {
    try {
      if (mounted) {
        setState(() {
          _loading = true;
          _error = null;
        });
      }

      final creditSales = await CreditSalesService().getAllCreditSales();

      if (mounted) {
        setState(() {
          _creditSales = creditSales;
          _filteredCreditSales = creditSales;
          _loading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _filterCreditSales() {
    final query = _searchController.text.toLowerCase();
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          _filteredCreditSales = _creditSales;
        } else {
          _filteredCreditSales =
              _creditSales.where((sale) {
                return sale.customer.name.toLowerCase().contains(query) ||
                    sale.customer.phoneNumber.toLowerCase().contains(query) ||
                    sale.totalAmount.toString().contains(query) ||
                    sale.status.toLowerCase().contains(query);
              }).toList();
        }
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'active':
        return 'Actif';
      case 'completed':
        return 'Terminé';
      case 'overdue':
        return 'En retard';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      drawer:
          _isMobile(context)
              ? Drawer(child: Sidebar(selected: SidebarSection.creditSales))
              : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_isMobile(context)) {
            return _buildMobileContent();
          } else {
            return _buildDesktopContent();
          }
        },
      ),
    );
  }

  Widget _buildMobileContent() {
    return SafeArea(
      child: Column(
        children: [
          _buildMobileHeader(),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? _buildErrorState()
                    : Column(
                      children: [
                        _buildSearchBar(),
                        Expanded(
                          child:
                              _filteredCreditSales.isEmpty
                                  ? _buildEmptyState()
                                  : _buildCreditSalesList(),
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent() {
    return Row(
      children: [
        Sidebar(selected: SidebarSection.creditSales),
        Expanded(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child:
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                        ? _buildErrorState()
                        : _filteredCreditSales.isEmpty
                        ? _buildEmptyState()
                        : _buildCreditSalesList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Builder(
            builder:
                (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Ventes à Crédit',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCreditSales,
          ),
          if (_currentUserRole == 'admin' || _currentUserRole == 'cashier')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showCreditSaleForm,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Erreur: $_error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCreditSales,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  void _showCreditSaleForm() {
    showDialog(
      context: context,
      builder:
          (context) => CreditSaleFormDialog(
            onSuccess: () {
              if (mounted) {
                _loadCreditSales();
              }
            },
          ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.credit_card,
                  color: Color(0xFF6366F1),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ventes à Crédit',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Gérer les ventes à crédit et les paiements',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              if (_currentUserRole == 'admin' || _currentUserRole == 'cashier')
                ElevatedButton.icon(
                  onPressed: _showCreditSaleForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle Vente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadCreditSales,
                tooltip: 'Actualiser',
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher par client, téléphone, montant...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
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
          Icon(Icons.credit_card_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune vente à crédit',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Commencez par créer une vente à crédit'
                : 'Aucun résultat trouvé',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditSalesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredCreditSales.length,
      itemBuilder: (context, index) {
        final sale = _filteredCreditSales[index];
        return FadeTransition(
          opacity: _animationController,
          child: _buildCreditSaleCard(sale),
        );
      },
    );
  }

  Widget _buildCreditSaleCard(CreditSale sale) {
    final remainingAmount =
        sale.creditAmount -
        sale.payments.fold(0.0, (sum, payment) => sum + payment.amount);
    final paidAmount = sale.payments.fold(
      0.0,
      (sum, payment) => sum + payment.amount,
    );
    final progress =
        sale.creditAmount > 0
            ? (paidAmount / sale.creditAmount).clamp(0.0, 1.0)
            : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showSaleDetails(sale),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.customer.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sale.customer.phoneNumber,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
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
                      color: _getStatusColor(sale.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(sale.status),
                      style: TextStyle(
                        color: _getStatusColor(sale.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Montant Total',
                      '${sale.totalAmount.toStringAsFixed(2)} DT',
                      Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Acompte',
                      '${sale.downPayment.toStringAsFixed(2)} DT',
                      Icons.payment,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Crédit',
                      '${sale.creditAmount.toStringAsFixed(2)} DT',
                      Icons.credit_score,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Mensualité',
                      '${sale.monthlyPayment.toStringAsFixed(2)} DT',
                      Icons.calendar_today,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payé: ${paidAmount.toStringAsFixed(2)} DT',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        'Restant: ${remainingAmount.toStringAsFixed(2)} DT',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(sale.status),
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSaleDetails(CreditSale sale) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Détails de la Vente'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Client', sale.customer.name),
                  _buildDetailRow('Téléphone', sale.customer.phoneNumber),
                  const Divider(),
                  _buildDetailRow(
                    'Montant Total',
                    '${sale.totalAmount.toStringAsFixed(2)} DT',
                  ),
                  _buildDetailRow(
                    'Acompte',
                    '${sale.downPayment.toStringAsFixed(2)} DT',
                  ),
                  _buildDetailRow(
                    'Crédit',
                    '${sale.creditAmount.toStringAsFixed(2)} DT',
                  ),
                  const Divider(),
                  _buildDetailRow(
                    'Mensualité',
                    '${sale.monthlyPayment.toStringAsFixed(2)} DT',
                  ),
                  _buildDetailRow(
                    'Nb. Mensualités',
                    '${sale.installmentCount}',
                  ),
                  _buildDetailRow(
                    'Date 1er Paiement',
                    sale.firstPaymentDate.toString().split(' ')[0],
                  ),
                  const Divider(),
                  _buildDetailRow('Statut', _getStatusLabel(sale.status)),
                  if (sale.notes != null && sale.notes!.isNotEmpty)
                    _buildDetailRow('Notes', sale.notes!),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
              if (_currentUserRole == 'admin' || _currentUserRole == 'cashier')
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showPaymentForm(sale);
                  },
                  icon: const Icon(Icons.payment),
                  label: const Text('Ajouter Paiement'),
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
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Color(0xFF1F2937)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentForm(CreditSale sale) {
    showDialog(
      context: context,
      builder:
          (context) => CreditPaymentFormDialog(
            creditSale: sale,
            onSuccess: () {
              if (mounted) {
                _loadCreditSales();
              }
            },
          ),
    );
  }
}
