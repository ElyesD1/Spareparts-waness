import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../services/user_service.dart';
import '../widgets/auth_background.dart';
import '../../utils/responsive_helper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String _fullPhoneNumber = '';

  bool _loading = false;
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _loading = true);

    try {
      final userService = UserService();
      // The role and warehouse name are hardcoded as they are not in the new design.
      // You may want to revisit this based on your application's logic.
      final result = await userService.register(
        name: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: int.parse(_fullPhoneNumber),
        role: 'manager', // Or a default role
        warehouseName: null, // Will be assigned by admin later
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(result['id'] != null ? 'Succès' : 'Erreur'),
            content: Text(result['id'] != null
                ? 'Votre compte a été créé avec succès !'
                : (result['message']?.toString() ?? 'Une erreur s\'est produite.')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (result['id'] != null) {
                    GoRouter.of(context).go('/login');
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Erreur'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final maxWidth = isMobile ? MediaQuery.of(context).size.width * 0.9 : 400.0;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAuthToggle(),
                    const SizedBox(height: 24),
                    const Text(
                      'Créer un Compte',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rejoignez-nous et commencez à gérer vos pièces détachées.',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildGlassyTextField(controller: _firstNameController, hint: 'Prénom')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildGlassyTextField(controller: _lastNameController, hint: 'Nom')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildGlassyTextField(controller: _emailController, hint: 'Entrez votre email', icon: Icons.email_outlined),
                    const SizedBox(height: 16),
                    _buildGlassyPasswordField(controller: _passwordController, hint: 'Mot de passe'),
                    const SizedBox(height: 16),
                    _buildGlassyPhoneField(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Text('Créer le compte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'En créant un compte, vous acceptez nos Conditions d\'utilisation',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {}, // Already on sign up
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('S\'inscrire', style: TextStyle(color: Colors.white)),
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: () => GoRouter.of(context).go('/login'),
              child: Text('Se connecter', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassyTextField({required TextEditingController controller, required String hint, IconData? icon}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      validator: (value) => (value == null || value.isEmpty) ? 'Please enter a value' : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white.withOpacity(0.7)) : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
  
  Widget _buildGlassyPasswordField({required TextEditingController controller, required String hint}) {
     bool _obscureText = true;
     return StatefulBuilder(
       builder: (context, setState) {
         return TextFormField(
          controller: controller,
          obscureText: _obscureText,
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white.withOpacity(0.7)),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            ),
          ),
      );
       }
     );
  }

  Widget _buildGlassyPhoneField() {
    return IntlPhoneField(
      controller: _phoneController,
      style: const TextStyle(color: Colors.white),
      onChanged: (phone) {
        _fullPhoneNumber = phone.completeNumber;
      },
      decoration: InputDecoration(
        hintText: 'Phone Number',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownTextStyle: const TextStyle(color: Colors.white),
      dropdownIcon: Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.7)),
      initialCountryCode: 'TN', // Default to Tunisia
    );
  }
}
// To use a real car image, add it to assets/images/car.jpg and register it in pubspec.yaml, then use Image.asset('assets/images/car.jpg') in place of the placeholder.

