/*import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoiceDCPdfService {
  static Future<pw.Document> generate({
    required pw.ImageProvider? logoImage,
    required Map<String, dynamic> data,
    required String terminalMode, // 'INWARD', 'OUTWARD', or 'PROFORMA'
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
                  // 1. HEADER
                  _buildHeader(logoImage!, currentHeading, terminalMode),
                  pw.Divider(thickness: 1, height: 1),

                  // 2. PARTY DETAILS (FIXED FOR EMPTY/MISSING BACKEND MOBILE KEYS)
                  _buildDynamicConsigneeSection(data, terminalMode),
                  pw.Divider(thickness: 1, height: 1),

                  // 3. ITEMS TABLE
                  _buildDynamicItemsTable(data['details'] ?? [], terminalMode),

                  // 4. BILLING/TOTALS SECTION
                  _buildDynamicBillingSection(data, terminalMode),

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

  static pw.Widget _buildHeader(pw.ImageProvider logo, String title, String terminalMode) {
    return pw.Column(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.SizedBox(width: 40),
          pw.Text(
              terminalMode == "PROFORMA" ? "PROFORMA INVOICE" : "DELIVERY CHALLAN",
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)
          ),
          pw.Text(title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ]),
      ),
      pw.Divider(thickness: 1, height: 1),
      pw.Row(
        crossAxisAlignment:  pw.CrossAxisAlignment.center,
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

  // ==========================================================================
  // 🔍 FIXED: EXTRACTED MOBILE BOUNDARY SAFE MATRIX
  // ==========================================================================
  static pw.Widget _buildDynamicConsigneeSection(Map<String, dynamic> data, String terminalMode) {
    const double sectionHeight = 100;

    // Strict multi-layer validation engine to block null exceptions
    String validatedMobile = "NOT AVAILABLE";
    if (data.containsKey('mobile_no') && data['mobile_no'] != null && data['mobile_no'].toString().trim().isNotEmpty) {
      validatedMobile = data['mobile_no'].toString();
    } else if (data.containsKey('customer_mobile') && data['customer_mobile'] != null) {
      validatedMobile = data['customer_mobile'].toString();
    } else if (data.containsKey('party_mobile') && data['party_mobile'] != null) {
      validatedMobile = data['party_mobile'].toString();
    } else if (data.containsKey('mobile') && data['mobile'] != null) {
      validatedMobile = data['mobile'].toString();
    }

    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(width: 1),
          bottom: pw.BorderSide(width: 1),
        ),
      ),
      child: pw.Row(
        children: [
          // --- LEFT SIDE: PARTY INFO ---
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
                          terminalMode == "PROFORMA" ? "NAME & ADDRESS OF CONSIGNEE" : "NAME & ADDRESS OF RECEIVER",
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(data['name']?.toString().toUpperCase() ?? "",
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text(data['address']?.toString() ?? "",
                          style: const pw.TextStyle(fontSize: 7.5)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("GSTIN: ${data['gst_number'] ?? data['gst_no'] ?? ''}",
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text("MOBILE: $validatedMobile",
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // --- RIGHT SIDE: METADATA COLUMN ---
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
                      terminalMode == "PROFORMA" ? "Proforma No" : "Challan / DC No",
                      data['billno'] ?? data['dc_no'] ?? "",
                      "DATE",
                      data['billdate'] ?? data['dc_date'] ?? ""
                  ),
                  _complexRow("Cust.P.O :", data['purchase_order_no'] ?? "", "DATE", data['purchase_order_date'] ?? ""),
                  _complexRow("REF. NO :", "", "DATE", ""),
                  _complexRow("DISPATCH :", data['dispatch'] ?? "", " ", ""),
                  _complexRow("EWB NO:", data['ewb_no'] ?? data['ewb_number'] ?? "", " ", "", isLast: true),
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

  static pw.Widget _buildDynamicItemsTable(List<dynamic> items, String terminalMode) {
    final bool isProforma = terminalMode == "PROFORMA";

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
            _cell("DESCRIPTION", flex: 1, b: true),
            _cell("HSN CODE", width: hsnWidth, b: true),
            _cell("QTY", width: qtyWidth, b: true),
            _cell("PRICE/QTY", width: priceWidth, b: true),
            _cell("AMOUNT", width: amountWidth, b: true, isLast: isProforma),
            if (!isProforma) _cell("REMARKS", width: remarksWidth, b: true, isLast: true),
          ]),
        ),
        ...items.map((i) => pw.Row(children: [
          _cell(i['sno']?.toString() ?? "", width: slWidth),
          _cell(i['product_name'] ?? "", flex: 1, align: pw.TextAlign.left),
          _cell(i['hsncode']?.toString() ?? " ", width: hsnWidth),
          _cell(i['qty']?.toString() ?? "0", width: qtyWidth),
          _cell(i['rate']?.toString() ?? "0", width: priceWidth),
          _cell(i['amount']?.toString() ?? i['total']?.toString() ?? "0", width: amountWidth, isLast: isProforma),
          if (!isProforma) _cell(i['remarks']?.toString() ?? " ", width: remarksWidth, align: pw.TextAlign.left, isLast: true),
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
              _cell("", width: amountWidth, isLast: isProforma),
              if (!isProforma) _cell("", width: remarksWidth, isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDynamicBillingSection(Map<String, dynamic> data, String terminalMode) {
    final bool isProforma = terminalMode == "PROFORMA";

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
              pw.Text("BANK: STATE BANK OF INDIA | A/C: 54009859972", style: const pw.TextStyle(fontSize: 7)),
              pw.Text("IFS CODE: SBIN0040552 | ADDRESS: SINGASANDRA", style: const pw.TextStyle(fontSize: 7)),
            ],
          ),
        ),
      ),
      pw.Expanded(
        flex: 2,
        child: pw.Column(children: [
          _calcRow("Subtotal", data['totalamount']?.toString() ?? data['total_base_amount']?.toString() ?? "0"),
          if (isProforma) ...[
            _calcRow("CGST", data['cgst']?.toString() ?? "0"),
            _calcRow("SGST", data['sgst']?.toString() ?? "0"),
            _calcRow("IGST", data['igst']?.toString() ?? "0"),
          ],
          _calcRow("Forwarding", data['forwading_charge']?.toString() ?? "0"),
          _calcRow("Total Value", data['grand_totamt']?.toString() ?? data['grand_total']?.toString() ?? "0", b: true),
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
                  pw.Text("1. Goods once sold will not be taken back or exchanged.", style: const pw.TextStyle(fontSize: 6)),
                  pw.Text("2. Interest @24% will be charged if not paid within due period.", style: const pw.TextStyle(fontSize: 6)),
                  pw.Text("3. All Disputes Subject to Bangalore Jurisdiction Only.", style: const pw.TextStyle(fontSize: 6)),
                  pw.Text("4. All Payment Should Be Made By A/c Payee Cheque/D.D Only.", style: const pw.TextStyle(fontSize: 6)),
                  pw.Text("5. Our Risk/Responsibility Ceases Once Goods Leave Our Premises.", style: const pw.TextStyle(fontSize: 6)),
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
                  pw.Text("Receiver signature", style: const pw.TextStyle(fontSize: 6.5)),
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
                  pw.Text("Authorised Signatory", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
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

  static pw.Widget _calcRow(String l, String v, {bool b = false}) => pw.Container(height: 22, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))), child: pw.Row(children: [pw.SizedBox(width: 55, child: pw.Padding(padding: const pw.EdgeInsets.only(left: 4), child: pw.Text(l, style: pw.TextStyle(fontSize: 7.5, fontWeight: b ? pw.FontWeight.bold : null)))), pw.Container(width: 1, color: PdfColors.black), pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.only(right: 4), child: pw.Text(v, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.5, fontWeight: b ? pw.FontWeight.bold : null))))]));
}*/

