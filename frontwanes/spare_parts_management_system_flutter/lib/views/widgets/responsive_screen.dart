import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/responsive_profile_button.dart';
import '../../utils/responsive_helper.dart';

class ResponsiveScreen extends StatelessWidget {
  final Widget child;
  final SidebarSection selectedSidebarSection;
  final String? title;
  final List<Widget>? actions;
  final FloatingActionButton? floatingActionButton;
  final Color? backgroundColor;

  const ResponsiveScreen({
    Key? key,
    required this.child,
    required this.selectedSidebarSection,
    this.title,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Scaffold(
      backgroundColor: backgroundColor ?? const Color(0xFFF8FAFC),
      // Add drawer for mobile
      drawer: isMobile ? Drawer(
        child: Sidebar(selected: selectedSidebarSection),
      ) : null,
      // Add app bar for mobile with menu button
      appBar: isMobile ? AppBar(
        title: Text(title ?? 'Application'),
        backgroundColor: backgroundColor ?? const Color(0xFFF8FAFC),
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          if (actions != null) ...actions!,
          ResponsiveProfileButton(
            isMobile: true,
            backgroundColor: Colors.white.withOpacity(0.2),
            size: 16,
          ),
          const SizedBox(width: 8),
        ],
      ) : null,
      body: Row(
        children: [
          // Only show sidebar on desktop
          if (!isMobile) Sidebar(selected: selectedSidebarSection),
          Expanded(
            child: child,
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
