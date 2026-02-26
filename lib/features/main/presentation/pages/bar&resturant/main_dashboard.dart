/*
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MainDashboard extends StatefulWidget {
  final Widget child;
  const MainDashboard({super.key, required this.child});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  static const Color cyanPrimary = Color(0xFF00BCD4);
  static const Color darkGrey = Color(0xFF1A1C24);
  final storage = const FlutterSecureStorage();

  String _userName = "Loading...";
  String _userRole = "Staff";
  String _initials = "U";
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initializeRole();
  }

  Future<void> _initializeRole() async {
    final role = await storage.read(key: 'user_role') ?? "staff";
    final name = await storage.read(key: 'name') ?? "User";

    if (mounted) {
      setState(() {
        _userRole = role.toLowerCase().trim();
        _userName = name;
        _initials = name.isNotEmpty ? name[0].toUpperCase() : "U";
        _isReady = true;
      });
    }
  }

  // ✅ Role-Based Filtered Items
  List<NavigationRailDestination> _getFilteredDestinations() {
    List<NavigationRailDestination> items = [
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard, color: cyanPrimary),
        label: Text('Dashboard'),
      ),
    ];

    // Check for privileged roles
    if (['superuser', 'admin', 'manager'].contains(_userRole)) {
      items.addAll([
        const NavigationRailDestination(
          icon: Icon(Icons.data_exploration_sharp),
          selectedIcon: Icon(Icons.data_exploration_sharp, color: cyanPrimary),
          label: Text("Stock Dashboard"),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.person_add_alt_1_rounded),
          selectedIcon: Icon(Icons.person_add_alt_1_rounded, color: cyanPrimary),
          label: Text("Manage Users"),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.inventory_2),
          selectedIcon: Icon(Icons.inventory_2, color: cyanPrimary),
          label: Text("Inventory"),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.person),
          selectedIcon: Icon(Icons.person, color: cyanPrimary),
          label: Text("Supplier"),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.add_box),
          selectedIcon: Icon(Icons.add_box, color: cyanPrimary),
          label: Text("Purchase Master"),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.production_quantity_limits),
          selectedIcon: Icon(Icons.production_quantity_limits, color: cyanPrimary),
          label: Text("Sales Master"), // Fixed plural
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.add_card),
          selectedIcon: Icon(Icons.add_card, color: cyanPrimary),
          label: Text("Stock Ledger"),
        ),
      ]);
    }

    return items;
  }

  // ✅ Index Finder logic - Matches current URL to the Rail index
  int _getSelectedIndex(List<NavigationRailDestination> destinations) {
    final String location = GoRouterState.of(context).uri.path;

    if (location.contains('manage_user')) return _findLabelIndex(destinations, 'Manage Users');
    if (location.contains('inventory')) return _findLabelIndex(destinations, 'Inventory');
    if (location.contains('transaction')) return _findLabelIndex(destinations, 'Supplier');
    if (location.contains('purchase')) return _findLabelIndex(destinations, 'Purchase Master');
    if (location.contains('sale')) return _findLabelIndex(destinations, 'Sales Master');
    if (location.contains('stock-dashboard')) return _findLabelIndex(destinations, 'Stock Dashboard');
    if (location.contains('stock-ledger')) return _findLabelIndex(destinations, 'Stock Ledger');

    return 0; // Default to Dashboard
  }

  int _findLabelIndex(List<NavigationRailDestination> destinations, String label) {
    for (int i = 0; i < destinations.length; i++) {
      if ((destinations[i].label as Text).data == label) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: cyanPrimary)));
    }

    final destinations = _getFilteredDestinations();
    final int selectedIndex = _getSelectedIndex(destinations);
    final bool isExtended = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: _buildProfessionalAppBar(context),
      body: Row(
        children: [
          LayoutBuilder(
            builder: (context, constraint) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraint.maxHeight),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      backgroundColor: Colors.white,
                      indicatorColor: cyanPrimary.withOpacity(0.1),
                      extended: isExtended,
                      minExtendedWidth: 200,
                      selectedIndex: selectedIndex >= destinations.length ? 0 : selectedIndex,
                      onDestinationSelected: (int index) {
                        _onItemTapped(index, context, destinations);
                      },
                      leading: _buildLeading(isExtended),
                      trailing: Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _buildTrailing(isExtended, context),
                        ),
                      ),
                      destinations: destinations,
                    ),
                  ),
                ),
              );
            },
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFB),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index, BuildContext context, List<NavigationRailDestination> currentItems) {
    final String label = (currentItems[index].label as Text).data!;
    switch (label) {
      case 'Dashboard': context.go('/dashboard'); break;
      case 'Manage Users': context.go('/manage_user'); break;
      case 'Inventory': context.go('/inventory'); break;
      case 'Supplier': context.go('/transaction'); break;
      case 'Purchase Master': context.go('/purchase'); break;
      case 'Sales Master': context.go('/sale'); break;
      case 'Stock Dashboard': context.go('/stock-dashboard'); break;
      case 'Stock Ledger': context.go('/stock-ledger'); break;
    }
  }

  Widget _buildLeading(bool isExtended) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.restaurant_menu, color: cyanPrimary, size: 36),
        if (isExtended) ...[
          const SizedBox(height: 10),
          const Text("SVENSKA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkGrey)),
        ],
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildTrailing(bool isExtended, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () => _logout(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isExtended ? 16 : 8, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
              if (isExtended) ...[
                const SizedBox(width: 12),
                const Text("Sign out", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.redAccent)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildProfessionalAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      toolbarHeight: 80,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SVENSKA RESTAURANT", style: TextStyle(color: darkGrey, fontWeight: FontWeight.w900, fontSize: 18)),
          Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()), style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
      actions: [_buildUserIdentity()],
    );
  }

  Widget _buildUserIdentity() {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_userName, style: const TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: cyanPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(_userRole.toUpperCase(), style: const TextStyle(color: cyanPrimary, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(width: 12),
          CircleAvatar(radius: 22, backgroundColor: darkGrey, child: Text(_initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await storage.deleteAll();
    if (mounted) context.go('/login');
  }
}*//*

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MainDashboard extends StatefulWidget {
  final Widget child;
  const MainDashboard({super.key, required this.child});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  static const Color cyanPrimary = Color(0xFF00BCD4);
  static const Color darkGrey = Color(0xFF1A1C24);
  final storage = const FlutterSecureStorage();

  String _userName = "Loading...";
  String _userRole = "staff";
  String _initials = "U";
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initializeRole();
  }

  Future<void> _initializeRole() async {
    try {
      final role = await storage.read(key: 'user_role') ?? "staff";
      final name = await storage.read(key: 'name') ?? "User";

      if (mounted) {
        setState(() {
          _userRole = role.toLowerCase().trim();
          _userName = name;
          _initials = name.isNotEmpty ? name[0].toUpperCase() : "U";
          _isReady = true;
        });
      }
    } catch (e) {
      debugPrint("Storage Error: $e");
      if (mounted) setState(() => _isReady = true);
    }
  }

  List<NavigationRailDestination> _getFilteredDestinations() {
    List<NavigationRailDestination> items = [
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard, color: cyanPrimary),
        label: Text('Dashboard'),
      ),
    ];

    if (['superuser', 'admin', 'manager'].contains(_userRole)) {
      items.addAll([

        const NavigationRailDestination(
          icon: Icon(Icons.person_add_alt_1_rounded),
          selectedIcon: Icon(Icons.person_add_alt_1_rounded, color: cyanPrimary),
          label: Text("Manage Users"),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.inventory_2),
          selectedIcon: Icon(Icons.inventory_2, color: cyanPrimary),
          label: Text("Inventory"),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.add_card),
          selectedIcon: Icon(Icons.add_card, color: cyanPrimary),
          label: Text("Stock Plus"),
        ),

        const NavigationRailDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle_outline, color: cyanPrimary),
          label: Text("Sales Bill"),
        ),


      ]);
    }
    return items;
  }

  int _getSelectedIndex(List<NavigationRailDestination> destinations) {
    // We use the full URI to match routes safely
    final String location = GoRouterState.of(context).uri.path;

    if (location.contains('manage_user')) return _findLabelIndex(destinations, 'Manage Users');
    if (location.contains('inventory')) return _findLabelIndex(destinations, 'Inventory');
    if (location.contains('stock-plus')) return _findLabelIndex(destinations, 'Stock Plus');
    if (location.contains('sales-bill')) return _findLabelIndex(destinations, 'Sales Bill');
    if (location.contains('stock-dashboard')) return _findLabelIndex(destinations, 'Stock Dashboard');

    return 0; // Default to Dashboard index
  }

  int _findLabelIndex(List<NavigationRailDestination> destinations, String label) {
    for (int i = 0; i < destinations.length; i++) {
      if ((destinations[i].label as Text).data == label) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Prevents black screen by returning a themed Scaffold during loading
    if (!_isReady) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: cyanPrimary)),
      );
    }

    final destinations = _getFilteredDestinations();
    final int selectedIndex = _getSelectedIndex(destinations);
    final bool isExtended = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: _buildProfessionalAppBar(context),
      body: Row(
        children: [
          // Simplified Rail: Fixed the "Expanded" and "IntrinsicHeight" crash
          NavigationRail(
            backgroundColor: Colors.white,
            indicatorColor: cyanPrimary.withOpacity(0.1),
            extended: isExtended,
            minExtendedWidth: 200,
            // Safety check: ensure index doesn't exceed list length
            selectedIndex: selectedIndex >= destinations.length ? 0 : selectedIndex,
            onDestinationSelected: (int index) => _onItemTapped(index, context, destinations),
            trailing: _buildTrailing(isExtended, context),
            destinations: destinations,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFB),
              // Use a Key for the child to help GoRouter maintain state
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index, BuildContext context, List<NavigationRailDestination> currentItems) {
    final String label = (currentItems[index].label as Text).data!;
    switch (label) {
      case 'Dashboard': context.go('/dashboard'); break;
      case 'Manage Users': context.go('/manage_user'); break;
      case 'Inventory': context.go('/inventory'); break;
      case 'Stock Plus': context.go('/stock_plus'); break;
      case 'Sales Bill': context.go('/sales_bill'); break;
    }
  }

  Widget _buildLeading(bool isExtended) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.restaurant_menu, color: cyanPrimary, size: 36),
        if (isExtended) ...[
          const SizedBox(height: 10),
          const Text("SVENSKA",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkGrey)),
        ],
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildTrailing(bool isExtended, BuildContext context) {
    // Removed the "Expanded" and "Align" inside the Rail's trailing
    // to prevent the LayoutBuilder crash.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: IconButton(
        onPressed: () => _logout(context),
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        tooltip: isExtended ? null : "Sign out",
      ),
    );
  }

  PreferredSizeWidget _buildProfessionalAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      toolbarHeight: 80,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("BUSINESS DASHBOARD",
              style: TextStyle(color: darkGrey, fontWeight: FontWeight.w900, fontSize: 18)),
          Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
      actions: [_buildUserIdentity()],
    );
  }

  Widget _buildUserIdentity() {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_userName,
                  style: const TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: cyanPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(_userRole.toUpperCase(),
                    style: const TextStyle(color: cyanPrimary, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(width: 12),
          CircleAvatar(
              radius: 22,
              backgroundColor: darkGrey,
              child: Text(_initials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await storage.deleteAll();
    if (mounted) context.go('/login');
  }
}*/


