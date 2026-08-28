import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../widgets/employee_avatar.dart';
import '../widgets/live_attendance_punch_dialog.dart';

class MainDashboard extends StatefulWidget {
  final Widget child;
  const MainDashboard({super.key, required this.child});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> with SingleTickerProviderStateMixin {
  // Corporate Palette
  static const Color brandBlue = Color(0xFF0066B3);
  static const Color accentCyan = Color(0xFF0284C7);
  static const Color deepNavy = Color(0xFF0F172A);
  static const Color surfaceBg = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF8B949E);
  static const Color roseRed = Color(0xFFF43F5E);

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late AnimationController _pulseController;

  String _userName = "Employee";
  String _empCode = "EMP-001";
  String _designation = "Staff";
  String _initials = "E";
  bool _isReady = false;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadEmployeeIdentity();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployeeIdentity() async {
    try {
      final name = await _storage.read(key: 'full_name') ?? await _storage.read(key: 'username') ?? "Employee";
      final code = await _storage.read(key: 'emp_code') ?? "SW-EMP";
      final desig = await _storage.read(key: 'designation') ?? "Team Member";
      final photo = await _storage.read(key: 'profile_photo'); // 🌟 Read photo URL

      if (mounted) {
        setState(() {
          _userName = name;
          _empCode = code;
          _designation = desig;
          _profilePhotoUrl = photo;
          _initials = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "E";
          _isReady = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isReady = true);
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/attendance')) return 1;
    if (location.startsWith('/calendar')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/attendance');
        break;
      case 2:
        context.go('/calendar');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        backgroundColor: deepNavy,
        body: Center(child: CircularProgressIndicator(color: accentCyan, strokeWidth: 2)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 950;
        final int activeIndex = _calculateSelectedIndex(context);

        return Scaffold(
          backgroundColor: surfaceBg,
          appBar: _buildTopBar(isDesktop),
          body: Row(
            children: [
              // Desktop Lateral Side Rail
              if (isDesktop) _buildDesktopSideRail(activeIndex),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
                    child: widget.child,
                  ),
                ),
              ),
            ],
          ),
          // Mobile & Tablet PhonePe-Style Floating Center FAB
          floatingActionButtonLocation: isDesktop ? null : FloatingActionButtonLocation.centerDocked,
          floatingActionButton: isDesktop ? null : _buildCenterPulsePunchButton(),
          // Mobile & Tablet Bottom Navigation Dock
          bottomNavigationBar: isDesktop ? null : _buildBottomNavigationDock(activeIndex),
        );
      },
    );
  }

  // ===========================================================================
  // 1. TOP BAR
  // ===========================================================================
  PreferredSizeWidget _buildTopBar(bool isDesktop) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      toolbarHeight: 56,
      titleSpacing: isDesktop ? 24 : 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: brandBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.badge_outlined, color: brandBlue, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "SOFTWING WORKFORCE",
                style: TextStyle(
                  color: deepNavy,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()).toUpperCase(),
                style: const TextStyle(color: textMuted, fontSize: 8.5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (isDesktop)
          ElevatedButton.icon(
            onPressed: () => showLiveAttendancePunchModal(context),
            icon: const Icon(Icons.fingerprint_rounded, size: 16),
            label: const Text("PUNCH DUTY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        const SizedBox(width: 12),
        _buildUserAvatar(isDesktop),
        const SizedBox(width: 16),
      ],
      shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
    );
  }

  Widget _buildUserAvatar(bool isDesktop) {
    return Row(
      children: [
        if (isDesktop) ...[
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _userName,
                style: const TextStyle(color: deepNavy, fontWeight: FontWeight.bold, fontSize: 11.5),
              ),
              Text(
                "$_empCode • $_designation",
                style: const TextStyle(color: textMuted, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(width: 10),
        ],
        EmployeeAvatar(
          photoUrl: _profilePhotoUrl,
          initials: _initials,
          radius: 17,
        ),
      ],
    );
  }
  // ===========================================================================
  // 2. DESKTOP SIDE RAIL NAVIGATION
  // ===========================================================================
  Widget _buildDesktopSideRail(int activeIndex) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: deepNavy,
        border: Border(right: BorderSide(color: Colors.grey.shade800, width: 0.5)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _navSideItem(0, Icons.dashboard_rounded, "Dashboard", activeIndex == 0),
          _navSideItem(1, Icons.history_toggle_off_rounded, "Attendance", activeIndex == 1),
          _navSideItem(2, Icons.event_available_rounded, "Holiday Calendar", activeIndex == 2),
          _navSideItem(3, Icons.person_rounded, "My Profile", activeIndex == 3),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: _executeSignOut,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: roseRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: roseRed, size: 16),
                    SizedBox(width: 10),
                    Text(
                      "SIGN OUT",
                      style: TextStyle(color: roseRed, fontSize: 10.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navSideItem(int index, IconData icon, String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? brandBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : textMuted),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. MOBILE & TABLET PHONEPE-STYLE PULSE PUNCH BUTTON
  // ===========================================================================
  Widget _buildCenterPulsePunchButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: brandBlue.withOpacity(0.25 + (_pulseController.value * 0.25)),
                blurRadius: 16 + (_pulseController.value * 10),
                spreadRadius: 2 + (_pulseController.value * 3),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => showLiveAttendancePunchModal(context),
            backgroundColor: brandBlue,
            elevation: 4,
            shape: const CircleBorder(),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF0284C7), Color(0xFF0066B3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fingerprint_rounded, color: Colors.white, size: 26),
                    Text(
                      "PUNCH",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 4. MOBILE & TABLET BOTTOM DOCK
  // ===========================================================================
  Widget _buildBottomNavigationDock(int activeIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 0,
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _dockItem(0, Icons.grid_view_rounded, Icons.grid_view_outlined, "Home", activeIndex == 0),
                _dockItem(1, Icons.history_toggle_off_rounded, Icons.history_rounded, "Logs", activeIndex == 1),
              ],
            ),
            const SizedBox(width: 48), // Gap for Punch FAB
            Row(
              children: [
                _dockItem(2, Icons.event_available_rounded, Icons.event_outlined, "Holiday", activeIndex == 2),
                _dockItem(3, Icons.person_rounded, Icons.person_outline_rounded, "Profile", activeIndex == 3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dockItem(int index, IconData activeIcon, IconData idleIcon, String label, bool isSelected) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : idleIcon,
              color: isSelected ? brandBlue : textMuted,
              size: 21,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? brandBlue : textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeSignOut() async {
    await _storage.deleteAll();
    if (mounted) context.go('/login');
  }
}