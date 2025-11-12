import 'package:go_router/go_router.dart';
import 'package:spare_parts_management_system_flutter/views/screens/login_screen.dart';
import 'package:spare_parts_management_system_flutter/views/screens/purchases_screen.dart';
import 'package:spare_parts_management_system_flutter/views/screens/stock_movement_listscreen.dart';
import 'package:spare_parts_management_system_flutter/views/screens/product_transfer_screen.dart';
import '../views/screens/home_screen.dart';
import '../views/screens/profile_screen.dart';
import '../views/screens/forgot_password_screen.dart';
import '../views/screens/reset_password_screen.dart';
import '../views/screens/verification_screen.dart';
import '../views/screens/products_screen.dart';
import '../views/screens/suppliers_screen.dart';
import '../views/screens/sales_screen.dart';
import '../views/screens/warehouses_screen.dart';
import '../views/screens/product_stocks_screen.dart';
import '../views/screens/sale_items_screen.dart';
import '../views/screens/users_screen.dart';
import '../views/screens/credit_sales_screen.dart';
import '../views/screens/operational_expenses_screen.dart';
import '../views/screens/purchase_returns_screen.dart';
import '../views/screens/customers_screen.dart';
import '../views/screens/market_screen.dart';

import 'package:flutter/material.dart';
import 'dart:ui';
import '../views/widgets/product_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final userId = int.tryParse(state.uri.queryParameters['userId'] ?? '');
        final otp = state.uri.queryParameters['otp'];
        return ResetPasswordScreen(userId: userId, otp: otp);
      },
    ),
    GoRoute(
      path: '/verification',
      builder: (context, state) {
        final userId = int.tryParse(state.uri.queryParameters['userId'] ?? '');
        final email = state.uri.queryParameters['email'];
        if (userId == null) {
          return const Scaffold(body: Center(child: Text('Invalid or missing userId')));
        }
        return VerificationScreen(userId: userId, email: email);
      },
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductsScreen(),
    ),
    GoRoute(
      path: '/market',
      builder: (context, state) => const MarketScreen(),
    ),
    GoRoute(
      path: '/suppliers',
      builder: (context, state) => const SuppliersScreen(),
    ),
    GoRoute(
      path: '/customers',
      builder: (context, state) => const CustomersScreen(),
    ),
    GoRoute(
      path: '/sales',
      builder: (context, state) => const SalesScreen(),
    ),
    GoRoute(
      path: '/warehouses',
      builder: (context, state) => const WarehousesScreen(),
    ),
    GoRoute(
      path: '/product-stocks',
      builder: (context, state) => const ProductStocksScreen(),
    ),
    GoRoute(
      path: '/stock-movement-list',
      builder: (context, state) => const StockMovementListScreen(),
    ),
    GoRoute(
      path: '/product-transfers',
      builder: (context, state) => const ProductTransferScreen(),
    ),
    GoRoute(
      path: '/purchases',
      builder: (context, state) => PurchasesScreen(),
    ),
    GoRoute(
      path: '/sale-items',
      builder: (context, state) => SaleItemsScreen(),
    ),
    GoRoute(
      path: '/users',
      builder: (context, state) => const UsersScreen(),
    ),
    GoRoute(
      path: '/credit-sales',
      builder: (context, state) => const CreditSalesScreen(),
    ),
    GoRoute(
      path: '/operational-expenses',
      builder: (context, state) => const OperationalExpensesScreen(),
    ),
    GoRoute(
      path: '/purchase-returns',
      builder: (context, state) => const PurchaseReturnsScreen(),
    ),
  ],
);

class ProductsOverlayScreen extends StatelessWidget {
  const ProductsOverlayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // HomeScreen as the background
        const HomeScreen(),
        // More colorful/gradient overlay for flow
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.purple.withOpacity(0.12),
                  Colors.blue.withOpacity(0.10),
                  Colors.transparent,
                ],
                center: Alignment.center,
                radius: 1.2,
              ),
            ),
          ),
        ),
        // Close button in the top-right corner
        Positioned(
          top: 24,
          right: 24,
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              icon: const Icon(Icons.close, size: 32, color: Colors.black54),
              tooltip: 'Close',
              onPressed: () {
                // Use GoRouter to navigate back to dashboard/home
                Navigator.of(context).pushReplacementNamed('/home');
              },
            ),
          ),
        ),
        // Floating product form card
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const ProductForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<bool> isLoggedIn() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('access_token') != null;
}
