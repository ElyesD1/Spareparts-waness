import 'package:flutter/material.dart';
import '../../models/domain/purchase_item.dart';
import 'package:printing/printing.dart';
import 'facture_pdf.dart';
import '../../models/domain/sale_item.dart';

class FactureDialog extends StatelessWidget {
  final dynamic purchase;
  final List<PurchaseItem> items;

  const FactureDialog({required this.purchase, required this.items, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the purchase's final amount (after credits) instead of calculating from items
    final totalFinal = purchase.finalAmount ?? items.fold<double>(0, (sum, item) => sum + item.quantity * item.unitPrice);
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titre centré
            Text('FACTURE',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, letterSpacing: 2)),
            const SizedBox(height: 8),
            // Numéro de facture centré
            Text('N° ${purchase.id}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            // Infos client/date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Client : ${purchase.supplier?['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Date : ${purchase.date ?? ''}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Tableau produits
            Table(
              border: TableBorder.all(),
              columnWidths: const {
                0: FlexColumnWidth(2), // Désignation
                1: FlexColumnWidth(2), // Référence
                2: FlexColumnWidth(1), // Qté
                3: FlexColumnWidth(1), // P.U
                4: FlexColumnWidth(1), // Total
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text('Désignation', style: TextStyle(fontWeight: FontWeight.bold))),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text('Référence', style: TextStyle(fontWeight: FontWeight.bold))),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text('Qté', style: TextStyle(fontWeight: FontWeight.bold))),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text('P.U', style: TextStyle(fontWeight: FontWeight.bold))),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                    ),
                  ],
                ),
                ...items.map((item) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(item.productName),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(item.product?.referenceCode ?? ''),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(child: Text(item.quantity.toString())),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(item.unitPrice.toStringAsFixed(3) + ' DNT'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text((item.quantity * item.unitPrice).toStringAsFixed(3) + ' DNT'),
                      ),
                    ),
                  ],
                )),
                // Ligne total final
                TableRow(
                  decoration: const BoxDecoration(color: Colors.grey),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('TOTAL FINAL', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(),
                    const SizedBox(),
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          totalFinal.toStringAsFixed(3),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final pdfData = await generateFacturePdf(purchase, items);
                    await Printing.layoutPdf(onLayout: (format) async => pdfData);
                  },
                  child: const Text('Imprimer PDF'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SaleFactureDialog extends StatelessWidget {
  final Map<String, dynamic> sale;
  final List<SaleItem> items;

  const SaleFactureDialog({required this.sale, required this.items, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate total with proper unit price logic
    final totalFinal = items.fold<double>(0, (sum, item) {
      double unitPrice = item.unitPrice ?? 0;
      // Use product's current unit price if sale item unit price is 0
      if (unitPrice <= 0 && item.product?.unitPrice != null) {
        unitPrice = item.product!.unitPrice;
      }
      return sum + (item.quantity ?? 0) * unitPrice;
    });
    
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('RECU',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('N° ${sale['id'] ?? ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Client : ${sale['customer_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Date : ${sale['sale_date'] ?? ''}'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Table(
              border: TableBorder.all(),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text('Désignation', style: TextStyle(fontWeight: FontWeight.bold))),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text('Référence', style: TextStyle(fontWeight: FontWeight.bold))),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text('Qté', style: TextStyle(fontWeight: FontWeight.bold))),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text('P.U', style: TextStyle(fontWeight: FontWeight.bold))),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                    ),
                  ],
                ),
                ...items.map((item) {
                  // Calculate proper unit price
                  double unitPrice = item.unitPrice ?? 0;
                  if (unitPrice <= 0 && item.product?.unitPrice != null) {
                    unitPrice = item.product!.unitPrice;
                  }
                  final itemTotal = (item.quantity ?? 0) * unitPrice;
                  
                  return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(item.product?.name ?? ''),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(item.product?.referenceCode ?? ''),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(child: Text((item.quantity ?? 0).toString())),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                          child: Text(unitPrice.toStringAsFixed(3) + ' DNT'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                          child: Text(itemTotal.toStringAsFixed(3) + ' DNT'),
                      ),
                    ),
                  ],
                  );
                }),
                TableRow(
                  decoration: const BoxDecoration(color: Colors.grey),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('TOTAL FINAL', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(),
                    const SizedBox(),
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          totalFinal.toStringAsFixed(3),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final pdfData = await generateSaleReceiptPdf(sale, items);
                    await Printing.layoutPdf(onLayout: (format) async => pdfData);
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Imprimer PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    // Print PDF for sales
                    final pdfData = await generateSaleReceiptPdf(sale, items);
                    await Printing.layoutPdf(onLayout: (format) async => pdfData);
                  },
                  child: const Text('Imprimer PDF'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 