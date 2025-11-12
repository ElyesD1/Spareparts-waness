import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/user_service.dart';
import '../widgets/branding_panel.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildAuthPanel(context),
          ),
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/volkswagen2.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthPanel(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/volkswagen.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withOpacity(0.4),
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: _ForgotPasswordForm(),
                  ),
                ),
              ),
              Positioned(
                top: 24,
                right: 24,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => GoRouter.of(context).go('/login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForgotPasswordForm extends StatefulWidget {
  @override
  _ForgotPasswordFormState createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<_ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  final _userService = UserService();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      try {
        final response = await _userService.forgotPassword(email: _emailController.text.trim());
        final userId = response['userId'];
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: const Color(0xFF333333),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Check Your Email',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        response['message'] ?? "We've sent a password reset link to your email address.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                          GoRouter.of(context).go('/verification?userId=$userId');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Error'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Forgot Password', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Enter the email associated with your account and we'll send an email with instructions to reset your password.", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
          const SizedBox(height: 32),
          _buildGlassyTextField(
            controller: _emailController,
            hint: 'Enter your email',
            icon: Icons.email_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your email';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(text: 'Send Instructions', isLoading: _loading, onPressed: _handleForgotPassword),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Remembered your password? ", style: TextStyle(color: Colors.white.withOpacity(0.7))),
              GestureDetector(
                onTap: () => GoRouter.of(context).go('/login'),
                child: const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper widgets for consistent styling

InputDecoration _glassyInputDecoration({required String hint, IconData? icon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
    prefixIcon: icon != null ? Icon(icon, color: Colors.white.withOpacity(0.7)) : null,
    filled: true,
    fillColor: Colors.white.withOpacity(0.1),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
    ),
  );
}

Widget _buildPrimaryButton({required String text, required bool isLoading, required VoidCallback onPressed}) {
  return ElevatedButton(
    onPressed: isLoading ? null : onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: isLoading
        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
        : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  );
}

Widget _buildGlassyTextField({
  required TextEditingController controller,
  required String hint,
  IconData? icon,
  required FormFieldValidator<String> validator,
}) {
  return TextFormField(
    controller: controller,
    style: const TextStyle(color: Colors.white),
    validator: validator,
    decoration: _glassyInputDecoration(hint: hint, icon: icon),
  );
}
