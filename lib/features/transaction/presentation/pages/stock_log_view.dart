import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../inventory/presentation/bloc/inventory_product_management_bloc.dart';
import '../../domain/entity/stock_log_entity.dart';
import '../bloc/stock_bloc.dart';


class StockLedgerView extends StatefulWidget {
  const StockLedgerView({super.key});
  @override
  State<StockLedgerView> createState() => _StockLedgerViewState();
}

class _StockLedgerViewState extends State<StockLedgerView> {
  @override
  void initState() {
    super.initState();
    context.read<StockBloc>().add(FetchStockLogs());
    context.read<InventoryProductBloc>().add(LoadProducts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Stock Audit Ledger", style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showWastageModal(context),
              icon: const Icon(Icons.remove_shopping_cart_rounded, size: 18),
              label: const Text("REPORT WASTAGE"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<StockBloc, StockState>(
        builder: (context, state) {
          if (state is StockLoading) return const Center(child: CircularProgressIndicator());
          if (state is StockLogsLoaded) {
            return _buildLedgerGrid(state.logs);
          }
          return const Center(child: Text("No Stock Logs Available."));
        },
      ),
    );
  }

  Widget _buildLedgerGrid(List<StockLogEntity> logs) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final bool isPositive = log.quantityChanged > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              _dateInfo(log.createdAt),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(log.note.isEmpty ? "No notes added" : log.note,
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              _typeBadge(log.transactionType),
              const SizedBox(width: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${isPositive ? '+' : ''}${log.quantityChanged}",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isPositive ? Colors.green : Colors.red
                    ),
                  ),
                  Text("Bal: ${log.balanceAfter}", style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWastageModal(BuildContext context) {
    int? selectedProd;
    final qtyController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.report_problem_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text("Stock Wastage Entry", style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Note: Reporting wastage will instantly deduct the current stock level.",
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 20),
              // 🛠️ FIXED DROPDOWN WITH TYPES
              BlocBuilder<InventoryProductBloc, ProductState>(
                builder: (context, state) {
                  final prods = state is ProductLoaded ? state.products : [];
                  return DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: "Product to Adjust", border: OutlineInputBorder()),
                    // 💡 Explicit types added here to fix red line
                    items: prods.map<DropdownMenuItem<int>>((p) => DropdownMenuItem<int>(
                        value: p.id,
                        child: Text(p.name)
                    )).toList(),
                    onChanged: (v) => selectedProd = v,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Wasted Quantity", border: OutlineInputBorder(), prefixIcon: Icon(Icons.numbers)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "Reason / Note", border: OutlineInputBorder(), hintText: "e.g. Broken packaging or Expired"),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (selectedProd != null && qtyController.text.isNotEmpty) {
                context.read<StockBloc>().add(CreateWastageEntry(WastageEntity(
                  productId: selectedProd!,
                  quantity: double.parse(qtyController.text),
                  reason: reasonController.text,
                )));
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            child: const Text("SUBMIT ADJUSTMENT", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _dateInfo(DateTime date) => Column(children: [
    Text("${date.day}/${date.month}", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
    Text("${date.hour}:${date.minute}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
  ]);

  Widget _typeBadge(String type) {
    Color c = type == 'PURCHASE' ? Colors.green : (type == 'SALE' ? Colors.blue : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(type, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }
}