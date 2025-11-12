import 'package:flutter/material.dart';
import '../../utils/responsive_helper.dart';

class ResponsiveFormField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool isRequired;
  final double? width;

  const ResponsiveFormField({
    Key? key,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: TextStyle(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                  mobile: 14, tablet: 16, desktop: 16),
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1B3C34),
              ),
              children: isRequired ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
              ] : null,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool isExpanded;

  const ResponsiveButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.isExpanded = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? const Color(0xFF6C63FF),
        foregroundColor: textColor ?? Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: isMobile ? 12 : 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  textColor ?? Colors.white,
                ),
              ),
            )
          : Row(
              mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context,
                      mobile: 14, tablet: 16, desktop: 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );

    return isExpanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class ResponsiveSearchBar extends StatelessWidget {
  final String hintText;
  final Function(String) onChanged;
  final double? width;
  final TextEditingController? controller;

  const ResponsiveSearchBar({
    Key? key,
    required this.hintText,
    required this.onChanged,
    this.width,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Container(
      width: width ?? (isMobile ? double.infinity : 260),
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
        onChanged: onChanged,
        style: TextStyle(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context,
            mobile: 14, tablet: 16, desktop: 16),
        ),
      ),
    );
  }
}

class ResponsiveDataTable extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;
  final bool isLoading;

  const ResponsiveDataTable({
    Key? key,
    required this.headers,
    required this.rows,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (isMobile) {
      // Card-based layout for mobile
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(headers.length, (i) {
                  if (i < rows[index].length) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              '${headers[i]}:',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(child: rows[index][i]),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ),
            ),
          );
        },
      );
    } else {
      // Table layout for desktop/tablet
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: headers
              .map((header) => DataColumn(
                    label: Text(
                      header,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ))
              .toList(),
          rows: rows
              .map((row) => DataRow(
                    cells: row
                        .map((cell) => DataCell(cell))
                        .toList(),
                  ))
              .toList(),
        ),
      );
    }
  }
}
