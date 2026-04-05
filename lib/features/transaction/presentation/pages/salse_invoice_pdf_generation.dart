
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/*
class InvoicePartService {
  // --- MAIN FUNCTION TO BUILD THE ENTIRE INVOICE ---
  static pw.Widget buildFullInvoice(pw.ImageProvider logoImage) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1.0, color: PdfColors.black),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          _buildHeaderSection(logoImage),
          _buildConsigneeSection(),
          _buildItemsTable(),
          _buildBillingAndBankSection(),
          _buildFooterTermsAndSign(),
        ],
      ),
    );
  }

  // --- PART 1: HEADER (Ultra Engineering Works Details) ---
  static pw.Widget _buildHeaderSection(pw.ImageProvider logo) {
    return pw.Column(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.SizedBox(width: 40),
          pw.Text("TAX INVOICE", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text("ORIGINAL FOR BUYER", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
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
              decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(width: 1))),
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

  // --- PART 2: CONSIGNEE & INVOICE DETAILS ---
  static pw.Widget _buildConsigneeSection() {
    return pw.Column(children: [
      pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              height: 90, padding: const pw.EdgeInsets.all(8),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text("NAME & ADDRESS OF CONSIGNEE", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text("SUPRAJIT ENGINEERING LIMITED UNIT 8,", style: const pw.TextStyle(fontSize: 8.5)),
                pw.Text("#14 A. BOMMASANDRA INDUSTRIAL AREA.", style: const pw.TextStyle(fontSize: 8.5)),
                pw.Text("BOMMASANDRA, BANGALORE - 560 099.", style: const pw.TextStyle(fontSize: 8.5)),
                pw.Spacer(),
                pw.Text("29AADCS1638L1Z0", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ]),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              height: 90, decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(width: 1))),
              child: pw.Column(children: [
                _gridRow("Invoice No", "302", "DATE : 23-Mar-26"),
                _gridRow("Cust.P.O :", "Mr. Somanna", "23-Mar-26"),
                _gridRow("D.C.NO :", "0", "0"),
                _gridRow("DESPATCH :", "KA51B1038", ""),
              ]),
            ),
          ),
        ],
      ),
      pw.Divider(thickness: 1, height: 1),
    ]);
  }

  // --- PART 3: ITEMS TABLE ---
  static pw.Widget _buildItemsTable() {
    return pw.Column(children: [
      pw.Container(
        decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))),
        child: pw.Row(children: [
          _cell("SL.NO", width: 35, b: true),
          _cell("DESCRIPTION", flex: 3, b: true),
          _cell("HSN/SAC", width: 70, b: true),
          _cell("QTY", width: 50, b: true),
          _cell("PRICE/UNIT", width: 70, b: true),
          _cell("AMOUNT", width: 85, b: true, isLast: true),
        ]),
      ),
      _itemRow("1", "DIE CASTING MACHINE SAFETY GUARD", "84669310", "2.00", "4,268.00", "8,536.00"),
      _itemRow("2", "TRIMMING MACHINE SAFETY GUARD", "84669310", "2.00", "2,033.00", "4,066.00"),
      pw.SizedBox(height: 100),
      pw.Divider(thickness: 1, height: 1),
    ]);
  }

  // --- PART 4: BILLING & TAX SECTION ---
  static pw.Widget _buildBillingAndBankSection() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Container(
            decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 1))),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text("GSTIN: 29AHOPK6473G1ZS", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.Text("SERVICE TAX NO: AHOPK6473GSD001", style: const pw.TextStyle(fontSize: 7.5)),
                  ]),
                ),
                pw.Divider(thickness: 1, height: 1),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text("RUPEES IN WORDS:", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                    pw.Text("FOURTEEN THOUSAND EIGHT HUNDRED AND SEVENTY ONLY", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ]),
                ),
                pw.Divider(thickness: 1, height: 1),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    _bankRow("BANK NAME :", "STATE BANK OF INDIA"),
                    _bankRow("ACCOUNT NO :", "54009859972"),
                    _bankRow("IFS CODE :", "SBIN0040552"),
                    _bankRow("BRANCH :", "SINGASANDRA"),
                  ]),
                ),
              ],
            ),
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            children: [
              _calcRow("Total", ":", "12,602.00"),
              _calcRow("SGST", ": 9.00 %", "1,134.18"),
              _calcRow("CGST", ": 9.00 %", "1,134.18"),
              _calcRow("IGST", ": 0.00 %", "0.00"),
              _calcRow("P & F", ":", "0.00"),
              _calcRow("Round Off", ":", "0.00"),
              _calcRow("G.Total", ":", "14,870.36", b: true),
            ],
          ),
        ),
      ],
    );
  }

  // --- PART 5: TERMS & SIGNATURES ---
  static pw.Widget _buildFooterTermsAndSign() {
    return pw.Container(
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 1))),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 1))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("TERMS & CONDITIONS:", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text("1.Good once sold will not be taken back or exchange", style: const pw.TextStyle(fontSize: 6.5)),
                  pw.Text("2.Interest @24% will be charged if not paid within due period.", style: const pw.TextStyle(fontSize: 6.5)),
                  pw.Text("3.All Disputes Subject to Bangalore Jurisdiction Only.", style: const pw.TextStyle(fontSize: 6.5)),
                  pw.Text("4.All Payment Should Be Made By A/c Payee Cheque/D.D Only", style: const pw.TextStyle(fontSize: 6.5)),
                ],
              ),
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 1))),
              child: pw.Column(children: [pw.SizedBox(height: 35), pw.Text("Receiver signature", style: const pw.TextStyle(fontSize: 6.5))]),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(children: [
                pw.Text("For ULTRA ENGINEERING WORKS", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 35),
                pw.Text("Authorised Signatory", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // --- RE-USABLE HELPERS ---
  static pw.Widget _gridRow(String l, String v1, String v2) {
    return pw.Container(
      height: 22, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))),
      child: pw.Row(children: [
        pw.SizedBox(width: 55, child: pw.Padding(padding: const pw.EdgeInsets.only(left: 4), child: pw.Text(l, style: const pw.TextStyle(fontSize: 7)))),
        pw.Container(width: 1, color: PdfColors.black),
        pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.only(left: 4), child: pw.Text(v1, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)))),
        pw.Container(width: 1, color: PdfColors.black),
        pw.SizedBox(width: 75, child: pw.Padding(padding: const pw.EdgeInsets.only(left: 4), child: pw.Text(v2, style: const pw.TextStyle(fontSize: 7)))),
      ]),
    );
  }

  static pw.Widget _itemRow(String s, String d, String h, String q, String p, String a) {
    return pw.Row(children: [ _cell(s, width: 35), _cell(d, flex: 3, align: pw.TextAlign.left), _cell(h, width: 70), _cell(q, width: 50, align: pw.TextAlign.right), _cell(p, width: 70, align: pw.TextAlign.right), _cell(a, width: 85, align: pw.TextAlign.right, isLast: true) ]);
  }

  static pw.Widget _cell(String t, {double? width, int? flex, bool b = false, pw.TextAlign align = pw.TextAlign.center, bool isLast = false}) {
    return flex != null
        ? pw.Expanded(flex: flex, child: pw.Container(decoration: pw.BoxDecoration(border: pw.Border(right: isLast ? pw.BorderSide.none : const pw.BorderSide(width: 1))), padding: const pw.EdgeInsets.all(5), child: pw.Text(t, textAlign: align, style: pw.TextStyle(fontSize: 7, fontWeight: b ? pw.FontWeight.bold : null))))
        : pw.SizedBox(width: width, child: pw.Container(decoration: pw.BoxDecoration(border: pw.Border(right: isLast ? pw.BorderSide.none : const pw.BorderSide(width: 1))), padding: const pw.EdgeInsets.all(5), child: pw.Text(t, textAlign: align, style: pw.TextStyle(fontSize: 7, fontWeight: b ? pw.FontWeight.bold : null))));
  }

  static pw.Widget _calcRow(String l, String mid, String v, {bool b = false}) {
    return pw.Container(
      height: 20, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))),
      child: pw.Row(children: [
        pw.SizedBox(width: 55, child: pw.Padding(padding: const pw.EdgeInsets.only(left: 4), child: pw.Text(l, style: pw.TextStyle(fontSize: 7.5, fontWeight: b ? pw.FontWeight.bold : null)))),
        pw.Expanded(child: pw.Text(mid, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5))),
        pw.Container(width: 1, color: PdfColors.black),
        pw.SizedBox(width: 80, child: pw.Padding(padding: const pw.EdgeInsets.only(right: 4), child: pw.Text(v, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)))),
      ]),
    );
  }

  static pw.Widget _bankRow(String l, String v) {
    return pw.Row(children: [
      pw.SizedBox(width: 65, child: pw.Text(l, style: const pw.TextStyle(fontSize: 7.5))),
      pw.Text(v, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
    ]);
  }
}
*/


