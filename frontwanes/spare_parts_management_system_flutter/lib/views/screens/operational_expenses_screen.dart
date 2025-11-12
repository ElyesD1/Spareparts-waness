import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/domain/operational_expense.dart';
import '../../services/operational_expense_service.dart';
import '../../services/session_manager.dart';
import '../widgets/operational_expense_form.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_toast.dart';

class OperationalExpensesScreen extends StatefulWidget {
  const OperationalExpensesScreen({Key? key}) : super(key: key);

  @override
  State<OperationalExpensesScreen> createState() =>
      _OperationalExpensesScreenState();
}

class _OperationalExpensesScreenState extends State<OperationalExpensesScreen> with TickerProviderStateMixin {
  List<OperationalExpense> _expenses = [];
  List<OperationalExpense> _filteredExpenses = [];
  bool _loading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String? _currentUserRole;
  late AnimationController _animationController;

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
    _searchController.addListener(_filterExpenses);
    _loadUserRole();
    _loadExpenses();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final user = await SessionManager.getUser();
    if (user != null) {
      setState(() {
        _currentUserRole = user['role'] as String?;
      });
    }
  }

  Future<void> _loadExpenses() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final expenses = await OperationalExpenseService.getOperationalExpenses();

      if (expenses.isNotEmpty) {
        final firstExpense = expenses.first;
      
      }

      setState(() {
        _expenses = expenses;
        _filteredExpenses = expenses;
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

  void _filterExpenses() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredExpenses = _expenses;
      } else {
        _filteredExpenses = _expenses.where((expense) {
          return expense.title.toLowerCase().contains(query) ||
              expense.type.toLowerCase().contains(query) ||
              (expense.warehouseName?.toLowerCase().contains(query) ?? false) ||
              expense.amount.toString().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // ✅ DRAWER FOR MOBILE - SIDEBAR EXISTS HERE!
      drawer: _isMobile(context) ? Drawer(
        child: Sidebar(selected: SidebarSection.operationalExpenses),
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
                : _error != null
                    ? _buildErrorState()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Stats Grid
                            _buildMobileStats(),
                            const SizedBox(height: 20),
                            
                            // Search Bar
                            _buildMobileSearchBar(),
                            const SizedBox(height: 20),
                            
                            // Expenses List
                            _buildMobileExpensesList(),
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
        Sidebar(selected: SidebarSection.operationalExpenses),
        
        // Main Content
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
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
                                    // Stats Row
                                    _buildDesktopStats(),
                                    const SizedBox(height: 32),
                                    
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

  Widget _buildMobileHeaderWithMenu() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.indigo.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
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
                  'Dépenses Opérationnelles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Suivi et gestion des dépenses',
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
              onPressed: () => _showExpenseForm(),
              icon: const Icon(Icons.add, color: Colors.white, size: 24),
              tooltip: 'Ajouter dépense',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStats() {
    final totalExpenses = _expenses.length;
    final totalAmount = _expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final avgAmount = totalExpenses > 0 ? totalAmount / totalExpenses : 0.0;
    final thisMonthExpenses = _expenses.where((expense) {
      final now = DateTime.now();
      final expenseDate = expense.date;
      return expenseDate.year == now.year && expenseDate.month == now.month;
    }).length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildMobileStatCard(
          'Total',
          totalExpenses.toString(),
          Icons.receipt_long_outlined,
          Colors.blue,
        ),
        _buildMobileStatCard(
          'Montant',
          '${totalAmount.toStringAsFixed(0)} DNT',
          Icons.attach_money_outlined,
          Colors.green,
        ),
        _buildMobileStatCard(
          'Moyenne',
          '${avgAmount.toStringAsFixed(0)} DNT',
          Icons.analytics_outlined,
          Colors.orange,
        ),
        _buildMobileStatCard(
          'Ce mois',
          thisMonthExpenses.toString(),
          Icons.calendar_month_outlined,
          Colors.purple,
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

  Widget _buildMobileSearchBar() {
    return Container(
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
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher des dépenses...',
          prefixIcon: Icon(Icons.search, color: Colors.indigo.shade300),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[400]),
                  onPressed: () {
                    _searchController.clear();
                    _filterExpenses();
                  },
                )
              : null,
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildMobileExpensesList() {
    if (_filteredExpenses.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: _filteredExpenses.map((expense) => _buildMobileExpenseCard(expense)).toList(),
    );
  }

  Widget _buildMobileExpenseCard(OperationalExpense expense) {
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.account_balance_wallet, color: Colors.indigo, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  expense.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              _buildTypeBadge(expense.type),
            ],
          ),
          const SizedBox(height: 16),
          
          // Amount Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.attach_money, color: Colors.green, size: 24),
                Text(
                  '${expense.amount.toStringAsFixed(2)} DNT',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Info Rows
          _buildMobileInfoRow(
            Icons.location_on_outlined,
            'Entrepôt',
            expense.warehouseName ?? 'Chargement...',
          ),
          const SizedBox(height: 12),
          _buildMobileInfoRow(
            Icons.person_outline,
            'Créé par',
            expense.createdByName ?? 'Chargement...',
          ),
          const SizedBox(height: 12),
          _buildMobileInfoRow(
            Icons.calendar_today_outlined,
            'Date',
            '${expense.date.day}/${expense.date.month}/${expense.date.year}',
          ),
          
          if (expense.note != null && expense.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildMobileInfoRow(
              Icons.note_outlined,
              'Note',
              expense.note!,
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showExpenseDetails(expense),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Détails'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.indigo.shade300),
                    foregroundColor: Colors.indigo.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showExpenseForm(expense),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Modifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
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
              color: Colors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.indigo.shade600),
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
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: value.contains('Chargement') || value.contains('Loading') || value.contains('Unknown')
                    ? Colors.orange.shade600
                    : const Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade600, Colors.indigo.shade800],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dépenses Opérationnelles',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gérer et suivre les dépenses opérationnelles',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showExpenseForm(),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter Dépense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopStats() {
    final totalExpenses = _expenses.length;
    final totalAmount = _expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final avgAmount = totalExpenses > 0 ? totalAmount / totalExpenses : 0.0;
    final thisMonthExpenses = _expenses.where((expense) {
      final now = DateTime.now();
      final expenseDate = expense.date;
      return expenseDate.year == now.year && expenseDate.month == now.month;
    }).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 900) {
          return Column(
            children: [
              Row(
                children: [
                  _buildDesktopStatCard('Total Dépenses', totalExpenses.toString(), Icons.receipt_long, Colors.blue),
                  const SizedBox(width: 20),
                  _buildDesktopStatCard('Montant Total', '${totalAmount.toStringAsFixed(2)} DNT', Icons.attach_money, Colors.green),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildDesktopStatCard('Montant Moyen', '${avgAmount.toStringAsFixed(2)} DNT', Icons.analytics, Colors.orange),
                  const SizedBox(width: 20),
                  _buildDesktopStatCard('Ce Mois', thisMonthExpenses.toString(), Icons.calendar_month, Colors.purple),
                ],
              ),
            ],
          );
        } else {
          return Row(
            children: [
              _buildDesktopStatCard('Total Dépenses', totalExpenses.toString(), Icons.receipt_long, Colors.blue),
              const SizedBox(width: 20),
              _buildDesktopStatCard('Montant Total', '${totalAmount.toStringAsFixed(2)} DNT', Icons.attach_money, Colors.green),
              const SizedBox(width: 20),
              _buildDesktopStatCard('Montant Moyen', '${avgAmount.toStringAsFixed(2)} DNT', Icons.analytics, Colors.orange),
              const SizedBox(width: 20),
              _buildDesktopStatCard('Ce Mois', thisMonthExpenses.toString(), Icons.calendar_month, Colors.purple),
            ],
          );
        }
      },
    );
  }

  Widget _buildDesktopStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
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
                        '+8.2%',
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
      ),
    );
  }

  Widget _buildDesktopContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Liste des Dépenses',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Spacer(),
                
                // Search Bar
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: Icon(Icons.search, color: Colors.indigo.shade300, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey[400]),
                              onPressed: () {
                                _searchController.clear();
                                _filterExpenses();
                              },
                            )
                          : null,
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Results count
                Text(
                  '${_filteredExpenses.length} dépenses',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          
          // Content
          Container(
            constraints: const BoxConstraints(minHeight: 400),
            child: _filteredExpenses.isEmpty
                ? _buildEmptyState()
                : _buildDesktopExpensesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopExpensesList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredExpenses.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
      itemBuilder: (context, index) {
        return _buildDesktopExpenseRow(_filteredExpenses[index]);
      },
    );
  }

  Widget _buildDesktopExpenseRow(OperationalExpense expense) {
    return InkWell(
      onTap: () => _showExpenseDetails(expense),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: Colors.indigo,
                size: 24,
              ),
            ),
            const SizedBox(width: 20),
            
            // Main Info
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        expense.warehouseName ?? 'Chargement...',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Type Badge
            Expanded(
              flex: 1,
              child: _buildTypeBadge(expense.type),
            ),
            
            // Date
            Expanded(
              flex: 1,
              child: Text(
                '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            
            // Amount
            Expanded(
              flex: 1,
              child: Text(
                '${expense.amount.toStringAsFixed(2)} DNT',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            
            // Created By
            Expanded(
              flex: 1,
              child: Text(
                expense.createdByName ?? 'Chargement...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Actions
            SizedBox(
              width: 120,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 18),
                    onPressed: () => _showExpenseDetails(expense),
                    tooltip: 'Voir détails',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _showExpenseForm(expense),
                    tooltip: 'Modifier',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: () => _deleteExpense(expense),
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

  Widget _buildTypeBadge(String type) {
    Color color;
    IconData icon;

    switch (type) {
      case 'rent':
        color = Colors.blue;
        icon = Icons.home;
        break;
      case 'electricity':
        color = Colors.orange;
        icon = Icons.electric_bolt;
        break;
      case 'water':
        color = Colors.cyan;
        icon = Icons.water_drop;
        break;
      case 'fuel':
        color = Colors.red;
        icon = Icons.local_gas_station;
        break;
      case 'other':
        color = Colors.grey;
        icon = Icons.more_horiz;
        break;
      default:
        color = Colors.grey;
        icon = Icons.category;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            type.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
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
              _error!,
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadExpenses,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
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
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune dépense trouvée',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajoutez votre première dépense opérationnelle pour commencer',
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showExpenseForm(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter Dépense'),
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

  Future<void> _deleteExpense(OperationalExpense expense) async {
    final confirmed = await showDialog<bool>(
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
            const Text('Supprimer Dépense'),
          ],
        ),
        content: Text('Êtes-vous sûr de vouloir supprimer "${expense.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
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
        await OperationalExpenseService.deleteOperationalExpense(expense.id!);
        AppToast.success(context, 'Dépense supprimée avec succès');
        _loadExpenses();
      } catch (e) {
        AppToast.error(context, 'Erreur lors de la suppression: $e');
      }
    }
  }

  void _showExpenseForm([OperationalExpense? expense]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OperationalExpenseForm(
        expense: expense,
        onSuccess: () {
          Navigator.of(context).pop();
          _loadExpenses();
        },
      ),
    );
  }

  void _showExpenseDetails(OperationalExpense expense) {
   

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.indigo,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Détails de la Dépense'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Titre', expense.title),
            _buildDetailRow(
              'Montant',
              '${expense.amount.toStringAsFixed(2)} DNT',
            ),
            _buildDetailRow('Type', expense.type.toUpperCase()),
            _buildDetailRow(
              'Entrepôt',
              expense.warehouseName ?? 'Chargement...',
            ),
            _buildDetailRow(
              'Créé par',
              expense.createdByName ?? 'Chargement...',
            ),
            _buildDetailRow(
              'Date',
              '${expense.date.day}/${expense.date.month}/${expense.date.year}',
            ),
            if (expense.note != null && expense.note!.isNotEmpty)
              _buildDetailRow('Note', expense.note!),
            // Show warehouse info if it's still unknown
            if (expense.warehouseName != null &&
                expense.warehouseName!.startsWith('Unknown Warehouse')) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nom d\'entrepôt introuvable dans la base de données pour l\'ID ${expense.warehouseId}',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
              _showExpenseForm(expense);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }
}