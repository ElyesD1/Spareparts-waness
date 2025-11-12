import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/user_service.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({Key? key, this.userId, this.otp}) : super(key: key);

  final int? userId;
  final String? otp;

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
                    child: _ResetPasswordForm(userId: userId, otp: otp),
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

class _ResetPasswordForm extends StatefulWidget {
  const _ResetPasswordForm({this.userId, this.otp});
  final int? userId;
  final String? otp;
  @override
  _ResetPasswordFormState createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<_ResetPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _userService = UserService();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      if (widget.userId == null || widget.otp == null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Missing user ID or OTP.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      setState(() => _loading = true);
      try {
        final response = await _userService.resetPassword(
          userId: widget.userId!,
          otp: widget.otp!,
          newPassword: _passwordController.text.trim(),
          confirmPassword: _confirmPasswordController.text.trim(),
        );
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
                      'Password Reset',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        response['message'] ?? 'You can now use your new password to log in to your account!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                          Navigator.of(context).pop();
                        GoRouter.of(context).go('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('LOG IN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
          const Text('Reset Password', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Your new password must be different from previous used passwords.', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16)),
          const SizedBox(height: 32),
          _buildGlassyPasswordField(
            controller: _passwordController,
            hint: 'New Password',
            obscureText: _obscurePassword,
            onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter a new password';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildGlassyPasswordField(
            controller: _confirmPasswordController,
            hint: 'Confirm New Password',
            obscureText: _obscureConfirmPassword,
            onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            validator: (value) {
              if (value != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(text: 'Reset Password', isLoading: _loading, onPressed: _handleResetPassword),
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

Widget _buildGlassyPasswordField({
  required TextEditingController controller,
  required String hint,
  required bool obscureText,
  required VoidCallback onToggleVisibility,
  required FormFieldValidator<String> validator,
}) {
  return TextFormField(
    controller: controller,
    obscureText: obscureText,
    style: const TextStyle(color: Colors.white),
    validator: validator,
    decoration: _glassyInputDecoration(hint: hint, icon: Icons.lock_outline).copyWith(
      suffixIcon: IconButton(
        icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white.withOpacity(0.7)),
        onPressed: onToggleVisibility,
      ),
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
}
