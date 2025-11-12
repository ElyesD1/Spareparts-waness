import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/domain/purchase_item.dart';
import '../../models/domain/sale_item.dart';

Future<Uint8List> generateFacturePdf(dynamic purchase, List<PurchaseItem> items) async {
  final pdf = pw.Document();
  // Use the purchase's final amount (after credits) instead of calculating from items
  final totalFinal = purchase.finalAmount ?? items.fold<double>(0, (sum, item) => sum + item.quantity * item.unitPrice);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text('FACTURE', style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 8),
            pw.Text('N° ${purchase.id}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Client : ${purchase.supplier?['name'] ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date : ${purchase.date ?? ''}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1),
                4: pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Center(child: pw.Text('Désignation', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Center(child: pw.Text('Référence', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Center(child: pw.Text('Qté', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Center(child: pw.Text('P.U', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Center(child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ),
                  ],
                ),
                ...items.map((item) => pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(item.productName),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(item.product?.referenceCode ?? ''),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Center(child: pw.Text(item.quantity.toString())),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(item.unitPrice.toStringAsFixed(3) + ' DNT'),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text((item.quantity * item.unitPrice).toStringAsFixed(3) + ' DNT'),
                      ),
                    ),
                  ],
                )),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey500),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('TOTAL FINAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(),
                    pw.SizedBox(),
                    pw.SizedBox(),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          totalFinal.toStringAsFixed(3) + ' DNT',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 32),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Signature et cachet', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

Future<Uint8List> generateSaleReceiptPdf(Map<String, dynamic> sale, List<SaleItem> items) async {
  final pdf = pw.Document();
  
  // Calculate total with proper unit price logic
  final totalFinal = items.fold<double>(0, (sum, item) {
    double unitPrice = item.unitPrice ?? 0;
    // Use product's current unit price if sale item unit price is 0
    if (unitPrice <= 0 && item.product?.unitPrice != null) {
      unitPrice = item.product!.unitPrice;
    }
    return sum + (item.quantity ?? 0) * unitPrice;
  });

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text('RECU', style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 8),
            pw.Text('N° ${sale['id'] ?? ''}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Client : ${sale['customer_name'] ?? ''}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date : ${sale['sale_date'] ?? ''}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1),
                4: pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Center(child: pw.Text('Désignation', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Center(child: pw.Text('Référence', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Center(child: pw.Text('Qté', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Center(child: pw.Text('P.U', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Center(child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
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
                  
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.product?.name ?? ''),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.product?.referenceCode ?? ''),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Center(child: pw.Text((item.quantity ?? 0).toString())),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(unitPrice.toStringAsFixed(3) + ' DNT'),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(itemTotal.toStringAsFixed(3) + ' DNT'),
                        ),
                      ),
                    ],
                  );
                }),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey500),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('TOTAL FINAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(),
                    pw.SizedBox(),
                    pw.SizedBox(),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Text(
                          totalFinal.toStringAsFixed(3) + ' DNT',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 32),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Merci pour votre confiance!', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Signature et cachet', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
} 