/*

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoiceDCPdfService {
  static Future<pw.Document> generate({
    required pw.ImageProvider? logoImage,
    required Map<String, dynamic> data,
    required String terminalMode, // 'INWARD', 'OUTWARD', or 'PROFORMA'
    required List<String> headings,
  }) async {
    final pdf = pw.Document();

    final double pageHeight = PdfPageFormat.a4.height; // ~842 points
    final double pageWidth = PdfPageFormat.a4.width;   // ~595 points

    // 🌟 CHANGE 1: Enhanced margin to give strict breathing room at page threshold bounds
    const double marginSize = 25.0;

    final double usableHeight = pageHeight - (marginSize * 2);
    final double usableWidth = pageWidth - (marginSize * 2);

    // Dynamic Bottom Height Resolution Matrix: Billing Section (80) + Footer Terms (70) = 150
    const double bottomThresholdLock = 150.0;

    for (String currentHeading in headings) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(marginSize),
          build: (pw.Context context) {
            return pw.Container(
              height: usableHeight,
              width: usableWidth,
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.0)),
              child: pw.Stack(
                children: [
                  // ==========================================================
                  // 🟢 GRID FILLER (SABSE PEECHE): Draws Perfect Full-Height Vertical Lines
                  // ==========================================================
                  pw.Positioned(
                    top: 191,     // Exact start from Header Section bottom threshold
                    bottom: bottomThresholdLock, // 🌟 Pinned perfectly above tightly bounded billing layer
                    left: 0,
                    right: 0,
                    child: _buildContinuousTabularGridFillerMatrix(terminalMode),
                  ),

                  // ==========================================================
                  // 🟢 TOP SEGMENT: HEADERS + PARTY INFO + DATA ROWS OVERLAY
                  // ==========================================================
                  pw.Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        _buildHeader(logoImage!, currentHeading, terminalMode),
                        _buildDynamicConsigneeSection(data, terminalMode),
                        _buildTableHeader(terminalMode),
                        _buildTableDataRows(data['details'] ?? [], terminalMode),
                      ],
                    ),
                  ),

                  // ==========================================================
                  // 🟢 BOTTOM SEGMENT: TOTALS + FOOTER TERMS
                  // ==========================================================
                  pw.Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Divider(thickness: 1, height: 1),
                        _buildDynamicBillingSection(data, terminalMode),
                        _buildFooterTerms(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
    return pdf;
  }

  static pw.Widget _buildHeader(pw.ImageProvider logo, String title, String terminalMode) {
    return pw.Column(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.SizedBox(width: 40),
            pw.Text(
                terminalMode == "PROFORMA" ? "PROFORMA INVOICE" : "DELIVERY CHALLAN",
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)
            ),
            pw.Text(title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
      pw.Divider(thickness: 1, height: 1),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(width: 100, height: 75, padding: const pw.EdgeInsets.all(5), child: pw.Image(logo, fit: pw.BoxFit.contain)),
          pw.Expanded(
            child: pw.Container(
              height: 75, padding: const pw.EdgeInsets.all(5),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text("ULTRA ENGINEERING WORKS", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text("SPM MANUFACTURERS & FABRICATORS", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text("OFFICE:NO: 15/6, 5th CROSS, VIDYA NAGAR, OPP. S.K.F. FACTORY, BOMMASANDRA INDL. AREA, BENGALURU-560 099.",
                      style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
                  pw.Text("Tele Fax: 080-27834287, Mob: 9342509313 Email: ueworks@gmail.com",
                      style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
                  pw.Text("Works: No.B-48, KSSIDC INDL Estate, Near Karnataka Bank, Bommasandra Indl. Area, BENGALURU-560 099.",
                      style: const pw.TextStyle(fontSize: 6.5), textAlign: pw.TextAlign.center),
                ],
              ),
            ),
          ),
        ],
      ),
      pw.Divider(thickness: 1, height: 1),
    ]);
  }

  static pw.Widget _buildDynamicConsigneeSection(Map<String, dynamic> data, String terminalMode) {
    const double sectionHeight = 100;

    String validatedMobile = "NOT AVAILABLE";
    if (data.containsKey('mobile_no') && data['mobile_no'] != null && data['mobile_no'].toString().trim().isNotEmpty) {
      validatedMobile = data['mobile_no'].toString();
    } else if (data.containsKey('customer_mobile') && data['customer_mobile'] != null) {
      validatedMobile = data['customer_mobile'].toString();
    } else if (data.containsKey('party_mobile') && data['party_mobile'] != null) {
      validatedMobile = data['party_mobile'].toString();
    } else if (data.containsKey('mobile') && data['mobile'] != null) {
      validatedMobile = data['mobile'].toString();
    }

    return pw.Container(
      height: sectionHeight,
      child: pw.Row(
        children: [
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
                          terminalMode == "PROFORMA" ? "NAME & ADDRESS OF CONSIGNEE" : "NAME & ADDRESS OF RECEIVER",
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(data['name']?.toString().toUpperCase() ?? "",
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text(data['address']?.toString() ?? "",
                          style: const pw.TextStyle(fontSize: 7.5)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("GSTIN: ${data['gst_number'] ?? data['gst_no'] ?? ''}",
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text("MOBILE: $validatedMobile",
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
                      terminalMode == "PROFORMA" ? "Proforma No" : "Challan / DC No",
                      data['billno'] ?? data['dc_no'] ?? "",
                      "DATE",
                      data['billdate'] ?? data['dc_date'] ?? ""
                  ),
                  _complexRow("Cust.P.O :", data['purchase_order_no'] ?? "", "DATE", data['purchase_order_date'] ?? ""),
                  _complexRow("REF. NO :", "", "DATE", ""),
                  _complexRow("DISPATCH :", data['dispatch'] ?? "", " ", ""),
                  _complexRow("EWB NO:", data['ewb_no'] ?? data['ewb_number'] ?? "", " ", "", isLast: true),
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

  static pw.Widget _buildTableHeader(String terminalMode) {
    final bool isProforma = terminalMode == "PROFORMA";
    return pw.Container(
      height: 20,
      decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(width: 1), bottom: pw.BorderSide(width: 1))
      ),
      child: pw.Row(children: [
        _overlayCell("SL", width: 30, b: true),
        _overlayCell("DESCRIPTION", flex: 1, b: true),
        _overlayCell("HSN CODE", width: 60, b: true),
        _overlayCell("QTY", width: 45, b: true),
        _overlayCell("PRICE/QTY", width: 65, b: true),
        _overlayCell("AMOUNT", width: 75, b: true),
        if (!isProforma) _overlayCell("REMARKS", width: 90, b: true),
      ]),
    );
  }

  static pw.Widget _buildTableDataRows(List<dynamic> items, String terminalMode) {
    final bool isProforma = terminalMode == "PROFORMA";
    return pw.Column(
      children: items.map((i) => pw.Container(
        height: 20,
        child: pw.Row(children: [
          _overlayCell(i['sno']?.toString() ?? "", width: 30),
          _overlayCell(i['product_name'] ?? "", flex: 1, align: pw.TextAlign.left),
          _overlayCell(i['hsncode']?.toString() ?? " ", width: 60),
          _overlayCell(i['qty']?.toString() ?? "0", width: 45),
          _overlayCell(i['rate']?.toString() ?? "0", width: 65),
          _overlayCell(i['amount']?.toString() ?? i['total']?.toString() ?? "0", width: 75),
          if (!isProforma) _overlayCell(i['remarks']?.toString() ?? " ", width: 90, align: pw.TextAlign.left),
        ]),
      )).toList(),
    );
  }

  static pw.Widget _buildContinuousTabularGridFillerMatrix(String terminalMode) {
    final bool isProforma = terminalMode == "PROFORMA";
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.SizedBox(width: 30), pw.Container(width: 1, color: PdfColors.black),
          pw.Expanded(flex: 1, child: pw.SizedBox()), pw.Container(width: 1, color: PdfColors.black),
          pw.SizedBox(width: 60), pw.Container(width: 1, color: PdfColors.black),
          pw.SizedBox(width: 45), pw.Container(width: 1, color: PdfColors.black),
          pw.SizedBox(width: 65), pw.Container(width: 1, color: PdfColors.black),
          pw.SizedBox(width: 75),
          if (!isProforma) ...[
            pw.Container(width: 1, color: PdfColors.black),
            pw.SizedBox(width: 90),
          ]
        ],
      ),
    );
  }

  static pw.Widget _buildDynamicBillingSection(Map<String, dynamic> data, String terminalMode) {
    final bool isProforma = terminalMode == "PROFORMA";

    return pw.Row(children: [
      pw.Expanded(
        flex: 3,
        child: pw.Container(
          height: 80, // 🌟 CHANGE 2: Slightly compressed height from 88 to 80 for safety
          decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 1))),
          padding: const pw.EdgeInsets.all(4),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("VALUE IN WORDS:", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
              pw.Text(data['amtin_words'] ?? "", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Text("BANK: STATE BANK OF INDIA | A/C: 54009859972", style: const pw.TextStyle(fontSize: 6.5)),
              pw.Text("IFS CODE: SBIN0040552 | ADDRESS: SINGASANDRA", style: const pw.TextStyle(fontSize: 6.5)),
            ],
          ),
        ),
      ),
      pw.Expanded(
        flex: 2,
        child: pw.Column(children: [
          _calcRow("Subtotal", data['totalamount']?.toString() ?? data['total_base_amount']?.toString() ?? "0"),
          if (isProforma) ...[
            _calcRow("CGST", data['cgst']?.toString() ?? "0"),
            _calcRow("SGST", data['sgst']?.toString() ?? "0"),
            _calcRow("IGST", data['igst']?.toString() ?? "0"),
          ],
          _calcRow("Forwarding", data['forwading_charge']?.toString() ?? "0"),
          _calcRow("Total Value", data['grand_totamt']?.toString() ?? data['grand_total']?.toString() ?? "0", b: true),
        ]),
      ),
    ]);
  }

  static pw.Widget _buildFooterTerms() {
    const double footerHeight = 70; // 🌟 CHANGE 3: Locked at 70 points for absolute relief
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(width: 1)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              height: footerHeight,
              padding: const pw.EdgeInsets.all(4),
              decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 1))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Text("TERMS & CONDITIONS:", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 1),
                  pw.Text("1. Goods once sold will not be taken back or exchanged.", style: const pw.TextStyle(fontSize: 6.2)),
                  pw.Text("2. Interest @24% will be charged if not paid within due period.", style: const pw.TextStyle(fontSize: 6.2)),
                  pw.Text("3. All Disputes Subject to Bangalore Jurisdiction Only.", style: const pw.TextStyle(fontSize: 6.2)),
                  pw.Text("4. All Payment Should Be Made By A/c Payee Cheque/D.D Only.", style: const pw.TextStyle(fontSize: 6.2)),
                  pw.Text("5. Our Risk/Responsibility Ceases Once Goods Leave Our Premises.", style: const pw.TextStyle(fontSize: 6.2)),
                ],
              ),
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              height: footerHeight,
              padding: const pw.EdgeInsets.all(4),
              decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 1))),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text("Receiver signature", style: const pw.TextStyle(fontSize: 6.2)),
                ],
              ),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              height: footerHeight,
              padding: const pw.EdgeInsets.all(4),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("For ULTRA ENGINEERING WORKS", style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Authorised Signatory", style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _overlayCell(String t, {double? width, int? flex, bool b = false, pw.TextAlign align = pw.TextAlign.center}) {
    final cellWidget = pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: pw.Text(t, textAlign: align, style: pw.TextStyle(fontSize: 7.5, fontWeight: b ? pw.FontWeight.bold : null))
    );

    return flex != null
        ? pw.Expanded(flex: flex, child: cellWidget)
        : pw.SizedBox(width: width, child: cellWidget);
  }

  static pw.Widget _calcRow(String l, String v, {bool b = false}) => pw.Container(height: 20, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))), child: pw.Row(children: [pw.SizedBox(width: 55, child: pw.Padding(padding: const pw.EdgeInsets.only(left: 4), child: pw.Text(l, style: pw.TextStyle(fontSize: 7.5, fontWeight: b ? pw.FontWeight.bold : null)))), pw.Container(width: 1, color: PdfColors.black), pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.only(right: 4), child: pw.Text(v, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.5, fontWeight: b ? pw.FontWeight.bold : null))))]));
}*/

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoiceDCPdfService {
  static Future<pw.Document> generate({
    required pw.ImageProvider? logoImage,
    required Map<String, dynamic> data,
    required String terminalMode, // 'INWARD', 'OUTWARD', or 'PROFORMA'
    required List<String> headings,
  }) async {
    final pdf = pw.Document();

    final double pageHeight = PdfPageFormat.a4.height; // ~842 points
    final double pageWidth = PdfPageFormat.a4.width;   // ~595 points

    // Strict industrial standard border margins
    const double marginSize = 25.0;

    final double usableHeight = pageHeight - (marginSize * 2);
    final double usableWidth = pageWidth - (marginSize * 2);

    // 🌟 SQUEEZED BOTTOM BLOCK: Billing Section (72) + Footer Terms (56) = 128 (Gives 22 points extra safety buffer)
    const double bottomThresholdLock = 128.0;

    for (String currentHeading in headings) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(marginSize),
          build: (pw.Context context) {
            return pw.Container(
              height: usableHeight,
              width: usableWidth,
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.0)),
              child: pw.Stack(
                children: [
                  // ==========================================================
                  // 🟢 GRID FILLER (SABSE PEECHE): Draws Perfect Full-Height Vertical Lines
                  // ==========================================================
                  pw.Positioned(
                    top: 172,     // 🌟 FIXED OFFSET: Seamless baseline sync after header compression
                    bottom: bottomThresholdLock, // Absolute safety clearance boundary lock
                    left: 0,
                    right: 0,
                    child: _buildContinuousTabularGridFillerMatrix(terminalMode),
                  ),

                  // ==========================================================
                  // 🟢 TOP SEGMENT: HEADERS + PARTY INFO + DATA ROWS OVERLAY
                  // ==========================================================
                  pw.Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        _buildHeader(logoImage!, currentHeading, terminalMode),
                        _buildDynamicConsigneeSection(data, terminalMode),
                        _buildTableHeader(terminalMode),
                        _buildTableDataRows(data['details'] ?? [], terminalMode),
                      ],
                    ),
                  ),

                  // ==========================================================
                  // 🟢 BOTTOM SEGMENT: TOTALS + FOOTER TERMS
                  // ==========================================================
                  pw.Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Divider(thickness: 1, height: 1),
                        _buildDynamicBillingSection(data, terminalMode),
                        _buildFooterTerms(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
    return pdf;
  }

  static pw.Widget _buildHeader(pw.ImageProvider logo, String title, String terminalMode) {
    return pw.Column(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.SizedBox(width: 40),
            pw.Text(
                terminalMode == "PROFORMA" ? "PROFORMA INVOICE" : "DELIVERY CHALLAN",
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)
            ),
            pw.Text(title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
      pw.Divider(thickness: 1, height: 1),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // 🌟 COMPRESSED DESIGN AREA: Height scale reduced gracefully to 65 points
          pw.Container(width: 90, height: 65, padding: const pw.EdgeInsets.all(4), child: pw.Image(logo, fit: pw.BoxFit.contain)),
          pw.Expanded(
            child: pw.Container(
              height: 65, padding: const pw.EdgeInsets.all(4),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text("ULTRA ENGINEERING WORKS", style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
                  pw.Text("SPM MANUFACTURERS & FABRICATORS", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text("OFFICE:NO: 15/6, 5th CROSS, VIDYA NAGAR, OPP. S.K.F. FACTORY, BOMMASANDRA INDL. AREA, BENGALURU-560 099.",
                      style: const pw.TextStyle(fontSize: 6.5), textAlign: pw.TextAlign.center),
                  pw.Text("Tele Fax: 080-27834287, Mob: 9342509313 Email: ueworks@gmail.com",
                      style: const pw.TextStyle(fontSize: 6.5), textAlign: pw.TextAlign.center),
                  pw.Text("Works: No.B-48, KSSIDC INDL Estate, Near Karnataka Bank, Bommasandra Indl. Area, BENGALURU-560 099.",
                      style: const pw.TextStyle(fontSize: 6.2), textAlign: pw.TextAlign.center),
                ],
              ),
            ),
          ),
        ],
      ),
      pw.Divider(thickness: 1, height: 1),
    ]);
  }

  static pw.Widget _buildDynamicConsigneeSection(Map<String, dynamic> data, String terminalMode) {
    // 🌟 COMPRESSED SCHEMA BOUNDS: Structural height locked perfectly at 86 points
    const double sectionHeight = 86;

    String validatedMobile = "NOT AVAILABLE";
    if (data.containsKey('mobile_no') && data['mobile_no'] != null && data['mobile_no'].toString().trim().isNotEmpty) {
      validatedMobile = data['mobile_no'].toString();
    } else if (data.containsKey('customer_mobile') && data['customer_mobile'] != null) {
      validatedMobile = data['customer_mobile'].toString();
    } else if (data.containsKey('party_mobile') && data['party_mobile'] != null) {
      validatedMobile = data['party_mobile'].toString();
    } else if (data.containsKey('mobile') && data['mobile'] != null) {
      validatedMobile = data['mobile'].toString();
    }

    return pw.Container(
      height: sectionHeight,
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 5,
            child: pw.Container(
              height: sectionHeight,
              padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                          terminalMode == "PROFORMA" ? "NAME & ADDRESS OF CONSIGNEE" : "NAME & ADDRESS OF RECEIVER",
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(data['name']?.toString().toUpperCase() ?? "",
                          style: pw.TextStyle(fontSize: 8.0, fontWeight: pw.FontWeight.bold)),
                      pw.Text(data['address']?.toString() ?? "",
                          style: const pw.TextStyle(fontSize: 7.0), maxLines: 2, overflow: pw.TextOverflow.clip),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("GSTIN: ${data['gst_number'] ?? data['gst_no'] ?? ''}",
                          style: pw.TextStyle(fontSize: 7.0, fontWeight: pw.FontWeight.bold)),
                      pw.Text("MOBILE: $validatedMobile",
                          style: pw.TextStyle(fontSize: 7.0, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
                      terminalMode == "PROFORMA" ? "Proforma No" : "Challan / DC No",
                      data['billno'] ?? data['dc_no'] ?? "",
                      "DATE",
                      data['billdate'] ?? data['dc_date'] ?? ""
                  ),
                  _complexRow("Cust.P.O :", data['purchase_order_no'] ?? "", "DATE", data['purchase_order_date'] ?? ""),
                  _complexRow("REF. NO :", "", "DATE", ""),
                  _complexRow("DISPATCH :", data['dispatch'] ?? "", " ", ""),
                  _complexRow("EWB NO:", data['ewb_no'] ?? data['ewb_number'] ?? "", " ", "", isLast: true),
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
                    pw.Text(l1, style: const pw.TextStyle(fontSize: 6.5)),
                    pw.Text(v1, style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
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
                    pw.Text(l2, style: const pw.TextStyle(fontSize: 6.5)),
                    pw.Text(v2, style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTableHeader(String terminalMode) {
    final bool isProforma = terminalMode == "PROFORMA";
    return pw.Container(
      height: 20,
      decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(width: 1), bottom: pw.BorderSide(width: 1))
      ),
      child: pw.Row(children: [
        _overlayCell("SL", width: 30, b: true),
        _overlayCell("DESCRIPTION", flex: 1, b: true),
        _overlayCell("HSN CODE", width: 60, b: true),
        _overlayCell("QTY", width: 45, b: true),
        _overlayCell("PRICE/QTY", width: 65, b: true),
        _overlayCell("AMOUNT", width: 75, b: true),
        if (!isProforma) _overlayCell("REMARKS", width: 90, b: true),
      ]),
    );
  }

  static pw.Widget _buildTableDataRows(List<dynamic> items, String terminalMode) {
    final bool isProforma = terminalMode == "PROFORMA";
    return pw.Column(
      children: items.map((i) => pw.Container(
        height: 20,
        child: pw.Row(children: [
          _overlayCell(i['sno']?.toString() ?? "", width: 30),
          _overlayCell(i['product_name'] ?? "", flex: 1, align: pw.TextAlign.left),
          _overlayCell(i['hsncode']?.toString() ?? " ", width: 60),
          _overlayCell(i['qty']?.toString() ?? "0", width: 45),
          _overlayCell(i['rate']?.toString() ?? "0", width: 65),
          _overlayCell(i['amount']?.toString() ?? i['total']?.toString() ?? "0", width: 75),
          if (!isProforma) _overlayCell(i['remarks']?.toString() ?? " ", width: 90, align: pw.TextAlign.left),
        ]),
      )).toList(),
    );
  }

  static pw.Widget _buildContinuousTabularGridFillerMatrix(String terminalMode) {
    final bool isProforma = terminalMode == "PROFORMA";
    return pw.Container(
      width: double.infinity,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.SizedBox(width: 30), pw.Container(width: 1, color: PdfColors.black),
          pw.Expanded(flex: 1, child: pw.SizedBox()), pw.Container(width: 1, color: PdfColors.black),
          pw.SizedBox(width: 60), pw.Container(width: 1, color: PdfColors.black),
          pw.SizedBox(width: 45), pw.Container(width: 1, color: PdfColors.black),
          pw.SizedBox(width: 65), pw.Container(width: 1, color: PdfColors.black),
          pw.SizedBox(width: 75),
          if (!isProforma) ...[
            pw.Container(width: 1, color: PdfColors.black),
            pw.SizedBox(width: 90),
          ]
        ],
      ),
    );
  }

  static pw.Widget _buildDynamicBillingSection(Map<String, dynamic> data, String terminalMode) {
    final bool isProforma = terminalMode == "PROFORMA";

    return pw.Row(children: [
      pw.Expanded(
        flex: 3,
        child: pw.Container(
          height: 72, // 🌟 COMPRESSED MATRIX HEIGHT: Locked at 72 points down from 80 safely
          decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 1))),
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, // Clean structural spacing layout
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("VALUE IN WORDS:", style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text(data['amtin_words'] ?? "", style: pw.TextStyle(fontSize: 7.0, fontWeight: pw.FontWeight.bold), maxLines: 2),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("BANK: STATE BANK OF INDIA | A/C: 54009859972", style: const pw.TextStyle(fontSize: 6.2)),
                  pw.Text("IFS CODE: SBIN0040552 | ADDRESS: SINGASANDRA", style: const pw.TextStyle(fontSize: 6.2)),
                ],
              ),
            ],
          ),
        ),
      ),
      pw.Expanded(
        flex: 2,
        child: pw.Column(children: [
          _calcRow("Subtotal", data['totalamount']?.toString() ?? data['total_base_amount']?.toString() ?? "0"),
          if (isProforma) ...[
            _calcRow("CGST", data['cgst']?.toString() ?? "0"),
            _calcRow("SGST", data['sgst']?.toString() ?? "0"),
            _calcRow("IGST", data['igst']?.toString() ?? "0"),
          ],
          _calcRow("Forwarding", data['forwading_charge']?.toString() ?? "0"),
          _calcRow("Total Value", data['grand_totamt']?.toString() ?? data['grand_total']?.toString() ?? "0", b: true),
        ]),
      ),
    ]);
  }

  static pw.Widget _buildFooterTerms() {
    const double footerHeight = 56; // 🌟 HIGH CONSOLIDATION LOGIC: Reduced from 70 to 56 points to give 14 points vertical relief
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(width: 1)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              height: footerHeight,
              padding: const pw.EdgeInsets.all(3),
              decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 1))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Text("TERMS & CONDITIONS:", style: pw.TextStyle(fontSize: 7.0, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 1),
                  pw.Text("1. Goods once sold will not be taken back or exchanged.", style: const pw.TextStyle(fontSize: 5.8)),
                  pw.Text("2. Interest @24% will be charged if not paid within due period.", style: const pw.TextStyle(fontSize: 5.8)),
                  pw.Text("3. All Disputes Subject to Bangalore Jurisdiction Only.", style: const pw.TextStyle(fontSize: 5.8)),
                  pw.Text("4. All Payment Should Be Made By A/c Payee Cheque/D.D Only.", style: const pw.TextStyle(fontSize: 5.8)),
                  pw.Text("5. Our Risk/Responsibility Ceases Once Goods Leave Our Premises.", style: const pw.TextStyle(fontSize: 5.8)),
                ],
              ),
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              height: footerHeight,
              padding: const pw.EdgeInsets.all(3),
              decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 1))),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text("Receiver signature", style: const pw.TextStyle(fontSize: 5.8)),
                ],
              ),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              height: footerHeight,
              padding: const pw.EdgeInsets.all(3),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("For ULTRA ENGINEERING WORKS", style: pw.TextStyle(fontSize: 6.0, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Authorised Signatory", style: pw.TextStyle(fontSize: 6.0, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _overlayCell(String t, {double? width, int? flex, bool b = false, pw.TextAlign align = pw.TextAlign.center}) {
    final cellWidget = pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: pw.Text(t, textAlign: align, style: pw.TextStyle(fontSize: 7.5, fontWeight: b ? pw.FontWeight.bold : null))
    );

    return flex != null
        ? pw.Expanded(flex: flex, child: cellWidget)
        : pw.SizedBox(width: width, child: cellWidget);
  }

  static pw.Widget _calcRow(String l, String v, {bool b = false}) => pw.Container(height: 18, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))), child: pw.Row(children: [pw.SizedBox(width: 55, child: pw.Padding(padding: const pw.EdgeInsets.only(left: 4), child: pw.Text(l, style: pw.TextStyle(fontSize: 7.0, fontWeight: b ? pw.FontWeight.bold : null)))), pw.Container(width: 1, color: PdfColors.black), pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.only(right: 4), child: pw.Text(v, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.0, fontWeight: b ? pw.FontWeight.bold : null))))]));
}