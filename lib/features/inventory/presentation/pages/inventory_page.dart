import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../injection.dart';

// Blocs Import
import '../bloc/inventory_category.dart';
import '../bloc/inventory_brand_block.dart';
import '../bloc/inventory_product_management_bloc.dart';
// Note: Make sure you have a Wastage Bloc too

// Views Import
import 'package:stock_management/features/inventory/presentation/widget/item_category_view.dart';
import 'package:stock_management/features/inventory/presentation/widget/inventory_units_view.dart';
import 'package:stock_management/features/inventory/presentation/widget/inventory_brand_view.dart';
import 'package:stock_management/features/inventory/presentation/widget/tax_profile_view.dart';
import 'package:stock_management/features/inventory/presentation/widget/inventory_product_view.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color cyanPrimary = Color(0xFF00BCD4);
  static const Color darkGrey = Color(0xFF1A1C24);
  static const Color surfaceGrey = Color(0xFFF4F7F9);

  @override
  void initState() {
    super.initState();
    // Total 6 Tabs: Category, Units, Brand, Tax, Product, Wastage
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 MultiBlocProvider at the TOP so all tabs can share data
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<InventoryCategoryBloc>()),
        BlocProvider(create: (context) => sl<InventoryUnitBloc>()),
        BlocProvider(create: (context) => sl<InventoryBrandBloc>()),
        BlocProvider(create: (context) => sl<TaxProfileBloc>()),
        BlocProvider(create: (context) => sl<InventoryProductBloc>()),
        // BlocProvider(create: (context) => sl<WastageBloc>()), // Add this when ready
      ],
      child: Scaffold(
        backgroundColor: surfaceGrey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 90,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Inventory Management & Control",
                  style: TextStyle(color: darkGrey, fontWeight: FontWeight.w900, fontSize: 24)),
              Text("Manage your inventory digital blueprint",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13, letterSpacing: 0.5)),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelPadding: const EdgeInsets.symmetric(horizontal: 40),
            indicatorColor: cyanPrimary,
            indicatorWeight: 4,
            labelColor: cyanPrimary,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: const [
              Tab(child: _TabLabel(Icons.category_outlined, "Manage Category")),
              Tab(child: _TabLabel(Icons.straighten_rounded, "Manage Units")),
              Tab(child: _TabLabel(Icons.branding_watermark_outlined, "Manage Brand")),
              Tab(child: _TabLabel(Icons.receipt_long_rounded, "Tax Profile")),
              Tab(child: _TabLabel(Icons.inventory_2_outlined, "Manage Product")),
              Tab(child: _TabLabel(Icons.delete_sweep_outlined, "Manage Wastage")),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            const CategoryView(),     // Tab 1
            const UnitView(),         // Tab 2
            const BrandView(),        // Tab 3
            const TaxProfileView(),   // Tab 4
            const ProductManagementView(), // Tab 5 (Now has access to all Blocs!)

            // Tab 6: Wastage (Abhi ke liye placeholder)
            Container(
              color: Colors.white,
              child: const Center(child: Text("Wastage Tracking Coming Soon",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TabLabel(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 10),
        Text(text),
      ],
    );
  }
}