import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({Key? key, required this.userId, this.email}) : super(key: key);

  final int userId;
  final String? email;

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
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => GoRouter.of(context).go('/login'),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 32),
                  child: _VerificationForm(email: email, userId: userId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerificationForm extends StatefulWidget {
  const _VerificationForm({required this.userId, this.email});
  final int userId;
  final String? email;

  @override
  _VerificationFormState createState() => _VerificationFormState();
}

class _VerificationFormState extends State<_VerificationForm> {
  final _pinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _handleVerifyCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      setState(() => _loading = false);
      if (mounted && widget.userId != null) {
        GoRouter.of(context).go('/reset-password?userId=${widget.userId}&otp=${_pinController.text.trim()}');
      }
    }
  }

  void _resendCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Verification code resent to ${widget.email}'),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 22, color: Colors.white),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
    );

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Verification',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Please enter the code we just sent to your email",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
          ),
          const SizedBox(height: 48),
          Pinput(
            controller: _pinController,
            length: 6,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
            ),
            submittedPinTheme: defaultPinTheme,
            validator: (s) {
              return s != null && s.length == 6 ? null : 'Pin is incorrect';
            },
          ),
          const SizedBox(height: 32),
          _buildPrimaryButton(
            text: 'Verify',
            isLoading: _loading,
            onPressed: _handleVerifyCode,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Didn't receive the code?", style: TextStyle(color: Colors.white.withOpacity(0.7))),
              TextButton(
                onPressed: _resendCode,
                child: const Text('Resend Code', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({required String text, required bool isLoading, required VoidCallback onPressed}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 5,
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.black))
          : Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
} 