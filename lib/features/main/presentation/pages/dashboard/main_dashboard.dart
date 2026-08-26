import 'dart:async';
import 'dart:convert';
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
  // --- Softwing Tech Labs Theme Palette ---
  static const Color brandBlue = Color(0xFF0066B3);
  static const Color brandRed = Color(0xFFD32027);
  static const Color darkSidebarBg = Color(0xFF0B0E14);
  static const Color sidebarHoverColor = Color(0xFF141923);
  static const Color textMuted = Color(0xFF8B949E);

  final storage = const FlutterSecureStorage();

  String _userName = "User";
  String _userRole = "staff";
  String _initials = "U";
  bool _isReady = false;

  Set<String> _userAllowedRoutes = {};

  final Map<String, bool> _expandedGroups = {
    "Staff Directory": false,
    "Payroll & Slips": false,
    "Documentation": false,
    "Attendance & Leaves": false,
    "Commercial Master": false,
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

      final rawRoutes = await storage.read(key: 'user_allowed_routes');
      Set<String> allowed = {'/dashboard'};

      if (rawRoutes != null) {
        final List<dynamic> parsed = jsonDecode(rawRoutes);
        allowed = parsed.cast<String>().toSet();
      }

      if (mounted) {
        setState(() {
          _userRole = role.toLowerCase().trim();
          _userName = name;
          _initials = name.isNotEmpty ? name[0].toUpperCase() : "U";
          _userAllowedRoutes = allowed;
          _isReady = true;
        });

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
    sl<WebSocketService>().closeGateway();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        backgroundColor: darkSidebarBg,
        body: Center(
          child: CircularProgressIndicator(color: brandBlue, strokeWidth: 2),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;
        final bool isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
        final bool shouldCollapseSidebar = _isSidebarManualCollapsed || isTablet;

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: _buildProfessionalAppBar(isMobile, shouldCollapseSidebar),
          drawer: isMobile ? Drawer(child: _buildSidebarContent(false, isMobile)) : null,
          body: Row(
            children: [
              if (!isMobile)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: shouldCollapseSidebar ? 68 : 250,
                  color: darkSidebarBg,
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
  // 🏢 PROFESSIONAL HIGH-DENSITY TOP BAR
  // ==========================================================================
  PreferredSizeWidget _buildProfessionalAppBar(bool isMobile, bool isCollapsed) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      toolbarHeight: 58,
      iconTheme: const IconThemeData(color: darkSidebarBg, size: 20),
      leading: isMobile
          ? null
          : IconButton(
        icon: Icon(
          isCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
          color: darkSidebarBg,
        ),
        onPressed: () => setState(() => _isSidebarManualCollapsed = !_isSidebarManualCollapsed),
      ),
      titleSpacing: isMobile ? 0 : 8,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/icons/logo.png',
              width: 26,
              height: 26,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMobile ? "SOFTWING HRMS" : "SOFTWING TECH LABS • HRMS CORE",
                style: const TextStyle(
                  color: darkSidebarBg,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()).toUpperCase(),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
            ],
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
                Text(
                  _userName.toUpperCase(),
                  style: const TextStyle(
                    color: darkSidebarBg,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: brandBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _userRole.toUpperCase(),
                    style: const TextStyle(
                      color: brandBlue,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
          ],
          CircleAvatar(
            radius: 17,
            backgroundColor: brandBlue,
            child: Text(
              _initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
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
            child: Row(
              children: const [
                Icon(Icons.dashboard_customize_outlined, size: 16, color: brandBlue),
                SizedBox(width: 10),
                Text(
                  "PORTAL NAVIGATION",
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
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
              if (_userRole == 'superuser' || _userAllowedRoutes.contains("/dashboard"))
                _buildRawNavItem(Icons.dashboard_outlined, "Overview", "/dashboard", isCollapsed),
              const SizedBox(height: 4),

              // 1. HRMS CORE MODULES
              _buildDynamicGroupMenu(
                icon: Icons.people_alt_outlined,
                label: "Staff Directory",
                isCollapsed: isCollapsed,
                children: [
                  {"title": "Designations & Roles", "route": "/roles_master"},
                  {"title": "Add New Employee", "route": "/staff_create"},
                  {"title": "Staff Records", "route": "/staff_master"},
                  {"title": "Issue Employees Documents ", "route": "/employment_documents"},
                ],
              ),
              const SizedBox(height: 4),

              _buildDynamicGroupMenu(
                icon: Icons.receipt_long_outlined,
                label: "Payroll & Slips",
                isCollapsed: isCollapsed,
                children: [
                  {"title": "Generate Salary Slip", "route": "/"},
                  {"title": "Salary History", "route": "/"},
                  {"title": "Bank Payout Report", "route": "/"},
                ],
              ),
              const SizedBox(height: 4),

              if (_userRole == 'superuser') ...[
                _buildCompactGroupMenu(
                  icon: Icons.admin_panel_settings_outlined,
                  label: "Admin Controls",
                  isCollapsed: isCollapsed,
                  children: [
                    {"title": "Company Profile", "route": "/company_profile"},
                    {"title": "Manage Users", "route": "/manage_user"},
                    {"title": "Manage Attendance", "route": "/attendance_master"},
                    {"title": "Device Sessions", "route": "/manage_session"},
                    {"title": "Route Permissions", "route": "/manage_permission"},
                  ],
                ),
              ],
            ],
          ),
        ),

        // Bottom Sign Out Control
        Container(
          padding: const EdgeInsets.all(8),
          color: const Color(0xFF07090D),
          child: _buildLogoutButton(isCollapsed),
        ),
      ],
    );
  }

  // ==========================================================================
  // ⚡ DYNAMIC PERMISSION WRAPPER HELPER
  // ==========================================================================
  Widget _buildDynamicGroupMenu({
    required IconData icon,
    required String label,
    required bool isCollapsed,
    required List<Map<String, String>> children,
  }) {
    final accessibleChildren = _userRole == 'superuser'
        ? children
        : children.where((child) => _userAllowedRoutes.contains(child["route"])).toList();

    if (accessibleChildren.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildCompactGroupMenu(
      icon: icon,
      label: label,
      isCollapsed: isCollapsed,
      children: accessibleChildren,
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

    if (isCollapsed) {
      return PopupMenuButton<String>(
        tooltip: label,
        offset: const Offset(55, 0),
        color: const Color(0xFF141923),
        style: IconButton.styleFrom(
          backgroundColor: hasActiveChild ? brandBlue.withOpacity(0.18) : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onSelected: (route) => context.go(route),
        icon: Icon(icon, size: 18, color: hasActiveChild ? brandBlue : textMuted),
        itemBuilder: (BuildContext context) {
          return children.map((item) {
            final bool isSubSelected = item["route"] == currentPath;
            return PopupMenuItem<String>(
              value: item["route"],
              height: 36,
              child: Text(
                item["title"]!,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSubSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSubSelected ? brandBlue : Colors.white70,
                ),
              ),
            );
          }).toList();
        },
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => setState(() => _expandedGroups[label] = !isGroupOpen),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: hasActiveChild ? brandBlue.withOpacity(0.12) : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: hasActiveChild ? brandBlue : textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasActiveChild ? Colors.white : const Color(0xFFCBD5E1),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Icon(
                  isGroupOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: textMuted,
                ),
              ],
            ),
          ),
        ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: isSubSelected ? brandBlue : Colors.transparent,
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item["title"]!,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSubSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSubSelected ? Colors.white : textMuted,
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
              color: isSelected ? brandBlue : Colors.transparent,
            ),
            child: Icon(icon, size: 18, color: isSelected ? Colors.white : textMuted),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => context.go(path),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? brandBlue : Colors.transparent,
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
                letterSpacing: 0.2,
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
          icon: const Icon(Icons.logout_rounded, color: brandRed, size: 17),
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
          color: brandRed.withOpacity(0.1),
        ),
        child: const Row(
          children: [
            Icon(Icons.logout_rounded, color: brandRed, size: 15),
            SizedBox(width: 10),
            Text(
              "SIGN OUT PLATFORM",
              style: TextStyle(
                color: brandRed,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeSignOutPipeline() async {
    sl<WebSocketService>().closeGateway();
    await storage.deleteAll();
    if (mounted) context.go('/login');
  }
}