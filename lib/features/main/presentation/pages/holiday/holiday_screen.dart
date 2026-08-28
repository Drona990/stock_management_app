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

class HolidayScreen extends StatefulWidget {
  const HolidayScreen({super.key});

  @override
  State<HolidayScreen> createState() => _HolidayScreenState();
}

class _HolidayScreenState extends State<HolidayScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  int _selectedYear = DateTime.now().year;
  int _totalCount = 0;
  int _upcomingCount = 0;
  int _passedCount = 0;

  List<dynamic> _allHolidays = [];
  List<dynamic> _filteredHolidays = [];
  String _activeFilter = "ALL"; // ALL, UPCOMING, NATIONAL, FESTIVAL, OPTIONAL

  @override
  void initState() {
    super.initState();
    _fetchHolidays();
  }

  Future<void> _fetchHolidays() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = sl<ApiClient>();
      final response = await client.get('/api/attendance/holidays/?year=$_selectedYear');

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        if (mounted) {
          setState(() {
            _totalCount = data['total_holidays'] ?? 0;
            _upcomingCount = data['upcoming_holidays_count'] ?? 0;
            _passedCount = data['passed_holidays_count'] ?? 0;
            _allHolidays = data['holidays'] ?? [];
            _applyFilter(_activeFilter);
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to load holiday calendar");
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
        _filteredHolidays = List.from(_allHolidays);
      } else if (filter == "UPCOMING") {
        _filteredHolidays = _allHolidays.where((h) => h['is_upcoming'] == true).toList();
      } else if (filter == "NATIONAL") {
        _filteredHolidays = _allHolidays.where((h) => h['holiday_type'] == 'NATIONAL').toList();
      } else if (filter == "FESTIVAL") {
        _filteredHolidays = _allHolidays.where((h) => h['holiday_type'] == 'FESTIVAL').toList();
      } else if (filter == "OPTIONAL") {
        _filteredHolidays = _allHolidays.where((h) => h['is_optional'] == true).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 950;

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
              const Icon(Icons.event_busy_rounded, color: kRoseRed, size: 40),
              const SizedBox(height: 12),
              Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: kDeepNavy, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: kBrandBlue, foregroundColor: Colors.white),
                onPressed: _fetchHolidays,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text("RETRY SYNC", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    // Next upcoming holiday for Spotlight
    final nextHoliday = _allHolidays.firstWhere(
          (h) => h['is_upcoming'] == true,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: kSurfaceBg,
      body: RefreshIndicator(
        color: kBrandBlue,
        onRefresh: _fetchHolidays,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 14.0 : 22.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with Year Selector
              _buildHeader(isMobile),
              const SizedBox(height: 16),

              // 2. Metrics Summary (Total, Upcoming, Completed)
              _buildMetricsSummary(isMobile),
              const SizedBox(height: 16),

              // 3. Next Upcoming Holiday Spotlight Hero
              if (nextHoliday != null) ...[
                _buildSectionLabel("NEXT UPCOMING HOLIDAY"),
                const SizedBox(height: 8),
                _buildSpotlightBanner(nextHoliday, isMobile),
                const SizedBox(height: 18),
              ],

              // 4. Filter Chips
              _buildFilterRow(isMobile),
              const SizedBox(height: 14),

              // 5. Holiday List
              _buildSectionLabel("CALENDAR SCHEDULE ($_selectedYear)"),
              const SizedBox(height: 10),
              if (_filteredHolidays.isEmpty)
                _buildEmptyState()
              else
                ..._filteredHolidays.map((h) => _buildHolidayCard(h, isMobile)),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER
  // ===========================================================================
  Widget _buildHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Company Holiday Calendar",
              style: TextStyle(
                fontSize: isMobile ? 16 : 20,
                fontWeight: FontWeight.w900,
                color: kDeepNavy,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              "Official Gazetted, Festival & Declared Paid Offs",
              style: TextStyle(fontSize: 10.5, color: kTextMuted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedYear,
              isDense: true,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: kBrandBlue),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: kBrandBlue),
              items: [DateTime.now().year - 1, DateTime.now().year, DateTime.now().year + 1]
                  .map((y) => DropdownMenuItem(value: y, child: Text("$y Roster")))
                  .toList(),
              onChanged: (val) {
                if (val != null && val != _selectedYear) {
                  setState(() => _selectedYear = val);
                  _fetchHolidays();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. METRICS SUMMARY
  // ===========================================================================
  Widget _buildMetricsSummary(bool isMobile) {
    return Row(
      children: [
        _metricBox("TOTAL", "$_totalCount", Icons.calendar_month_rounded, kBrandBlue),
        const SizedBox(width: 8),
        _metricBox("UPCOMING", "$_upcomingCount", Icons.celebration_rounded, kAccentGreen),
        const SizedBox(width: 8),
        _metricBox("PASSED", "$_passedCount", Icons.history_toggle_off_rounded, kTextMuted),
      ],
    );
  }

  Widget _metricBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: kTextMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Icon(icon, color: color, size: 15),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: kDeepNavy,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. SPOTLIGHT NEXT HOLIDAY BANNER
  // ===========================================================================
  Widget _buildSpotlightBanner(Map<String, dynamic> holiday, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kDeepNavy, Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBrandBlue.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.celebration_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kAccentGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    holiday['status_badge'] ?? "Upcoming",
                    style: const TextStyle(color: kAccentGreen, fontSize: 8.5, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  holiday['name'] ?? "",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  "${holiday['day_name']}, ${holiday['formatted_date']} • ${holiday['holiday_type_display']}",
                  style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. FILTER CHIPS
  // ===========================================================================
  Widget _buildFilterRow(bool isMobile) {
    final filters = [
      {"id": "ALL", "label": "All ($_totalCount)"},
      {"id": "UPCOMING", "label": "Upcoming ($_upcomingCount)"},
      {"id": "NATIONAL", "label": "Gazetted"},
      {"id": "FESTIVAL", "label": "Festival"},
      {"id": "OPTIONAL", "label": "Optional"},
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? kBrandBlue : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? kBrandBlue : Colors.grey.shade300),
                ),
                child: Text(
                  f['label']!,
                  style: TextStyle(
                    fontSize: 10.5,
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
  // 5. HOLIDAY ITEM CARD
  // ===========================================================================
  Widget _buildHolidayCard(Map<String, dynamic> holiday, bool isMobile) {
    final bool isUpcoming = holiday['is_upcoming'] == true;
    final bool isOptional = holiday['is_optional'] == true;
    final String type = holiday['holiday_type'] ?? 'FESTIVAL';

    Color typeColor = kBrandBlue;
    if (type == 'NATIONAL') typeColor = kAccentPurple;
    if (type == 'COMPANY_SPECIAL') typeColor = kAccentAmber;
    if (isOptional) typeColor = const Color(0xFFF97316);

    final DateTime parsedDate = DateTime.tryParse(holiday['date'] ?? '') ?? DateTime.now();
    final String dayNum = DateFormat('dd').format(parsedDate);
    final String monthShort = DateFormat('MMM').format(parsedDate).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUpcoming ? Colors.grey.shade200 : Colors.grey.shade100,
        ),
        boxShadow: isUpcoming
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Row(
        children: [
          // Date Square Badge
          Container(
            width: 48,
            height: 52,
            decoration: BoxDecoration(
              color: isUpcoming ? kBrandBlue.withValues(alpha: 0.08) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isUpcoming ? kBrandBlue.withValues(alpha: 0.2) : Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayNum,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isUpcoming ? kBrandBlue : kTextMuted,
                    height: 1.1,
                  ),
                ),
                Text(
                  monthShort,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: isUpcoming ? kBrandBlue : kTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Holiday Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        holiday['holiday_type_display'] ?? "Holiday",
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: typeColor),
                      ),
                    ),
                    if (isOptional) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF97316).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "OPTIONAL",
                          style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Color(0xFFF97316)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  holiday['name'] ?? "",
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: isUpcoming ? kDeepNavy : kTextMuted,
                  ),
                ),
                Text(
                  "${holiday['day_name']} • ${holiday['formatted_date']}",
                  style: const TextStyle(fontSize: 10, color: kTextMuted, fontWeight: FontWeight.w500),
                ),
                if (holiday['description'] != null && holiday['description'].toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    holiday['description'],
                    style: const TextStyle(fontSize: 9.5, color: kTextMuted, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),

          // Status Badge / Countdown Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUpcoming ? kAccentGreen.withValues(alpha: 0.12) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              holiday['status_badge'] ?? "",
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: isUpcoming ? kAccentGreen : kTextMuted,
              ),
            ),
          ),
        ],
      ),
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
          Icon(Icons.event_busy_rounded, color: kTextMuted, size: 30),
          SizedBox(height: 8),
          Text("No holidays found under this filter.", style: TextStyle(color: kTextMuted, fontSize: 11)),
        ],
      ),
    );
  }
}