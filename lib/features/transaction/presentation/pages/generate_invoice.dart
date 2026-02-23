import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/entity/salse_entity.dart';



class PdfInvoiceService {
  static Future<void> generateInvoice(SaleHistoryEntity sale) async {
    final pdf = pw.Document();

    double totalTaxableAmount = 0;
    double totalTaxAmount = 0;

    // 1. Calculate totals first for accuracy
    for (var item in sale.items) {
      // Base amount = Qty * Price (excluding tax)
      double base = item.quantity * item.unitPrice;
      // Tax amount for this specific item
      double tax = base * (item.taxPercentage / 100);

      totalTaxableAmount += base;
      totalTaxAmount += tax;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(8),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // 🏪 Store Header
              pw.Text("RETAIL INVOICE",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text("GSTIN: 21XXXXX0000X1Z",
                  style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 5),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // 📑 Invoice Metadata
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Inv: ${sale.invoiceNo}", style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(DateFormat('dd/MM/yy').format(sale.saleDate),
                      style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 5),

              // 🛒 Items Table
              ...sale.items.map((it) {
                // 💡 Taxable price for this row (Qty x Price)
                double rowBaseTotal = it.quantity * it.unitPrice;

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(it.productName,
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("${it.quantity.toInt()} x ${it.unitPrice.toStringAsFixed(2)}",
                              style: const pw.TextStyle(fontSize: 8)),
                          // 💡 Displaying TAXABLE (Base) amount here
                          pw.Text(rowBaseTotal.toStringAsFixed(2),
                              style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),

              pw.SizedBox(height: 5),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // 💰 Financial Summary
              _buildAmountRow("Taxable Amt:", totalTaxableAmount),
              _buildAmountRow("CGST Output:", totalTaxAmount / 2),
              _buildAmountRow("SGST Output:", totalTaxAmount / 2),

              pw.Divider(thickness: 1),

              // 🏁 FINAL TOTAL
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("GRAND TOTAL:",
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Rs ${sale.totalAmount.toStringAsFixed(2)}",
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                ],
              ),

              pw.SizedBox(height: 15),
              pw.Text("Thank You! Visit Again",
                  style:  pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
              pw.SizedBox(height: 10),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // Helper widget for repetitive rows
  static pw.Widget _buildAmountRow(String label, double amount) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(amount.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }
}