import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. REPOSITORY
// ==========================================================================
class ReturnRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<Map<String, dynamic>> fetchBill(String invoiceNo) async {
    final encodedInvoice = Uri.encodeComponent(invoiceNo);
    final res = await apiClient.get('/api/inventory/returns/fetch/$encodedInvoice/');
    return res.data;
  }

  Future<Map<String, dynamic>> processAction(Map<String, dynamic> data) async {
    final res = await apiClient.post('/api/inventory/returns/process/', data: data);
    return res.data;
  }
}

// ==========================================================================
// 2. PRINT SERVICE (Detailed Breakdown)
// ==========================================================================
class ReturnPrintService {
  static Future<void> printVoucher(Map<String, dynamic> billData, String actionType) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          List items = billData['items'] ?? [];
          return pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text("${actionType.toUpperCase()} VOUCHER",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                ),
                pw.Divider(thickness: 0.5),
                pw.Text("Invoice: ${billData['bill_no']}", style: pw.TextStyle(fontSize: 8)),
                pw.Text("Customer: ${billData['customer_name']}", style: pw.TextStyle(fontSize: 8)),
                pw.Text("Date: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}", style: pw.TextStyle(fontSize: 8)),
                pw.Divider(thickness: 0.5),

                pw.Row(children: [
                  pw.Expanded(flex: 5, child: pw.Text("ITEM", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 3, child: pw.Text("PRICE", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold))),
                ]),
                pw.Divider(thickness: 0.3),

                ...items.map((item) => pw.Row(children: [
                  pw.Expanded(flex: 5, child: pw.Text("${item['item_name']} (${item['barcode_number']})", style: pw.TextStyle(fontSize: 7))),
                  pw.Expanded(flex: 3, child: pw.Text("${item['rate']}", textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 7))),
                ])),

                pw.Divider(thickness: 0.5),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("UPDATED TOTAL:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      pw.Text("Rs. ${billData['total_amount']}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ]
                ),
                pw.SizedBox(height: 10),
                pw.Center(child: pw.Text("*** Thank You ***", style: pw.TextStyle(fontSize: 7))),
              ],
            ),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}

// ==========================================================================
// 3. BLOC
// ==========================================================================
abstract class ReturnEvent {}
class FetchInvoice extends ReturnEvent { final String invoiceNo; FetchInvoice(this.invoiceNo); }
class ExecuteAction extends ReturnEvent {
  final int itemId; final String type; final String? newBC;
  ExecuteAction(this.itemId, this.type, this.newBC);
}

abstract class ReturnState {}
class ReturnInitial extends ReturnState {}
class ReturnLoading extends ReturnState {}
class InvoiceLoaded extends ReturnState { final Map<String, dynamic> billData; InvoiceLoaded(this.billData); }
class ActionSuccess extends ReturnState { final String msg; final Map<String, dynamic> updatedData; ActionSuccess(this.msg, this.updatedData); }
class ReturnError extends ReturnState { final String error; ReturnError(this.error); }

class ReturnBloc extends Bloc<ReturnEvent, ReturnState> {
  final ReturnRepository repository;
  ReturnBloc(this.repository) : super(ReturnInitial()) {

    on<FetchInvoice>((event, emit) async {
      emit(ReturnLoading());
      try {
        final res = await repository.fetchBill(event.invoiceNo);
        if(res['status'] == 'success') {
          emit(InvoiceLoaded(res['data']));
        } else {
          emit(ReturnError(res['error'] ?? "Invoice not found"));
        }
      } catch (e) { emit(ReturnError("Connection Error")); }
    });

    on<ExecuteAction>((event, emit) async {
      emit(ReturnLoading());
      try {
        final payload = {"sale_item_id": event.itemId, "action_type": event.type, "new_barcode": event.newBC};
        final res = await repository.processAction(payload);
        if (res['status'] == 'success') {
          // ✅ Success hote hi updated data se print nikalo
          await ReturnPrintService.printVoucher(res['data'], event.type);
          emit(ActionSuccess(res['message'], res['data']));
          // Refresh table
          add(FetchInvoice(res['data']['bill_no']));
        } else {
          emit(ReturnError(res['error'] ?? "Action failed"));
        }
      } catch (e) { emit(ReturnError("Server Error during process")); }
    });
  }
}

// ==========================================================================
// 4. UI LAYER
// ==========================================================================
class ReturnExchangeScreen extends StatefulWidget {
  const ReturnExchangeScreen({super.key});
  @override State<ReturnExchangeScreen> createState() => _ReturnExchangeScreenState();
}

