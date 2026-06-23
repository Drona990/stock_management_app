import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../injection.dart';
import '../../../transaction/presentation/pages/dc_invoice_pdf_generator.dart';
import '../../../transaction/presentation/pages/purchase_order_transaction_page.dart';

class PurchaseOrderHistoryPage extends StatefulWidget {
  const PurchaseOrderHistoryPage({super.key});

  @override
  State<PurchaseOrderHistoryPage> createState() => _PurchaseOrderHistoryPageState();
}

class _PurchaseOrderHistoryPageState extends State<PurchaseOrderHistoryPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color industrialSlate = Color(0xFF1E293B);
    bool isMobile = MediaQuery.of(context).size.width < 650;

    return BlocProvider<PurchaseOrderBloc>(
      create: (_) => PurchaseOrderBloc(sl<PurchaseOrderRepository>())..add(LoadPoHistoryEvent()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          elevation: 0, backgroundColor: Colors.white, toolbarHeight: 52,
          iconTheme: const IconThemeData(color: industrialSlate, size: 18),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("PURCHASE ORDERS LOGS DIRECTORY", style: TextStyle(color: industrialSlate, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
              Text("PROCUREMENT COMMITTED TRACK REVERSALS AUDIT TRAIL DATA REPOSITORY", style: TextStyle(color: Colors.grey.shade500, fontSize: 7.5, fontWeight: FontWeight.bold))
            ],
          ),
          shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        body: Builder(
            builder: (context) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10), color: Colors.white,
                    child: Container(
                      height: 35, decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: Colors.grey.shade200)),
                      child: TextField(
                        controller: _searchCtrl, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        onChanged: (v) => context.read<PurchaseOrderBloc>().add(LoadPoHistoryEvent(query: v.trim())),
                        decoration: const InputDecoration(hintText: "SEARCH LOGS BY SERIAL PO NO, SUPPLIER OR MATERIAL PARTICULARS...", hintStyle: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold), prefixIcon: Icon(Icons.search_rounded, size: 14, color: Colors.blueGrey), border: InputBorder.none, contentPadding: EdgeInsets.only(bottom: 12)),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(child: _buildHistoryCardsList(isMobile)),
                ],
              );
            }
        ),
      ),
    );
  }

  Widget _buildHistoryCardsList(bool isMobile) {
    return BlocBuilder<PurchaseOrderBloc, PurchaseOrderState>(
      builder: (context, state) {
        if (state is PoCounterLoaded) return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4), strokeWidth: 1.5));
        if (state is PoHistoryLoadedState) {
          final list = state.poList;
          if (list.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text("Zero operational purchase orders found.", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))));

          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, idx) {
              final item = list[idx];
              String poNoSequence = item['po_bill_no']?.toString() ?? 'N/A';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        left: const BorderSide(color: Color(0xFF047857), width: 4.5),
                        top: BorderSide(color: Colors.grey.shade200), bottom: BorderSide(color: Colors.grey.shade200), right: BorderSide(color: Colors.grey.shade200)
                    )
                ),
                child: isMobile
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: const Color(0xFF047857).withOpacity(0.08)), child: const Text("PO VOUCHER", style: TextStyle(color: Color(0xFF047857), fontSize: 6.5, fontWeight: FontWeight.bold))),
                    Text("₹ ${double.tryParse(item['grand_totamt']?.toString() ?? '0')?.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))
                  ]),
                  const SizedBox(height: 4),
                  Text(item['name']?.toString().toUpperCase() ?? '', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Wrap(spacing: 4, runSpacing: 2, children: [
                    _infoLabel("SERIAL NO", poNoSequence, active: true), _bullet(),
                    _infoLabel("DOC ID", item['billno'] ?? ''), _bullet(),
                    _infoLabel("DATE", item['billdate'] ?? ''),
                  ]),
                  const SizedBox(height: 6),
                  Align(alignment: Alignment.bottomRight, child: _buildReprintButton(item)),
                ])
                    : Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(item['name']?.toString().toUpperCase() ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: const Color(0xFF047857).withOpacity(0.08)), child: const Text("PO VOUCHER", style: TextStyle(color: Color(0xFF047857), fontSize: 6.5, fontWeight: FontWeight.bold))),
                    ]),
                    const SizedBox(height: 5),
                    Row(children: [
                      _infoLabel("SERIAL NO", poNoSequence, active: true), _bullet(),
                      _infoLabel("DOC ID", item['billno'] ?? ''), _bullet(),
                      _infoLabel("PLACEMENT DATE", item['billdate'] ?? ''),
                    ])
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text("₹ ${double.tryParse(item['grand_totamt']?.toString() ?? '0')?.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    Text("${double.tryParse(item['total_pcs']?.toString() ?? '0')?.toStringAsFixed(0)} PCS ORDERED", style: const TextStyle(fontSize: 7.5, color: Colors.grey))
                  ]),
                  const SizedBox(width: 16),
                  _buildReprintButton(item)
                ]),
              );
            },
          );
        }
        if (state is PoFailure) {
          return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("Error: ${state.errorMsg}", style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold))));
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildReprintButton(Map<String, dynamic> item) {
    return InkWell(
      onTap: () async {
        try {
          final ByteData rawLogo = await rootBundle.load('assets/images/ultra_logo.jpeg');
          final pw.ImageProvider logoImage = pw.MemoryImage(rawLogo.buffer.asUint8List());
          final pdfDoc = await InvoiceDCPdfService.generate(logoImage: logoImage, data: item, terminalMode: "PO", headings: ["DUPLICATE DETAILED PO REPRINT"]);
          await Printing.layoutPdf(onLayout: (format) async => pdfDoc.save(), name: 'DUPLICATE_PO_${item['billno']}.pdf');
        } catch (_) {}
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), border: Border.all(color: Colors.grey.shade300)),
        child: const Row(children: [Icon(Icons.print_rounded, color: Color(0xFF475569), size: 11), SizedBox(width: 4), Text("REPRINT PO", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF475569)))]),
      ),
    );
  }

  Widget _infoLabel(String l, String v, {bool active = false}) => Text("$l: ${v.toUpperCase()}", style: TextStyle(fontSize: 8.5, color: active ? const Color(0xFF16A085) : Colors.grey.shade600, fontWeight: active ? FontWeight.w900 : FontWeight.bold));
  Widget _bullet() => const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Text("•", style: TextStyle(fontSize: 9, color: Colors.grey)));
}