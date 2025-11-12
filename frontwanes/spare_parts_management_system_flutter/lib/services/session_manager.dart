import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SessionManager {
  static const String _userKey = 'user';

  // Sauvegarder l'utilisateur (sous forme de Map ou JSON)
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert MongoDB _id to id for frontend compatibility
    if (user.containsKey('_id') && !user.containsKey('id')) {
      user['id'] = user['_id'];
    }
    await prefs.setString(_userKey, jsonEncode(user));
  }

  // Récupérer l'utilisateur (Map<String, dynamic> ou null)
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    final user = jsonDecode(userJson) as Map<String, dynamic>;
    // Convert MongoDB _id to id for frontend compatibility if not already present
    if (user.containsKey('_id') && !user.containsKey('id')) {
      user['id'] = user['_id'];
    }
    return user;
  }

  // Supprimer la session utilisateur
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  // Vérifier si un utilisateur est connecté
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_userKey);
  }
}
