import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';

// =============================================================================
// COLOR PALETTE & DESIGN TOKENS
// =============================================================================
const Color kBrandBlue = Color(0xFF0066B3);
const Color kBrandRed = Color(0xFFD32027);
const Color kDarkSlate = Color(0xFF0B0E14);
const Color kTextMuted = Color(0xFF8B949E);
const Color kSurfaceBg = Color(0xFFF1F5F9);
const Color kCardBg = Color(0xFFF8FAFC);
const Color kAccentGreen = Color(0xFF10B981);
const Color kAccentAmber = Color(0xFFF59E0B);
const Color kAccentPurple = Color(0xFF8B5CF6);

// =============================================================================
// 1. DATA ENTITIES & REPOSITORY
// =============================================================================
class DashboardData {
  final int totalEmployees;
  final int activeEmployees;
  final int onNotice;
  final double monthlyPayout;
  final List<Map<String, dynamic>> recentEmployees;
  final List<Map<String, dynamic>> departments;
  final Map<String, dynamic>? companyInfo;

  DashboardData({
    required this.totalEmployees,
    required this.activeEmployees,
    required this.onNotice,
    required this.monthlyPayout,
    required this.recentEmployees,
    required this.departments,
    this.companyInfo,
  });
}

class DashboardRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<DashboardData> fetchDashboardOverview() async {
    final results = await Future.wait([
      apiClient.get('/api/hrms/employees/statistics/'),
      apiClient.get('/api/hrms/employees/'),
      apiClient.get('/api/hrms/departments/'),
      apiClient.get('/api/hrms/company-profile/'),
    ]);

    // 1. Stats
    final statsRes = results[0].data;
    final Map<String, dynamic> stats = (statsRes is Map && statsRes.containsKey('data'))
        ? statsRes['data']
        : {};

    // 2. Employees
    final empRes = results[1].data;
    List empList = [];
    if (empRes is Map && empRes.containsKey('data')) {
      empList = empRes['data'] as List;
    } else if (empRes is Map && empRes.containsKey('results')) {
      empList = empRes['results'] as List;
    } else if (empRes is List) {
      empList = empRes;
    }

    // 3. Departments
    final deptRes = results[2].data;
    List deptList = [];
    if (deptRes is Map && deptRes.containsKey('data')) {
      deptList = deptRes['data'] as List;
    } else if (deptRes is Map && deptRes.containsKey('results')) {
      deptList = deptRes['results'] as List;
    } else if (deptRes is List) {
      deptList = deptRes;
    }

    // 4. Company Profile
    final compRes = results[3].data;
    Map<String, dynamic>? company;
    if (compRes is Map && compRes.containsKey('data') && compRes['data'] != null) {
      company = compRes['data'] is List && (compRes['data'] as List).isNotEmpty
          ? (compRes['data'] as List).first
          : (compRes['data'] is Map ? compRes['data'] : null);
    }

    return DashboardData(
      totalEmployees: stats['total_employees'] ?? empList.length,
      activeEmployees: stats['active_employees'] ?? empList.where((e) => e['employment_status'] == 'ACTIVE').length,
      onNotice: stats['on_notice'] ?? empList.where((e) => e['employment_status'] == 'ON_NOTICE').length,
      monthlyPayout: double.tryParse((stats['monthly_payout_liability'] ?? 0).toString()) ?? 0.0,
      recentEmployees: empList.take(6).toList().cast<Map<String, dynamic>>(),
      departments: deptList.cast<Map<String, dynamic>>(),
      companyInfo: company,
    );
  }
}

// =============================================================================
// 2. BLOC STATE MANAGEMENT
// =============================================================================
abstract class DashboardEvent {}
class LoadDashboardDataEvent extends DashboardEvent {}

