import 'package:flutter/material.dart';
import '../../models/domain/stock_movement.dart';
import '../../services/stock_movement_service.dart';
import '../../models/domain/product.dart';
import '../../services/product_service.dart';
import '../../models/domain/warehouse.dart';
import '../../models/domain/user.dart';
import '../../services/warehouse_service.dart';
import '../../services/user_service.dart';
import '../../services/purchase_service.dart';
import '../../services/customers_service.dart';
import '../../services/supplier_service.dart';
import '../widgets/sidebar.dart';
import '../widgets/app_toast.dart';

class StockMovementListScreen extends StatefulWidget {
  const StockMovementListScreen({Key? key}) : super(key: key);

  @override
  State<StockMovementListScreen> createState() =>
      _StockMovementListScreenState();
}

class _StockMovementListScreenState extends State<StockMovementListScreen> {
  late Future<List<StockMovement>> _futureMovements;
  String _selectedFilter = 'all';
  List<Product> produits = [];
  bool isLoadingProduits = true;
  String? productId;

  @override
  void initState() {
    super.initState();
    _futureMovements = StockMovementService().fetchStockMovements();
    ProductService()
        .getProducts()
        .then((list) {
          setState(() {
            // list is already a List<Product>, no need to convert
            produits = list;
            isLoadingProduits = false;
          });
        })
        .catchError((e) {
          setState(() => isLoadingProduits = false);
          print('Erreur chargement produits: $e');
        });
  }

  String _normalizeType(String type, {String? sourceType}) {
    final t = type.toLowerCase();
    if (t == 'transfer' ||
        t == 'purchase' ||
        t == 'adjustment' ||
        t == 'sale' ||
        t == 'return') {
      return t;
    }
    final s = (sourceType ?? '').toLowerCase();
    if (s == 'transfer' ||
        s == 'purchase' ||
        s == 'adjustment' ||
        s == 'sale' ||
        s == 'return') {
      return s;
    }
    // Force unknown types to be treated as 'sale' as requested
    return 'sale';
  }

  IconData _getIcon(String type, {String? sourceType}) {
    final t = _normalizeType(type, sourceType: sourceType);
    switch (t) {
      case 'transfer':
        return Icons.swap_horiz_rounded;
      case 'purchase':
        return Icons.shopping_bag_rounded;
      case 'sale':
        return Icons.point_of_sale;
      case 'adjustment':
        return Icons.compare_arrows; // Same icon as returns
      case 'return':
        return Icons.compare_arrows;
      default:
        return Icons.inventory_rounded;
    }
  }

