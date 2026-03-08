import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

class PerformanceModal {
  static void show(BuildContext context, int initialMonth, List months, List locs) {
    int selMonth = initialMonth;
    int? selLoc;
    String selectedPeriod = 'monthly';

    void fetch(BuildContext ctx) async {
      showDialog(context: ctx, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
      try {
        final res = await sl<ApiClient>().get('/api/inventory/dashboard/staff_performance_report/',
            query: {
              'period': selectedPeriod,
              'month': selMonth.toString(),
              'location': selLoc?.toString() ?? ''
            });

        if (ctx.mounted) Navigator.of(ctx, rootNavigator: true).pop();
        _showUI(ctx, res.data, selMonth, selectedPeriod, months, locs, selLoc, (m, p, l) {
          selMonth = m; selectedPeriod = p; selLoc = l; fetch(ctx);
        });
      } catch (e) {
        if (ctx.mounted) Navigator.of(ctx, rootNavigator: true).pop();
      }
    }
    fetch(context);
  }

  static void _showUI(BuildContext context, Map<String, dynamic> data, int month, String period, List months, List locs, int? loc, Function(int, String, int?) onRefresh) {
    List report = data['report'] ?? [];
    var best = data['best_performer'];
    String query = "";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (context, setS) {
        List filtered = report.where((s) => (s['full_name'] ?? s['username'] ?? "").toString().toLowerCase().contains(query.toLowerCase())).toList();

        return Dialog.fullscreen(
          child: Scaffold(
            backgroundColor: const Color(0xFFF1F5F9), // ✅ Industrial Grey Background
            appBar: AppBar(
              elevation: 0,
              backgroundColor: const Color(0xFF0F172A),
              title: const Text("PERFORMANCE ANALYTICS", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(backgroundColor: Colors.red.shade900, foregroundColor: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text("EXIT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                // --- FIXED TOP CONTROLS ---
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _periodTab(ctx, "DAILY", period == "daily", () => onRefresh(month, "daily", loc)),
                            _periodTab(ctx, "MONTHLY", period == "monthly", () => onRefresh(month, "monthly", loc)),
                            _periodTab(ctx, "OVERALL", period == "overall", () => onRefresh(month, "overall", loc)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: _compactSearch((v) => setS(() => query = v))),
                            const SizedBox(width: 8),
                            if (period == "monthly")
                              Expanded(flex: 2, child: _compactDrop<int>(month, months, (v) { Navigator.pop(ctx); onRefresh(v!, period, loc); })),
                            const SizedBox(width: 8),
                            Expanded(flex: 2, child: _compactLocDrop(loc, locs, (v) { Navigator.pop(ctx); onRefresh(month, period, v); })),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // --- SCROLLABLE CONTENT AREA ---
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (best != null && query.isEmpty) _buildHeroCard(best, period),

                        // --- 🏆 THE CONTAINED TABLE CARD ---
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: DataTable(
                                headingRowHeight: 50,
                                dataRowHeight: 60,
                                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                columnSpacing: 15,
                                columns: const [
                                  DataColumn(label: Text("RANK", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text("REPRESENTATIVE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF64748B)))),
                                  DataColumn(label: Text("REVENUE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF64748B)))),
                                ],
                                rows: filtered.asMap().entries.map((e) {
                                  final index = e.key;
                                  final s = e.value;
                                  return DataRow(
                                    color: WidgetStateProperty.resolveWith<Color?>((states) => index.isEven ? Colors.transparent : const Color(0xFFF1F5F9).withOpacity(0.3)),
                                    cells: [
                                      DataCell(_rankBadge(index + 1)),
                                      DataCell(Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(s['full_name'] ?? s['username'] ?? "-", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B))),
                                          Text("Inv: ${s['total_invoices']}", style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
                                        ],
                                      )),
                                      DataCell(Text("₹${s['revenue']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 13))),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // --- COMPONENT HELPERS ---

  static Widget _periodTab(BuildContext ctx, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { Navigator.pop(ctx); onTap(); },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: active ? Colors.white : Colors.blueGrey)),
      ),
    );
  }

  static Widget _buildHeroCard(dynamic best, String period) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF334155)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Color(0xFFFACC15), size: 45),
          const SizedBox(width: 20),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${period.toUpperCase()} TOP STAR", style: const TextStyle(color: Color(0xFFFACC15), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              Text(best['full_name'] ?? best['username'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text("Performance: ₹${best['revenue']}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ))
        ],
      ),
    );
  }

  static Widget _rankBadge(int rank) {
    Color color = rank == 1 ? Colors.amber : (rank == 2 ? Colors.blueGrey : (rank == 3 ? Colors.brown : Colors.grey.shade400));
    return CircleAvatar(radius: 12, backgroundColor: color.withOpacity(0.1), child: Text("$rank", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: rank <= 3 ? color : Colors.grey)));
  }

  static Widget _compactSearch(Function(String) onChanged) => SizedBox(height: 38, child: TextField(
    onChanged: onChanged, style: const TextStyle(fontSize: 12),
    decoration: InputDecoration(hintText: "Search staff...", prefixIcon: const Icon(Icons.search, size: 16), filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))), contentPadding: EdgeInsets.zero),
  ));

  static Widget _compactDrop<T>(T val, List items, Function(T?) onChange) => SizedBox(height: 38, child: DropdownButtonFormField<T>(
    value: val, style: const TextStyle(fontSize: 12, color: Colors.black),
    items: items.map((m) => DropdownMenuItem<T>(value: m['id'] as T, child: Text(m['name'], style: const TextStyle(fontSize: 12)))).toList(),
    onChanged: onChange, decoration: _inputDeco("Month"),
  ));

  static Widget _compactLocDrop(int? val, List items, Function(int?) onChange) => SizedBox(height: 38, child: DropdownButtonFormField<int?>(
    value: val, style: const TextStyle(fontSize: 12, color: Colors.black),
    items: [const DropdownMenuItem(value: null, child: Text("All Branch", style: TextStyle(fontSize: 12))), ...items.map((l) => DropdownMenuItem(value: l['id'] as int, child: Text(l['name'], style: const TextStyle(fontSize: 12))))],
    onChanged: onChange, decoration: _inputDeco("Branch"),
  ));

  static InputDecoration _inputDeco(String l) => InputDecoration(filled: true, fillColor: const Color(0xFFF8FAFC), hintText: l, contentPadding: const EdgeInsets.symmetric(horizontal: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))));
}