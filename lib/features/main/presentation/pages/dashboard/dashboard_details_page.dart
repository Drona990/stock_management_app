import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';
import '../widgets/live_attendance_punch_dialog.dart';

// =============================================================================
// COLOR PALETTE & DESIGN TOKENS
// =============================================================================
const Color kBrandBlue = Color(0xFF0066B3);
const Color kBrandRed = Color(0xFFD32027);
const Color kDarkSlate = Color(0xFF0B0E14);
const Color kTextMuted = Color(0xFF8B949E);
const Color kSurfaceBg = Color(0xFFF1F5F9);
const Color kAccentGreen = Color(0xFF10B981);
const Color kAccentAmber = Color(0xFFF59E0B);
const Color kAccentPurple = Color(0xFF8B5CF6);
const Color kAccentCyan = Color(0xFF06B6D4);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  String _employeeName = "Employee";
  String _empCode = "SW-EMP-001";
  String _designation = "Staff";
  String _department = "General";
  String _workLocation = "Softwing HQ";
  String _shiftName = "General Shift (GS-01)";
  String _shiftTiming = "09:30 AM — 06:30 PM";
  int _graceMinutes = 15;

  Map<String, dynamic> _metrics = {
    "present_days": 0,
    "absent_days": 0,
    "half_days": 0,
    "leaves_taken": 0,
    "late_marks": 0,
    "total_working_days": 0,
  };

  Map<String, dynamic> _upcomingHoliday = {};

  @override
  void initState() {
    super.initState();
    _fetchLiveDashboardData();
  }

  Future<void> _fetchLiveDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = sl<ApiClient>();
      final response = await client.get('/api/hrms/employee/dashboard-overview/');
      print("dashboard Response $response");

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        final profile = data['profile'] ?? {};
        final shift = data['shift'] ?? {};
        final metrics = data['metrics'] ?? {};
        final holiday = data['upcoming_holiday'] ?? {};

        if (mounted) {
          setState(() {
            _employeeName = profile['full_name'] ?? "Employee";
            _empCode = profile['emp_code'] ?? "SW-EMP";
            _designation = profile['designation'] ?? "Staff";
            _department = profile['department'] ?? "General";
            _workLocation = profile['work_location'] ?? "Softwing HQ";

            _shiftName = shift['shift_name'] ?? "General Shift (GS-01)";
            _shiftTiming = shift['shift_timing'] ?? "09:30 AM — 06:30 PM";
            _graceMinutes = shift['grace_minutes'] ?? 15;

            _metrics = Map<String, dynamic>.from(metrics);
            _upcomingHoliday = Map<String, dynamic>.from(holiday);
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Invalid response structure from server");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 950;
    final String currentMonthName = DateFormat('MMMM yyyy').format(DateTime.now()).toUpperCase();

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kSurfaceBg,
        body: Center(
          child: CircularProgressIndicator(color: kBrandBlue, strokeWidth: 2),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: kSurfaceBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, color: kBrandRed, size: 42),
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: kDarkSlate, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _fetchLiveDashboardData,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text("RETRY CONNECTION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kSurfaceBg,
      body: RefreshIndicator(
        color: kBrandBlue,
        onRefresh: _fetchLiveDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 14.0 : 22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Welcome Greeting Header
              _buildWelcomeHeader(isMobile),
              const SizedBox(height: 16),

              // 2. Active Shift & Duty Status Hero Card
              _buildShiftDutyHeroCard(isMobile),
              const SizedBox(height: 16),

              // 3. Current Month Attendance Metrics Grid
              _buildSectionLabel("MONTHLY ATTENDANCE MATRIX ($currentMonthName)"),
              const SizedBox(height: 10),
              _buildAttendanceMetricsGrid(isMobile),
              const SizedBox(height: 18),

              // 4. Highlighted Upcoming Holiday Spotlight Banner (Conditional Render)
              if (_upcomingHoliday.isNotEmpty) ...[
                _buildSectionLabel("COMPANY CALENDAR HIGHLIGHT"),
                const SizedBox(height: 10),
                _buildHolidaySpotlightCard(isMobile),
                const SizedBox(height: 18),
              ],

              // 5. Quick Employee Self-Service Desk
              _buildSectionLabel("QUICK SERVICES & DESK"),
              const SizedBox(height: 10),
              _buildQuickServicesGrid(isMobile),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER GREETING
  // ===========================================================================
  Widget _buildWelcomeHeader(bool isMobile) {
    final String hourGreeting = DateTime.now().hour < 12
        ? "Good Morning"
        : DateTime.now().hour < 17
        ? "Good Afternoon"
        : "Good Evening";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$hourGreeting, $_employeeName 👋",
              style: TextStyle(
                fontSize: isMobile ? 16 : 20,
                fontWeight: FontWeight.w900,
                color: kDarkSlate,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "$_empCode • $_designation ($_department)",
              style: const TextStyle(fontSize: 10.5, color: kTextMuted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        if (!isMobile)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: const [
                CircleAvatar(radius: 3.5, backgroundColor: kAccentGreen),
                SizedBox(width: 8),
                Text(
                  "SECURE WORKSPACE ACTIVE",
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kDarkSlate, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // 2. ACTIVE SHIFT & DUTY HERO CARD
  // ===========================================================================
  Widget _buildShiftDutyHeroCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B0E14), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: kAccentGreen.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: kAccentGreen),
                    SizedBox(width: 6),
                    Text(
                      "TODAY'S ROSTER",
                      style: TextStyle(color: kAccentGreen, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => showLiveAttendancePunchModal(context),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kBrandBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fingerprint_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text("PUNCH TERMINAL", style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _shiftName,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            "Shift Timings: $_shiftTiming (${_graceMinutes}m Grace Period Allowed)",
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const Divider(color: Colors.white12, height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("GEOFENCE ZONE", style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(_workLocation, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("SYSTEM PUNCH LOG", style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text("GPS Verified", style: TextStyle(color: kAccentCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. ATTENDANCE METRICS GRID
  // ===========================================================================
  Widget _buildAttendanceMetricsGrid(bool isMobile) {
    final items = [
      _metricCard("TOTAL PRESENT", "${_metrics['present_days'] ?? 0}", Icons.verified_user_rounded, kAccentGreen),
      _metricCard("ABSENT DAYS", "${_metrics['absent_days'] ?? 0}", Icons.cancel_outlined, kBrandRed),
      _metricCard("HALF DAYS", "${_metrics['half_days'] ?? 0}", Icons.timelapse_rounded, kAccentAmber),
      _metricCard("PAID LEAVES", "${_metrics['leaves_taken'] ?? 0}", Icons.beach_access_rounded, kAccentPurple),
      _metricCard("LATE MARKS", "${_metrics['late_marks'] ?? 0}", Icons.alarm_outlined, const Color(0xFFF97316)),
      _metricCard("TOTAL WORKING", "${_metrics['total_working_days'] ?? 0}", Icons.calendar_today_rounded, kBrandBlue),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 90,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  Widget _metricCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 8.5, color: kTextMuted, fontWeight: FontWeight.w800, letterSpacing: 0.4),
              ),
              Icon(icon, color: color, size: 16),
            ],
          ),
          Text(
            val,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kDarkSlate, letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. UPCOMING HOLIDAY SPOTLIGHT CARD
  // ===========================================================================
  Widget _buildHolidaySpotlightCard(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: kBrandBlue.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.celebration_rounded, color: kBrandBlue, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_upcomingHoliday['days_left'] != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: kBrandBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _upcomingHoliday['days_left']!,
                      style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: kBrandBlue),
                    ),
                  ),
                Text(
                  _upcomingHoliday['name'] ?? "Upcoming Holiday",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: kDarkSlate),
                ),
                Text(
                  "${_upcomingHoliday['date'] ?? ''} • ${_upcomingHoliday['type'] ?? ''}",
                  style: const TextStyle(fontSize: 10, color: kTextMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. QUICK SERVICES MATRIX
  // ===========================================================================
  Widget _buildQuickServicesGrid(bool isMobile) {
    final services = [
      {"title": "Download Payslips", "sub": "Monthly Salary Ledger", "icon": Icons.receipt_long_outlined, "color": kBrandBlue},
      {"title": "Request Leave", "sub": "Apply for Time-Off", "icon": Icons.event_note_rounded, "color": kAccentPurple},
      {"title": "Attendance History", "sub": "Detailed Punch Logs", "icon": Icons.history_rounded, "color": kAccentGreen},
      {"title": "Policy & Documents", "sub": "Company Handbook", "icon": Icons.folder_shared_outlined, "color": kAccentAmber},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 70,
      ),
      itemCount: services.length,
      itemBuilder: (ctx, i) {
        final item = services[i];
        return InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${item['title']} module opening..."),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
              ),
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item['title'] as String, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: kDarkSlate)),
                      Text(item['sub'] as String, style: const TextStyle(fontSize: 9, color: kTextMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 16, color: kTextMuted),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kTextMuted, letterSpacing: 0.6),
    );
  }
}