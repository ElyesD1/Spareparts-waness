import 'package:flutter/material.dart';
import '../../models/domain/product.dart';
import '../../config/app_config.dart';

class ProductDetailsModal extends StatelessWidget {
  final Product product;
  final VoidCallback? onEdit;

  const ProductDetailsModal({Key? key, required this.product, this.onEdit})
    : super(key: key);

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
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.blue.shade600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Détails du produit',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    color: Colors.grey[600],
                  ),
                ],
              ),
              const Divider(height: 32),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image and Basic Info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child:
                                  product.image != null &&
                                          product.image!.isNotEmpty
                                      ? Image.network(
                                        getProductImageUrl(product.image),
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Icon(
                                            Icons.image_not_supported,
                                            size: 48,
                                            color: Colors.grey[400],
                                          );
                                        },
                                      )
                                      : Icon(
                                        Icons.inventory_2_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                            ),
                          ),
                          const SizedBox(width: 32),

                          // Product Information
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoSection('Informations générales', [
                                  _buildInfoRow('Nom', product.name),
                                  _buildInfoRow(
                                    'Référence',
                                    product.referenceCode,
                                  ),
                                  if (product.brand != null)
                                    _buildInfoRow('Marque', product.brand!),
                                  if (product.category != null)
                                    _buildInfoRow(
                                      'Catégorie',
                                      product.category!,
                                    ),
                                ]),
                                const SizedBox(height: 24),
                                _buildInfoSection('Tarification', [
                                  _buildInfoRow(
                                    'Prix unitaire',
                                    '${product.unitPrice.toStringAsFixed(2)} TND',
                                    valueColor: Colors.green[700],
                                    valueFontWeight: FontWeight.bold,
                                  ),
                                  if (product.supplierPrice != null)
                                    _buildInfoRow(
                                      'Prix fournisseur',
                                      '${product.supplierPrice!.toStringAsFixed(2)} TND',
                                    ),
                                ]),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Description
                      if (product.description != null &&
                          product.description!.isNotEmpty) ...[
                        _buildInfoSection('Description', [
                          Text(
                            product.description!,
                            style: const TextStyle(fontSize: 14, height: 1.6),
                          ),
                        ]),
                        const SizedBox(height: 32),
                      ],

                      // Supplier Information
                      if (product.supplier != null)
                        _buildInfoSection('Information fournisseur', [
                          _buildInfoRow(
                            'Nom',
                            product.supplier!['name'] ?? 'N/A',
                          ),
                          if (product.supplier!['contact'] != null)
                            _buildInfoRow(
                              'Contact',
                              product.supplier!['contact'],
                            ),
                        ]),
                    ],
                  ),
                ),
              ),

              // Footer
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Modifier'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? const Color(0xFF1F2937),
                fontWeight: valueFontWeight ?? FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
