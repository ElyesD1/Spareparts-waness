import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/domain/user.dart';

class ResponsiveProfileButton extends StatefulWidget {
  final bool isMobile;
  final Color? backgroundColor;
  final Color? textColor;
  final double? size;
  
  const ResponsiveProfileButton({
    Key? key,
    required this.isMobile,
    this.backgroundColor,
    this.textColor,
    this.size,
  }) : super(key: key);

  @override
  State<ResponsiveProfileButton> createState() => _ResponsiveProfileButtonState();
}

class _ResponsiveProfileButtonState extends State<ResponsiveProfileButton> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      setState(() {
        _user = User.fromJson(jsonDecode(userJson));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) {
      return _buildMobileProfileButton();
    } else {
      return _buildDesktopProfileButton();
    }
  }

  Widget _buildMobileProfileButton() {
    return GestureDetector(
      onTap: () => GoRouter.of(context).go('/profile'),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _user != null
            ? CircleAvatar(
                backgroundColor: Colors.deepPurple[100],
                radius: widget.size ?? 16,
                child: Text(
                  _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: (widget.size ?? 16) * 0.8,
                    color: Colors.deepPurple,
                  ),
                ),
              )
            : CircleAvatar(
                backgroundColor: Colors.grey[300],
                radius: widget.size ?? 16,
                child: Icon(
                  Icons.person, 
                  color: Colors.grey[700],
                  size: (widget.size ?? 16) * 0.8,
                ),
              ),
      ),
    );
  }

  Widget _buildDesktopProfileButton() {
    return GestureDetector(
      onTap: () => GoRouter.of(context).go('/profile'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _user != null
              ? CircleAvatar(
                  backgroundColor: Colors.deepPurple[100],
                  radius: widget.size ?? 20,
                  child: Text(
                    _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: (widget.size ?? 20) * 0.8,
                      color: Colors.deepPurple,
                    ),
                  ),
                )
              : CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  radius: widget.size ?? 20,
                  child: Icon(
                    Icons.person, 
                    color: Colors.grey[700],
                    size: (widget.size ?? 20) * 0.8,
                  ),
                ),
          const SizedBox(width: 12),
          Text(
            _user?.name ?? 'Utilisateur',
            style: TextStyle(
              fontWeight: FontWeight.w600, 
              fontSize: 14,
              color: widget.textColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

