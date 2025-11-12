import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'products_screen.dart';
import '../widgets/product_form.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/domain/user.dart';
import '../../models/domain/product_stock.dart';
import 'dart:convert';
import '../../services/supplier_service.dart';
import '../../services/purchase_service.dart';
import '../../services/product_service.dart';
import 'dart:math' as math;
import '../widgets/sidebar.dart';
import '../widgets/responsive_profile_button.dart';
import '../../services/sales_service.dart';
import '../../services/sale_item_service.dart';
import '../../services/credit_sales_service.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Responsive breakpoints
  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;
  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  int _selectedYear = DateTime.now().year;

  List<int> get _yearOptions {
    final current = DateTime.now().year;
    return List.generate(6, (i) => current - i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      // Add drawer for mobile
      drawer:
          _isMobile(context)
              ? Drawer(child: Sidebar(selected: SidebarSection.dashboard))
              : null,
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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMobileHeaderWithMenu(),
              const SizedBox(height: 20),
              // Mobile year filter below header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    const Text('Année'),
                    const Spacer(),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        items:
                            _yearOptions
                                .map(
                                  (y) => DropdownMenuItem<int>(
                                    value: y,
                                    child: Text(y.toString()),
                                  ),
                                )
                                .toList(),
                        onChanged: (y) {
                          if (y != null) setState(() => _selectedYear = y);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildStatsGrid(),
              const SizedBox(height: 20),
              _buildSalesChartMobile(),
              const SizedBox(height: 20),
              _buildTopProductsMobile(),
              const SizedBox(height: 20),
              _buildProfitCategoryMobile(),
              const SizedBox(height: 20),
              _buildLowStockAlertsMobile(),
              const SizedBox(height: 20),
              _buildRecentPurchasesMobile(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMobileHeader(),
              const SizedBox(height: 20),
              _buildStatsGrid(),
              const SizedBox(height: 20),
              _buildSalesChartMobile(),
              const SizedBox(height: 20),
              _buildTopProductsMobile(),
              const SizedBox(height: 20),
              _buildProfitCategoryMobile(),
              const SizedBox(height: 20),
              _buildLowStockAlertsMobile(),
              const SizedBox(height: 20),
              _buildRecentPurchasesMobile(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Sidebar(selected: SidebarSection.dashboard),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(
                    selectedYear: _selectedYear,
                    yearOptions: _yearOptions,
                    onYearChanged: (y) => setState(() => _selectedYear = y),
                  ),
                  const SizedBox(height: 24),
                  _DashboardStatsRow(selectedYear: _selectedYear),
                  const SizedBox(height: 24),
                  _DashboardChartsRow(selectedYear: _selectedYear),
                  const SizedBox(height: 24),
                  _ProfitByCategoryChart(),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 800) {
                        return Column(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Derniers achats',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _RecentPurchasesTable(),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Alertes stock faible',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _LowStockAlertsCard(),
                              ],
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Derniers achats',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _RecentPurchasesTable(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Alertes stock faible',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _LowStockAlertsCard(),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Mobile-specific widgets
  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.deepPurple.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FutureBuilder<User?>(
                future: _loadUser(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  return Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        radius: 25,
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            user?.name ?? 'Utilisateur',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => GoRouter.of(context).go('/profile'),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Tableau de bord',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vue d\'ensemble de votre entrepôt',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Hamburger menu button
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
                FutureBuilder<User?>(
                  future: _loadUser(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    return Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          radius: 20,
                          child: Text(
                            user?.name.isNotEmpty == true
                                ? user!.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bonjour',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            Text(
                              user?.name ?? 'Utilisateur',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tableau de bord',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vue d\'ensemble de votre entrepôt',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 18,
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
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildMobileStatCard(
          'Produits',
          Icons.inventory_2_outlined,
          Colors.blue,
          ProductService().getProducts().then((l) => l.length),
        ),
        _buildMobileStatCard(
          'Fournisseurs',
          Icons.business_outlined,
          Colors.orange,
          SupplierService().getSuppliers().then((l) => l.length),
        ),
        _buildMobileStatCard(
          'Ventes',
          Icons.shopping_cart_outlined,
          Colors.green,
          _getSalesCountForYear(),
        ),
        _buildMobileStatCard(
          'Profit',
          Icons.trending_up_outlined,
          Colors.purple,
          _calculateTotalProfit(),
        ),
      ],
    );
  }

  Widget _buildMobileStatCard(
    String title,
    IconData icon,
    Color color,
    Future<int> future,
  ) {
    final bool isProfitCard = title == 'Profit';
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
              FutureBuilder<int>(
                future: future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return Text(
                    snapshot.hasData
                        ? (isProfitCard
                            ? '${snapshot.data} DNT'
                            : '${snapshot.data}')
                        : (isProfitCard ? '0 DNT' : '0'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.grey[800],
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChartMobile() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Text(
            'Ventes ${_selectedYear}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchSalesData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sales = snapshot.data ?? [];
                final spots = _generateSalesSpots(sales);
                final monthNames = _getMonthNames();

                if (spots.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucune donnée disponible',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
                      },
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < monthNames.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  monthNames[value.toInt()],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                          interval: 1,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            );
                          },
                          interval: 25,
                          reservedSize: 30,
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.deepPurple,
                        barWidth: 3,
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.deepPurple.withOpacity(0.1),
                        ),
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 3,
                              color: Colors.deepPurple,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsMobile() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Text(
            'Top 5 Produits',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchTopProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = snapshot.data ?? [];

              if (products.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucune donnée disponible',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return Column(
                children:
                    products.asMap().entries.map((entry) {
                      final index = entry.key;
                      final product = entry.value;
                      final revenue = product['revenue'] as double;
                      final name = product['name'] as String;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _getProductColor(index),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.length > 25
                                        ? '${name.substring(0, 25)}...'
                                        : name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${revenue.toStringAsFixed(0)} DNT',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getProductColor(index),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfitCategoryMobile() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Text(
            'Profit par Catégorie',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchProfitByCategory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final categories = snapshot.data ?? [];

              if (categories.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucune donnée disponible',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return SizedBox(
                height: 250,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sections:
                              categories.asMap().entries.map((entry) {
                                final index = entry.key;
                                final category = entry.value;
                                final profit = category['profit'] as double;

                                return PieChartSectionData(
                                  color: _getCategoryColor(index),
                                  value: profit > 0 ? profit : 0.1,
                                  title: '',
                                  radius: 50,
                                );
                              }).toList(),
                          centerSpaceRadius: 30,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            categories.asMap().entries.map((entry) {
                              final index = entry.key;
                              final category = entry.value;
                              final profit = category['profit'] as double;
                              final categoryName =
                                  category['category'] as String;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(index),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        categoryName,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${profit.toStringAsFixed(0)} DNT',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            profit >= 0
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockAlertsMobile() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_outlined,
                color: Colors.red[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Alertes Stock Faible',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<ProductStock>>(
            future: _fetchProductStocks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text(
                  'Aucun stock faible détecté',
                  style: TextStyle(color: Colors.grey),
                );
              }

              final lowStock =
                  snapshot.data!.where((stock) => stock.quantity < 50).toList();

              if (lowStock.isEmpty) {
                return Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Tous les stocks sont à niveau',
                      style: TextStyle(color: Colors.green, fontSize: 14),
                    ),
                  ],
                );
              }

              return Column(
                children:
                    lowStock
                        .take(3)
                        .map(
                          (stock) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  stock.quantity < 10
                                      ? Colors.red[50]
                                      : Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    stock.quantity < 10
                                        ? Colors.red[200]!
                                        : Colors.orange[200]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color:
                                        stock.quantity < 10
                                            ? Colors.red[100]
                                            : Colors.orange[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    color:
                                        stock.quantity < 10
                                            ? Colors.red
                                            : Colors.orange[700],
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        stock.product?.name ??
                                            'Produit inconnu',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Stock: ${stock.quantity}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        stock.quantity < 10
                                            ? Colors.red
                                            : Colors.orange[700],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    stock.quantity < 10 ? 'Critique' : 'Faible',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPurchasesMobile() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Text(
            'Achats Récents',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<dynamic>>(
            future: PurchaseService().fetchPurchases(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text(
                  'Aucun achat récent',
                  style: TextStyle(color: Colors.grey),
                );
              }

              return Column(
                children:
                    snapshot.data!
                        .take(3)
                        .map(
                          (purchase) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        purchase.supplier?['name'] ??
                                            'Fournisseur inconnu',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        purchase.date ?? 'Date inconnue',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${purchase.finalAmount ?? 0} DNT',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper methods remain the same
  Future<User?> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<int> _calculateTotalProfit() async {
    try {
      final sales = await SalesService().getSales();
      final filteredSales =
          sales.where((s) {
            final d = DateTime.tryParse(s['sale_date'] ?? '');
            return d != null && d.year == _selectedYear;
          }).toList();
      double totalProfit = 0;

      for (final sale in filteredSales) {
        try {
          final saleItems = await SaleItemService().getSaleItems(sale['id']);

          for (final item in saleItems) {
            double unitPrice = item.unitPrice ?? 0;
            if (unitPrice <= 0 && item.product?.unitPrice != null) {
              unitPrice = item.product!.unitPrice;
            }
            final supplierPrice = item.product?.supplierPrice ?? 0;
            final quantity = item.quantity ?? 0;

            final profit = (unitPrice - supplierPrice) * quantity;
            totalProfit += profit;
          }
        } catch (e) {
          // Handle error
        }
      }

      // Add profit from credit sales
      try {
        final creditSalesProfit = await CreditSalesService().getProfitByYear(
          _selectedYear,
        );
        totalProfit += creditSalesProfit;
      } catch (e) {
        print('Error calculating credit sales profit: $e');
        // Continue with just regular sales profit
      }

      return totalProfit.toInt();
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getSalesCountForYear() async {
    try {
      final sales = await SalesService().getSales();
      return sales.where((s) {
        final d = DateTime.tryParse(s['sale_date'] ?? '');
        return d != null && d.year == _selectedYear;
      }).length;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSalesData() async {
    try {
      final sales = await SalesService().getSales();
      return sales.where((s) {
        final d = DateTime.tryParse(s['sale_date'] ?? '');
        return d != null && d.year == _selectedYear;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  List<FlSpot> _generateSalesSpots(List<Map<String, dynamic>> sales) {
    final Map<int, double> monthlySales = {for (var m = 1; m <= 12; m++) m: 0};

    for (final sale in sales) {
      final saleDate = DateTime.tryParse(sale['sale_date'] ?? '');
      if (saleDate != null && saleDate.year == _selectedYear) {
        final amount =
            double.tryParse(sale['total_amount']?.toString() ?? '') ?? 0;
        monthlySales[saleDate.month] =
            (monthlySales[saleDate.month] ?? 0) + amount;
      }
    }

    final spots = <FlSpot>[];
    final months = List<int>.generate(12, (i) => i + 1);
    double maxValue = monthlySales.values.fold(
      0,
      (max, value) => value > max ? value : max,
    );

    for (int i = 0; i < months.length; i++) {
      final value = monthlySales[months[i]] ?? 0;
      final normalizedValue = maxValue > 0 ? (value / maxValue) * 100 : 0;
      spots.add(FlSpot(i.toDouble(), normalizedValue.toDouble()));
    }

    return spots;
  }

  List<String> _getMonthNames() {
    final months = <String>[];
    for (int m = 1; m <= 12; m++) {
      switch (m) {
        case 1:
          months.add('Jan');
          break;
        case 2:
          months.add('Fév');
          break;
        case 3:
          months.add('Mar');
          break;
        case 4:
          months.add('Avr');
          break;
        case 5:
          months.add('Mai');
          break;
        case 6:
          months.add('Jun');
          break;
        case 7:
          months.add('Jul');
          break;
        case 8:
          months.add('Aoû');
          break;
        case 9:
          months.add('Sep');
          break;
        case 10:
          months.add('Oct');
          break;
        case 11:
          months.add('Nov');
          break;
        case 12:
          months.add('Déc');
          break;
      }
    }
    return months;
  }

  Future<List<Map<String, dynamic>>> _fetchTopProducts() async {
    try {
      final sales = await SalesService().getSales();
      final Map<String, double> productRevenue = {};

      for (final sale in sales.where((s) {
        final d = DateTime.tryParse(s['sale_date'] ?? '');
        return d != null && d.year == _selectedYear;
      })) {
        try {
          final saleItems = await SaleItemService().getSaleItems(sale['id']);

          for (final item in saleItems) {
            final productName = item.product?.name ?? 'Unknown Product';
            final quantity = item.quantity ?? 0;
            double unitPrice = item.unitPrice ?? 0;
            if (unitPrice <= 0 && item.product?.unitPrice != null) {
              unitPrice = item.product!.unitPrice;
            }
            final revenue = quantity * unitPrice;

            productRevenue[productName] =
                (productRevenue[productName] ?? 0) + revenue;
          }
        } catch (e) {
          final totalAmount =
              double.tryParse(sale['total_amount']?.toString() ?? '') ?? 0;
          if (totalAmount > 0) {
            final customerName = sale['customer_name'] ?? 'Unknown Customer';
            productRevenue['Sale to $customerName'] =
                (productRevenue['Sale to $customerName'] ?? 0) + totalAmount;
          }
        }
      }

      if (productRevenue.isEmpty) {
        return [
          {'name': 'Filtre à huile', 'revenue': 180.0},
          {'name': 'Pneu 205/55 R16', 'revenue': 120.0},
          {'name': 'Plaquettes de frein', 'revenue': 85.0},
          {'name': 'Huile moteur', 'revenue': 65.0},
          {'name': 'Batterie auto', 'revenue': 45.0},
        ];
      }

      final sortedProducts =
          productRevenue.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      return sortedProducts
          .take(5)
          .map((entry) => {'name': entry.key, 'revenue': entry.value})
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProfitByCategory() async {
    try {
      final sales = await SalesService().getSales();
      final Map<String, double> categoryProfit = {};

      for (final sale in sales) {
        try {
          final saleItems = await SaleItemService().getSaleItems(sale['id']);

          for (final item in saleItems) {
            final category = item.product?.category ?? 'Autre';
            final quantity = item.quantity ?? 0;
            double unitPrice = item.unitPrice ?? 0;
            if (unitPrice <= 0 && item.product?.unitPrice != null) {
              unitPrice = item.product!.unitPrice;
            }
            final supplierPrice = item.product?.supplierPrice ?? 0;

            final profit = (unitPrice - supplierPrice) * quantity;
            categoryProfit[category] = (categoryProfit[category] ?? 0) + profit;
          }
        } catch (e) {
          final totalAmount =
              double.tryParse(sale['total_amount']?.toString() ?? '') ?? 0;
          if (totalAmount > 0) {
            final estimatedProfit = totalAmount * 0.2;
            categoryProfit['Autre'] =
                (categoryProfit['Autre'] ?? 0) + estimatedProfit;
          }
        }
      }

      if (categoryProfit.isEmpty) {
        return [
          {'category': 'Automobile', 'profit': 60.0},
          {'category': 'Freins', 'profit': 45.0},
          {'category': 'Filtres', 'profit': 30.0},
          {'category': 'Lubrifiants', 'profit': 25.0},
        ];
      }

      final sortedCategories =
          categoryProfit.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      return sortedCategories
          .map((entry) => {'category': entry.key, 'profit': entry.value})
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<ProductStock>> _fetchProductStocks() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/product-stocks'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ProductStock.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load product stocks');
      }
    } catch (e) {
      return [];
    }
  }

  Color _getProductColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    return colors[index % colors.length];
  }

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }
}

// Keep existing desktop widgets unchanged
class _Header extends StatefulWidget {
  final int selectedYear;
  final List<int> yearOptions;
  final ValueChanged<int> onYearChanged;
  const _Header({
    this.selectedYear = 0,
    this.yearOptions = const [],
    required this.onYearChanged,
  });

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      setState(() {
        _user = User.fromJson(jsonDecode(userJson));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tableau de bord',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Vue d\'ensemble de votre entrepôt',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 280,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(Icons.search, color: Colors.grey[500], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Year dropdown filter (desktop)
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: widget.selectedYear,
                    items:
                        widget.yearOptions
                            .map(
                              (y) => DropdownMenuItem<int>(
                                value: y,
                                child: Text(y.toString()),
                              ),
                            )
                            .toList(),
                    onChanged: (y) {
                      if (y != null) widget.onYearChanged(y);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.notifications_outlined,
                  color: Colors.grey[600],
                ),
                tooltip: 'Notifications',
              ),
              const SizedBox(width: 8),
              // Profile Button
              ResponsiveProfileButton(
                isMobile: false,
                textColor: Colors.black87,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardStatsRow extends StatelessWidget {
  final int selectedYear;
  const _DashboardStatsRow({super.key, required this.selectedYear});
  Future<int> _calculateTotalProfit() async {
    try {
      final sales = await SalesService().getSales();
      final filteredSales =
          sales.where((s) {
            final d = DateTime.tryParse(s['sale_date'] ?? '');
            return d != null && d.year == selectedYear;
          }).toList();
      double totalProfit = 0;

      for (final sale in filteredSales) {
        try {
          final saleItems = await SaleItemService().getSaleItems(sale['id']);

          for (final item in saleItems) {
            double unitPrice = item.unitPrice ?? 0;
            if (unitPrice <= 0 && item.product?.unitPrice != null) {
              unitPrice = item.product!.unitPrice;
            }
            final supplierPrice = item.product?.supplierPrice ?? 0;
            final quantity = item.quantity ?? 0;

            final profit = (unitPrice - supplierPrice) * quantity;
            totalProfit += profit;
          }
        } catch (e) {}
      }

      return totalProfit.toInt();
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _statCard(
                'Produits en stock',
                Icons.inventory_2,
                Colors.blue,
                ProductService().getProducts().then((l) => l.length),
                '+2.5%',
              ),
              const SizedBox(height: 16),
              _statCard(
                'Fournisseurs',
                Icons.business,
                Colors.orange,
                SupplierService().getSuppliers().then((l) => l.length),
                '+1.2%',
              ),
              const SizedBox(height: 16),
              _statCard(
                'Total Ventes',
                Icons.shopping_cart,
                Colors.green,
                SalesService().getSales().then(
                  (sales) =>
                      sales.where((s) {
                        final d = DateTime.tryParse(s['sale_date'] ?? '');
                        return d != null && d.year == selectedYear;
                      }).length,
                ),
                '+12.3%',
              ),
              const SizedBox(height: 16),
              _statCard(
                'Profit total',
                Icons.trending_up,
                Colors.purple,
                _calculateTotalProfit(),
                '+8.1%',
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(
                child: _statCard(
                  'Produits en stock',
                  Icons.inventory_2,
                  Colors.blue,
                  ProductService().getProducts().then((l) => l.length),
                  '+2.5%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statCard(
                  'Fournisseurs',
                  Icons.business,
                  Colors.orange,
                  SupplierService().getSuppliers().then((l) => l.length),
                  '+1.2%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statCard(
                  'Total Ventes',
                  Icons.shopping_cart,
                  Colors.green,
                  SalesService().getSales().then(
                    (sales) =>
                        sales.where((s) {
                          final d = DateTime.tryParse(s['sale_date'] ?? '');
                          return d != null && d.year == selectedYear;
                        }).length,
                  ),
                  '+12.3%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statCard(
                  'Profit total',
                  Icons.trending_up,
                  Colors.purple,
                  _calculateTotalProfit(),
                  '+8.1%',
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _statCard(
    String title,
    IconData icon,
    Color color,
    Future<int> future,
    String change,
  ) {
    final bool isProfitCard = title == 'Profit total';
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      change,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  snapshot.hasData
                      ? (isProfitCard
                          ? '${snapshot.data} DNT'
                          : '${snapshot.data}')
                      : (isProfitCard ? '0 DNT' : '0'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.grey[800],
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
      },
    );
  }
}

class _DashboardChartsRow extends StatelessWidget {
  final int selectedYear;
  const _DashboardChartsRow({super.key, required this.selectedYear});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 2, child: _SalesChart(selectedYear: selectedYear)),
        const SizedBox(width: 16),
        Expanded(child: _TopProductsChart(selectedYear: selectedYear)),
      ],
    );
  }
}

class _SalesChart extends StatelessWidget {
  final int selectedYear;

  const _SalesChart({required this.selectedYear});

  Future<List<Map<String, dynamic>>> _fetchSalesData() async {
    try {
      final sales = await SalesService().getSales();
      return sales.where((sale) {
        final saleDate = DateTime.tryParse(sale['sale_date'] ?? '');
        return saleDate != null && saleDate.year == selectedYear;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  List<FlSpot> _generateSalesSpots(List<Map<String, dynamic>> sales) {
    final Map<int, double> monthlySales = {};

    // Initialize all months with 0
    for (int month = 1; month <= 12; month++) {
      monthlySales[month] = 0;
    }

    // Sum sales by month for the selected year only
    for (final sale in sales) {
      final saleDate = DateTime.tryParse(sale['sale_date'] ?? '');
      if (saleDate != null && saleDate.year == selectedYear) {
        final amount =
            double.tryParse(sale['total_amount']?.toString() ?? '') ?? 0;
        monthlySales[saleDate.month] =
            (monthlySales[saleDate.month] ?? 0) + amount;
      }
    }

    // Convert to FlSpot format
    final spots = <FlSpot>[];
    final months = monthlySales.keys.toList()..sort();
    double maxValue = monthlySales.values.fold(
      0,
      (max, value) => value > max ? value : max,
    );

    // Ensure we have at least 2 points for the chart
    if (months.length < 2) {
      // Add dummy data if not enough months
      spots.add(FlSpot(0, 0));
      spots.add(FlSpot(1, 0));
      return spots;
    }

    for (int i = 0; i < months.length; i++) {
      final value = monthlySales[months[i]] ?? 0;
      // Normalize to 0-100 scale for better visualization
      final normalizedValue = maxValue > 0 ? (value / maxValue) * 100 : 0;
      spots.add(FlSpot(i.toDouble(), normalizedValue.toDouble()));
    }

    return spots;
  }

  List<String> _getMonthNames() {
    final now = DateTime.now();
    final months = <String>[];
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      switch (month.month) {
        case 1:
          months.add('Jan');
          break;
        case 2:
          months.add('Fév');
          break;
        case 3:
          months.add('Mar');
          break;
        case 4:
          months.add('Avr');
          break;
        case 5:
          months.add('Mai');
          break;
        case 6:
          months.add('Jun');
          break;
        case 7:
          months.add('Jul');
          break;
        case 8:
          months.add('Aoû');
          break;
        case 9:
          months.add('Sep');
          break;
        case 10:
          months.add('Oct');
          break;
        case 11:
          months.add('Nov');
          break;
        case 12:
          months.add('Déc');
          break;
      }
    }
    return months;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Évolution des ventes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Icon(Icons.more_horiz, color: Colors.grey[600]),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchSalesData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final sales = snapshot.data ?? [];
              final spots = _generateSalesSpots(sales);
              final monthNames = _getMonthNames();

              if (spots.isEmpty) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Aucune donnée disponible',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return Container(
                height: 200,
                width: double.infinity,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: false,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
                      },
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < monthNames.length) {
                              return Text(
                                monthNames[value.toInt()],
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              );
                            }
                            return const Text('');
                          },
                          interval: 1,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}%',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            );
                          },
                          interval: 20,
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.deepPurple,
                        barWidth: 3,
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.deepPurple.withOpacity(0.1),
                        ),
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.deepPurple,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopProductsChart extends StatelessWidget {
  final int selectedYear;

  const _TopProductsChart({required this.selectedYear});

  Future<List<Map<String, dynamic>>> _fetchTopProducts() async {
    try {
      final sales = await SalesService().getSales();
      final Map<String, double> productRevenue = {};

      // Filter sales by selected year
      final yearSales =
          sales.where((sale) {
            final saleDate = DateTime.tryParse(sale['sale_date'] ?? '');
            return saleDate != null && saleDate.year == selectedYear;
          }).toList();

      print(
        '🔍 [TopProductsChart] Found ${yearSales.length} sales for year $selectedYear',
      );

      for (final sale in yearSales) {
        try {
          final saleItems = await SaleItemService().getSaleItems(sale['id']);

          for (final item in saleItems) {
            final productName = item.product?.name ?? 'Unknown Product';
            final quantity = item.quantity ?? 0;
            // Use product's current unit price if sale item unit price is 0
            double unitPrice = item.unitPrice ?? 0;
            if (unitPrice <= 0 && item.product?.unitPrice != null) {
              unitPrice = item.product!.unitPrice;
            }
            final revenue = quantity * unitPrice;

            productRevenue[productName] =
                (productRevenue[productName] ?? 0) + revenue;
          }
        } catch (e) {
          // Fallback: use sale total amount if available
          final totalAmount =
              double.tryParse(sale['total_amount']?.toString() ?? '') ?? 0;
          if (totalAmount > 0) {
            final customerName = sale['customer_name'] ?? 'Unknown Customer';
            productRevenue['Sale to $customerName'] =
                (productRevenue['Sale to $customerName'] ?? 0) + totalAmount;
          }
        }
      }

      // If no real data, add some demo data for testing
      if (productRevenue.isEmpty) {
        return [
          {'name': 'Filtre à huile', 'revenue': 180.0},
          {'name': 'Pneu 205/55 R16', 'revenue': 120.0},
          {'name': 'Plaquettes de frein', 'revenue': 85.0},
          {'name': 'Huile moteur', 'revenue': 65.0},
          {'name': 'Batterie auto', 'revenue': 45.0},
        ];
      }

      // Sort by revenue and take top 5
      final sortedProducts =
          productRevenue.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      return sortedProducts
          .take(5)
          .map((entry) => {'name': entry.key, 'revenue': entry.value})
          .toList();
    } catch (e) {
      return [];
    }
  }

  Color _getProductColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Produits par Revenus',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Icon(Icons.more_horiz, color: Colors.grey[600]),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchTopProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final products = snapshot.data ?? [];

              if (products.isEmpty) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Aucune donnée disponible',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 200,
                child: Column(
                  children:
                      products.asMap().entries.map((entry) {
                        final index = entry.key;
                        final product = entry.value;
                        final revenue = product['revenue'] as double;
                        final name = product['name'] as String;

                        // Calculate percentage of total revenue
                        final totalRevenue = products.fold<double>(
                          0,
                          (sum, p) => sum + (p['revenue'] as double),
                        );
                        final percentage =
                            totalRevenue > 0
                                ? (revenue / totalRevenue) * 100
                                : 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _getProductColor(index),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.length > 20
                                          ? '${name.substring(0, 20)}...'
                                          : name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: percentage / 100,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _getProductColor(index),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${revenue.toStringAsFixed(0)} DNT',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfitByCategoryChart extends StatelessWidget {
  Future<List<Map<String, dynamic>>> _fetchProfitByCategory() async {
    try {
      final sales = await SalesService().getSales();
      final Map<String, double> categoryProfit = {};

      for (final sale in sales) {
        // Try to get sale items for this sale
        try {
          final saleItems = await SaleItemService().getSaleItems(sale['id']);

          for (final item in saleItems) {
            final category = item.product?.category ?? 'Autre';
            final quantity = item.quantity ?? 0;
            // Use product's current unit price if sale item unit price is 0
            double unitPrice = item.unitPrice ?? 0;
            if (unitPrice <= 0 && item.product?.unitPrice != null) {
              unitPrice = item.product!.unitPrice;
            }
            final supplierPrice = item.product?.supplierPrice ?? 0;

            final profit = (unitPrice - supplierPrice) * quantity;
            categoryProfit[category] = (categoryProfit[category] ?? 0) + profit;
          }
        } catch (e) {
          // Fallback: estimate profit from sale total
          final totalAmount =
              double.tryParse(sale['total_amount']?.toString() ?? '') ?? 0;
          if (totalAmount > 0) {
            // Assume 20% profit margin as fallback
            final estimatedProfit = totalAmount * 0.2;
            categoryProfit['Autre'] =
                (categoryProfit['Autre'] ?? 0) + estimatedProfit;
          }
        }
      }

      // If no real data, add some demo data for testing
      if (categoryProfit.isEmpty) {
        return [
          {'category': 'Automobile', 'profit': 60.0},
          {'category': 'Freins', 'profit': 45.0},
          {'category': 'Filtres', 'profit': 30.0},
          {'category': 'Lubrifiants', 'profit': 25.0},
        ];
      }

      // Convert to list and sort by profit
      final sortedCategories =
          categoryProfit.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      return sortedCategories
          .map((entry) => {'category': entry.key, 'profit': entry.value})
          .toList();
    } catch (e) {
      return [];
    }
  }

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profit par Catégorie',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Icon(Icons.more_horiz, color: Colors.grey[600]),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchProfitByCategory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final categories = snapshot.data ?? [];

              if (categories.isEmpty) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Aucune donnée disponible',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return Container(
                height: 200,
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child:
                          categories.isNotEmpty
                              ? PieChart(
                                PieChartData(
                                  sections:
                                      categories.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final category = entry.value;
                                        final profit =
                                            category['profit'] as double;
                                        final categoryName =
                                            category['category'] as String;

                                        // Calculate percentage
                                        final totalProfit = categories
                                            .fold<double>(
                                              0,
                                              (sum, c) =>
                                                  sum + (c['profit'] as double),
                                            );
                                        final percentage =
                                            totalProfit > 0
                                                ? (profit / totalProfit) * 100
                                                : 0;

                                        return PieChartSectionData(
                                          color: _getCategoryColor(index),
                                          value:
                                              profit > 0
                                                  ? profit
                                                  : 0.1, // Ensure positive value
                                          title:
                                              '${percentage.toStringAsFixed(1)}%',
                                          radius: 60,
                                          titleStyle: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        );
                                      }).toList(),
                                  centerSpaceRadius: 40,
                                  sectionsSpace: 2,
                                ),
                              )
                              : const Center(
                                child: Text(
                                  'Aucune donnée',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            categories.asMap().entries.map((entry) {
                              final index = entry.key;
                              final category = entry.value;
                              final profit = category['profit'] as double;
                              final categoryName =
                                  category['category'] as String;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(index),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        categoryName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${profit.toStringAsFixed(0)} DNT',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            profit >= 0
                                                ? Colors.green
                                                : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentPurchasesTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: PurchaseService().fetchPurchases(),
      builder: (context, snapshot) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Fournisseur',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Montant',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )
              else if (!snapshot.hasData || snapshot.data!.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Aucun achat récent',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              else
                ...snapshot.data!
                    .take(5)
                    .map(
                      (purchase) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                purchase.date ?? 'N/A',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                purchase.supplier?['name'] ?? 'N/A',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${purchase.finalAmount ?? 0} DNT',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.more_vert,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _LowStockAlertsCard extends StatelessWidget {
  Future<List<ProductStock>> _fetchProductStocks() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/product-stocks'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ProductStock.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load product stocks');
      }
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductStock>>(
      future: _fetchProductStocks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Aucun stock faible détecté',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          );
        }
        // Filtrer les produits à stock faible (quantité < 50)
        final lowStock =
            snapshot.data!.where((stock) => stock.quantity < 50).toList();
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Stock faible',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (lowStock.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aucun produit en stock faible',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...lowStock
                    .take(5)
                    .map(
                      (stock) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stock.product?.name ?? 'Produit inconnu',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Stock: ${stock.quantity} / Seuil: 50',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (stock.warehouse != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Entrepôt: ${stock.warehouse!['name'] ?? 'Inconnu'}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    stock.quantity < 10
                                        ? Colors.red[100]
                                        : Colors.orange[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                stock.quantity < 10 ? 'Critique' : 'Faible',
                                style: TextStyle(
                                  color:
                                      stock.quantity < 10
                                          ? Colors.red
                                          : Colors.orange[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _RecentMovementsTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // À brancher sur StockMovementService
    return FutureBuilder<List<dynamic>>(
      future: Future.value(
        [],
      ), // Remplace par StockMovementService().getRecentMovements() si tu l'as
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Aucun mouvement récent',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          );
        }
        final movements = snapshot.data!;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: const [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Type',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Produit',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Quantité',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Entrepôt',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...movements.map(
                (movement) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.swap_horiz,
                                color: Colors.blue,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              movement['type'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          movement['product'] ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${movement['quantity'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          movement['date'] ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          movement['warehouse'] ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Keep all existing chart classes unchanged (_SalesChart, _TopProductsChart, _ProfitByCategoryChart, _RecentPurchasesTable, _LowStockAlertsCard, _RecentMovementsTable)
// ... [Include all the existing chart classes here without changes]