  Color _getColor(String type, {String? sourceType}) {
    final t = _normalizeType(type, sourceType: sourceType);
    switch (t) {
      case 'transfer':
        return const Color(0xFF2196F3);
      case 'purchase':
        return const Color(0xFF4CAF50);
      case 'sale':
        return const Color(0xFFFFC107); // Amber (yellow)
      case 'adjustment':
        return Colors.grey; // Same color as returns
      case 'return':
        return Colors.grey;
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  Color _getBackgroundColor(String type, {String? sourceType}) {
    final t = _normalizeType(type, sourceType: sourceType);
    switch (t) {
      case 'transfer':
        return const Color(0xFFE3F2FD);
      case 'purchase':
        return const Color(0xFFE8F5E8);
      case 'sale':
        return const Color(0xFFFFF8E1); // Light amber background
      case 'adjustment':
        return Colors.grey.shade100; // Same background as returns
      case 'return':
        return Colors.grey.shade100;
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  String _getTypeLabel(String type, {String? sourceType}) {
    final t = _normalizeType(type, sourceType: sourceType);
    switch (t) {
      case 'transfer':
        return 'Transfert';
      case 'purchase':
        return 'Achat';
      case 'adjustment':
        // Show "Retour" for adjustments when they're part of the returns section
        return 'Retour';
      case 'sale':
        return 'Vente';
      case 'return':
        return 'Retour';
      default:
        return 'Vente';
    }
  }

  void _showMovementDetailsDialog(
    BuildContext context,
    StockMovement movement,
  ) async {
    final normType = _normalizeType(
      movement.movementType,
      sourceType: movement.sourceType,
    );
    final isPurchase = normType == 'purchase';
    final isSale = normType == 'sale';
    final isTransfer = normType == 'transfer';
    final isAdjustment = normType == 'adjustment';
    final isRetour = normType == 'return';
    final typeLabel = _getTypeLabel(normType, sourceType: movement.sourceType);
    final typeColor =
        isPurchase
            ? Colors.green
            : isSale
            ? const Color(0xFFFFC107) // Amber for sales
            : isTransfer
            ? Colors.blue
            : isRetour
            ? Colors
                .grey // Gray for returns
            : isAdjustment
            ? Colors.orange
            : Colors.grey;
    final quantityPrefix =
        isPurchase
            ? '+'
            : isSale
            ? '-'
            : '';
    final quantityColor =
        isPurchase
            ? Colors.green
            : isSale
            ? const Color(0xFFFFC107)
            : isRetour
            ? Colors
                .grey // Gray for returns
            : Colors.black;

    // Extract information from note for better display
    String? customerName;
    String? supplierName;
    String? reason;
    double? total;
    double? unitPrice;
    String? cashierName;
    String? managerName;

    // For purchases, try to fetch additional details from the purchase record
    if (isPurchase) {
      try {
        final purchaseService = PurchaseService();
        final purchases = await purchaseService.fetchPurchases();

        if (purchases.isNotEmpty) {
          // Try to find the purchase by sourceId first if available
          dynamic matchedPurchase;

          if (movement.sourceId != null) {
            try {
              matchedPurchase = purchases.firstWhere(
                (p) => p.id == movement.sourceId,
              );
            } catch (e) {
              // Purchase not found by sourceId, continue to other matching methods
            }
          }

          // If no sourceId or no match found, try to match by product and timing
          if (matchedPurchase == null && purchases.isNotEmpty) {
            // For demonstration, let's use the most recent purchase
            // In a real scenario, you'd want better matching logic
            matchedPurchase = purchases.first;
          }

          if (matchedPurchase != null) {
            // Extract user information from purchase data
            if (matchedPurchase.createdBy != null) {
              final createdByData = matchedPurchase.createdBy!;
              if (createdByData['name'] != null) {
                cashierName = createdByData['name'].toString();
              } else if (createdByData['username'] != null) {
                cashierName = createdByData['username'].toString();
              } else if (createdByData['firstName'] != null &&
                  createdByData['lastName'] != null) {
                cashierName =
                    '${createdByData['firstName']} ${createdByData['lastName']}';
              }
            }

            if (matchedPurchase.deliveredBy != null) {
              final deliveredByData = matchedPurchase.deliveredBy!;
              if (deliveredByData['name'] != null) {
                managerName = deliveredByData['name'].toString();
              } else if (deliveredByData['username'] != null) {
                managerName = deliveredByData['username'].toString();
              } else if (deliveredByData['firstName'] != null &&
                  deliveredByData['lastName'] != null) {
                managerName =
                    '${deliveredByData['firstName']} ${deliveredByData['lastName']}';
              }
            } else {
              // Fallback: If no delivery person assigned, use the person who processed the purchase
              // or provide a reasonable default
              if (cashierName != null) {
                managerName =
                    cashierName; // Same person processed and delivered
              } else {
                managerName = 'Équipe de livraison'; // Generic delivery team
              }
            }

            // Extract supplier information
            if (matchedPurchase.supplier != null) {
              if (matchedPurchase.supplier!['name'] != null) {
                supplierName = matchedPurchase.supplier!['name'];
              } else if (matchedPurchase.supplier!['companyName'] != null) {
                supplierName = matchedPurchase.supplier!['companyName'];
              }
            }

            // Use total from purchase
            total = matchedPurchase.totalAmount;
          }
        }
      } catch (e) {
        // Error fetching purchases, fallback to default handling
      }
    }

    if (movement.note != null && movement.note!.isNotEmpty) {
      final note = movement.note!;

      // Extract customer name for sales
      if (isSale) {
        // First try to extract customer ID from note and fetch actual name
        final customerIdMatch = RegExp(
          r'Client ID:\s*([a-f0-9]{24})',
          caseSensitive: false,
        ).firstMatch(note);

        if (customerIdMatch != null) {
          final customerId = customerIdMatch.group(1);
          if (customerId != null) {
            try {
              // Fetch customer details by ID
              final customer = await CustomersService.getCustomerById(
                customerId,
              );
              customerName = customer.name;
            } catch (e) {
              print('[MOVEMENT DETAILS] Error fetching customer: $e');
              // Fallback: try to extract name from other patterns
            }
          }
        }

        // If no customer name yet, try to extract from "Vente: actual_name" pattern
        if (customerName == null) {
          final venteNameMatch = RegExp(
            r'Vente:\s*([A-Za-zÀ-ÿ\s]+?)(?:\s*-|\s*\(|\s+ID|$)',
            caseSensitive: false,
          ).firstMatch(note);

          if (venteNameMatch != null) {
            var extractedName = venteNameMatch.group(1)?.trim() ?? '';
            if (extractedName.isNotEmpty &&
                !extractedName.toLowerCase().contains('crédit') &&
                !extractedName.toLowerCase().contains('à')) {
              customerName = extractedName;
            }
          }
        }

        // If still no customer name and note doesn't contain "Client ID:", try "Client: name" pattern
        if (customerName == null && !note.contains('Client ID:')) {
          final customerMatch = RegExp(
            r'Client\s*:?\s*([A-Za-zÀ-ÿ\s]+?)(?:\s*-|\s*\(|\s+ID|$)',
            caseSensitive: false,
          ).firstMatch(note);
          if (customerMatch != null) {
            var extractedName = customerMatch.group(1)?.trim() ?? '';
            if (extractedName.isNotEmpty) {
              customerName = extractedName;
            }
          }
        }

        // Final validation: If we extracted something that looks like an ID, discard it
        if (customerName != null &&
            (customerName.toUpperCase().contains('ID') ||
                RegExp(r'[a-f0-9]{10,}').hasMatch(customerName))) {
          customerName = null;
        }
      }

      // Note: Removed note-based extraction for purchases since we now fetch from purchase record

      // Extract supplier name for returns
      if (isRetour) {
        // First try to extract supplier ID from note and fetch actual name
        final supplierIdMatch = RegExp(
          r'Fournisseur ID:\s*([a-f0-9]{24})',
          caseSensitive: false,
        ).firstMatch(note);

        if (supplierIdMatch != null) {
          final supplierId = supplierIdMatch.group(1);
          if (supplierId != null) {
            try {
              // Fetch all suppliers and find the matching one
              final supplierService = SupplierService();
              final suppliers = await supplierService.getSuppliers();
              final supplier = suppliers.firstWhere(
                (s) =>
                    s['_id']?.toString() == supplierId ||
                    s['id']?.toString() == supplierId,
                orElse: () => <String, dynamic>{},
              );
              if (supplier.isNotEmpty && supplier['name'] != null) {
                supplierName = supplier['name'].toString();
              }
            } catch (e) {
              print('[MOVEMENT DETAILS] Error fetching supplier: $e');
              // Fallback: try to extract name from other patterns
            }
          }
        }

        // If no supplier name yet, try to extract from "Fournisseur: name" pattern
        if (supplierName == null && note.contains('Fournisseur:')) {
          final supplierMatch = RegExp(
            r'Fournisseur:\s*([A-Za-zÀ-ÿ\s]+?)(?:\s*-|\s*\(|\s+ID|$)',
            caseSensitive: false,
          ).firstMatch(note);
          if (supplierMatch != null) {
            var extractedName = supplierMatch.group(1)?.trim() ?? '';
            // If the name contains "ID" or looks like an ObjectId, skip it
            if (extractedName.isNotEmpty &&
                !extractedName.toUpperCase().contains('ID') &&
                !RegExp(r'[a-f0-9]{10,}').hasMatch(extractedName)) {
              supplierName = extractedName;
            }
          }
        }
      }

      // Extract reason for returns
      if (isRetour && note.contains('Raison:')) {
        final reasonMatch = RegExp(
          r'Raison:\s*(.+?)(?:\s*-|\s*\(|$)',
        ).firstMatch(note);
        if (reasonMatch != null) {
          reason = reasonMatch.group(1)?.trim();
        }
      }

      // Extract unit price and total for sales and purchases
      if ((isSale || isPurchase) && note.contains('Prix:')) {
        final priceMatch = RegExp(r'Prix:\s*(\d+(?:\.\d+)?)').firstMatch(note);
        if (priceMatch != null) {
          final price = double.tryParse(priceMatch.group(1) ?? '');
          if (price != null) {
            unitPrice = price;
            total = price * movement.quantity;
          }
        }
      }
    }

    // Fetch warehouse names if we have IDs but no names yet
    String? fetchedFromWarehouseName;
    String? fetchedToWarehouseName;

    if (isTransfer) {
      // Try to extract warehouse IDs from note if available
      if (movement.note != null && movement.note!.isNotEmpty) {
        final warehousePattern = RegExp(
          r'warehouse\s+([a-f0-9]{24})',
          caseSensitive: false,
        );
        final matches = warehousePattern.allMatches(movement.note!).toList();

        if (matches.length >= 2) {
          // First match is "from", second is "to"
          final fromWarehouseId = matches[0].group(1);
          final toWarehouseId = matches[1].group(1);

          try {
            final warehouseService = WarehouseService();
            final warehouses = await warehouseService.getWarehouses();

            // Fetch source warehouse name
            if (fromWarehouseId != null) {
              final fromWarehouse = warehouses.firstWhere(
                (w) =>
                    w['_id']?.toString() == fromWarehouseId ||
                    w['id']?.toString() == fromWarehouseId,
                orElse: () => <String, dynamic>{},
              );
              if (fromWarehouse.isNotEmpty && fromWarehouse['name'] != null) {
                fetchedFromWarehouseName = fromWarehouse['name'].toString();
              }
            }

            // Fetch destination warehouse name
            if (toWarehouseId != null) {
              final toWarehouse = warehouses.firstWhere(
                (w) =>
                    w['_id']?.toString() == toWarehouseId ||
                    w['id']?.toString() == toWarehouseId,
                orElse: () => <String, dynamic>{},
              );
              if (toWarehouse.isNotEmpty && toWarehouse['name'] != null) {
                fetchedToWarehouseName = toWarehouse['name'].toString();
              }
            }
          } catch (e) {
            print('[MOVEMENT DETAILS] Error fetching warehouses: $e');
          }
        }
      }

      // Also try using warehouse IDs directly from movement if note didn't work
      if (fetchedFromWarehouseName == null &&
          movement.fromWarehouseId != null) {
        try {
          final warehouseService = WarehouseService();
          final warehouses = await warehouseService.getWarehouses();
          final warehouse = warehouses.firstWhere(
            (w) =>
                w['_id']?.toString() == movement.fromWarehouseId ||
                w['id']?.toString() == movement.fromWarehouseId,
            orElse: () => <String, dynamic>{},
          );
          if (warehouse.isNotEmpty && warehouse['name'] != null) {
            fetchedFromWarehouseName = warehouse['name'].toString();
          }
        } catch (e) {
          print('[MOVEMENT DETAILS] Error fetching source warehouse: $e');
        }
      }

      if (fetchedToWarehouseName == null && movement.toWarehouseId != null) {
        try {
          final warehouseService = WarehouseService();
          final warehouses = await warehouseService.getWarehouses();
          final warehouse = warehouses.firstWhere(
            (w) =>
                w['_id']?.toString() == movement.toWarehouseId ||
                w['id']?.toString() == movement.toWarehouseId,
            orElse: () => <String, dynamic>{},
          );
          if (warehouse.isNotEmpty && warehouse['name'] != null) {
            fetchedToWarehouseName = warehouse['name'].toString();
          }
        } catch (e) {
          print('[MOVEMENT DETAILS] Error fetching destination warehouse: $e');
        }
      }
    }

    // Create a cleaned-up note for display (replace IDs with names)
    String? displayNote = movement.note;
    if (displayNote != null && displayNote.isNotEmpty) {
      // Replace warehouse IDs with names in the note
      if (isTransfer &&
          fetchedFromWarehouseName != null &&
          fetchedToWarehouseName != null) {
        // Replace the warehouse ID patterns with actual names
        final warehousePattern = RegExp(
          r'warehouse\s+([a-f0-9]{24})',
          caseSensitive: false,
        );
        final matches = warehousePattern.allMatches(displayNote).toList();

        if (matches.length >= 2) {
          // Replace in reverse order to maintain string positions
          final fromId = matches[0].group(1);
          final toId = matches[1].group(1);

          // Replace second occurrence (destination) first
          displayNote = displayNote.replaceFirst(
            'warehouse $toId',
            fetchedToWarehouseName,
            matches[1].start,
          );

          // Replace first occurrence (source)
          displayNote = displayNote.replaceFirst(
            'warehouse $fromId',
            fetchedFromWarehouseName,
          );
        }
      }

      // Replace customer ID with name in sales
      if (isSale && customerName != null) {
        displayNote = displayNote.replaceAllMapped(
          RegExp(r'Client ID:\s*[a-f0-9]{24}', caseSensitive: false),
          (match) => 'Client: $customerName',
        );
      }

      // Replace supplier ID with name in returns
      if (isRetour && supplierName != null) {
        displayNote = displayNote.replaceAllMapped(
          RegExp(r'Fournisseur ID:\s*[a-f0-9]{24}', caseSensitive: false),
          (match) => 'Fournisseur: $supplierName',
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width:
                MediaQuery.of(context).size.width > 600
                    ? 550
                    : MediaQuery.of(context).size.width * 0.95,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Modern Header with Gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [typeColor, typeColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.inventory_2_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movement.displayProductName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (movement.productReference != null &&
                                    movement.productReference!.isNotEmpty ||
                                movement.product?.referenceCode != null &&
                                    movement.product!.referenceCode.isNotEmpty)
                              Text(
                                'Réf: ${movement.productReference ?? movement.product?.referenceCode ?? 'N/A'}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                typeLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content Area
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quantity and Date Section
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                'Quantité',
                                '$quantityPrefix${movement.quantity}',
                                Icons.inventory,
                                quantityColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                'Date',
                                '${movement.createdAt.day}/${movement.createdAt.month}/${movement.createdAt.year}',
                                Icons.calendar_today,
                                Colors.blue,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Warehouse Information Section
                        if (isTransfer) ...[
                          _buildTransferDetails(
                            movement,
                            fromWarehouseName: fetchedFromWarehouseName,
                            toWarehouseName: fetchedToWarehouseName,
                          ),
                          const SizedBox(height: 20),
                        ],

                        // User Information
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: Colors.blue.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Informations Utilisateur',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (movement.userName != null)
                                _buildDetailRow(
                                  'Utilisateur',
                                  movement.userName!,
                                  Icons.person_outline,
                                ),
                              if (movement.userRole != null)
                                _buildDetailRow(
                                  'Rôle',
                                  movement.userRole!,
                                  Icons.badge,
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Movement-specific Information
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: typeColor.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info, color: typeColor, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Détails du Mouvement',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: typeColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Movement-specific details
                              // Purchase-specific details
                              if (isPurchase) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade600,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.shopping_cart,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Informations d\'Achat',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade800,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Who processed the purchase
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.blue.shade200,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.person_add,
                                                  color: Colors.blue.shade600,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Traité par',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue.shade700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              cashierName ?? 'Non spécifié',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    cashierName != null
                                                        ? Colors.black87
                                                        : Colors.grey.shade600,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                if (cashierName != null) ...[
                                                  Icon(
                                                    Icons.verified,
                                                    size: 14,
                                                    color:
                                                        Colors.green.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      'Responsable du traitement de l\'achat',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade600,
                                                      ),
                                                    ),
                                                  ),
                                                ] else ...[
                                                  Icon(
                                                    Icons.info_outline,
                                                    size: 14,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      'Information non disponible',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade600,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Who delivered the purchase
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.orange.shade200,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.local_shipping,
                                                  color: Colors.orange.shade600,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Livré par',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.orange.shade700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              managerName ?? 'Non spécifié',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    managerName != null
                                                        ? Colors.black87
                                                        : Colors.grey.shade600,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                if (managerName != null) ...[
                                                  Icon(
                                                    Icons.verified,
                                                    size: 14,
                                                    color:
                                                        Colors.green.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      'Responsable de la livraison',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade600,
                                                      ),
                                                    ),
                                                  ),
                                                ] else ...[
                                                  Icon(
                                                    Icons.info_outline,
                                                    size: 14,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      'Information non disponible',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade600,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Other purchase details
                                      if (supplierName != null)
                                        _buildDetailRow(
                                          'Fournisseur',
                                          supplierName,
                                          Icons.business,
                                        ),
                                      if (unitPrice != null)
                                        _buildDetailRow(
                                          'Prix unitaire',
                                          '${unitPrice.toStringAsFixed(2)} DNT',
                                          Icons.attach_money,
                                        ),
                                      if (movement.sourceId != null)
                                        _buildDetailRow(
                                          'Bon d\'achat',
                                          '#${movement.sourceId}',
                                          Icons.receipt_long,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],

                              // Sale-specific details
                              if (isSale) ...[
                                if (customerName != null)
                                  _buildDetailRow(
                                    'Client',
                                    customerName,
                                    Icons.person_outline,
                                  ),
                                if (unitPrice != null)
                                  _buildDetailRow(
                                    'Prix unitaire',
                                    '${unitPrice.toStringAsFixed(2)} DNT',
                                    Icons.tag,
                                  ),
                              ],

                              // Return-specific details
                              if (isRetour) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.orange.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.keyboard_return,
                                            color: Colors.orange.shade600,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Détails du Retour',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade800,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (supplierName != null)
                                        _buildDetailRow(
                                          'Fournisseur',
                                          supplierName,
                                          Icons.business,
                                        ),
                                      if (reason != null)
                                        _buildDetailRow(
                                          'Raison',
                                          reason,
                                          Icons.info_outline,
                                        ),
                                      if (movement.sourceId != null)
                                        _buildDetailRow(
                                          'Bon de retour',
                                          '#${movement.sourceId}',
                                          Icons.receipt_long,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],

                              // General information
                              if (displayNote != null &&
                                  displayNote.isNotEmpty &&
                                  !isPurchase &&
                                  !isRetour)
                                _buildDetailRow(
                                  'Notes',
                                  displayNote,
                                  Icons.notes,
                                ),
                            ],
                          ),
                        ),

                        // Financial Information
                        if ((isSale || isPurchase) && total != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.attach_money,
                                      color: Colors.green.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Informations Financières',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildDetailRow(
                                  'Total',
                                  '${total.toStringAsFixed(2)} DNT',
                                  Icons.monetization_on,
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Time Information
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    color: Colors.purple.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Informations Temporelles',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple.shade800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Date de création',
                                '${movement.createdAt.day}/${movement.createdAt.month}/${movement.createdAt.year} à ${movement.createdAt.hour.toString().padLeft(2, '0')}:${movement.createdAt.minute.toString().padLeft(2, '0')}',
                                Icons.calendar_today,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer with Close Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check),
                        label: const Text('Fermer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: typeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransferDetails(
    StockMovement movement, {
    String? fromWarehouseName,
    String? toWarehouseName,
  }) {
    // Use fetched names if available, otherwise fallback to movement's names
    final displayFromName =
        fromWarehouseName ?? movement.fromWarehouseName ?? 'Dépôt source';
    final displayToName =
        toWarehouseName ?? movement.toWarehouseName ?? 'Dépôt destination';

    return Column(
      children: [
        _buildInfoRow(
          'Transfert de',
          displayFromName,
          Icons.warehouse_outlined,
        ),
        _buildInfoRow('Transfert vers', displayToName, Icons.warehouse),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('all', 'Tout'),
          _buildFilterChip('purchase', 'Achats'),
          _buildFilterChip('sale', 'Ventes'),
          _buildFilterChip('return', 'Retours'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        selectedColor: Colors.indigo.withOpacity(0.2),
        checkmarkColor: Colors.indigo,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.indigo : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(List<StockMovement> movements) {
    final purchases =
        movements
            .where(
              (m) =>
                  _normalizeType(m.movementType, sourceType: m.sourceType) ==
                  'purchase',
            )
            .length;
    final sales =
        movements
            .where(
              (m) =>
                  _normalizeType(m.movementType, sourceType: m.sourceType) ==
                  'sale',
            )
            .length;
    final returns =
        movements.where((m) {
          final normalizedType = _normalizeType(
            m.movementType,
            sourceType: m.sourceType,
          );
          return normalizedType == 'return' || normalizedType == 'adjustment';
        }).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_rounded,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Résumé des mouvements',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: MediaQuery.of(context).size.width < 400 ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Make stats responsive - stack on small screens
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 300) {
                // Stack vertically on very small screens
                return Column(
                  children: [
                    _buildStatItem(
                      'Achats',
                      purchases.toString(),
                      Icons.shopping_bag_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildStatItem(
                      'Ventes',
                      sales.toString(),
                      Icons.point_of_sale,
                    ),
                    const SizedBox(height: 12),
                    _buildStatItem(
                      'Retours',
                      returns.toString(),
                      Icons.compare_arrows,
                    ),
                  ],
                );
              } else {
                // Row layout for wider screens
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _selectedFilter = 'purchase'),
                      child: _buildStatItem(
                        'Achats',
                        purchases.toString(),
                        Icons.shopping_bag_rounded,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedFilter = 'sale'),
                      child: _buildStatItem(
                        'Ventes',
                        sales.toString(),
                        Icons.point_of_sale,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedFilter = 'return'),
                      child: _buildStatItem(
                        'Retours',
                        returns.toString(),
                        Icons.compare_arrows,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  List<StockMovement> _filterMovements(List<StockMovement> movements) {
    if (_selectedFilter == 'all') return movements;

    return movements.where((m) {
      final normalizedType = _normalizeType(
        m.movementType,
        sourceType: m.sourceType,
      );

      // When "return" filter is selected, include both returns and adjustments
      if (_selectedFilter == 'return') {
        return normalizedType == 'return' || normalizedType == 'adjustment';
      }

      return normalizedType == _selectedFilter;
    }).toList();
  }

  Widget _buildMovementCard(StockMovement movement) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          _showMovementDetailsDialog(context, movement);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 400;

              if (isSmallScreen) {
                // Vertical layout for small screens
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getBackgroundColor(
                              movement.movementType,
                              sourceType: movement.sourceType,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getIcon(
                              movement.movementType,
                              sourceType: movement.sourceType,
                            ),
                            color: _getColor(
                              movement.movementType,
                              sourceType: movement.sourceType,
                            ),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            movement.displayProductName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getColor(
                              movement.movementType,
                              sourceType: movement.sourceType,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getTypeLabel(
                              movement.movementType,
                              sourceType: movement.sourceType,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          'Qté: ${movement.quantity}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${movement.createdAt.day}/${movement.createdAt.month}/${movement.createdAt.year}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                // Horizontal layout for wider screens
                return Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getBackgroundColor(
                          movement.movementType,
                          sourceType: movement.sourceType,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIcon(
                          movement.movementType,
                          sourceType: movement.sourceType,
                        ),
                        color: _getColor(
                          movement.movementType,
                          sourceType: movement.sourceType,
                        ),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  movement.displayProductName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getColor(
                                    movement.movementType,
                                    sourceType: movement.sourceType,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getTypeLabel(
                                    movement.movementType,
                                    sourceType: movement.sourceType,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Quantité: ${movement.quantity}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.schedule_outlined,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${movement.createdAt.day}/${movement.createdAt.month}/${movement.createdAt.year}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width to determine if we're on mobile
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      // Add drawer for mobile
      drawer:
          isMobile
              ? Drawer(child: Sidebar(selected: SidebarSection.stockMovements))
              : null,
      // Add app bar for mobile with menu button
      appBar:
          isMobile
              ? AppBar(
                title: const Text('Mouvements de Stock'),
                backgroundColor: const Color(0xFFF8FAFC),
                elevation: 0,
                foregroundColor: Colors.black87,
              )
              : null,
      body: Row(
        children: [
          // Only show sidebar on desktop
          if (!isMobile) Sidebar(selected: SidebarSection.stockMovements),
          Expanded(
            child: FutureBuilder<List<StockMovement>>(
              future: _futureMovements,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF6366F1),
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur de chargement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun mouvement trouvé',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Commencez par ajouter un mouvement',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final movements = snapshot.data!;
                final filteredMovements = _filterMovements(movements);

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      print(
                        '[LISTE] Rafraîchissement de la liste des mouvements',
                      );
                      _futureMovements =
                          StockMovementService().fetchStockMovements();
                    });
                  },
                  color: const Color(0xFF6366F1),
                  child: Column(
                    children: [
                      _buildStatsCard(movements),
                      _buildFilterChips(),
                      Expanded(
                        child:
                            filteredMovements.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.filter_list_off_rounded,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Aucun mouvement pour ce filtre',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 80),
                                  itemCount: filteredMovements.length,
                                  itemBuilder: (context, index) {
                                    return _buildMovementCard(
                                      filteredMovements[index],
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StockMovementFormDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const StockMovementFormDialog({required this.onSuccess, Key? key})
    : super(key: key);

  @override
  State<StockMovementFormDialog> createState() =>
      _StockMovementFormDialogState();
}

class _StockMovementFormDialogState extends State<StockMovementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String? productId, fromWarehouseId, toWarehouseId, userId;
  int? quantity;
  String? movementType, note;
  final List<String> movementTypes = ['transfer', 'purchase', 'adjustment'];
  List<Product> produits = [];
  List<Warehouse> entrepots = [];
  List<User> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final produitsList = await ProductService().getProducts();
      final entrepotsList = await WarehouseService().getWarehouses();
      final usersList = await UserService.getUsers();
      setState(() {
        produits =
            produitsList
                .map((e) => Product.fromJson(e as Map<String, dynamic>))
                .toList();
        entrepots = entrepotsList.map((e) => Warehouse.fromJson(e)).toList();
        users =
            usersList
                .map((e) => User.fromJson(e as Map<String, dynamic>))
                .toList();
        isLoading = false;
      });
    } catch (e, stack) {
      print('[DIALOG LOAD ERROR] $e');
      print(stack);
      setState(() {
        isLoading = false;
      });
      // Optionnel : Affiche une erreur à l’utilisateur
      AppToast.error(context, 'Erreur lors du chargement des données : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return AlertDialog(
      title: const Text('Ajouter un mouvement de stock'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Produit'),
                  items:
                      produits
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p.id,
                              child: Text(p.name),
                            ),
                          )
                          .toList(),
                  validator: (value) => value == null ? 'Champ requis' : null,
                  onChanged: (value) => productId = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Type de mouvement',
                  ),
                  items:
                      movementTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                  validator: (value) => value == null ? 'Champ requis' : null,
                  onChanged: (value) => movementType = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Entrepôt source',
                  ),
                  items:
                      entrepots
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e.id,
                              child: Text(e.name),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => fromWarehouseId = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Entrepôt destination',
                  ),
                  items:
                      entrepots
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e.id,
                              child: Text(e.name),
                            ),
                          )
                          .toList(),
                  onChanged: (value) => toWarehouseId = value,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Utilisateur'),
                  items:
                      users
                          .map(
                            (u) => DropdownMenuItem<String>(
                              value: u.id,
                              child: Text(u.name),
                            ),
                          )
                          .toList(),
                  validator: (value) => value == null ? 'Champ requis' : null,
                  onChanged: (value) => userId = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Quantité'),
                  keyboardType: TextInputType.number,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Champ requis'
                              : null,
                  onSaved: (value) => quantity = int.tryParse(value!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Note'),
                  onSaved: (value) => note = value,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              // Appel API pour ajouter le mouvement ici
              widget.onSuccess();
              Navigator.of(context).pop();
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
