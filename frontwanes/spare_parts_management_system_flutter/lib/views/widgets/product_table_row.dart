import 'package:flutter/material.dart';
import '../../models/domain/product.dart';
import '../../config/app_config.dart';

class ProductTableRow extends StatefulWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductTableRow({
    Key? key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<ProductTableRow> createState() => _ProductTableRowState();
}

class _ProductTableRowState extends State<ProductTableRow> {
  bool isHovered = false;

  String getProductImageUrl(String? image) {
    if (image == null || image.isEmpty) {
      return '';
    }

    if (image.startsWith('http')) {
      return image;
    }

    String cleanImage = image.replaceAll(RegExp(r'^[/\\]+'), '');
    return '${AppConfig.uploadsUrl}/$cleanImage';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isHovered ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isHovered ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
            width: 1,
          ),
          boxShadow:
              isHovered
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  // Modern Product Image
                  _buildProductImage(),
                  const SizedBox(width: 20),

                  // Product Info
                  Expanded(flex: 3, child: _buildProductInfo()),

                  // Category Badge
                  Expanded(flex: 2, child: _buildCategoryBadge()),

                  // Supplier Info
                  Expanded(flex: 2, child: _buildSupplierInfo()),

                  // Price
                  Expanded(flex: 2, child: _buildPriceInfo()),

                  // Modern Actions
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
        ),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child:
            widget.product.image != null && widget.product.image!.isNotEmpty
                ? Image.network(
                  getProductImageUrl(widget.product.image),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey[100]!, Colors.grey[200]!],
                        ),
                      ),
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey[500],
                        size: 24,
                      ),
                    );
                  },
                )
                : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF64748B).withOpacity(0.1),
                        const Color(0xFF475569).withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: const Color(0xFF64748B),
                    size: 28,
                  ),
                ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.product.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF1E293B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          widget.product.referenceCode,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.1),
            const Color(0xFF1D4ED8).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
      ),
      child: Text(
        widget.product.category ?? 'Non catégorisé',
        style: const TextStyle(
          color: Color(0xFF1E40AF),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSupplierInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fournisseur',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.product.supplier?['name'] ?? 'N/A',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPriceInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF059669).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Text(
        '${widget.product.unitPrice.toStringAsFixed(2)} DNT',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF047857),
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.edit_rounded,
          onPressed: widget.onEdit,
          color: const Color(0xFF3B82F6),
          tooltip: 'Modifier',
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.delete_rounded,
          onPressed: widget.onDelete,
          color: const Color(0xFFEF4444),
          tooltip: 'Supprimer',
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}
