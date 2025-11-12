import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spare_parts_management_system_flutter/view_model/forgotpassword_view_model.dart';
import 'package:spare_parts_management_system_flutter/view_model/profile_view_model.dart';
import 'package:spare_parts_management_system_flutter/view_model/reset_password_view_model.dart';
import 'package:spare_parts_management_system_flutter/view_model/credit_sales_view_model.dart';
import 'package:spare_parts_management_system_flutter/view_model/credit_payments_view_model.dart';
import 'package:spare_parts_management_system_flutter/view_model/products_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'view_model/login_view_model.dart';
import 'view_model/signup_view_model.dart';
import 'view_model/home_view_model.dart';

import 'views/screens/signup_screen.dart';
import 'routes/routes.dart';
import 'package:go_router/go_router.dart';
import 'views/widgets/sidebar.dart';
import 'views/widgets/error_boundary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up global error handler for friendly error messages
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return FriendlyErrorWidget(errorDetails: details);
  };

  // Catch Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('access_token');
  final bool rememberMe = prefs.getBool('remember_me') ?? false;

  // Only auto-login if Remember Me is enabled and token exists
  final bool shouldAutoLogin = token != null && rememberMe;

  runApp(MyApp(initialRoute: shouldAutoLogin ? '/home' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => SignupViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => ForgotpasswordViewModel()),
        ChangeNotifierProvider(create: (_) => ResetPasswordViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => CreditSalesViewModel()),
        ChangeNotifierProvider(create: (_) => CreditPaymentsViewModel()),
        ChangeNotifierProvider(create: (_) => ProductsViewModel()),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Spare Parts Management',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}

SidebarSection _getSidebarSectionFromRoute(String location) {
  if (location.startsWith('/products')) return SidebarSection.products;
  if (location.startsWith('/warehouses')) return SidebarSection.warehouses;
  if (location.startsWith('/stock-movement-list'))
    return SidebarSection.stockMovements;
  if (location.startsWith('/purchases')) return SidebarSection.purchases;
  if (location.startsWith('/sales')) return SidebarSection.sales;
  if (location.startsWith('/credit-sales')) return SidebarSection.creditSales;
  if (location.startsWith('/users')) return SidebarSection.users;
  if (location.startsWith('/suppliers')) return SidebarSection.suppliers;
  if (location.startsWith('/otp')) return SidebarSection.otpSecurity;
  if (location.startsWith('/settings')) return SidebarSection.settings;
  return SidebarSection.dashboard;
}