abstract class DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardLoaded extends DashboardState {
  final DashboardData data;
  DashboardLoaded(this.data);
}
class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository repository;

  DashboardBloc(this.repository) : super(DashboardLoading()) {
    on<LoadDashboardDataEvent>((event, emit) async {
      emit(DashboardLoading());
      try {
        final data = await repository.fetchDashboardOverview();
        emit(DashboardLoaded(data));
      } catch (e) {
        emit(DashboardError("Failed to fetch dashboard metrics: $e"));
      }
    });
  }
}

// =============================================================================
// 3. MAIN DASHBOARD SCREEN UI
// =============================================================================
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 950;

    return BlocProvider(
      create: (context) => DashboardBloc(DashboardRepository())..add(LoadDashboardDataEvent()),
      child: Scaffold(
        backgroundColor: kSurfaceBg,
        body: BlocConsumer<DashboardBloc, DashboardState>(
          listener: (context, state) {
            if (state is DashboardError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: kBrandRed),
              );
            }
          },
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(child: CircularProgressIndicator(color: kBrandBlue, strokeWidth: 2.5));
            }
            if (state is DashboardLoaded) {
              return RefreshIndicator(
                color: kBrandBlue,
                onRefresh: () async => context.read<DashboardBloc>().add(LoadDashboardDataEvent()),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopHeader(context, state.data),
                      const SizedBox(height: 16),
                      _buildMetricsRibbon(state.data, isMobile),
                      const SizedBox(height: 16),
                      _buildQuickActionStation(context, isMobile),
                      const SizedBox(height: 16),
                      if (isMobile) ...[
                        _buildRecentStaffCard(context, state.data),
                        const SizedBox(height: 16),
                        _buildSideStatsCard(state.data),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 7, child: _buildRecentStaffCard(context, state.data)),
                            const SizedBox(width: 16),
                            Expanded(flex: 4, child: _buildSideStatsCard(state.data)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  // --- TOP HEADER ---
  Widget _buildTopHeader(BuildContext context, DashboardData data) {
    final compName = data.companyInfo?['company_name'] ?? 'Softwing Tech Labs';
    final udyam = data.companyInfo?['msme_udyam_reg_no'] ?? 'MSME Registered Enterprise';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  compName.toUpperCase(),
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: kDarkSlate, letterSpacing: 0.6),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: kBrandBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: const Text("ENTERPRISE HRMS", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: kBrandBlue, letterSpacing: 0.4)),
                )
              ],
            ),
            const SizedBox(height: 3),
            Text(
              "Operational Overview & Personnel Lifecycle Monitor • $udyam",
              style: const TextStyle(fontSize: 9.5, color: kTextMuted, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        IconButton(
          tooltip: "Refresh Live Metrics",
          icon: const Icon(Icons.refresh_rounded, color: kBrandBlue, size: 20),
          onPressed: () => context.read<DashboardBloc>().add(LoadDashboardDataEvent()),
        ),
      ],
    );
  }

  // --- METRICS RIBBON ---
  Widget _buildMetricsRibbon(DashboardData data, bool isMobile) {
    final liability = NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(data.monthlyPayout);

    final cards = [
      _metricTile("TOTAL HEADCOUNT", "${data.totalEmployees}", Icons.people_alt_outlined, kBrandBlue, "All Registered Staff"),
      _metricTile("ACTIVE ON ROLL", "${data.activeEmployees}", Icons.verified_user_outlined, kAccentGreen, "Operational Force"),
      _metricTile("SERVING NOTICE", "${data.onNotice}", Icons.hourglass_top_rounded, kAccentAmber, "Exit Transition Phase"),
      _metricTile("MONTHLY CTC LIABILITY", liability, Icons.account_balance_wallet_outlined, kBrandRed, "Estimated Gross Payroll"),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.8,
        children: cards,
      );
    }

    return Row(
      children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
    );
  }

  Widget _metricTile(String title, String value, IconData icon, Color color, String sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: kTextMuted, letterSpacing: 0.4)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: kDarkSlate)),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- QUICK ACTION HUB ---
  Widget _buildQuickActionStation(BuildContext context, bool isMobile) {
    final actions = [
      _actionChip(context, "Onboard New Staff", Icons.person_add_outlined, kBrandBlue, '/staff_create'),
      _actionChip(context, "Staff Master & Vault", Icons.badge_outlined, kAccentPurple, '/staff_master'),
      _actionChip(context, "Issue Official Letter", Icons.post_add_rounded, kAccentGreen, '/employment_documents'),
      _actionChip(context, "Company Profile & Seals", Icons.business_outlined, kAccentAmber, '/company_profile'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("QUICK OPERATIONS COMMAND", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kDarkSlate, letterSpacing: 0.5)),
          const Divider(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: actions,
          ),
        ],
      ),
    );
  }

  Widget _actionChip(BuildContext context, String title, IconData icon, Color color, String route) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  // --- RECENT STAFF REGISTER ---
  Widget _buildRecentStaffCard(BuildContext context, DashboardData data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("RECENTLY ONBOARDED PERSONNEL", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kDarkSlate, letterSpacing: 0.4)),
                TextButton(
                  onPressed: () => context.go('/staff_master'),
                  child: const Text("VIEW ALL STAFF →", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: kBrandBlue)),
                )
              ],
            ),
          ),
          const Divider(height: 1),
          if (data.recentEmployees.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text("No employee records registered yet.", style: TextStyle(color: kTextMuted, fontSize: 11))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.recentEmployees.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (ctx, i) {
                final emp = data.recentEmployees[i];
                final String fName = emp['first_name'] ?? '';
                final String lName = emp['last_name'] ?? '';
                final String code = emp['emp_code'] ?? 'EMP';
                final String role = emp['designation_title'] ?? 'Staff';
                final String dept = emp['department_name'] ?? 'General';
                final String status = emp['employment_status'] ?? 'ACTIVE';

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    backgroundColor: kBrandBlue,
                    radius: 14,
                    child: Text(fName.isNotEmpty ? fName[0] : 'E', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  title: Text("$fName $lName ($code)", style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: kDarkSlate)),
                  subtitle: Text("$role • $dept", style: const TextStyle(fontSize: 9.5, color: kTextMuted)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: status == 'ACTIVE' ? Colors.green.shade50 : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: status == 'ACTIVE' ? Colors.green.shade800 : Colors.amber.shade900,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- SIDE STATS & DEPARTMENTS ---
  Widget _buildSideStatsCard(DashboardData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ORGANIZATIONAL STRUCTURE", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kDarkSlate, letterSpacing: 0.4)),
          const SizedBox(height: 12),
          _infoMetricRow("Configured Departments", "${data.departments.length} Units", Icons.account_tree_outlined),
          const SizedBox(height: 8),
          _infoMetricRow("System Health", "Operational Online", Icons.check_circle_outline, color: kAccentGreen),
          const SizedBox(height: 8),
          _infoMetricRow("Compliance Standard", "Indian MSME Norms", Icons.verified_outlined, color: kBrandBlue),
          const Divider(height: 24),
          const Text("DEPARTMENT MATRIX", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: kTextMuted, letterSpacing: 0.4)),
          const SizedBox(height: 8),
          if (data.departments.isEmpty)
            const Text("No departments created yet.", style: TextStyle(color: kTextMuted, fontSize: 10.5))
          else
            ...data.departments.take(5).map((d) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(d['name'] ?? '', style: const TextStyle(fontSize: 10.5, color: kDarkSlate, fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(color: kSurfaceBg, borderRadius: BorderRadius.circular(3)),
                      child: Text(d['code'] ?? 'DEP', style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: kTextMuted)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _infoMetricRow(String label, String val, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? kTextMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 10.5, color: kTextMuted))),
        Text(val, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color ?? kDarkSlate)),
      ],
    );
  }
}