import 'package:flutter/material.dart';

/// A widget that catches and displays user-friendly error messages
/// instead of showing scary red error screens
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;

  const ErrorBoundary({Key? key, required this.child, this.errorBuilder})
    : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();
    // This doesn't actually catch errors in the current widget tree
    // but serves as a wrapper for better error handling
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      return widget.errorBuilder?.call(_errorDetails!) ??
          _buildDefaultErrorWidget(_errorDetails!);
    }

    return widget.child;
  }

  Widget _buildDefaultErrorWidget(FlutterErrorDetails details) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Oups! Quelque chose s\'est mal passé',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3C34),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Une erreur inattendue s\'est produite. Veuillez réessayer.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _errorDetails = null;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A custom ErrorWidget that shows a friendly message instead of red screen
class FriendlyErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const FriendlyErrorWidget({Key? key, required this.errorDetails})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Oups! Une erreur s\'est produite',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3C34),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _getFriendlyErrorMessage(errorDetails.exception),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Try to navigate back or reload
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFriendlyErrorMessage(Object exception) {
    final errorString = exception.toString().toLowerCase();

    if (errorString.contains('parentdata')) {
      return 'Problème d\'affichage de la mise en page. Veuillez réessayer.';
    } else if (errorString.contains('cast')) {
      return 'Problème de format de données. Veuillez vérifier vos entrées.';
    } else if (errorString.contains('null')) {
      return 'Données manquantes. Veuillez remplir tous les champs requis.';
    } else if (errorString.contains('connection') ||
        errorString.contains('network')) {
      return 'Problème de connexion. Vérifiez votre connexion internet.';
    } else if (errorString.contains('timeout')) {
      return 'La requête a pris trop de temps. Veuillez réessayer.';
    } else if (errorString.contains('assertion')) {
      return 'Erreur de validation. Veuillez vérifier vos données.';
    } else {
      return 'Une erreur inattendue s\'est produite. Veuillez réessayer.';
    }
  }
}
