import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoicePdfService {
  static Future<pw.Document> generate({
    required pw.ImageProvider? logoImage,
    required Map<String, dynamic> data,
    required bool isSales,
    required List<String> headings,
  }) async {
    final pdf = pw.Document();

    for (String currentHeading in headings) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.0)),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  _buildHeader(logoImage!, currentHeading),
                  pw.Divider(thickness: 1, height: 1),

                  // --- SECTION 2: PARTY DETAILS ---
                  _buildDynamicConsigneeSection(data),
                  pw.Divider(thickness: 1, height: 1),

                  // --- SECTION 3: ITEMS TABLE ---
                  _buildDynamicItemsTable(data['details'] ?? []),

                  // --- SECTION 4: BILLING ---
                  _buildDynamicBillingSection(data),

                  // --- SECTION 5: FOOTER ---
                  _buildFooterTerms(),
                ],
              ),
            );
          },
        ),
      );
    }
    return pdf;
  }


  static pw.Widget _buildHeader(pw.ImageProvider logo, String title) {
    return pw.Column(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.SizedBox(width: 40),
          pw.Text("TAX INVOICE", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          // ✅ Dynamic Title (Original for Buyer, etc.)
          pw.Text(title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ]),
      ),
      pw.Divider(thickness: 1, height: 1),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(width: 100, height: 75, padding: const pw.EdgeInsets.all(5), child: pw.Image(logo, fit: pw.BoxFit.contain)),
          pw.Expanded(
            child: pw.Container(
              height: 75, padding: const pw.EdgeInsets.all(5),
              child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
                pw.Text("ULTRA ENGINEERING WORKS", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text("SPM MANUFACTURERS & FABRICATORS", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text("OFFICE:NO: 15/6, 5th CROSS, VIDYA NAGAR, OPP. S.K.F. FACTORY, BOMMASANDRA INDL. AREA, BENGALURU-560 099.",
                    style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
                pw.Text("Tele Fax: 080-27834287, Mob: 9342509313 Email: ueworks@gmail.com",
                    style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
                pw.Text("Works: No.B-48, KSSIDC INDL Estate, Near Karnataka Bank, Bommasandra Indl. Area, BENGALURU-560 099.",
                    style: const pw.TextStyle(fontSize: 6.5), textAlign: pw.TextAlign.center),
              ]),
            ),
          ),
        ],
      ),
      pw.Divider(thickness: 1, height: 1),
    ]);
  }

  static pw.Widget _buildDynamicConsigneeSection(Map<String, dynamic> data) {
    // Height fix karne se "Unbounded height" error chala jayega
    const double sectionHeight = 100;

    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(width: 1),
          bottom: pw.BorderSide(width: 1),
        ),
      ),
      child: pw.Row(
        children: [
          // --- LEFT SIDE: CONSIGNEE INFO ---
          pw.Expanded(
            flex: 5,
            child: pw.Container(
              height: sectionHeight, // FIXED HEIGHT
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("NAME & ADDRESS OF CONSIGNEE",
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 3),
                  pw.Text(data['name']?.toString().toUpperCase() ?? "",
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text(data['address'] ?? "",
                      style: const pw.TextStyle(fontSize: 7.5)),
                  // Spacer() ki jagah SizedBox use karein agar MultiPage hai
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("GSTIN: ${data['gst_number'] ?? ''}",
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text("MOBILE: ${data['mobile'] ?? ''}",
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // --- RIGHT SIDE: INVOICE DETAILS ---
          pw.Expanded(
            flex: 5,
            child: pw.Container(
              height: sectionHeight, // SAME FIXED HEIGHT
              decoration: const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(width: 1)),
              ),
              child: pw.Column(
                children: [
                  _complexRow("Invoice No", data['billno'] ?? "", "DATE", data['billdate'] ?? ""),
                  _complexRow("Cust.P.O :", data['purchase_order_no'] ?? "", " ", data['purchase_order_date'] ?? ""),
                  _complexRow("D.C.NO :", data['dc_no'] ?? "", " ", data['dc_date'] ?? ""),
                  _complexRow("DESPATCH :", data['no_of_package'] ?? "", " ", ""),
                  _complexRow("EWB NO:", "", " ", "", isLast: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _complexRow(String l1, String v1, String l2, String v2, {bool isLast = false}) {
    return pw.Expanded(
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: isLast ? pw.BorderSide.none : pw.BorderSide(width: 1)),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Sub-Column 1
            pw.Expanded(
              flex: 6,
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(l1, style: const pw.TextStyle(fontSize: 7)),
                    pw.Text(v1, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ),
            // Vertical Line
            pw.Container(width: 1, color: PdfColors.black),
            // Sub-Column 2
            pw.Expanded(
              flex: 4,
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(l2, style: const pw.TextStyle(fontSize: 7)),
                    pw.Text(v2, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildDynamicItemsTable(List<dynamic> items) {
    const double slWidth = 35;
    const double qtyWidth = 50;
    const double priceWidth = 70;
    const double amountWidth = 85;
    const double hsnWidth = 80;

    return pw.Column(
      children: [
        // 1. HEADER
        pw.Container(
          decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1), top: pw.BorderSide(width: 1))
          ),
          child: pw.Row(children: [
            _cell("SL", width: slWidth, b: true),
            _cell("DESCRIPTION", flex: 1, b: true),
            _cell("HSN CODE", width: hsnWidth, b: true),
            _cell("QTY", width: qtyWidth, b: true),
            _cell("PRICE", width: priceWidth, b: true),
            _cell("AMOUNT", width: amountWidth, b: true, isLast: true),
          ]),
        ),

        // 2. DATA ROWS
        ...items.map((i) => pw.Row(children: [
          _cell(i['sno']?.toString() ?? "", width: slWidth),
          _cell(i['product_name'] ?? "", flex: 1, align: pw.TextAlign.left),
          _cell(i['hsncode']?.toString() ?? " ", width: hsnWidth),
          _cell(i['qty']?.toString() ?? "0", width: qtyWidth),
          _cell(i['rate']?.toString() ?? "0", width: priceWidth),
          _cell(i['total']?.toString() ?? "0", width: amountWidth, isLast: true),
        ])),

        pw.Container(
          height: 150,
          decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1))
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _cell("", width: slWidth),
              _cell("", flex: 1),
              _cell("", width: hsnWidth),
              _cell("", width: qtyWidth),
              _cell("", width: priceWidth),
              _cell("", width: amountWidth, isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDynamicBillingSection(Map<String, dynamic> data) {
    return pw.Row(children: [
      pw.Expanded(
        flex: 3,
        child: pw.Container(
          height: 88,
          decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 1))),
          padding: const pw.EdgeInsets.all(5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("RUPEES IN WORDS:", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
              pw.Text(data['amtin_words'] ?? "", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("BANK: STATE BANK OF INDIA | A/C: 54009859972", style: const pw.TextStyle(fontSize: 7)),
              pw.Text("IFS CODE: SBIN0040552 | ADDRESS: SINGASANDRA", style: const pw.TextStyle(fontSize: 7)),
            ],
          ),
        ),
      ),
      pw.Expanded(
        flex: 2,
        child: pw.Column(children: [
          _calcRow("Total", data['totalamount']?.toString() ?? "0"),
          _calcRow("CGST", data['cgst']?.toString() ?? "0"),
          _calcRow("SGST", data['sgst']?.toString() ?? "0"),
          _calcRow("G.Total", data['grand_totamt']?.toString() ?? "0", b: true),
        ]),
      ),
    ]);
  }

  static pw.Widget _buildFooterTerms() {
    const double footerHeight = 60;
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(width: 1),
          bottom: pw.BorderSide(width: 1),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              height: footerHeight, // Fixed Height
              padding: const pw.EdgeInsets.all(5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide(width: 1)), // Vertical Line
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Text("TERMS & CONDITIONS:",
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text("1. Good once sold will not be taken back or exchange",
                      style: const pw.TextStyle(fontSize: 6)),
                  pw.Text("2. Interest @24% will be charged if not paid within due period.",
                      style: const pw.TextStyle(fontSize: 6)),
                  pw.Text("3. All Disputes Subject to Bangalore Jurisdiction Only.",
                      style: const pw.TextStyle(fontSize: 6)),
                  pw.Text("4. All Payment Should Be Made By A/c Payee Cheque/D.D Only",
                      style: const pw.TextStyle(fontSize: 6)),
                  pw.Text("5. Our Risk/Responsibility Ceases Once Goods Leave Our Premises",
                      style: const pw.TextStyle(fontSize: 6)),
                ],
              ),
            ),
          ),

          pw.Expanded(
            flex: 1,
            child: pw.Container(
              height: footerHeight,
              padding: const pw.EdgeInsets.all(5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide(width: 1)),
              ),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text("Receiver signature",
                      style: const pw.TextStyle(fontSize: 6.5)),
                ],
              ),
            ),
          ),

          pw.Expanded(
            flex: 2,
            child: pw.Container(
              height: footerHeight,
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("For ULTRA ENGINEERING WORKS",
                      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Authorised Signatory",
                      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _cell(String t, {double? width, int? flex, bool b = false, pw.TextAlign align = pw.TextAlign.center, bool isLast = false}) {
    final cellWidget = pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(t, textAlign: align, style: pw.TextStyle(fontSize: 7, fontWeight: b ? pw.FontWeight.bold : null)));
    final decoration = pw.BoxDecoration(border: pw.Border(right: isLast ? pw.BorderSide.none : const pw.BorderSide(width: 1)));

    return flex != null
        ? pw.Expanded(flex: flex, child: pw.Container(decoration: decoration, child: cellWidget))
        : pw.SizedBox(width: width, child: pw.Container(decoration: decoration, child: cellWidget));
  }

  static pw.Widget _calcRow(String l, String v, {bool b = false}) => pw.Container(height: 22, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))), child: pw.Row(children: [pw.SizedBox(width: 55, child: pw.Padding(padding: const pw.EdgeInsets.only(left: 4), child: pw.Text(l, style: pw.TextStyle(fontSize: 7.5, fontWeight: b ? pw.FontWeight.bold : null)))), pw.Container(width: 1, color: PdfColors.black), pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.only(right: 4), child: pw.Text(v, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))))]));

}