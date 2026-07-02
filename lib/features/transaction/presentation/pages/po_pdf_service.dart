import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoicePOPdfService {
  static Future<pw.Document> generate({
    required pw.ImageProvider? logoImage,
    required Map<String, dynamic> data,
    required String terminalMode,
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
                  // 1. HEADER (Purchase Order Mode Locked)
                  _buildHeader(logoImage!, currentHeading),
                  pw.Divider(thickness: 1, height: 1),

                  // 2. SUPPLIER DETAILS (Mapped exactly to live API payload keys)
                  _buildDynamicSupplierSection(data),
                  pw.Divider(thickness: 1, height: 1),

                  // 3. MATERIAL ITEMS TABLE (Preserving Exact Heights & Widths Grid)
                  _buildDynamicItemsTable(data['details'] ?? []),

                  // 4. BILLING/TOTALS SECTION (PO Tax Engine Compliant)
                  _buildDynamicBillingSection(data),

                  // 5. FOOTER TERMS
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
          pw.Text(
              "PURCHASE ORDER VOUCHER",
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)
          ),
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

  static pw.Widget _buildDynamicSupplierSection(Map<String, dynamic> data) {
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
          // --- LEFT SIDE: SUPPLIER ALLOCATION INFO ---
          pw.Expanded(
            flex: 5,
            child: pw.Container(
              height: sectionHeight,
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                          "SUPPLIER BILLING MASTER ALLOCATION OFFICE",
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(data['name']?.toString().toUpperCase() ?? "",
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text("${data['address'] ?? ''} ${data['city'] ?? ''} ${data['pin'] ?? ''}".trim(),
                          style: const pw.TextStyle(fontSize: 7.5)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("GSTIN: ${data['gst_number'] ?? 'N/A'}",
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text("STATUS: MANDATORY CORE PO",
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // --- RIGHT SIDE: PO ORDER METADATA COLUMN (Live Data Payload Keys Mapping) ---
          pw.Expanded(
            flex: 5,
            child: pw.Container(
              height: sectionHeight,
              decoration: const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(width: 1)),
              ),
              child: pw.Column(
                children: [
                  _complexRow(
                      "PURCHASE ORDER NO",
                      data['po_bill_no']?.toString() ?? "N/A",
                      "DATE",
                      data['billdate'] ?? ""
                  ),
                  _complexRow("EXPECTED PKG :", data['no_of_package']?.toString() ?? "", "VALIDITY", "${data['due_date'] ?? '0'} DAYS"),
                  _complexRow("SYSTEM TOKEN :", data['billno']?.toString() ?? "", " ", ""),
                  _complexRow("DISPATCH BY :", data['dispatch']?.toString() ?? "", " ", ""),
                  _complexRow("TAX preference:", data['tax_zone']?.toString() ?? "", " ", "", isLast: true),
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
            pw.Container(width: 1, color: PdfColors.black),
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
    const double slWidth = 30;
    const double hsnWidth = 60;
    const double qtyWidth = 45;
    const double priceWidth = 65;
    const double amountWidth = 75;
    const double remarksWidth = 90;

    return pw.Column(
      children: [
        pw.Container(
          decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1), top: pw.BorderSide(width: 1))
          ),
          child: pw.Row(children: [
            _cell("SL", width: slWidth, b: true),
            _cell("MATERIAL CORE NOMENCLATURE DESCRIPTION", flex: 1, b: true, align: pw.TextAlign.left),
            _cell("HSN CODE", width: hsnWidth, b: true),
            _cell("REQ QTY", width: qtyWidth, b: true),
            _cell("AGREED RATE", width: priceWidth, b: true),
            _cell("NET TOTAL", width: amountWidth, b: true),
            _cell("UOM / REMARKS", width: remarksWidth, b: true, isLast: true),
          ]),
        ),
        ...items.map((i) => pw.Row(children: [
          _cell(i['sno']?.toString() ?? "", width: slWidth),
          _cell(i['product_name'] ?? "", flex: 1, align: pw.TextAlign.left),
          _cell(i['hsncode']?.toString() ?? " ", width: hsnWidth),
          _cell(i['qty']?.toString() ?? "0", width: qtyWidth),
          _cell(i['rate']?.toString() ?? "0", width: priceWidth),
          _cell(i['total']?.toString() ?? i['amount']?.toString() ?? "0", width: amountWidth),
          _cell(i['uom']?.toString() ?? (i['remarks'] != null ? i['remarks'].toString() : " "), width: remarksWidth, align: pw.TextAlign.left, isLast: true),
        ])),
        pw.Container(
          height: 370,
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
              _cell("", width: amountWidth),
              _cell("", width: remarksWidth, isLast: true),
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
              pw.Text("VALUE IN WORDS:", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
              pw.Text(data['amtin_words'] ?? "", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("TERMS: PROCUREMENT COMMITTED VIA CORE INTERNAL ERP MATRIX LOGS", style: const pw.TextStyle(fontSize: 6.5)),
            ],
          ),
        ),
      ),
      pw.Expanded(
        flex: 2,
        child: pw.Column(children: [
          _calcRow("Subtotal", data['totalamount']?.toString() ?? "0"),
          _calcRow("CGST amt", data['cgst']?.toString() ?? "0"),
          _calcRow("SGST amt", data['sgst']?.toString() ?? "0"),
          _calcRow("IGST amt", data['igst']?.toString() ?? "0"),
          _calcRow("Forwarding", data['forwading_charge']?.toString() ?? "0"),
          _calcRow("Grand Total", data['grand_totamt']?.toString() ?? "0", b: true),
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
              height: footerHeight,
              padding: const pw.EdgeInsets.all(5),
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide(width: 1)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Text("TERMS & CONDITIONS:", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 2),
                  pw.Text("1. Materials subject to absolute inspection verification grid at store limits.", style: const pw.TextStyle(fontSize: 6)),
                  pw.Text("2. Delays beyond timeline constraints trigger penalty indices.", style: const pw.TextStyle(fontSize: 6)),
                  pw.Text("3. All Disputes Subject to Bangalore Jurisdiction Only.", style: const pw.TextStyle(fontSize: 6)),
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
                  pw.Text("Prepared By", style: const pw.TextStyle(fontSize: 6.5)),
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
                  pw.Text("For ULTRA ENGINEERING WORKS", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Authorised Procurement Seal", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
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

  static pw.Widget _calcRow(String l, String v, {bool b = false}) => pw.Container(height: 14.5, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))), child: pw.Row(children: [pw.SizedBox(width: 55, child: pw.Padding(padding: const pw.EdgeInsets.only(left: 4), child: pw.Text(l, style: pw.TextStyle(fontSize: 7.5, fontWeight: b ? pw.FontWeight.bold : null)))), pw.Container(width: 1, color: PdfColors.black), pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.only(right: 4), child: pw.Text(v, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.5, fontWeight: b ? pw.FontWeight.bold : null))))]));
}