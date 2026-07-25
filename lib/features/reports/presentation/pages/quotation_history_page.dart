import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../injection.dart';
import '../../../transaction/presentation/pages/quotation_page.dart';
import '../../../transaction/presentation/pages/quotation_pdf_generator.dart';

class QuotationHistoryPage extends StatefulWidget {
  const QuotationHistoryPage({super.key});

  @override
  State<QuotationHistoryPage> createState() => _QuotationHistoryPageState();
}

class _QuotationHistoryPageState extends State<QuotationHistoryPage> {
  final _searchCtrl = TextEditingController();

  String _selectedPartyFilter = 'ALL';

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'ACCEPTED':
      case 'COMPLETED':
        return const Color(0xFF10B981); // Emerald Green
      case 'REJECTED':
      case 'CANCELLED':
        return const Color(0xFFEF4444); // Crimson Red
      case 'EXPIRED':
        return const Color(0xFF6B7280); // Slate Gray
      case 'PENDING':
      default:
        return const Color(0xFFF59E0B); // Amber Yellow
    }
  }

  String formatLiveDateTime(String? rawTimeStamp) {
    if (rawTimeStamp == null || rawTimeStamp.isEmpty) return "—";
    try {
      DateTime parsed = DateTime.parse(rawTimeStamp).toLocal();
      return DateFormat('dd-MM-yyyy  hh:mm a').format(parsed);
    } catch (e) {
      return rawTimeStamp;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color industrialSlate = Color(0xFF1E293B);
    bool isMobile = MediaQuery.of(context).size.width < 650;

    return BlocProvider<QuotationBloc>(
      create: (_) => QuotationBloc(sl<QuotationRepository>())..add(LoadQuotationHistoryEvent()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          toolbarHeight: 52,
          iconTheme: const IconThemeData(color: industrialSlate, size: 18),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  "QUOTATION LOGS DIRECTORY",
                  style: TextStyle(color: industrialSlate, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.3)
              ),
              Text(
                  "COMMERCIAL QUOTATIONS TRACK REVERSALS AUDIT TRAIL REPOSITORY",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 7.5, fontWeight: FontWeight.bold)
              )
            ],
          ),
          shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        body: Builder(
            builder: (context) {
              return Column(
                children: [
                  // 🟢 TOP FILTER BAR WITH SEARCH & PARTY TYPE SWITCH TOGGLES
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.white,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 35,
                                decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    border: Border.all(color: Colors.grey.shade200)
                                ),
                                child: TextField(
                                  controller: _searchCtrl,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                  onChanged: (v) => context.read<QuotationBloc>().add(LoadQuotationHistoryEvent(query: v.trim())),
                                  decoration: const InputDecoration(
                                      hintText: "SEARCH LOGS BY SERIAL QT NO, CLIENT OR PRODUCT PARTICULARS...",
                                      hintStyle: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                                      prefixIcon: Icon(Icons.search_rounded, size: 14, color: Colors.blueGrey),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.only(bottom: 12)
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // 🌟 SWITCH / TOGGLE BUTTON BAR (ALL | SUPPLIERS | CUSTOMERS)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "FILTER BY PARTY: $_selectedPartyFilter",
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                            ),
                            SizedBox(
                              height: 28,
                              child: ToggleButtons(
                                isSelected: [
                                  _selectedPartyFilter == 'ALL',
                                  _selectedPartyFilter == 'SUPPLIER',
                                  _selectedPartyFilter == 'CUSTOMER',
                                ],
                                onPressed: (index) {
                                  setState(() {
                                    if (index == 0) _selectedPartyFilter = 'ALL';
                                    if (index == 1) _selectedPartyFilter = 'SUPPLIER';
                                    if (index == 2) _selectedPartyFilter = 'CUSTOMER';
                                  });
                                },
                                borderRadius: BorderRadius.circular(4),
                                selectedColor: Colors.white,
                                fillColor: _selectedPartyFilter == 'SUPPLIER'
                                    ? Colors.deepOrange
                                    : (_selectedPartyFilter == 'CUSTOMER' ? Colors.blue : const Color(0xFF1E293B)),
                                color: Colors.black87,
                                constraints: const BoxConstraints(minWidth: 70, minHeight: 28),
                                children: const [
                                  Text("ALL", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                  Text("SUPPLIERS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                  Text("CUSTOMERS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
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
    return BlocBuilder<QuotationBloc, QuotationState>(
      builder: (context, state) {
        if (state is QuotationLoading || state is QuotationPreloadingCounter) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0F4C81), strokeWidth: 1.5));
        }

        if (state is QuotationHistoryLoadedState) {
          final rawList = state.quotationList;

          final list = rawList.where((item) {
            if (_selectedPartyFilter == 'ALL') return true;

            String partyType = (item['party_type'] ?? '').toString().toUpperCase();
            if (partyType.isNotEmpty) {
              return partyType == _selectedPartyFilter;
            }

            if (_selectedPartyFilter == 'SUPPLIER') return item['supplier'] != null;
            if (_selectedPartyFilter == 'CUSTOMER') return item['customer'] != null;
            return true;
          }).toList();

          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Zero operational quotations found for filter '$_selectedPartyFilter'.",
                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, idx) {
              final item = list[idx];
              String quotationNoSequence = item['quotation_bill_no']?.toString() ?? 'N/A';
              String currentStatus = item['status']?.toString().toUpperCase() ?? 'PENDING';
              Color statusColor = _getStatusColor(currentStatus);

              // Extract Party Tag Details for visual indicator
              String partyTypeTag = (item['party_type'] ?? (item['customer'] != null ? 'CUSTOMER' : 'SUPPLIER')).toString().toUpperCase();

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        left: BorderSide(color: statusColor, width: 4.5),
                        top: BorderSide(color: Colors.grey.shade200),
                        bottom: BorderSide(color: Colors.grey.shade200),
                        right: BorderSide(color: Colors.grey.shade200)
                    )
                ),
                child: isMobile
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(
                      children: [
                        Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.08)),
                            child: Text(currentStatus, style: TextStyle(color: statusColor, fontSize: 6.5, fontWeight: FontWeight.bold, letterSpacing: 0.3))
                        ),
                        const SizedBox(width: 6),
                        Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(color: partyTypeTag == 'SUPPLIER' ? Colors.deepOrange.shade50 : Colors.blue.shade50),
                            child: Text(partyTypeTag, style: TextStyle(color: partyTypeTag == 'SUPPLIER' ? Colors.deepOrange : Colors.blue, fontSize: 6.5, fontWeight: FontWeight.bold))
                        ),
                      ],
                    ),
                    Text("₹ ${double.tryParse(item['grand_totamt']?.toString() ?? '0')?.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))
                  ]),
                  const SizedBox(height: 4),
                  Text(item['name']?.toString().toUpperCase() ?? '', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Wrap(spacing: 4, runSpacing: 2, children: [
                    _infoLabel("SERIAL NO", quotationNoSequence, active: true), _bullet(),
                    _infoLabel("REF NO", item['billno'] ?? ''), _bullet(),
                    _infoLabel("DATE", item['billdate'] ?? ''),
                  ]),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusDropdownButton(context, item['id'], currentStatus, statusColor),
                      _buildReprintButton(item)
                    ],
                  ),
                ])
                    : Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(item['name']?.toString().toUpperCase() ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                      const SizedBox(width: 8),
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.08)),
                          child: Text(currentStatus, style: TextStyle(color: statusColor, fontSize: 6.5, fontWeight: FontWeight.bold, letterSpacing: 0.2))
                      ),
                      const SizedBox(width: 6),
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: partyTypeTag == 'SUPPLIER' ? Colors.deepOrange.shade50 : Colors.blue.shade50),
                          child: Text(partyTypeTag, style: TextStyle(color: partyTypeTag == 'SUPPLIER' ? Colors.deepOrange : Colors.blue, fontSize: 6.5, fontWeight: FontWeight.bold))
                      ),
                    ]),
                    const SizedBox(height: 5),
                    Row(children: [
                      _infoLabel("SERIAL NO", quotationNoSequence, active: true), _bullet(),
                      _infoLabel("REF NO", item['billno'] ?? ''), _bullet(),
                      _infoLabel("QUOTATION DATE", item['billdate'] ?? ''),
                    ])
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text("₹ ${double.tryParse(item['grand_totamt']?.toString() ?? '0')?.toStringAsFixed(2)}", style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    Text("${double.tryParse(item['total_pcs']?.toString() ?? '0')?.toStringAsFixed(0)} PCS QUOTED", style: const TextStyle(fontSize: 7.5, color: Colors.grey))
                  ]),
                  const SizedBox(width: 16),
                  _buildStatusDropdownButton(context, item['id'], currentStatus, statusColor),
                  const SizedBox(width: 8),
                  _buildReprintButton(item)
                ]),
              );
            },
          );
        }

        if (state is QuotationFailure) {
          return Center(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text("Error: ${state.errorMsg}", style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold))
              )
          );
        }
        return const SizedBox();
      },
    );
  }

  // Dynamic Quotation Status Action Controller Dropdown Button
  Widget _buildStatusDropdownButton(BuildContext context, dynamic quotationId, String currentStatus, Color statusColor) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: statusColor.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentStatus,
          icon: Icon(Icons.arrow_drop_down_rounded, size: 14, color: statusColor),
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: statusColor),
          onChanged: (String? nextStatus) {
            if (nextStatus != null && nextStatus != currentStatus) {
              context.read<QuotationBloc>().add(
                  UpdateQuotationStatusEvent(quotationId: quotationId, status: nextStatus)
              );
            }
          },
          items: <String>['PENDING', 'APPROVED', 'REJECTED', 'EXPIRED']
              .map<DropdownMenuItem<String>>((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(
                val,
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: _getStatusColor(val)),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReprintButton(Map<String, dynamic> item) {
    return InkWell(
      onTap: () async {
        try {
          final ByteData rawLogo = await rootBundle.load('assets/images/ultra_logo.jpeg');
          final pw.ImageProvider logoImage = pw.MemoryImage(rawLogo.buffer.asUint8List());

          final pdfDoc = await InvoiceQuotationPdfService.generate(
              logoImage: logoImage,
              data: item,
              terminalMode: "QUOTATION",
              headings: ["DUPLICATE QUOTATION REPRINT"]
          );

          await Printing.layoutPdf(
              onLayout: (format) async => pdfDoc.save(),
              name: 'DUPLICATE_QT_${item['billno']}.pdf'
          );
        } catch (_) {}
      },
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), border: Border.all(color: Colors.grey.shade300)),
        child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.print_rounded, color: Color(0xFF475569), size: 11),
              SizedBox(width: 4),
              Text("REPRINT QT", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF475569)))
            ]
        ),
      ),
    );
  }

  Widget _infoLabel(String l, String v, {bool active = false}) => Text(
      "$l: ${v.toUpperCase()}",
      style: TextStyle(fontSize: 8.5, color: active ? const Color(0xFF0F4C81) : Colors.grey.shade600, fontWeight: active ? FontWeight.w900 : FontWeight.bold)
  );

  Widget _bullet() => const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text("•", style: TextStyle(fontSize: 9, color: Colors.grey))
  );
}