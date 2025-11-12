import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/auth_service.dart';
import '../../services/session_manager.dart';
import '../widgets/app_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (savedEmail != null) _emailController.text = savedEmail;
    if (savedPassword != null) _passwordController.text = savedPassword;
    setState(() {
      _rememberMe = rememberMe;
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;
  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;
  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final result = await UserService().login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;

      if (result.containsKey('access_token')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', result['access_token']);

        // Fetch and save user info from /auth/me
        final user = await UserService().fetchCurrentUser(
          result['access_token'],
        );
        if (user != null) {
          // Save user data to SessionManager
          final userData = {
            'id': user.id,
            'name': user.name,
            'email': user.email,
            'role': user.role,
            'phone_number': user.phoneNumber,
            'warehouse_id': user.warehouseId,
          };
          await SessionManager.saveUser(userData);
          await prefs.setString('user', jsonEncode(userData));
        }

        await _saveCredentials();

        // Success message
        if (mounted) {
          AppToast.success(context, 'Connexion réussie !');
        }

        // Role-based navigation - get role from fetched user data
        String userRole = 'admin'; // default fallback

        // Try to get role from the fetched user data
        if (user != null) {
          userRole = user.role;
        } else {
          // Fallback: get role from AuthService
          final authService = AuthService();
          final currentUser = await authService.getCurrentUser();
          if (currentUser != null && currentUser.containsKey('role')) {
            userRole = currentUser['role'] ?? 'admin';
          } else {}
        }

        switch (userRole) {
          case 'admin':
            GoRouter.of(context).go('/home'); // Dashboard screen
            break;
          case 'manager':
            GoRouter.of(context).go('/purchases'); // Achats screen
            break;
          case 'cashier':
            GoRouter.of(context).go('/sales'); // Ventes screen
            break;
          case 'guest':
            GoRouter.of(context).go('/market'); // Market screen
            break;
          default:
            GoRouter.of(context).go('/home'); // Default to dashboard
        }
      } else {
        if (mounted) {
          AppToast.error(
            context,
            result['message']?.toString() ?? 'Échec de la connexion',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Une erreur s\'est produite';
        if (e.toString().contains('Invalid credentials')) {
          errorMessage = 'Email ou mot de passe incorrect';
        } else if (e.toString().contains('Network')) {
          errorMessage = 'Erreur de connexion réseau';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Délai d\'attente dépassé';
        }
        AppToast.error(context, errorMessage);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_isDesktop(context)) {
            return _buildDesktopLayout();
          } else if (_isTablet(context)) {
            return _buildTabletLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildLoginForm()),
        Expanded(flex: 3, child: _buildImageSection()),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildLoginForm()),
        Expanded(flex: 2, child: _buildImageSection()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/volkswagen.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: _buildLoginFormContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/volkswagen.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 24.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _buildLoginFormContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/volkswagen2.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildLoginFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Bon Retour !',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connectez-vous pour accéder à votre tableau de bord.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          _buildGlassyTextField(
            controller: _emailController,
            hint: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          _buildGlassyPasswordField(
            controller: _passwordController,
            hint: 'Mot de passe',
            obscureText: _obscurePassword,
            onToggleVisibility:
                () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Theme(
                data: Theme.of(context).copyWith(
                  unselectedWidgetColor: Colors.white.withOpacity(0.7),
                ),
                child: Checkbox(
                  value: _rememberMe,
                  onChanged:
                      (val) => setState(() => _rememberMe = val ?? false),
                  fillColor: MaterialStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.white;
                    }
                    return null;
                  }),
                  checkColor: Colors.black,
                ),
              ),
              Text(
                'Se souvenir de moi',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => GoRouter.of(context).go('/forgot-password'),
              child: Text(
                'Mot de passe oublié ?',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 3,
            ),
            onPressed: _loading ? null : _handleLogin,
            child:
                _loading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                    : const Text(
                      'Se Connecter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassyTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon:
            icon != null
                ? Icon(icon, color: Colors.white.withOpacity(0.8), size: 20)
                : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.5),
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ce champ est requis';
        }
        if (hint.toLowerCase().contains('email') &&
            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Email invalide';
        }
        return null;
      },
    );
  }

  Widget _buildGlassyPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.white.withOpacity(0.8),
            size: 20,
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.5),
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Mot de passe requis';
        }
        if (value.length < 6) {
          return 'Minimum 6 caractères';
        }
        return null;
      },
    );
  }
}
