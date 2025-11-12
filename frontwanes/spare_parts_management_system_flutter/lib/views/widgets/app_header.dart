import 'package:flutter/material.dart';
import 'responsive_profile_button.dart';

class AppHeader extends StatefulWidget {
  final bool isMobile;
  
  const AppHeader({Key? key, this.isMobile = false}) : super(key: key);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ResponsiveProfileButton(
          isMobile: widget.isMobile,
          textColor: Colors.black87,
        ),
      ],
    );
  }
} 