class _ReturnExchangeScreenState extends State<ReturnExchangeScreen> {
  final _invoiceCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReturnBloc(ReturnRepository()),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A252F),
          title: const Text("RETURN & EXCHANGE TERMINAL", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        body: BlocConsumer<ReturnBloc, ReturnState>(
          listener: (context, state) {
            if (state is ReturnError) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error), backgroundColor: Colors.red));
            }
            if (state is ActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.msg), backgroundColor: Colors.green));
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                _buildSearchSection(context),
                if (state is ReturnLoading) const LinearProgressIndicator(color: Colors.orange),
                if (state is InvoiceLoaded || state is ActionSuccess) ...[
                  _buildInvoiceInfo(state),
                  Expanded(child: _buildItemsTable(context, state)),
                  _buildFooter(state),
                ] else if (state is! ReturnLoading)
                  const Expanded(child: Center(child: Text("Invoice number enter karein...", style: TextStyle(color: Colors.grey)))),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _invoiceCtrl,
            decoration: InputDecoration(
              hintText: "INVOICE NUMBER SCAN",
              prefixIcon: const Icon(Icons.qr_code_scanner),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onSubmitted: (v) => context.read<ReturnBloc>().add(FetchInvoice(v.trim())),
          ),
        ),
        const SizedBox(width: 15),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade900, minimumSize: const Size(120, 55)),
          onPressed: () => context.read<ReturnBloc>().add(FetchInvoice(_invoiceCtrl.text.trim())),
          child: const Text("SEARCH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  Widget _buildInvoiceInfo(dynamic state) {
    final data = (state is InvoiceLoaded) ? state.billData : (state as ActionSuccess).updatedData;
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.blueGrey.shade50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _infoText("CUSTOMER", data['customer_name'] ?? "CASH"),
          _infoText("INV DATE", data['bill_date'].toString().split('T')[0]),
          _infoText("TOTAL AMT", "₹${data['total_amount']}"),
        ],
      ),
    );
  }

  Widget _infoText(String label, String val) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _buildItemsTable(BuildContext context, dynamic state) {
    final data = (state is InvoiceLoaded) ? state.billData : (state as ActionSuccess).updatedData;
    List items = data['items'] ?? [];

    return LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: constraints.maxWidth),
        child: DataTable(
          headingRowHeight: 40,
          headingRowColor: WidgetStateProperty.all(const Color(0xFF34495E)),
          columns: const [
            DataColumn(label: Text("ITEM", style: TextStyle(color: Colors.white))),
            DataColumn(label: Text("BARCODE", style: TextStyle(color: Colors.white))),
            DataColumn(label: Text("PRICE", style: TextStyle(color: Colors.white))),
            DataColumn(label: Text("ACTION", style: TextStyle(color: Colors.white))),
          ],
          rows: items.map((item) => DataRow(cells: [
            DataCell(Text(item['item_name'] ?? "N/A")),
            DataCell(Text(item['barcode_number'] ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text("₹${item['rate']}")),
            DataCell(Row(
              children: [
                IconButton(icon: const Icon(Icons.undo, color: Colors.red), onPressed: () => _confirmAction(context, item, 'return')),
                IconButton(icon: const Icon(Icons.sync, color: Colors.orange), onPressed: () => _confirmAction(context, item, 'exchange')),
              ],
            )),
          ])).toList(),
        ),
      ),
    ));
  }

  void _confirmAction(BuildContext context, Map item, String type) {
    final bcCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A252F),
        title: Text("${type.toUpperCase()} CONFIRMATION", style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Confirm ${type} for: ${item['item_name']}", style: const TextStyle(color: Colors.white70)),
            if (type == 'exchange') ...[
              const SizedBox(height: 15),
              TextField(
                controller: bcCtrl,
                style: const TextStyle(color: Colors.blueGrey),
                autofocus: true,
                decoration: const InputDecoration(hintText: "Scan New Item Barcode", border: OutlineInputBorder()),
              ),
            ]
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: type == 'return' ? Colors.red : Colors.orange),
            onPressed: () {
              context.read<ReturnBloc>().add(ExecuteAction(item['barcode'], type, bcCtrl.text));
              Navigator.pop(ctx);
            },
            child: const Text("PROCEED"),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(dynamic state) {
    final data = (state is InvoiceLoaded) ? state.billData : (state as ActionSuccess).updatedData;
    return Container(
      height: 100,
      color: const Color(0xFF1A252F),
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("ADJUSTED BILL TOTAL", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          Text("₹ ${data['total_amount']}", style: const TextStyle(color: Colors.yellowAccent, fontSize: 26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}