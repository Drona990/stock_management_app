import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BomPdfGeneratorHelper {
  static Future<void> printConfigurationInvoice(Map<String, dynamic> data) async {
    final pdf = pw.Document();
    final List<dynamic> items = data['configured_items'] ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // 1. MAIN TAX INVOICE STRUCTURE BLOCK
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("ULTRA ENGINEERING WORKS", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
                    pw.SizedBox(height: 2),
                    pw.Text("TAX INVOICE / PRODUCTION RELEASE LOGS", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.Text("Config Token: ${data['config_code']}", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Master Template: ${data['parent_project_code']}", style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("RELEASE DATE: ${data['created_at'] ?? '—'}", style: const pw.TextStyle(fontSize: 9)),
                    pw.Text("DELIVERY TIMELINE: ${data['delivery_timeline'] ?? '—'}", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                  ],
                )
              ],
            ),
            pw.Divider(color: PdfColors.grey400, thickness: 0.5, height: 16),

            // 2. INDUSTRIAL AUDIT LOGS REFERENCE MATRICES
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("DISPATCH LOGISTICS LOCATION:", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
                    pw.Text(data['location'] ?? "Main Factory Floor", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("SOLD BY OPERATOR STAFF MASTER:", style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontWeight: pw.FontWeight.bold)),
                    pw.Text(data['sold_by_staff_name'] ?? "Authorized Signatory", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                  ],
                )
              ],
            ),
            pw.SizedBox(height: 16),

            pw.Text("PROJECT MANIFEST IDENTITY: ${data['project_name']}", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text("Total Project Batched Volume Multiplier: ${data['final_configured_quantity']} Units", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
            pw.SizedBox(height: 10),

            // 3. SPREADSHEET MATRIX DESIGN LOOKUP
            pw.TableHelper.fromTextArray(
              headers: ['Item No', 'Description Specifications', 'Raw Size', 'Finishing Size', 'Process Flow', 'Qty', 'Unit Rate', 'Total Cost'],
              data: items.map((item) {
                return [
                  item['item_no']?.toString() ?? '',
                  item['description']?.toString() ?? '',
                  item['raw_size']?.toString() ?? '—',
                  item['finishing_size']?.toString() ?? '—',
                  item['process_flow']?.toString() ?? 'LASER',
                  item['quantity']?.toString() ?? '0',
                  "Rs. ${(item['purchase_price'] ?? 0.0).toStringAsFixed(2)}",
                  "Rs. ${(item['total_cost'] ?? 0.0).toStringAsFixed(2)}",
                ];
              }).toList(),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey900),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                5: pw.Alignment.centerRight,
                6: pw.Alignment.centerRight,
                7: pw.Alignment.centerRight,
              },
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellPadding: const pw.EdgeInsets.all(5),
            ),
            pw.SizedBox(height: 16),

            // 4. COST TOTALING MATRICES
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 180,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blueGrey900, width: 0.5),
                    color: PdfColors.grey100,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("NET MANIFEST TOTAL:", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Rs. ${(data['grand_total_estimation_cost'] ?? 0.0).toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                    ],
                  ),
                )
              ],
            ),
          ];
        },
      ),
    );

    // Dispatches the compiled layout directly into system spool layers
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Release_Order_${data['config_code']}.pdf',
    );
  }
}