/*

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
}*/

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

  String _userName = "User";
  String _userRole = "staff";
  bool _isReady = false;
  String? _expandedGroup; // Tracking which menu is open

  @override
  void initState() {
    super.initState();
    _initializeRole();
  }

  Future<void> _initializeRole() async {
    final role = await storage.read(key: 'user_role') ?? "staff";
    final name = await storage.read(key: 'username') ?? "Admin";
    if (mounted) {
      setState(() {
        _userRole = role.toLowerCase();
        _userName = name;
        _isReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;
        final bool isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;

        return Scaffold(
          appBar: _buildAppBar(isMobile),
          drawer: isMobile ? Drawer(child: _buildSidebarContent(true)) : null,
          body: Row(
            children: [
              if (!isMobile)
                Container(
                  width: isTablet ? 80 : 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: _buildSidebarContent(!isTablet),
                ),
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
    );
  }

  // --- SIDEBAR CONTENT (Common for Rail & Drawer) ---
  Widget _buildSidebarContent(bool isExtended) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            children: [
              _buildNavItem(Icons.dashboard_outlined, "Dashboard", "/dashboard", isExtended),

              // --- STOCK MANAGEMENT SECTION ---
              _buildGroupMenu(
                icon: Icons.inventory_2_outlined,
                label: "Stock Management",
                isExtended: isExtended,
                children: [
                  _buildSubItem("Inventory", "/inventory"),
                  _buildSubItem("Stock Plus", "/stock_plus"),
                  _buildSubItem("Sales Bill", "/sales_bill"),
                  _buildSubItem("Return Exchange", "/return"),
                ],
              ),

              // --- ACCOUNTING SECTION ---
              _buildGroupMenu(
                icon: Icons.account_balance_wallet_outlined,
                label: "Accounting",
                isExtended: isExtended,
                children: [
                  _buildSubItem("Customer Master", "/customer_master"),
                  _buildSubItem("Supplier Master", "/supplier_master"),
                  _buildSubItem("Ledger Creation", "/ledger"),
                  _buildSubItem("My Reports", "/my_reports"),
                ],
              ),

              if (_userRole != 'staff')
                _buildNavItem(Icons.people_outline, "Manage Users", "/manage_user", isExtended),
            ],
          ),
        ),
        _buildLogoutButton(isExtended),
      ],
    );
  }

  // Helper for Single Items
  Widget _buildNavItem(IconData icon, String label, String path, bool isExtended) {
    final bool isSelected = GoRouterState.of(context).uri.path == path;
    return ListTile(
      leading: Icon(icon, color: isSelected ? cyanPrimary : Colors.grey),
      title: isExtended ? Text(label, style: TextStyle(color: isSelected ? cyanPrimary : darkGrey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)) : null,
      selected: isSelected,
      onTap: () => context.go(path),
    );
  }

  // Helper for Group/Nested Menus
  Widget _buildGroupMenu({required IconData icon, required String label, required bool isExtended, required List<Widget> children}) {
    if (!isExtended) {
      return IconButton(
        icon: Icon(icon, color: darkGrey),
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label))),
      );
    }

    return ExpansionTile(
      key: PageStorageKey(label),
      initiallyExpanded: _expandedGroup == label,
      onExpansionChanged: (val) => setState(() => _expandedGroup = val ? label : null),
      leading: Icon(icon, color: darkGrey),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkGrey)),
      children: children,
    );
  }

  // Helper for Sub-menu Items
  Widget _buildSubItem(String label, String path) {
    final bool isSelected = GoRouterState.of(context).uri.path == path;
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 55),
      visualDensity: VisualDensity.compact,
      title: Text(label, style: TextStyle(fontSize: 13, color: isSelected ? cyanPrimary : Colors.black54)),
      onTap: () => context.go(path),
    );
  }

  // --- APPBAR & OTHERS ---
  PreferredSizeWidget _buildAppBar(bool isMobile) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: Text(isMobile ? "POS" : "BUSINESS MANAGEMENT", style: const TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontSize: 16)),
      iconTheme: const IconThemeData(color: darkGrey),
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_userName, style: const TextStyle(color: darkGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(_userRole.toUpperCase(), style: const TextStyle(color: cyanPrimary, fontSize: 9)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(bool isExtended) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.redAccent),
      title: isExtended ? const Text("Sign Out", style: TextStyle(color: Colors.redAccent)) : null,
      onTap: () async {
        await storage.deleteAll();
        if (mounted) context.go('/login');
      },
    );
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

  String _userName = "User";
  String _userRole = "staff";
  String _initials = "U";
  bool _isReady = false;
  String? _expandedGroup;

  bool showStockManagement = false;
  bool showAccounting = true;
  bool showReports = true;
  bool showTransaction = true;


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
      if (mounted) setState(() => _isReady = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return const Scaffold(body: Center(child: CircularProgressIndicator(color: cyanPrimary)));

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;
        final bool isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;

        return Scaffold(
          appBar: _buildProfessionalAppBar(isMobile),
          drawer: isMobile ? Drawer(child: _buildSidebarContent(true)) : null,
          body: Row(
            children: [
              if (!isMobile)
                Container(
                  width: isTablet ? 80 : 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: _buildSidebarContent(!isTablet),
                ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: Container(color: const Color(0xFFF8FAFB), child: widget.child)),
            ],
          ),
        );
      },
    );
  }

  // --- APPBAR (VERSION 1) ---
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
                Text(_userName, style: const TextStyle(color: darkGrey, fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: cyanPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(_userRole.toUpperCase(), style: const TextStyle(color: cyanPrimary, fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          const SizedBox(width: 12),
          CircleAvatar(radius: isMobile ? 18 : 22, backgroundColor: darkGrey, child: Text(_initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  // --- SIDEBAR WITH VISIBILITY LOGIC ---
  Widget _buildSidebarContent(bool isExtended) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            children: [
              _buildNavItem(Icons.dashboard_outlined, "Dashboard", "/dashboard", isExtended),

              // 1. STOCK MANAGEMENT (Visible False by default)
              if (showStockManagement)
                _buildGroupMenu(
                  icon: Icons.inventory_2_outlined,
                  label: "Stock Management",
                  isExtended: isExtended,
                  children: [
                    _buildSubItem("Inventory", "/inventory"),
                    _buildSubItem("Stock Plus", "/stock_plus"),
                    _buildSubItem("Sales Bill", "/sales_bill"),
                    _buildSubItem("Return Exchange", "/return"),
                  ],
                ),

              // 2. ACCOUNTING (Visible True)
              if (showAccounting)
                _buildGroupMenu(
                  icon: Icons.account_balance_wallet_outlined,
                  label: "Account Master",
                  isExtended: isExtended,
                  children: [
                    _buildSubItem("Customer Master", "/customer_master"),
                    _buildSubItem("Supplier Master", "/supplier_master"),
                    _buildSubItem("Unit Master", "/uom_master"),
                    _buildSubItem("Ledger", "/ledger_screen"),
                  ],
                ),

              if (showTransaction)
                _buildGroupMenu(
                  icon: Icons.add_card_sharp,
                  label: "Transactions",
                  isExtended: isExtended,
                  children: [
                    _buildSubItem("Sales", "/sales_transaction"),
                    _buildSubItem("Purchase", "/purchase_transaction"),
                    _buildSubItem("Cash", "/cash_transaction"),
                    _buildSubItem("Journal Entry", "/journal_entry"),
                  ],
                ),

              // 3. REPORTS SECTION (Naya Alag Rail Group)
              if (showReports)
                _buildGroupMenu(
                  icon: Icons.assessment_outlined,
                  label: "Reports Center",
                  isExtended: isExtended,
                  children: [
                    _buildSubItem("Sales Reports", "/sales_ledger_report"),
                    _buildSubItem("Purchase Reports", "/purchase_ledger_report"),
                    _buildSubItem("Journal Report", "/ledger_summary"),
                  ],
                ),

              if (_userRole != 'staff')
                _buildNavItem(Icons.people_alt_outlined, "Manage Users", "/manage_user", isExtended),
            ],
          ),
        ),
        _buildLogoutButton(isExtended),
      ],
    );
  }

  // --- UI HELPERS ---
  Widget _buildGroupMenu({
    required IconData icon,
    required String label,
    required bool isExtended,
    required List<Widget> children
  }) {
    final bool hasActiveChild = children.any((child) {
      if (child is ListTile && child.onTap != null) {
        return false;
      }
      return false;
    });

    if (!isExtended) {
      return IconButton(
        // Icon color logic
        icon: Icon(icon, color: _expandedGroup == label ? cyanPrimary : Colors.grey),
        onPressed: () => setState(() => _expandedGroup = _expandedGroup == label ? null : label),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: _expandedGroup == label,
        onExpansionChanged: (val) => setState(() => _expandedGroup = val ? label : null),
        leading: Icon(icon, color: _expandedGroup == label ? cyanPrimary : darkGrey),
        title: Text(label, style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _expandedGroup == label ? cyanPrimary : darkGrey
        )),
        children: children,
      ),
    );
  }
  Widget _buildSubItem(String label, String path) {
    // CURRENT PATH CHECK KARNE KE LIYE
    final bool isSelected = GoRouterState.of(context).uri.path == path;

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 55),
      visualDensity: VisualDensity.compact,
      // TEXT COLOR CHANGE
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: isSelected ? cyanPrimary : Colors.black54, // Highlight if selected
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? cyanPrimary.withOpacity(0.05) : Colors.transparent,
      onTap: () => context.go(path),
    );
  }
  Widget _buildNavItem(IconData icon, String label, String path, bool isExtended) {
    final bool isSelected = GoRouterState.of(context).uri.path == path;
    return ListTile(
      leading: Icon(icon, color: isSelected ? cyanPrimary : Colors.grey),
      title: isExtended ? Text(label, style: TextStyle(color: isSelected ? cyanPrimary : darkGrey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)) : null,
      onTap: () => context.go(path),
    );
  }

  Widget _buildLogoutButton(bool isExtended) {
    return ListTile(
      leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
      title: isExtended ? const Text("Sign out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)) : null,
      onTap: () async {
        await storage.deleteAll();
        if (mounted) context.go('/login');
      },
    );
  }
}