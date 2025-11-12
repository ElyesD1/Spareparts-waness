import 'package:flutter/material.dart';
import '../../utils/responsive_helper.dart';
import 'sidebar.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final SidebarSection? sidebarSection;

  const ResponsiveWrapper({
    Key? key,
    required this.child,
    this.sidebarSection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    if (isMobile) {
      return Scaffold(
        drawer: sidebarSection != null ? Drawer(
          child: Sidebar(selected: sidebarSection!),
        ) : null,
        body: child,
      );
    } else {
      return Row(
        children: [
          if (sidebarSection != null) Sidebar(selected: sidebarSection!),
          Expanded(child: child),
        ],
      );
    }
  }
}