class InvoicePdfService {
  static Future<pw.Document> generate({
    required pw.ImageProvider? logoImage,
    required Map<String, dynamic> data,
    required bool isSales,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.0)),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min, // Fixes unbounded height error
              children: [
                // --- SECTION 1: HEADER & COMPANY ---
                // Logo null check handling added to prevent crash
                _buildHeader(logoImage!),
                pw.Divider(thickness: 1, height: 1),

                // --- SECTION 2: CONSIGNEE & INVOICE GRID ---
                _buildDynamicConsigneeSection(data),
                pw.Divider(thickness: 1, height: 1),

                // --- SECTION 3: ITEMS TABLE ---
                _buildDynamicItemsTable(data['details'] ?? []),

                // --- SECTION 4: BILLING & BANK ---
                _buildDynamicBillingSection(data),

                // --- SECTION 5: FOOTER ---
                _buildFooterTerms(),
              ],
            ),
          );
        },
      ),
    );
    return pdf;
  }

  static pw.Widget _buildHeader(pw.ImageProvider logo) {
    return pw.Column(children: [
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 8),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.SizedBox(width: 40),
          pw.Text("TAX INVOICE", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text("ORIGINAL FOR BUYER", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
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
              // Vertical line between logo and text removed as per your last request
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
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Container(
            height: 90,
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("NAME & ADDRESS OF CONSIGNEE", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(data['name']?.toString().toUpperCase() ?? "", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text(data['address'] ?? "", style: const pw.TextStyle(fontSize: 7.5)),
                pw.Spacer(), // Uses Spacer but container has fixed height now
                pw.Text("GSTIN: ${data['gst_number'] ?? 'N/A'}", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
        ),
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            height: 90,
            decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(width: 1))),
            child: pw.Column(children: [
              _gridRow("Invoice No", data['billno']?.toString() ?? ""),
              _gridRow("DATE", data['billdate'] ?? ""),
              _gridRow("Cust.P.O", data['purchase_order_no'] ?? ""),
              _gridRow("DESPATCH", data['no_of_package'] ?? ""),
            ]),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDynamicItemsTable(List<dynamic> items) {
    return pw.Column(
      children: [
        pw.Container(
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))),
          child: pw.Row(children: [
            _cell("SL", width: 35, b: true),
            _cell("DESCRIPTION", flex: 3, b: true),
            _cell("QTY", width: 50, b: true),
            _cell("PRICE", width: 70, b: true),
            _cell("AMOUNT", width: 85, b: true, isLast: true),
          ]),
        ),

        ...items.map((i) => pw.Row(children: [
          _cell(i['sno']?.toString() ?? "", width: 35),
          _cell(i['product_name'] ?? "", flex: 3, align: pw.TextAlign.left),
          _cell(i['qty']?.toString() ?? "0", width: 50),
          _cell(i['rate']?.toString() ?? "0", width: 70),
          _cell(i['total']?.toString() ?? "0", width: 85, isLast: true),
        ])),

        // FIX: This container now expands vertical lines to touch Section 4
        pw.Container(
          height: 150,
          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _cell("", width: 35),
              _cell("", flex: 3),
              _cell("", width: 50),
              _cell("", width: 70),
              _cell("", width: 85, isLast: true),
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
              pw.Text("IFS CODE: SBIN0040552", style: const pw.TextStyle(fontSize: 7)),
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
    return pw.Container(
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 1))),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 1))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("TERMS & CONDITIONS:", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text("1.Good once sold will not be taken back or exchange", style: const pw.TextStyle(fontSize: 6.5)),
                  pw.Text("2.Interest @24% will be charged if not paid within due period.", style: const pw.TextStyle(fontSize: 6.5)),
                  pw.Text("3.All Disputes Subject to Bangalore Jurisdiction Only.", style: const pw.TextStyle(fontSize: 6.5)),
                  pw.Text("4.All Payment Should Be Made By A/c Payee Cheque/D.D Only", style: const pw.TextStyle(fontSize: 6.5)),
                ],
              ),
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 1))),
              child: pw.Column(children: [pw.SizedBox(height: 35), pw.Text("Receiver signature", style: const pw.TextStyle(fontSize: 6.5))]),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(children: [
                pw.Text("For ULTRA ENGINEERING WORKS", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 35),
                pw.Text("Authorised Signatory", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _gridRow(String l, String v) => pw.Container(height: 22.5, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))), child: pw.Row(children: [pw.SizedBox(width: 55, child: pw.Padding(padding: const pw.EdgeInsets.only(left: 4), child: pw.Text(l, style: const pw.TextStyle(fontSize: 7)))), pw.Container(width: 1, color: PdfColors.black), pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.only(left: 4), child: pw.Text(v, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))))]));

  static pw.Widget _cell(String t, {double? width, int? flex, bool b = false, pw.TextAlign align = pw.TextAlign.center, bool isLast = false}) {
    final cellWidget = pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(t, textAlign: align, style: pw.TextStyle(fontSize: 7, fontWeight: b ? pw.FontWeight.bold : null)));
    final decoration = pw.BoxDecoration(border: pw.Border(right: isLast ? pw.BorderSide.none : const pw.BorderSide(width: 1)));

    return flex != null
        ? pw.Expanded(flex: flex, child: pw.Container(decoration: decoration, child: cellWidget))
        : pw.SizedBox(width: width, child: pw.Container(decoration: decoration, child: cellWidget));
  }

  static pw.Widget _calcRow(String l, String v, {bool b = false}) => pw.Container(height: 22, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))), child: pw.Row(children: [pw.SizedBox(width: 55, child: pw.Padding(padding: const pw.EdgeInsets.only(left: 4), child: pw.Text(l, style: pw.TextStyle(fontSize: 7.5, fontWeight: b ? pw.FontWeight.bold : null)))), pw.Container(width: 1, color: PdfColors.black), pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.only(right: 4), child: pw.Text(v, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))))]));
}