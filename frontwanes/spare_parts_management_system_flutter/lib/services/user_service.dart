import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/domain/user.dart';
import 'session_manager.dart';
import '../config/app_config.dart';

class UserService {
  static final String baseUrl = AppConfig.baseUrl;
  static final String _authBaseUrl = AppConfig.authUrl;

  // Helper method to get access token from SharedPreferences
  static Future<String> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token found. Please log in again.');
    }

    return accessToken;
  }

  // Authentication methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_authBaseUrl/login');
    final body = jsonEncode({'email': email, 'password': password});

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('LOGIN ERROR: ' + e.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required int phoneNumber,
    required String role,
    String? warehouseName,
  }) async {
    final url = Uri.parse('$_authBaseUrl/signup');
    final body = jsonEncode({
      'name': name,
      'email': email,
      'password': password,
      'phone_number': phoneNumber,
      'role': role,
      if (warehouseName != null && warehouseName.isNotEmpty)
        'warehouse_name': warehouseName,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          jsonDecode(response.body)['message'] ?? 'Register failed',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final url = Uri.parse('${AppConfig.authUrl}/forgot-password');
    final body = jsonEncode({'email': email, 'password': ''});

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          jsonDecode(response.body)['message'] ?? 'Forgot password failed',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required int userId,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final url = Uri.parse('${AppConfig.otpUrl}/reset-password');
    final body = jsonEncode({
      'userId': userId,
      'otp': otp,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          jsonDecode(response.body)['message'] ?? 'Reset password failed',
        );
      }
    } catch (e) {
      print('RESET PASSWORD ERROR: ' + e.toString());
      rethrow;
    }
  }

  Future<User?> fetchCurrentUser(String accessToken) async {
    final url = Uri.parse('$_authBaseUrl/me');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return User.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      print('FETCH CURRENT USER ERROR: ' + e.toString());
      return null;
    }
  }

  Future<void> saveUserToPrefs(User user) async {
    // This method is handled by SessionManager now
  }

  Future<User?> getUserById(String id) async {
    final response = await http.get(
      Uri.parse('${AppConfig.usersUrl}/profile/$id'),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateUserProfile(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.patch(
      Uri.parse('${AppConfig.usersUrl}/update/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update user profile');
    }
  }

  // User management methods (for admin)
  static Future<List<User>> getUsers() async {
    try {
      final accessToken = await _getAccessToken();

      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading users: $e');
    }
  }

  static Future<User> createUser(User user) async {
    try {
      final response = await http.post(
        Uri.parse('$_authBaseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  static Future<User> updateUser(User user) async {
    try {
      final accessToken = await _getAccessToken();

      final response = await http.patch(
        Uri.parse('$baseUrl/users/update/${user.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(user.toJson()),
      );

      if (response.statusCode == 200) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  static Future<void> deleteUser(String userId) async {
    try {
      print('🔄 [UserService] Deleting user with ID: $userId');

      // Validate user ID
      if (userId.isEmpty) {
        throw Exception('Invalid user ID: $userId');
      }

      final accessToken = await _getAccessToken();
      print(
        '🔄 [UserService] Found access token: ${accessToken.substring(0, 20)}...',
      );

      final url = Uri.parse('$baseUrl/users/$userId');
      print('🔄 [UserService] Making DELETE request to: $url');
      print(
        '🔄 [UserService] Authorization header: Bearer ${accessToken.substring(0, 20)}...',
      );

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      print('🔄 [UserService] Response status: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        print('🔄 [UserService] Response body: ${response.body}');
      }

      if (response.statusCode == 401) {
        print(
          '❌ [UserService] 401 Unauthorized - Token might be expired or invalid',
        );
        print('❌ [UserService] Full response headers: ${response.headers}');
        throw Exception('Unauthorized: Please log in again');
      } else if (response.statusCode == 403) {
        throw Exception(
          'Forbidden: You do not have permission to delete users',
        );
      } else if (response.statusCode == 404) {
        throw Exception(
          'User not found: The user may have already been deleted',
        );
      } else if (response.statusCode != 200 && response.statusCode != 204) {
        print('❌ [UserService] Failed to delete user: ${response.statusCode}');
        throw Exception('Failed to delete user: ${response.statusCode}');
      }

      print('✅ [UserService] User deleted successfully');
    } catch (e) {
      print('❌ [UserService] Error deleting user: $e');
      throw Exception('Error deleting user: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getWarehouses() async {
    try {
      final accessToken = await _getAccessToken();

      final response = await http.get(
        Uri.parse('$baseUrl/warehouses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load warehouses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading warehouses: $e');
    }
  }
}
