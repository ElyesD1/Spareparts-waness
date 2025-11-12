import 'package:flutter/material.dart';
import '../services/user_service.dart';

class LoginViewModel extends ChangeNotifier {
  final UserService _userService = UserService();

  bool isLoading = false;
  String? errorMessage;

  Future<Map<String, dynamic>?> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final result = await _userService.login(email, password);
      isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return null;
    }
  }
} 