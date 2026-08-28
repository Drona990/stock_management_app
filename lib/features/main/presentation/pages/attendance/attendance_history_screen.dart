import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';


const Color kBrandBlue = Color(0xFF0066B3);
const Color kDeepNavy = Color(0xFF0F172A);
const Color kSurfaceBg = Color(0xFFF1F5F9);
const Color kTextMuted = Color(0xFF8B949E);
const Color kAccentGreen = Color(0xFF10B981);
const Color kAccentAmber = Color(0xFFF59E0B);
const Color kAccentPurple = Color(0xFF8B5CF6);
const Color kRoseRed = Color(0xFFF43F5E);
const Color kAccentCyan = Color(0xFF06B6D4);

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  Map<String, dynamic> _summary = {
    "present_days": 0,
    "absent_days": 0,
    "half_days": 0,
    "leaves_taken": 0,
    "late_marks": 0,
    "total_work_hours": "0.0 hrs",
  };

  List<dynamic> _allLogs = [];
  List<dynamic> _filteredLogs = [];
  String _activeFilter = "ALL"; // ALL, PRESENT, LATE, HALF_DAY, LEAVE

  @override
  void initState() {
    super.initState();
    _fetchAttendanceLogs();
  }

  Future<void> _fetchAttendanceLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = sl<ApiClient>();
      final response = await client.get(
        '/api/attendance/attendance-history/?month=$_selectedMonth&year=$_selectedYear',
      );

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        if (mounted) {
          setState(() {
            _summary = data['summary'] ?? {};
            _allLogs = data['logs'] ?? [];
            _applyFilter(_activeFilter);
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to load attendance registry");
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

  void _applyFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      if (filter == "ALL") {
        _filteredLogs = List.from(_allLogs);
      } else if (filter == "PRESENT") {
        _filteredLogs = _allLogs.where((l) => l['status'] == 'PRESENT').toList();
      } else if (filter == "LATE") {
        _filteredLogs = _allLogs.where((l) => l['is_late_entry'] == true).toList();
      } else if (filter == "HALF_DAY") {
        _filteredLogs = _allLogs.where((l) => l['status'] == 'HALF_DAY').toList();
      } else if (filter == "LEAVE") {
        _filteredLogs = _allLogs.where((l) => l['status'] == 'ON_LEAVE').toList();
      }
    });
  }

  void _changeMonth(int delta) {
    var newDate = DateTime(_selectedYear, _selectedMonth + delta);
    setState(() {
      _selectedMonth = newDate.month;
      _selectedYear = newDate.year;
    });
    _fetchAttendanceLogs();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 950;
    final monthHeader = DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth));

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kSurfaceBg,
        body: Center(child: CircularProgressIndicator(color: kBrandBlue, strokeWidth: 2)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: kSurfaceBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history_toggle_off_rounded, color: kRoseRed, size: 40),
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: kDeepNavy, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: kBrandBlue, foregroundColor: Colors.white),
                onPressed: _fetchAttendanceLogs,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text("RETRY REGISTRY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kSurfaceBg,
      body: RefreshIndicator(
        color: kBrandBlue,
        onRefresh: _fetchAttendanceLogs,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 14.0 : 22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Month Selector Bar
              _buildMonthNavigator(monthHeader, isMobile),
              const SizedBox(height: 16),

              // 2. Metrics Quick Overview
              _buildMonthlyMetrics(isMobile),
              const SizedBox(height: 16),

              // 3. Status Filters
              _buildFilterChips(isMobile),
              const SizedBox(height: 14),

              // 4. Daily Attendance Timeline Logs
              _buildSectionLabel("DUTY LOGS & IN/OUT TIMELINE (${_filteredLogs.length} DAYS)"),
              const SizedBox(height: 10),
              if (_filteredLogs.isEmpty)
                _buildEmptyState()
              else
                ..._filteredLogs.map((log) => _buildAttendanceLogCard(log, isMobile)),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. MONTH NAVIGATOR
  // ===========================================================================
  Widget _buildMonthNavigator(String monthHeader, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded, color: kDeepNavy, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16, color: kBrandBlue),
              const SizedBox(width: 8),
              Text(
                monthHeader.toUpperCase(),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kDeepNavy, letterSpacing: 0.5),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right_rounded, color: kDeepNavy, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. MONTHLY METRICS
  // ===========================================================================
  Widget _buildMonthlyMetrics(bool isMobile) {
    return Row(
      children: [
        _metricTile("PRESENT", "${_summary['present_days'] ?? 0}", kAccentGreen),
        const SizedBox(width: 8),
        _metricTile("WORK HOURS", "${_summary['total_work_hours'] ?? '0.0'}", kBrandBlue),
        const SizedBox(width: 8),
        _metricTile("LATE MARKS", "${_summary['late_marks'] ?? 0}", const Color(0xFFF97316)),
        const SizedBox(width: 8),
        _metricTile("ABSENTS", "${_summary['absent_days'] ?? 0}", kRoseRed),
      ],
    );
  }

  Widget _metricTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: kTextMuted),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. FILTER CHIPS
  // ===========================================================================
  Widget _buildFilterChips(bool isMobile) {
    final filters = [
      {"id": "ALL", "label": "All Logs"},
      {"id": "PRESENT", "label": "Present"},
      {"id": "LATE", "label": "Late Entries"},
      {"id": "HALF_DAY", "label": "Half Day"},
      {"id": "LEAVE", "label": "Leaves"},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _activeFilter == f['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => _applyFilter(f['id']!),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? kBrandBlue : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? kBrandBlue : Colors.grey.shade300),
                ),
                child: Text(
                  f['label']!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : kTextMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // 4. DAILY ATTENDANCE CARD
  // ===========================================================================
  Widget _buildAttendanceLogCard(Map<String, dynamic> log, bool isMobile) {
    final status = log['status'] ?? 'ABSENT';
    final isLate = log['is_late_entry'] == true;
    final isManual = log['is_manual_override'] == true;

    Color badgeColor = kAccentGreen;
    if (status == 'ABSENT') badgeColor = kRoseRed;
    if (status == 'HALF_DAY') badgeColor = kAccentAmber;
    if (status == 'ON_LEAVE') badgeColor = kAccentPurple;
    if (status == 'WEEKLY_OFF' || status == 'HOLIDAY') badgeColor = kAccentCyan;

    final DateTime parsedDate = DateTime.tryParse(log['date'] ?? '') ?? DateTime.now();
    final String dayNum = DateFormat('dd').format(parsedDate);
    final String monthShort = DateFormat('MMM').format(parsedDate).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Box
              Container(
                width: 46,
                height: 50,
                decoration: BoxDecoration(
                  color: kSurfaceBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayNum,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kDeepNavy, height: 1.1),
                    ),
                    Text(
                      monthShort,
                      style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: kTextMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Title & Date Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log['status_display'] ?? status,
                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: badgeColor),
                          ),
                        ),
                        if (isLate) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "LATE ENTRY",
                              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Color(0xFFF97316)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${log['day_name']}, ${log['formatted_date']}",
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: kDeepNavy),
                    ),
                  ],
                ),
              ),

              // Work Hours Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kBrandBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${log['total_work_hours']} hrs",
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kBrandBlue),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.black12, height: 20),

          // Check In / Check Out Times
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _punchTimeColumn("CHECK IN", log['check_in'] ?? "N/A", Icons.login_rounded, kAccentGreen),
              _punchTimeColumn("CHECK OUT", log['check_out'] ?? "N/A", Icons.logout_rounded, kRoseRed),
              _punchTimeColumn("VERIFICATION", isManual ? "Manual Override" : "GPS Verified", Icons.shield_outlined, kAccentCyan),
            ],
          ),
        ],
      ),
    );
  }

  Widget _punchTimeColumn(String label, String time, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 7.5, color: kTextMuted, fontWeight: FontWeight.bold)),
            Text(time, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: kDeepNavy)),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kTextMuted, letterSpacing: 0.6),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Column(
        children: [
          Icon(Icons.history_rounded, color: kTextMuted, size: 30),
          SizedBox(height: 8),
          Text("No attendance logs found for this period.", style: TextStyle(color: kTextMuted, fontSize: 11)),
        ],
      ),
    );
  }
}