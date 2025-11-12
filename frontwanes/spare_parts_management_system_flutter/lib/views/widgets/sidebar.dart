import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:spare_parts_management_system_flutter/services/session_manager.dart';

enum SidebarSection {
  dashboard,
  market,
  products,
  warehouses,
  stockMovements,
  productTransfers,
  purchases,
  sales,
  creditSales,
  purchaseReturns,
  productStocks,
  saleItems,
  users,
  suppliers,
  customers,
  operationalExpenses,
  otpSecurity,
  settings,
}

class Sidebar extends StatefulWidget {
  final SidebarSection selected;
  const Sidebar({Key? key, required this.selected}) : super(key: key);

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = await SessionManager.getUser();
    if (user != null) {
      setState(() {
        userRole = user['role'] as String?;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[SIDEBAR] Build - selected: ${widget.selected}');
    // Build role-based items
    final List<_SidebarItem> menuItems = _buildMenuItems(context);
    return Container(
      width: 220,
      color: const Color(0xFFF8F9FB),
      child: Column(
        children: [
          const SizedBox(height: 32),
          if (userRole == 'admin')
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.dashboard, color: Colors.deepPurple, size: 32),
                SizedBox(width: 8),
                Text('Tableau de bord', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.deepPurple)),
              ],
            ),
          // Debug: Show current user role
          if (userRole != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Rôle: $userRole',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: _SidebarSection(title: 'MAIN', items: menuItems),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<_SidebarItem> _buildMenuItems(BuildContext context) {
    List<_SidebarItem> items = [];
    void add(SidebarSection section, IconData icon, String label, String route) {
      items.add(_SidebarItem(
        icon: icon,
        label: label,
        selected: widget.selected == section,
        onTap: () => GoRouter.of(context).go(route),
      ));
    }
    
    // Debug: Show current user role
    print('[SIDEBAR] Current user role: $userRole');
    
    if (userRole == 'guest') {
      // Guest users only have access to the market
      add(SidebarSection.market, Icons.storefront, 'Market', '/market');
    } else if (userRole == 'cashier') {
      add(SidebarSection.sales, Icons.point_of_sale, 'Ventes', '/sales');
      add(SidebarSection.purchases, Icons.shopping_cart, 'Achats', '/purchases');
      add(SidebarSection.products, Icons.inventory_2, 'Produits', '/products');
      add(SidebarSection.productStocks, Icons.storage, 'Stocks Produits', '/product-stocks');
      add(SidebarSection.suppliers, Icons.local_shipping, 'Fournisseurs', '/suppliers');
      add(SidebarSection.customers, Icons.people, 'Clients', '/customers');
      // TEMPORARY: Add purchase returns for testing
      add(SidebarSection.purchaseReturns, Icons.assignment_return, 'Retours Achats', '/purchase-returns');
    } else if (userRole == 'manager') {
      add(SidebarSection.purchases, Icons.shopping_cart, 'Achats', '/purchases');
      add(SidebarSection.productStocks, Icons.storage, 'Stocks Produits', '/product-stocks');
      // TEMPORARY: Add purchase returns for testing
      add(SidebarSection.purchaseReturns, Icons.assignment_return, 'Retours Achats', '/purchase-returns');
    } else {
      // Admin (default) full access
      add(SidebarSection.dashboard, Icons.dashboard, 'Tableau de bord', '/');
      add(SidebarSection.products, Icons.inventory_2, 'Produits', '/products');
      add(SidebarSection.warehouses, Icons.home_work, 'Entrepôts', '/warehouses');
      add(SidebarSection.stockMovements, Icons.swap_horiz, 'Mouvements Stock', '/stock-movement-list');
      add(SidebarSection.productTransfers, Icons.transfer_within_a_station, 'Transferts Produits', '/product-transfers');
      add(SidebarSection.purchases, Icons.shopping_cart, 'Achats', '/purchases');
      add(SidebarSection.sales, Icons.point_of_sale, 'Ventes', '/sales');
      add(SidebarSection.creditSales, Icons.credit_card, 'Ventes à Crédit', '/credit-sales');
      add(SidebarSection.purchaseReturns, Icons.assignment_return, 'Retours Achats', '/purchase-returns');
      add(SidebarSection.productStocks, Icons.storage, 'Stocks Produits', '/product-stocks');
      add(SidebarSection.saleItems, Icons.list_alt, 'Articles Ventes', '/sale-items');
      add(SidebarSection.suppliers, Icons.local_shipping, 'Fournisseurs', '/suppliers');
      add(SidebarSection.customers, Icons.people, 'Clients', '/customers');
      add(SidebarSection.operationalExpenses, Icons.account_balance_wallet, 'Dépenses', '/operational-expenses');
      add(SidebarSection.users, Icons.people, 'Utilisateurs', '/users');
    }
    return items;
  }
}

class _SidebarSection extends StatelessWidget {
  final String title;
  final List<_SidebarItem> items;
  const _SidebarSection({required this.title, required this.items});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ...items,
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SidebarItem({required this.icon, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: selected ? Colors.deepPurple.withOpacity(0.08) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: selected ? Colors.deepPurple : Colors.grey[700]),
        title: Text(label, style: TextStyle(color: selected ? Colors.deepPurple : Colors.grey[800], fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
} 