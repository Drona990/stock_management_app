import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintService {
  static Future<void> generateAndPrint(Map<String, dynamic> billData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Standard 80mm Thermal Paper
        build: (pw.Context context) {
          // Calculation Logic for Footer
          double subtotal = 0;
          List items = billData['items'] ?? [];
          for (var item in items) {
            subtotal += double.tryParse(item['rate'].toString()) ?? 0;
          }

          double discPercent = double.tryParse(billData['discount'].toString()) ?? 0;
          double discAmt = subtotal * (discPercent / 100);
          double freight = double.tryParse(billData['freight_charge'].toString()) ?? 0;

          return pw.Container(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // --- Header ---
                pw.Center(
                  child: pw.Text("TAX INVOICE",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                ),
                pw.SizedBox(height: 5),
                pw.Text("Bill No : ${billData['bill_no']}", style: pw.TextStyle(fontSize: 8)),
                pw.Text("Date    : ${billData['bill_date']}", style: pw.TextStyle(fontSize: 8)),
                pw.Text("Cust    : ${billData['customer_name']}", style: pw.TextStyle(fontSize: 8)),
                pw.Divider(thickness: 0.5),

                // --- Table Header ---
                pw.Row(children: [
                  pw.Expanded(flex: 4, child: pw.Text("ITEM / BARCODE", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                  // FIXED: Changed 'textAlig' to 'textAlign' and moved it outside TextStyle
                  pw.Expanded(flex: 2, child: pw.Text("TAXABLE", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text("GST", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text("TOTAL", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                ]),
                pw.Divider(thickness: 0.5),

                // --- Items Loop ---
                ...items.map((item) {
                  double rate = double.tryParse(item['rate'].toString()) ?? 0;
                  double cgst = double.tryParse(item['cgst_amt'].toString()) ?? 0;
                  double sgst = double.tryParse(item['sgst_amt'].toString()) ?? 0;
                  double igst = double.tryParse(item['igst_amt'].toString()) ?? 0;
                  double totalGst = cgst + sgst + igst;
                  double taxable = rate - totalGst;

                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(children: [
                      pw.Expanded(flex: 4, child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text("${item['item_name']}", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                            pw.Text("(${item['barcode_number']})", style: pw.TextStyle(fontSize: 6)),
                          ]
                      )),
                      // FIXED: Alignment moved to Text property
                      pw.Expanded(flex: 2, child: pw.Text(taxable.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7))),
                      pw.Expanded(flex: 2, child: pw.Text(totalGst.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7))),
                      pw.Expanded(flex: 2, child: pw.Text(rate.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                    ]),
                  );
                }).toList(),

                pw.Divider(thickness: 0.5),

                // --- Summary Section ---
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text("Sub-Total:", style: pw.TextStyle(fontSize: 8)),
                  pw.Text("Rs. ${subtotal.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 8)),
                ]),

                // RED LINE FOR DISCOUNT
                if (discPercent > 0)
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                    pw.Text("Discount ($discPercent%):",
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.red, fontWeight: pw.FontWeight.bold)),
                    pw.Text("- Rs. ${discAmt.toStringAsFixed(2)}",
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.red, fontWeight: pw.FontWeight.bold)),
                  ]),

                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text("Freight Charge:", style: pw.TextStyle(fontSize: 8)),
                  pw.Text("+ Rs. ${freight.toStringAsFixed(2)}", style: pw.TextStyle(fontSize: 8)),
                ]),
                pw.SizedBox(height: 2),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text("GRAND TOTAL:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text("Rs. ${billData['total_amount']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                ]),

                pw.SizedBox(height: 5),
                pw.Text("Amount in words:", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                pw.Text("${billData['amount_in_words']}", style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic)),

                pw.SizedBox(height: 15),
                pw.Center(child: pw.Text("--- THANK YOU! VISIT AGAIN ---", style: pw.TextStyle(fontSize: 8))),
                pw.SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );

    // Opening System Print Dialog
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Bill_${billData['bill_no']}'
    );
  }
}