import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_management/features/inventory/presentation/bloc/item_location_bloc.dart';
import 'package:stock_management/features/inventory/presentation/widget/inventory_group_subgroup_view.dart';
import 'package:stock_management/features/inventory/presentation/widget/location_view.dart';
import '../../../../../injection.dart';
import '../bloc/inventory_category.dart';
import '../bloc/inventory_group_subgroup_bloc.dart';
import 'package:stock_management/features/inventory/presentation/widget/item_category_view.dart';

import '../bloc/location_bloc.dart';
import '../widget/item_location_view.dart';

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
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 MultiBlocProvider at the TOP so all tabs can share data
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => sl<InventoryCategoryBloc>()),
        BlocProvider(create: (context) => sl<ProductGroupBloc>()),
        BlocProvider(create: (context) => sl<ProductSubGroupBloc>()),
        BlocProvider(create: (context) => sl<LocationBloc>()),
        BlocProvider(create: (context) => sl<ItemLocationBloc>()),
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
              Tab(child: _TabLabel(Icons.category_outlined, "Group Sub Group")),
              Tab(child: _TabLabel(Icons.category_outlined, "Manage Staff Location")),
              Tab(child: _TabLabel(Icons.warehouse_outlined, "Manage Item Location")),


            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            const CategoryView(),
            const InventoryGroupSubgroupView(),
            const LocationView(),
            const ItemLocationView(),

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