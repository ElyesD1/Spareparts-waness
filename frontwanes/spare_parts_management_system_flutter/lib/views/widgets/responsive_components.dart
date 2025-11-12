import 'package:flutter/material.dart';
import '../../utils/responsive_helper.dart';

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? maxWidth;
  final double? minWidth;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;

  const ResponsiveCard({
    Key? key,
    required this.child,
    this.padding,
    this.margin,
    this.maxWidth,
    this.minWidth,
    this.backgroundColor,
    this.boxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? (isMobile ? screenWidth * 0.95 : 1200),
        minWidth: minWidth ?? 0,
      ),
      margin: margin ?? ResponsiveHelper.getResponsiveMargin(context,
        mobile: 16.0, tablet: 24.0, desktop: 32.0),
      padding: padding ?? ResponsiveHelper.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 24),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ResponsiveDialog extends StatelessWidget {
  final Widget child;
  final String? title;
  final double? maxWidth;
  final double? maxHeight;
  final EdgeInsets? padding;

  const ResponsiveDialog({
    Key? key,
    required this.child,
    this.title,
    this.maxWidth,
    this.maxHeight,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    final screenHeight = ResponsiveHelper.getScreenHeight(context);
    final isMobile = ResponsiveHelper.isMobile(context);
    
    final dialogWidth = maxWidth ?? (isMobile ? screenWidth * 0.9 : 600.0);
    final dialogHeight = maxHeight ?? screenHeight * 0.8;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: dialogHeight,
        ),
        padding: padding ?? const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: TextStyle(
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 24,
                        ),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B3C34),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFFB0B3C7)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Flexible(
              child: SingleChildScrollView(
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final bool forceColumn;
  
  const ResponsiveRow({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.forceColumn = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    if (isMobile || forceColumn) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children.map((child) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: child,
        )).toList(),
      );
    } else {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      );
    }
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int maxCrossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  
  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.maxCrossAxisCount = 3,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 16.0,
    this.mainAxisSpacing = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    int crossAxisCount;
    
    if (screenWidth < 600) {
      crossAxisCount = 1;
    } else if (screenWidth < 900) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = maxCrossAxisCount;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}
