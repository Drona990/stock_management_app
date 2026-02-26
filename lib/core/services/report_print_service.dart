import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportPrintService {
  static Future<void> generateReportPDF(String title, List data) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text("${title.toUpperCase()} REPORT")),
          pw.TableHelper.fromTextArray(
            headers: ['DATE', 'ITEM NAME', 'BARCODE', 'PRICE', 'REMARK'],
            data: data.map((item) => [
              item['date']?.toString().split('T')[0] ?? '-',
              item['item_name'] ?? '-',
              item['barcode_number'] ?? '-',
              item['price']?.toString() ?? '0',
              item['sale__bill_no'] ?? item['status'] ?? '-'
            ]).toList(),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: '${title}_Report');
  }
}