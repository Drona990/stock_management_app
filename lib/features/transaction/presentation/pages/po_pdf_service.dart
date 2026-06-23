import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoiceDCPdfService {
  static Future<pw.Document> generate({
    required pw.ImageProvider logoImage,
    required Map<String, dynamic> data,
    required String terminalMode,
    required List<String> headings,
  }) async {
    final pdf = pw.Document();
    final double pageHeight = PdfPageFormat.a4.height;
    final double pageWidth = PdfPageFormat.a4.width;
    const double marginSize = 25.0;

    final double usableHeight = pageHeight - (marginSize * 2);
    final double usableWidth = pageWidth - (marginSize * 2);
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
                  pw.Positioned(
                    top: 172,
                    bottom: bottomThresholdLock,
                    left: 0, right: 0,
                    child: _buildContinuousTabularGridFillerMatrix(terminalMode),
                  ),
                  pw.Positioned(
                    top: 0, left: 0, right: 0,
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        _buildHeader(logoImage, currentHeading, terminalMode),
                        _buildDynamicConsigneeSection(data, terminalMode),
                        _buildTableHeader(terminalMode),
                        _buildTableDataRows(data['details'] ?? [], terminalMode),
                      ],
                    ),
                  ),
                  pw.Positioned(
                    bottom: 0, left: 0, right: 0,
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
            pw.Text("PURCHASE ORDER VOUCHER", style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            pw.Text(title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
      pw.Divider(thickness: 1, height: 1),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(width: 90, height: 65, padding: const pw.EdgeInsets.all(4), child: pw.Image(logo, fit: pw.BoxFit.contain)),
          pw.Expanded(
            child: pw.Container(
              height: 65, padding: const pw.EdgeInsets.all(4),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text("ULTRA ENGINEERING WORKS", style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold)),
                  pw.Text("SPM MANUFACTURERS & FABRICATORS", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text("OFFICE:NO: 15/6, 5th CROSS, VIDYA NAGAR, OPP. S.K.F. FACTORY, BOMMASANDRA INDL. AREA, BENGALURU-560 099.", style: const pw.TextStyle(fontSize: 6.5), textAlign: pw.TextAlign.center),
                  pw.Text("Tele Fax: 080-27834287, Mob: 9342509313 Email: ueworks@gmail.com", style: const pw.TextStyle(fontSize: 6.5), textAlign: pw.TextAlign.center),
                  pw.Text("Works: No.B-48, KSSIDC INDL Estate, Near Karnataka Bank, Bommasandra Indl. Area, BENGALURU-560 099.", style: const pw.TextStyle(fontSize: 6.2), textAlign: pw.TextAlign.center),
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
    const double sectionHeight = 86;
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
                      pw.Text("SUPPLIER BILLING MASTER ALLOCATION OFFICE", style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(data['name']?.toString().toUpperCase() ?? "", style: pw.TextStyle(fontSize: 8.0, fontWeight: pw.FontWeight.bold)),
                      pw.Text(data['address']?.toString() ?? "", style: const pw.TextStyle(fontSize: 7.0), maxLines: 2, overflow: pw.TextOverflow.clip),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("GSTIN: ${data['gst_number'] ?? data['gst_no'] ?? 'N/A'}", style: pw.TextStyle(fontSize: 7.0, fontWeight: pw.FontWeight.bold)),
                      pw.Text("STATUS: MANDATORY CORE PO", style: pw.TextStyle(fontSize: 7.0, fontWeight: pw.FontWeight.bold)),
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
              decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(width: 1))),
              child: pw.Column(
                children: [
                  _complexRow("PURCHASE ORDER NO", data['po_bill_no']?.toString() ?? data['billno'] ?? "", "DATE", data['billdate'] ?? ""),
                  _complexRow("EXPECTED PKG :", data['no_of_package'] ?? "", "VALIDITY", "${data['due_date'] ?? '0'} DAYS"),
                  _complexRow("SYSTEM TOKEN :", data['billno'] ?? "", " ", ""),
                  _complexRow("DISPATCH BY :", data['dispatch'] ?? "", " ", ""),
                  _complexRow("TAX preference:", data['tax_zone'] ?? "", " ", "", isLast: true),
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
        decoration: pw.BoxDecoration(border: pw.Border(bottom: isLast ? pw.BorderSide.none : pw.BorderSide(width: 1))),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Expanded(flex: 6, child: pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(l1, style: const pw.TextStyle(fontSize: 6.5)), pw.Text(v1, style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold))]))),
            pw.Container(width: 1, color: PdfColors.black),
            pw.Expanded(flex: 4, child: pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(l2, style: const pw.TextStyle(fontSize: 6.5)), pw.Text(v2, style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold))]))),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTableHeader(String terminalMode) {
    return pw.Container(
      height: 20,
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 1), bottom: pw.BorderSide(width: 1))),
      child: pw.Row(children: [
        _overlayCell("SL", width: 30, b: true),
        _overlayCell("MATERIAL CORE NOMENCLATURE DESCRIPTION", flex: 1, b: true, align: pw.TextAlign.left),
        _overlayCell("HSN CODE", width: 60, b: true),
        _overlayCell("REQ QTY", width: 45, b: true),
        _overlayCell("AGREED RATE", width: 65, b: true),
        _overlayCell("NET TOTAL", width: 75, b: true),
      ]),
    );
  }

  static pw.Widget _buildTableDataRows(List<dynamic> items, String terminalMode) {
    return pw.Column(
      children: items.map((i) => pw.Container(
        height: 20,
        child: pw.Row(children: [
          _overlayCell(i['sno']?.toString() ?? "", width: 30),
          _overlayCell(i['product_name'] ?? "", flex: 1, align: pw.TextAlign.left),
          _overlayCell(i['hsncode']?.toString() ?? " ", width: 60),
          _overlayCell(i['qty']?.toString() ?? "0", width: 45),
          _overlayCell(i['rate']?.toString() ?? "0", width: 65),
          _overlayCell(i['total']?.toString() ?? i['amount']?.toString() ?? "0", width: 75),
        ]),
      )).toList(),
    );
  }

  static pw.Widget _buildContinuousTabularGridFillerMatrix(String terminalMode) {
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
        ],
      ),
    );
  }

  static pw.Widget _buildDynamicBillingSection(Map<String, dynamic> data, String terminalMode) {
    return pw.Row(children: [
      pw.Expanded(
        flex: 3,
        child: pw.Container(
          height: 72,
          decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 1))),
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("VALUE IN WORDS:", style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text(data['amtin_words'] ?? "", style: pw.TextStyle(fontSize: 7.0, fontWeight: pw.FontWeight.bold), maxLines: 2),
                ],
              ),
              pw.Text("TERMS: PROCUREMENT COMMITTED VIA CORE INTERNAL ERP MATRIX LOGS", style: const pw.TextStyle(fontSize: 6.0)),
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
    const double footerHeight = 56;
    return pw.Container(
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 1))),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              height: footerHeight, padding: const pw.EdgeInsets.all(3),
              decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 1))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text("TERMS & CONDITIONS:", style: pw.TextStyle(fontSize: 7.0, fontWeight: pw.FontWeight.bold)),
                pw.Text("1. Materials subject to absolute inspection verification grid at store limits.", style: const pw.TextStyle(fontSize: 5.8)),
                pw.Text("2. Delays beyond timeline constraints trigger penalty indices.", style: const pw.TextStyle(fontSize: 5.8)),
                pw.Text("3. All Disputes Subject to Bangalore Jurisdiction Only.", style: const pw.TextStyle(fontSize: 5.8)),
              ],
              ),
            ),
          ),
          pw.Expanded(flex: 1, child: pw.Container(height: footerHeight, padding: const pw.EdgeInsets.all(3), decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 1))), child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.end, children: [pw.Text("Prepared By", style: const pw.TextStyle(fontSize: 5.8))]))),
          pw.Expanded(flex: 2, child: pw.Container(height: footerHeight, padding: const pw.EdgeInsets.all(3), child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("For ULTRA ENGINEERING WORKS", style: pw.TextStyle(fontSize: 6.0, fontWeight: pw.FontWeight.bold)), pw.Text("Authorised Procurement Seal", style: pw.TextStyle(fontSize: 6.0, fontWeight: pw.FontWeight.bold))]))),
        ],
      ),
    );
  }

  static pw.Widget _overlayCell(String t, {double? width, int? flex, bool b = false, pw.TextAlign align = pw.TextAlign.center}) {
    final cellWidget = pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4), child: pw.Text(t, textAlign: align, style: pw.TextStyle(fontSize: 7.5, fontWeight: b ? pw.FontWeight.bold : null)));
    return flex != null ? pw.Expanded(flex: flex, child: cellWidget) : pw.SizedBox(width: width, child: cellWidget);
  }

  static pw.Widget _calcRow(String l, String v, {bool b = false}) => pw.Container(height: 12, decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))), child: pw.Row(children: [pw.SizedBox(width: 55, child: pw.Padding(padding: const pw.EdgeInsets.only(left: 4), child: pw.Text(l, style: pw.TextStyle(fontSize: 6.5, fontWeight: b ? pw.FontWeight.bold : null)))), pw.Container(width: 1, color: PdfColors.black), pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.only(right: 4), child: pw.Text(v, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 6.5, fontWeight: b ? pw.FontWeight.bold : null))))]));
}