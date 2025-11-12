import 'package:flutter/material.dart';
import 'session_manager.dart';

class RouteGuard {
  static Future<bool> canAccess(String route, String? userRole) async {
    // Public routes - accessible to everyone
    const publicRoutes = ['/login', '/signup'];
    if (publicRoutes.contains(route)) {
      return true;
    }

    // Check if user is logged in
    final currentUser = await SessionManager.getUser();
    if (currentUser == null) {
      return false;
    }

    // Admin can access everything
    if (userRole == 'admin') {
      return true;
    }

    // Role-based access control
    switch (userRole) {
      case 'employee':
        return _employeeRoutes.contains(route);
      case 'guest':
        return _guestRoutes.contains(route);
      default:
        return false;
    }
  }

  static const List<String> _employeeRoutes = [
    '/home',
    '/products',
    '/product-stocks',
    '/purchases',
    '/sales',
    '/customers',
    '/suppliers',
    '/warehouses',
    '/stock-movements',
    '/purchase-returns',
    '/profile',
    '/market',
  ];

  static const List<String> _guestRoutes = [
    '/market',
    '/profile',
  ];

  static Future<void> checkAccessAndNavigate(
    BuildContext context,
    String route,
  ) async {
    final currentUser = await SessionManager.getUser();
    final userRole = currentUser?['role'] as String?;

    final hasAccess = await canAccess(route, userRole);
    
    if (!hasAccess) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous n\'avez pas accès à cette page'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      Navigator.pushNamed(context, route);
    }
  }
}
