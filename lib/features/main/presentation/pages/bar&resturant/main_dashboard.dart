/*


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // ✅ Added for BlocListener
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../auth/presentation/block/login_bloc.dart';

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

  // ✅ This function refreshes everything from storage
  Future<void> _initializeRole() async {
    try {
      final role = await storage.read(key: 'user_role') ?? "staff";
      final name = await storage.read(key: 'username') ?? "User";

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

  // ==========================================================================
  // 🧭 FILTERED DESTINATIONS (Role-Based)
  // ==========================================================================
  List<NavigationRailDestination> _getFilteredDestinations() {
    if (_userRole == 'staff') {
      return [
        const NavigationRailDestination(
          icon: Icon(Icons.add_circle_outline),
          selectedIcon: Icon(Icons.add_circle_outline, color: cyanPrimary),
          label: Text("Sales Bill"),
        ),
        // ✅ Staff can now see "Return Exchange" as requested
        const NavigationRailDestination(
          icon: Icon(Icons.assignment_return_outlined),
          selectedIcon: Icon(Icons.assignment_return, color: cyanPrimary),
          label: Text("Return Exchange"),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.assessment_outlined),
          selectedIcon: Icon(Icons.assessment, color: cyanPrimary),
          label: Text("My Reports"),
        ),
      ];
    }

    // Admin/Superuser destinations
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
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2, color: cyanPrimary),
        label: Text("Inventory"),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.add_card_outlined),
        selectedIcon: Icon(Icons.add_card, color: cyanPrimary),
        label: Text("Stock Plus"),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.add_circle_outline),
        selectedIcon: Icon(Icons.add_circle_outline, color: cyanPrimary),
        label: Text("Sales Bill"),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.assignment_return),
        selectedIcon: Icon(Icons.assignment_return, color: cyanPrimary),
        label: Text("Return Exchange"),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.assessment_outlined),
        selectedIcon: Icon(Icons.assessment, color: cyanPrimary),
        label: Text("My Reports"),
      ),
    ];
  }

  // ==========================================================================
  // 🎯 DYNAMIC SELECTION LOGIC
  // ==========================================================================
  int _getSelectedIndex(List<NavigationRailDestination> destinations) {
    try {
      final String location = GoRouterState.of(context).uri.path;

      if (location.contains('manage_user')) return _findLabelIndex(destinations, 'Manage Users');
      if (location.contains('inventory')) return _findLabelIndex(destinations, 'Inventory');
      if (location.contains('stock_plus')) return _findLabelIndex(destinations, 'Stock Plus');
      if (location.contains('sales_bill')) return _findLabelIndex(destinations, 'Sales Bill');
      if (location.contains('return')) return _findLabelIndex(destinations, 'Return Exchange');
      if (location.contains('my_reports')) return _findLabelIndex(destinations, 'My Reports');
      if (location.contains('dashboard')) return _findLabelIndex(destinations, 'Dashboard');
    } catch (e) {
      return 0;
    }
    return 0;
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

    // ✅ BlocListener wrap kiya taaki Master Dashboard refresh ho sake
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          debugPrint("🔄 Identity Changed: Refreshing Master Dashboard...");
          _initializeRole();
        }
      },
      child: Scaffold(
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
      case 'Return Exchange': context.go('/return'); break;
      case 'My Reports': context.go('/my_reports'); break;
    }
  }

  // --- UI COMPONENTS ---

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
*/

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../auth/presentation/block/login_bloc.dart';

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
      final name = await storage.read(key: 'username') ?? "User";

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

  // --- NAVIGATION CONFIGURATION ---

  List<Map<String, dynamic>> _getNavItems() {
    if (_userRole == 'staff') {
      return [
        {'label': 'Sales Bill', 'icon': Icons.add_circle_outline, 'activeIcon': Icons.add_circle},
        {'label': 'Return Exchange', 'icon': Icons.assignment_return_outlined, 'activeIcon': Icons.assignment_return},
        {'label': 'My Reports', 'icon': Icons.assessment_outlined, 'activeIcon': Icons.assessment},
      ];
    }
    return [
      {'label': 'Dashboard', 'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard},
      {'label': 'Manage Users', 'icon': Icons.person_add_alt_1_rounded, 'activeIcon': Icons.person_add_alt_1_rounded},
      {'label': 'Inventory', 'icon': Icons.inventory_2_outlined, 'activeIcon': Icons.inventory_2},
      {'label': 'Stock Plus', 'icon': Icons.add_card_outlined, 'activeIcon': Icons.add_card},
      {'label': 'Sales Bill', 'icon': Icons.add_circle_outline, 'activeIcon': Icons.add_circle},
      {'label': 'Return Exchange', 'icon': Icons.assignment_return_outlined, 'activeIcon': Icons.assignment_return},
      {'label': 'My Reports', 'icon': Icons.assessment_outlined, 'activeIcon': Icons.assessment},
    ];
  }

  int _getSelectedIndex(List<Map<String, dynamic>> items) {
    try {
      final String location = GoRouterState.of(context).uri.path;
      if (location.contains('manage_user')) return _findLabelIndex(items, 'Manage Users');
      if (location.contains('inventory')) return _findLabelIndex(items, 'Inventory');
      if (location.contains('stock_plus')) return _findLabelIndex(items, 'Stock Plus');
      if (location.contains('sales_bill')) return _findLabelIndex(items, 'Sales Bill');
      if (location.contains('return')) return _findLabelIndex(items, 'Return Exchange');
      if (location.contains('my_reports')) return _findLabelIndex(items, 'My Reports');
      if (location.contains('dashboard')) return _findLabelIndex(items, 'Dashboard');
    } catch (e) {
      return 0;
    }
    return 0;
  }

  int _findLabelIndex(List<Map<String, dynamic>> items, String label) {
    final index = items.indexWhere((element) => element['label'] == label);
    return index != -1 ? index : 0;
  }

  void _onNavigate(String label) {
    switch (label) {
      case 'Dashboard': context.go('/dashboard'); break;
      case 'Manage Users': context.go('/manage_user'); break;
      case 'Inventory': context.go('/inventory'); break;
      case 'Stock Plus': context.go('/stock_plus'); break;
      case 'Sales Bill': context.go('/sales_bill'); break;
      case 'Return Exchange': context.go('/return'); break;
      case 'My Reports': context.go('/my_reports'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: cyanPrimary)),
      );
    }

    final navItems = _getNavItems();
    final int selectedIndex = _getSelectedIndex(navItems);

    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          _initializeRole();
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;
          final bool isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;

          return Scaffold(
            appBar: _buildProfessionalAppBar(isMobile),
            drawer: isMobile ? _buildMobileDrawer(navItems, selectedIndex) : null,
            bottomNavigationBar: isMobile
                ? _buildBottomBar(navItems, selectedIndex)
                : null,
            body: Row(
              children: [
                if (!isMobile)
                  NavigationRail(
                    backgroundColor: Colors.white,
                    indicatorColor: cyanPrimary.withOpacity(0.1),
                    extended: !isTablet,
                    minExtendedWidth: 200,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) => _onNavigate(navItems[index]['label']),
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _buildRailTrailing(!isTablet),
                      ),
                    ),
                    destinations: navItems.map((item) => NavigationRailDestination(
                      icon: Icon(item['icon']),
                      selectedIcon: Icon(item['activeIcon'], color: cyanPrimary),
                      label: Text(item['label']),
                    )).toList(),
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
        },
      ),
    );
  }

  // --- UI COMPONENTS ---

  PreferredSizeWidget _buildProfessionalAppBar(bool isMobile) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      toolbarHeight: isMobile ? 60 : 80,
      iconTheme: const IconThemeData(color: darkGrey),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isMobile ? "BUSINESS" : "BUSINESS DASHBOARD",
              style: const TextStyle(color: darkGrey, fontWeight: FontWeight.w900, fontSize: 18)),
          if (!isMobile)
            Text(DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
      actions: [_buildUserIdentity(isMobile)],
    );
  }

  Widget _buildUserIdentity(bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(right: isMobile ? 12 : 24),
      child: Row(
        children: [
          if (!isMobile)
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
              radius: isMobile ? 18 : 22,
              backgroundColor: darkGrey,
              child: Text(_initials,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildBottomBar(List<Map<String, dynamic>> items, int selectedIndex) {
    // Safety: Only show max 4 items in bottom bar to avoid clutter
    final int displayCount = items.length > 4 ? 4 : items.length;
    final displayItems = items.take(displayCount).toList();

    return BottomNavigationBar(
      currentIndex: selectedIndex >= displayCount ? 0 : selectedIndex,
      selectedItemColor: cyanPrimary,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontSize: 11),
      onTap: (index) => _onNavigate(displayItems[index]['label']),
      items: displayItems.map((item) => BottomNavigationBarItem(
        icon: Icon(item['icon']),
        activeIcon: Icon(item['activeIcon']),
        label: item['label'],
      )).toList(),
    );
  }

  Widget _buildMobileDrawer(List<Map<String, dynamic>> items, int selectedIndex) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: darkGrey),
            currentAccountPicture: CircleAvatar(
              backgroundColor: cyanPrimary,
              child: Text(_initials, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            accountName: Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(_userRole.toUpperCase(), style: const TextStyle(color: cyanPrimary, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final bool isSelected = selectedIndex == index;
                return ListTile(
                  leading: Icon(item['icon'], color: isSelected ? cyanPrimary : Colors.grey),
                  title: Text(item['label'],
                      style: TextStyle(
                          color: isSelected ? cyanPrimary : darkGrey,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                      )
                  ),
                  selected: isSelected,
                  onTap: () {
                    Navigator.pop(context);
                    _onNavigate(item['label']);
                  },
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text("Sign out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () => _logout(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRailTrailing(bool isExtended) {
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await storage.deleteAll();
    if (mounted) context.go('/login');
  }
}