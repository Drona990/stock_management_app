
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/utils/websocket/websocket_service.dart';
import '../../../../../injection.dart';

class MainDashboard extends StatefulWidget {
  final Widget child;
  const MainDashboard({super.key, required this.child});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> with SingleTickerProviderStateMixin {
  static const Color cyanPrimary = Color(0xFF00BCD4);
  static const Color darkSlateBg = Color(0xFF1E293B);
  static const Color sidebarHoverColor = Color(0xFF334155);
  static const Color textMuted = Color(0xFF94A3B8);

  final storage = const FlutterSecureStorage();

  String _userName = "User";
  String _userRole = "staff";
  String _initials = "U";
  bool _isReady = false;

  final Map<String, bool> _expandedGroups = {
    "Account Master": false,
    "Transactions": false,
    "Reports Center": false,
  };

  bool _isSidebarManualCollapsed = false;

  @override
  void initState() {
    super.initState();
    _initializeRoleAndSockets();
  }

  Future<void> _initializeRoleAndSockets() async {
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

        // 🌟 REAL-TIME CENTRAL CONNECTION TRIGGER:
        // Layout build hote hi framework frame validation ke baad socket open karega
        WidgetsBinding.instance.addPostFrameCallback((_) {
          sl<WebSocketService>().initCentralGateway();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isReady = true);
    }
  }

  @override
  void dispose() {
    // 🌟 CLEANUP: User agar is layout scope se baahar jaye toh gateway channel safely close ho
    sl<WebSocketService>().closeGateway();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        backgroundColor: darkSlateBg,
        body: Center(child: CircularProgressIndicator(color: cyanPrimary, strokeWidth: 2)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;
        final bool isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;

        final bool shouldCollapseSidebar = _isSidebarManualCollapsed || isTablet;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFB),
          appBar: _buildProfessionalAppBar(isMobile, shouldCollapseSidebar),
          drawer: isMobile ? Drawer(child: _buildSidebarContent(false, isMobile)) : null,
          body: Row(
            children: [
              if (!isMobile)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: shouldCollapseSidebar ? 64 : 240, // Strict ERP compact width metrics
                  color: darkSlateBg,
                  child: _buildSidebarContent(shouldCollapseSidebar, isMobile),
                ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        child: widget.child,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================================
  // 🏢 PROFESSIONAL HIGH-DENSITY APPBAR
  // ==========================================================================
  PreferredSizeWidget _buildProfessionalAppBar(bool isMobile, bool isCollapsed) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      toolbarHeight: 56, // Symmetrical compact ERP standard height
      iconTheme: const IconThemeData(color: darkSlateBg, size: 18),
      leading: isMobile
          ? null
          : IconButton(
        icon: Icon(isCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded, color: darkSlateBg),
        onPressed: () => setState(() => _isSidebarManualCollapsed = !_isSidebarManualCollapsed),
      ),
      titleSpacing: isMobile ? 0 : 8,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMobile ? "ENGINE MODULE" : "COMMERCIAL ENTERPRISE PLATFORM ENGINE",
            style: const TextStyle(color: darkSlateBg, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()).toUpperCase(),
            style: TextStyle(color: Colors.grey.shade500, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.3),
          ),
        ],
      ),
      actions: [_buildUserIdentity(isMobile)],
      shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
    );
  }

  Widget _buildUserIdentity(bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(right: isMobile ? 12 : 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMobile) ...[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_userName.toUpperCase(), style: const TextStyle(color: darkSlateBg, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.2)),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: cyanPrimary.withOpacity(0.12), borderRadius: BorderRadius.circular(3)),
                  child: Text(_userRole.toUpperCase(), style: const TextStyle(color: cyanPrimary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ],
            ),
            const SizedBox(width: 10),
          ],
          CircleAvatar(
            radius: 16,
            backgroundColor: darkSlateBg,
            child: Text(_initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 🧭 SIDEBAR NAVIGATION ARCHITECTURE
  // ==========================================================================
  Widget _buildSidebarContent(bool isCollapsed, bool isMobile) {
    return Column(
      children: [
        if (!isMobile && !isCollapsed) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            alignment: Alignment.centerLeft,
            child: const Row(
              children: [
                Icon(Icons.widgets_outlined, size: 16, color: cyanPrimary),
                SizedBox(width: 10),
                Text("NAVIGATION MATRIX", style: TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              ],
            ),
          ),
        ] else if (isCollapsed) ...[
          const SizedBox(height: 16),
        ],

        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            physics: const ClampingScrollPhysics(),
            children: [
              _buildRawNavItem(Icons.analytics_outlined, "Dashboard", "/dashboard", isCollapsed),
              const SizedBox(height: 4),

              // 1. ACCOUNTING SUB-SYSTEM
              _buildCompactGroupMenu(
                icon: Icons.account_balance_wallet_outlined,
                label: "Account Master",
                isCollapsed: isCollapsed,
                children: [
                  {"title": "Customer Master", "route": "/customer_master"},
                  {"title": "Supplier Master", "route": "/supplier_master"},
                  {"title": "Unit Master", "route": "/uom_master"},
                  {"title": "Ledger Master", "route": "/ledger_screen"},
                ],
              ),

              const SizedBox(height: 4),

              _buildCompactGroupMenu(
                icon: Icons.assignment_outlined,
                label: "Delivery Challan",
                isCollapsed: isCollapsed,
                children: [
                  {"title": "Delivery Challan", "route": "/dc_terminal"},
                  {"title": "DC History", "route": "/dc_summary"},
                ],
              ),

              const SizedBox(height: 4),

              _buildCompactGroupMenu(
                icon: Icons.assignment_outlined,
                label: "Salse",
                isCollapsed: isCollapsed,
                children: [
                  {"title": "Sales Invoice", "route": "/sales_transaction"},
                  {"title": "Sales Reports", "route": "/sales_ledger_report"},
                ],
              ),
              _buildCompactGroupMenu(
                icon: Icons.assignment_outlined,
                label: "Purchase",
                isCollapsed: isCollapsed,
                children: [
                  {"title": "Purchase Order", "route": "/purchase_order"},
                  {"title": "Purchase Voucher", "route": "/purchase_transaction"},
                  {"title": "Purchase Reports", "route": "/purchase_ledger_report"},
                ],
              ),

              const SizedBox(height: 4),
              _buildCompactGroupMenu(
                icon: Icons.assignment_outlined,
                label: "Transactions",
                isCollapsed: isCollapsed,
                children: [
                  {"title": "Adjustment & Return", "route": "/adjustment_return"},
                  {"title": "Cash Book", "route": "/cash_transaction"},
                  {"title": "Journal Entry", "route": "/journal_entry"},
                ],
              ),
              const SizedBox(height: 4),
              _buildCompactGroupMenu(
                icon: Icons.assignment_outlined,
                label: "Job Work",
                isCollapsed: isCollapsed,
                children: [
                  {"title": "Material Type Master", "route": "/material_type_master"},
                  {"title": "Material Master", "route": "/material_master"},
                  {"title": "BOM Entry","route":"/bom_entry"},
                  {"title": "BOM Project Config","route":"/project_bom"},
                  {"title": "BOM History", "route": "/bom_history"},
                ],
              ),
              const SizedBox(height: 4),

              // 3. INDUSTRIAL REPORT LOGISTICS
              _buildCompactGroupMenu(
                icon: Icons.assessment_outlined,
                label: "Reports Center",
                isCollapsed: isCollapsed,
                children: [
                  {"title": "Journal Summary", "route": "/ledger_summary"},
                  {"title": "Debit / Credit Note History", "route": "/financial_note_summary"},
                ],
              ),
              const SizedBox(height: 4),

              if (_userRole == 'superuser') ...[
                _buildCompactGroupMenu(
                  icon: Icons.manage_accounts_outlined,
                  label: "Manage Users",
                  isCollapsed: isCollapsed,
                  children: [
                    {"title": "User Details", "route": "/manage_user"},
                    {"title": "Manage Session", "route": "/manage_session"},
                  ],
                ),
              ],
/*
              if (_userRole == 'superuser') ...[
                _buildCompactGroupMenu(
                  icon: Icons.manage_accounts_outlined,
                  label: "Manage Users",
                  isCollapsed: isCollapsed,
                  children: [
                    {"title": "User Details", "route": "/manage_user"},
                    {"title": "Manage Session", "route": "/manage_session"},
                  ],
                ),
                _buildRawNavItem(Icons.manage_accounts_outlined, "Manage Users", "/manage_user", isCollapsed),
              ],
*/

            ],
          ),
        ),

        // Bottom Control Bar
        Container(
          padding: const EdgeInsets.all(8),
          color: const Color(0xFF0F172A), // Darker accent footer cap
          child: _buildLogoutButton(isCollapsed),
        ),
      ],
    );
  }

  // ==========================================================================
  // ⚡ CORE INTERFACE HELPER GENERATORS
  // ==========================================================================

  Widget _buildCompactGroupMenu({
    required IconData icon,
    required String label,
    required bool isCollapsed,
    required List<Map<String, String>> children,
  }) {
    final currentPath = GoRouterState.of(context).uri.path;
    final bool hasActiveChild = children.any((element) => element["route"] == currentPath);
    final bool isGroupOpen = _expandedGroups[label] ?? false;

    // 🏮 MINI SIDEBAR STATE: Hover/Click Popover Dropdown Controller Matrix
    if (isCollapsed) {
      return PopupMenuButton<String>(
        tooltip: label,
        offset: const Offset(50, 0),
        style: IconButton.styleFrom(
          backgroundColor: hasActiveChild ? cyanPrimary.withOpacity(0.12) : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onSelected: (route) => context.go(route),
        icon: Icon(icon, size: 18, color: hasActiveChild ? cyanPrimary : textMuted),
        itemBuilder: (BuildContext context) {
          return children.map((item) {
            final bool isSubSelected = item["route"] == currentPath;
            return PopupMenuItem<String>(
              value: item["route"],
              height: 34,
              child: Text(
                item["title"]!,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSubSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSubSelected ? cyanPrimary : darkSlateBg
                ),
              ),
            );
          }).toList();
        },
      );
    }

    // 💻 EXTENDED SIDEBAR STATE: Animated Collapsible Tree Layout
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _expandedGroups[label] = !isGroupOpen),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: hasActiveChild ? Colors.white.withOpacity(0.04) : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: hasActiveChild ? cyanPrimary : textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      label,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: hasActiveChild ? Colors.white : const Color(0xFFCBD5E1), letterSpacing: 0.2)
                  ),
                ),
                Icon(
                  isGroupOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: textMuted,
                ),
              ],
            ),
          ),
        ),

        // Smooth architectural child lists rollout
        if (isGroupOpen)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: Column(
              children: children.map((item) {
                final bool isSubSelected = item["route"] == currentPath;
                return InkWell(
                  onTap: () => context.go(item["route"]!),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    margin: const EdgeInsets.only(left: 14, top: 2, bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: isSubSelected ? cyanPrimary : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSubSelected ? Colors.white : textMuted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item["title"]!,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSubSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSubSelected ? Colors.white : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildRawNavItem(IconData icon, String label, String path, bool isCollapsed) {
    final bool isSelected = GoRouterState.of(context).uri.path == path;

    if (isCollapsed) {
      return Tooltip(
        message: label,
        child: InkWell(
          onTap: () => context.go(path),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isSelected ? cyanPrimary : Colors.transparent,
            ),
            child: Icon(icon, size: 18, color: isSelected ? Colors.white : textMuted),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isSelected ? cyanPrimary : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : textMuted),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                  letterSpacing: 0.2
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(bool isCollapsed) {
    if (isCollapsed) {
      return Tooltip(
        message: "Sign Out",
        child: IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 16),
          onPressed: _executeSignOutPipeline,
        ),
      );
    }

    return InkWell(
      onTap: _executeSignOutPipeline,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.redAccent.withOpacity(0.08),
        ),
        child: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 14),
            SizedBox(width: 12),
            Text(
              "SIGN OUT ENGINE",
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // ⚡ TERMINATE CONNECTION & FLUSH SECURE CACHE ON MANUAL LOGOUT
  // ==========================================================================
  Future<void> _executeSignOutPipeline() async {
    sl<WebSocketService>().closeGateway();

    await storage.deleteAll();
    if (mounted) context.go('/login');
  }
}