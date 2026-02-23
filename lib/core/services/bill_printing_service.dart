// BillPrintingService.dart
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BillPrintingService {

  Future<void> showBillPreview(Map<String, dynamic> data) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) => _generateDMartPdf(format, data),
    );
  }

  Future<Uint8List> _generateDMartPdf(PdfPageFormat format, Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // 🌟 Safer Data Extraction
    final Map<String, dynamic> header = data['header'] ?? {};
    final Map<String, dynamic> meta = data['meta'] ?? {};
    final Map<String, dynamic> summary = data['summary'] ?? {};
    final List items = data['items'] ?? [];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(child: pw.Text(header['name'] ?? "SVENSKA RESTAURANT", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold))),
              pw.Center(child: pw.Text(header['address'] ?? "Bhubaneswar", style: const pw.TextStyle(fontSize: 9))),
              pw.Divider(thickness: 1),

              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("Invoice: ${meta['inv'] ?? 'N/A'}", style: const pw.TextStyle(fontSize: 9)),
                pw.Text("Date: ${meta['time'] ?? 'N/A'}", style: const pw.TextStyle(fontSize: 9)), // 🌟 Date Fix
              ]),
              pw.Text("Table: ${meta['table']} | Waiter: ${meta['waiter']}", style: const pw.TextStyle(fontSize: 9)),
              pw.Text("Bill No: ${meta['order_id'] ?? 'N/A'}", style: const pw.TextStyle(fontSize: 9)),
              pw.Text("Payment: ${meta['method'] ?? 'N/A'}", style: const pw.TextStyle(fontSize: 9)),
              pw.Divider(thickness: 1),

              pw.Table(
                children: [
                  pw.TableRow(children: [
                    pw.Text("Item", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Qty", textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Total", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ]),
                  ...items.map((it) => pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 2), child: pw.Text(it['name'] ?? "", style: const pw.TextStyle(fontSize: 9))),
                    pw.Text(it['qty'].toString(), textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9)),
                    pw.Text("Rs.${it['total']}", textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9)),
                  ])),
                ],
              ),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),

              _summaryRow("Subtotal", "Rs.${summary['subtotal'] ?? '0.00'}"),
              _summaryRow("Offer: ${summary['offer'] ?? 'None'}", "-Rs.${summary['discount'] ?? '0.00'}", isBold: true), // 🌟 Discount Fix
              _summaryRow("Tax (GST 5%)", "Rs.${summary['tax'] ?? '0.00'}"),
              pw.Divider(),

              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text("GRAND TOTAL", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text("Rs.${summary['grand_total'] ?? '0.00'}", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ]),
              pw.Divider(),

              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text("Thank You! Visit Again", style: const pw.TextStyle(fontSize: 8))),
              pw.SizedBox(height: 5),
              pw.Center(child: pw.BarcodeWidget(barcode: pw.Barcode.code128(), data: meta['inv'] ?? "000", width: 80, height: 25)),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  pw.Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ]),
    );
  }
}