import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MainDashboard extends StatefulWidget {
  final Widget child;
  const MainDashboard({super.key, required this.child});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  static const Color cyanPrimary = Color(0xFF00BCD4);
  static const Color darkGrey = Color(0xFF1A1C24);
  final storage = const FlutterSecureStorage();

  String _userName = "Loading...";
  String _userRole = "staff";
  String _initials = "U";
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _initializeRole();
  }

  Future<void> _initializeRole() async {
    try {
      final role = await storage.read(key: 'user_role') ?? "staff";
      final name = await storage.read(key: 'name') ?? "User";

      if (mounted) {
        setState(() {
          _userRole = role.toLowerCase().trim();
          _userName = name;
          _initials = name.isNotEmpty ? name[0].toUpperCase() : "U";
          _isReady = true;
        });
      }
    } catch (e) {
      debugPrint("Storage Error: $e");
      if (mounted) setState(() => _isReady = true);
    }
  }

  List<NavigationRailDestination> _getFilteredDestinations() {
    if (_userRole == 'staff') {
      return [
        const NavigationRailDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle_outline, color: cyanPrimary),
          label: Text("Sales Bill"),
        ),
      ];
    }

    // 2. Otherwise (Admin/Manager/Superuser), they get full access
    return [
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard, color: cyanPrimary),
        label: Text('Dashboard'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.person_add_alt_1_rounded),
        selectedIcon: Icon(Icons.person_add_alt_1_rounded, color: cyanPrimary),
        label: Text("Manage Users"),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.inventory_2),
        selectedIcon: Icon(Icons.inventory_2, color: cyanPrimary),
        label: Text("Inventory"),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.add_card),
        selectedIcon: Icon(Icons.add_card, color: cyanPrimary),
        label: Text("Stock Plus"),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.add_circle_outline),
        selectedIcon: Icon(Icons.add_circle_outline, color: cyanPrimary),
        label: Text("Sales Bill"),
      ),
    ];
  }

  int _getSelectedIndex(List<NavigationRailDestination> destinations) {
    final String location = GoRouterState.of(context).uri.path;

    // Staff only has one option, so index is always 0
    if (_userRole == 'staff') return 0;

    if (location.contains('manage_user')) return _findLabelIndex(destinations, 'Manage Users');
    if (location.contains('inventory')) return _findLabelIndex(destinations, 'Inventory');
    if (location.contains('stock_plus')) return _findLabelIndex(destinations, 'Stock Plus');
    if (location.contains('sales_bill')) return _findLabelIndex(destinations, 'Sales Bill');

    return 0; // Default to Dashboard for Admin
  }

  int _findLabelIndex(List<NavigationRailDestination> destinations, String label) {
    for (int i = 0; i < destinations.length; i++) {
      if ((destinations[i].label as Text).data == label) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: cyanPrimary)),
      );
    }

    final destinations = _getFilteredDestinations();
    final int selectedIndex = _getSelectedIndex(destinations);
    final bool isExtended = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: _buildProfessionalAppBar(context),
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: Colors.white,
            indicatorColor: cyanPrimary.withOpacity(0.1),
            extended: isExtended,
            minExtendedWidth: 200,
            selectedIndex: selectedIndex >= destinations.length ? 0 : selectedIndex,
            onDestinationSelected: (int index) => _onItemTapped(index, context, destinations),
            leading: _buildLeading(isExtended),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _buildTrailing(isExtended, context),
              ),
            ),
            destinations: destinations,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFB),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index, BuildContext context, List<NavigationRailDestination> currentItems) {
    final String label = (currentItems[index].label as Text).data!;
    switch (label) {
      case 'Dashboard': context.go('/dashboard'); break;
      case 'Manage Users': context.go('/manage_user'); break;
      case 'Inventory': context.go('/inventory'); break;
      case 'Stock Plus': context.go('/stock_plus'); break;
      case 'Sales Bill': context.go('/sales_bill'); break;
    }
  }

  Widget _buildLeading(bool isExtended) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.restaurant_menu, color: cyanPrimary, size: 36),
        if (isExtended) ...[
          const SizedBox(height: 10),
          const Text("SVENSKA",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkGrey)),
        ],
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildTrailing(bool isExtended, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () => _logout(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isExtended ? 16 : 8, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
              if (isExtended) ...[
                const SizedBox(width: 12),
                const Text("Sign out",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.redAccent)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildProfessionalAppBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      toolbarHeight: 80,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("BUSINESS DASHBOARD",
              style: TextStyle(color: darkGrey, fontWeight: FontWeight.w900, fontSize: 18)),
          Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
      actions: [_buildUserIdentity()],
    );
  }

  Widget _buildUserIdentity() {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_userName,
                  style: const TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: cyanPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(_userRole.toUpperCase(),
                    style: const TextStyle(color: cyanPrimary, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(width: 12),
          CircleAvatar(
              radius: 22,
              backgroundColor: darkGrey,
              child: Text(_initials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await storage.deleteAll();
    if (mounted) context.go('/login');
  }
}