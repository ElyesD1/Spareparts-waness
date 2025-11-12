import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:spare_parts_management_system_flutter/services/user_service.dart'; // Added import for UserService
import '../config/app_config.dart';

class AuthService {
  static final String _baseUrl = AppConfig.authUrl;
  static const Duration _tokenRefreshThreshold = Duration(minutes: 5);

  // Cache for JWT payload to avoid repeated decoding
  Map<String, dynamic>? _cachedJwtPayload;

  // Getter for JWT payload
  Map<String, dynamic>? get jwtPayload => _cachedJwtPayload;

  // Getter for current user ID from JWT
  String? get currentUserId => _cachedJwtPayload?['sub'];

  // Getter for user role from JWT
  String? get userRole => _cachedJwtPayload?['role'];

  // Check if token is expired or about to expire
  bool _isTokenExpiringSoon(Map<String, dynamic> payload) {
    try {
      final expiration = DateTime.fromMillisecondsSinceEpoch(
        payload['exp'] * 1000,
      );
      final now = DateTime.now();
      return now.isAfter(expiration.subtract(_tokenRefreshThreshold));
    } catch (e) {
      return true; // Assume token needs refresh if we can't verify expiration
    }
  }

  // Decode JWT token to extract user information
  Map<String, dynamic>? _decodeJwtToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);

      // Verify token expiration
      final expiration = DateTime.fromMillisecondsSinceEpoch(
        payloadMap['exp'] * 1000,
      );
      if (DateTime.now().isAfter(expiration)) {
        return null;
      }

      return payloadMap;
    } catch (e) {
      return null;
    }
  }

  // Refresh the access token
  Future<String?> _refreshToken(String currentToken) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/refresh'),
        headers: {
          'Authorization': 'Bearer $currentToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newToken = data['access_token'];

        // Save new token and update cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', newToken);
        _cachedJwtPayload = _decodeJwtToken(newToken);

        return newToken;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get and validate current token
  Future<String?> getValidToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      return null;
    }

    final payload = _decodeJwtToken(token);
    if (payload == null) {
      await _clearAuthData();
      return null;
    }

    if (_isTokenExpiringSoon(payload)) {
      return await _refreshToken(token);
    }

    return token;
  }

  // Clear auth data
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user');
    _cachedJwtPayload = null;
  }

  // Fetch current user profile from backend
  Future<Map<String, dynamic>?> _fetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) {
        return null;
      }

      // Use cached JWT payload or decode if not available
      final payload = _cachedJwtPayload ?? _decodeJwtToken(token);
      if (payload == null) {
        return null;
      }

      // Cache the payload if not already cached
      _cachedJwtPayload ??= payload;

      final userId = payload['sub'];
      if (userId == null) {
        return null;
      }

      // Appel du UserService pour récupérer le profil par id
      final user = await UserService().getUserById(userId);
      // Convert User object to Map<String, dynamic>
      if (user != null) {
        return user.toJson(); // Convert User object to Map
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get current user from shared preferences or fetch from backend
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = await getValidToken();
    if (token == null) {
      await _clearAuthData();
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    // If we have stored user data, validate it
    if (userJson != null) {
      try {
        final storedUser = jsonDecode(userJson) as Map<String, dynamic>;

        // Convert MongoDB _id to id for frontend compatibility
        if (storedUser.containsKey('_id') && !storedUser.containsKey('id')) {
          storedUser['id'] = storedUser['_id'];
        }

        final storedUserId = storedUser['userId'] ?? storedUser['id'];

        // Verify the stored user matches the JWT subject
        if (storedUserId.toString() == currentUserId) {
          return storedUser;
        } else {
          await prefs.remove('user');
        }
      } catch (e) {
        await prefs.remove('user');
      }
    }

    // Fetch fresh user data from backend
    final userData = await _fetchUserProfile();
    if (userData != null) {
      // Normalize user ID field
      if (userData['userId'] == null && userData['id'] != null) {
        userData['userId'] = userData['id'];
      }

      // Cache the fresh user data
      await prefs.setString('user', jsonEncode(userData));
      return userData;
    }

    // If backend fetch fails, use JWT data as fallback
    if (_cachedJwtPayload != null) {
      final jwtUserData = {
        'userId': currentUserId,
        'email': _cachedJwtPayload!['email'],
        'role': userRole,
      };

      await prefs.setString('user', jsonEncode(jwtUserData));
      return jwtUserData;
    }

    return null;
  }

  // Get current user ID
  Future<String?> getCurrentUserId() async {
    final user = await getCurrentUser();
    final userId = user?['id'];
    return userId?.toString();
  }

  // Get user by ID from API
  // Removed: Duplicated with UserService

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final hasToken = prefs.getString('access_token') != null;
    return hasToken;
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user');
  }

  // Debug method to print all stored data
  Future<void> debugStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final user = prefs.getString('user');

    // Also decode and show JWT payload
    if (token != null) {
      final jwtPayload = _decodeJwtToken(token);
      if (jwtPayload != null) {}
    }
  }

  // Test method to manually decode a JWT token
  void testJwtDecoding(String token) {
    final payload = _decodeJwtToken(token);
    if (payload != null) {
    } else {}
  }

  // Method to get current JWT user ID
  Future<String?> getCurrentJwtUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return null;

    final jwtPayload = _decodeJwtToken(token);
    if (jwtPayload != null) {
      final userId = jwtPayload['sub'];
      return userId?.toString();
    }
    return null;
  }
}
