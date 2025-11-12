import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class ApiClient {
  final String baseUrl;
  final AuthService _auth;

  ApiClient({String? baseUrl, AuthService? auth})
    : baseUrl = baseUrl ?? AppConfig.baseUrl,
      _auth = auth ?? AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getValidToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  String _friendlyErrorMessage(int statusCode, String body, String action) {
    // Parse backend error message if available
    String backendMessage = '';
    try {
      final json = jsonDecode(body);
      backendMessage = json['message'] ?? json['error'] ?? '';
    } catch (e) {
      // Not JSON or doesn't have message
    }

    // Return user-friendly messages based on status code
    switch (statusCode) {
      case 400:
        return backendMessage.isNotEmpty
            ? backendMessage
            : 'Données invalides. Veuillez vérifier vos entrées.';
      case 401:
        return 'Session expirée. Veuillez vous reconnecter.';
      case 403:
        return 'Accès refusé. Vous n\'avez pas les permissions nécessaires.';
      case 404:
        return 'Ressource non trouvée.';
      case 409:
        return backendMessage.isNotEmpty
            ? backendMessage
            : 'Cette opération crée un conflit. Vérifiez les données existantes.';
      case 422:
        return backendMessage.isNotEmpty
            ? backendMessage
            : 'Données invalides. Veuillez vérifier tous les champs.';
      case 500:
      case 502:
      case 503:
        return 'Erreur serveur. Veuillez réessayer plus tard.';
      default:
        if (statusCode >= 500) {
          return 'Erreur serveur. Veuillez réessayer plus tard.';
        }
        return backendMessage.isNotEmpty
            ? backendMessage
            : 'Une erreur s\'est produite lors de $action. Veuillez réessayer.';
    }
  }

  Future<dynamic> get(String path) async {
    try {
      final res = await http.get(_u(path), headers: await _headers());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(
        _friendlyErrorMessage(
          res.statusCode,
          res.body,
          'la récupération des données',
        ),
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
        'Erreur de connexion. Vérifiez votre connexion internet.',
      );
    }
  }

  Future<dynamic> post(String path, dynamic body) async {
    try {
      final res = await http.post(
        _u(path),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(
        _friendlyErrorMessage(res.statusCode, res.body, 'la création'),
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
        'Erreur de connexion. Vérifiez votre connexion internet.',
      );
    }
  }

  Future<dynamic> put(String path, dynamic body) async {
    try {
      final res = await http.put(
        _u(path),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      }
      throw Exception(
        _friendlyErrorMessage(res.statusCode, res.body, 'la mise à jour'),
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
        'Erreur de connexion. Vérifiez votre connexion internet.',
      );
    }
  }

  Future<void> delete(String path) async {
    try {
      final res = await http.delete(_u(path), headers: await _headers());
      if (res.statusCode >= 200 && res.statusCode < 300) return;
      throw Exception(
        _friendlyErrorMessage(res.statusCode, res.body, 'la suppression'),
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(
        'Erreur de connexion. Vérifiez votre connexion internet.',
      );
    }
  }
}
