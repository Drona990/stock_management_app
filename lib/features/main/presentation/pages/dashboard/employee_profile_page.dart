import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';
import '../widgets/employee_avatar.dart';



const Color kBrandBlue = Color(0xFF0066B3);
const Color kDeepNavy = Color(0xFF0F172A);
const Color kSurfaceBg = Color(0xFFF1F5F9);
const Color kTextMuted = Color(0xFF8B949E);
const Color kAccentGreen = Color(0xFF10B981);
const Color kAccentAmber = Color(0xFFF59E0B);
const Color kRoseRed = Color(0xFFF43F5E);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late TabController _tabController;

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic> _personal = {};
  Map<String, dynamic> _employment = {};
  Map<String, dynamic> _banking = {};
  List<dynamic> _payslips = [];
  List<dynamic> _documents = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchFullProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFullProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = sl<ApiClient>();
      final response = await client.get('/api/hrms/employee/profile-full/');

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        if (mounted) {
          setState(() {
            _personal = data['personal'] ?? {};
            _employment = data['employment'] ?? {};
            _banking = data['banking_statutory'] ?? {};
            _payslips = data['payslips'] ?? [];
            _documents = data['documents'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to retrieve profile record.");
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

  Future<void> _handleSignOut() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Sign Out Confirmation", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to log out of your employee account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCEL", style: TextStyle(color: kTextMuted, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kRoseRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storage.deleteAll();
      if (mounted) context.go('/login');
    }
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
              const Icon(Icons.error_outline_rounded, color: kRoseRed, size: 38),
              const SizedBox(height: 10),
              Text(_errorMessage!, style: const TextStyle(fontSize: 12, color: kDeepNavy)),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: kBrandBlue, foregroundColor: Colors.white),
                onPressed: _fetchFullProfile,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text("RELOAD PROFILE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    final String fullName = _personal['full_name'] ?? "Employee";
    final String empCode = _personal['emp_code'] ?? "EMP";
    final String designation = _employment['designation'] ?? "Staff";
    final String department = _employment['department'] ?? "General";
    final String? photoUrl = _personal['profile_photo'];
    final String initials = fullName.isNotEmpty ? fullName[0].toUpperCase() : "E";

    return Scaffold(
      backgroundColor: kSurfaceBg,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 14.0 : 22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Employee Identity Card Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kDeepNavy, Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  EmployeeAvatar(
                    photoUrl: photoUrl,
                    initials: initials,
                    radius: isMobile ? 30 : 38,
                    backgroundColor: kBrandBlue,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: kAccentGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _employment['employment_status'] ?? "ACTIVE",
                                style: const TextStyle(color: kAccentGreen, fontSize: 8.5, fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              empCode,
                              style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          fullName,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "$designation • $department",
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Tab Switcher
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: isMobile,
                labelColor: kBrandBlue,
                unselectedLabelColor: kTextMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                indicatorColor: kBrandBlue,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: "PERSONAL"),
                  Tab(text: "JOB HIERARCHY"),
                  Tab(text: "BANK & STATUTORY"),
                  Tab(text: "DOCUMENTS"),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Tab Contents Container
            SizedBox(
              height: 480,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPersonalTab(),
                  _buildEmploymentTab(),
                  _buildBankingTab(),
                  _buildDocumentsTab(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Logout / Danger Action Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleSignOut,
                icon: const Icon(Icons.logout_rounded, size: 16, color: kRoseRed),
                label: const Text("SIGN OUT FROM SESSION", style: TextStyle(color: kRoseRed, fontWeight: FontWeight.bold, fontSize: 11.5)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: kRoseRed.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: PERSONAL INFORMATION
  // ===========================================================================
  Widget _buildPersonalTab() {
    return _buildCardWrapper([
      _infoRow("Official Email", _personal['official_email']),
      _infoRow("Personal Email", _personal['personal_email']),
      _infoRow("Phone Number", _personal['phone_primary']),
      _infoRow("Date of Birth", _personal['dob']),
      _infoRow("Gender", _personal['gender']),
      _infoRow("Blood Group", _personal['blood_group']),
      _infoRow("Marital Status", _personal['marital_status']),
      _infoRow("Current Address", _personal['current_address']),
    ]);
  }

  // ===========================================================================
  // TAB 2: JOB & ORGANIZATIONAL HIERARCHY
  // ===========================================================================
  Widget _buildEmploymentTab() {
    return _buildCardWrapper([
      _infoRow("Organization", _employment['company_name']),
      _infoRow("Department", _employment['department']),
      _infoRow("Designation", _employment['designation']),
      _infoRow("Reporting Head", _employment['reporting_manager']),
      _infoRow("Employment Nature", _employment['employment_nature']),
      _infoRow("Work Location", _employment['work_location']),
      _infoRow("Date of Joining", _employment['date_of_joining']),
      _infoRow("Notice Period", _employment['notice_period_days']),
      _infoRow("Assigned Shift", _employment['shift_name']),
    ]);
  }

  // ===========================================================================
  // TAB 3: BANKING & STATUTORY KYC
  // ===========================================================================
  Widget _buildBankingTab() {
    return _buildCardWrapper([
      _infoRow("Bank Name", _banking['bank_name']),
      _infoRow("Account Holder", _banking['account_holder']),
      _infoRow("Account Number", _banking['account_number']),
      _infoRow("IFSC Code", _banking['ifsc_code']),
      _infoRow("Branch Name", _banking['bank_branch']),
      _infoRow("PAN Number", _banking['pan_number']),
      _infoRow("UAN (PF Number)", _banking['uan_number']),
      _infoRow("ESI Number", _banking['esi_number']),
    ]);
  }

  // ===========================================================================
  // TAB 4: DOCUMENTS & PAYSLIPS
  // ===========================================================================
  Widget _buildDocumentsTab() {
    return ListView(
      children: [
        _buildSectionTitle("RECENT SALARY PAYSLIPS"),
        if (_payslips.isEmpty)
          _emptyState("No salary slips generated yet.")
        else
          ..._payslips.map((p) => _docTile(
            title: "Salary Slip — ${p['period']}",
            subtitle: "Net Pay: ₹${p['net_salary']} • Status: ${p['payment_status']}",
            icon: Icons.receipt_long_rounded,
            color: kBrandBlue,
            url: p['pdf_url'],
          )),
        const SizedBox(height: 16),
        _buildSectionTitle("OFFICIALLY ISSUED LETTERS"),
        if (_documents.isEmpty)
          _emptyState("No issued employment letters.")
        else
          ..._documents.map((d) => _docTile(
            title: d['title'] ?? "Employment Letter",
            subtitle: "Doc #: ${d['doc_number']} • Issued: ${d['issue_date']}",
            icon: Icons.description_rounded,
            color: kAccentAmber,
            url: d['pdf_url'],
          )),
      ],
    );
  }

  Widget _buildCardWrapper(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: children.length,
        separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100, height: 1),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    final displayVal = (value != null && value.toString().trim().isNotEmpty) ? value.toString() : "N/A";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10.5, color: kTextMuted, fontWeight: FontWeight.w600)),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              displayVal,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: kDeepNavy),
            ),
          ),
        ],
      ),
    );
  }

  Widget _docTile({required String title, required String subtitle, required IconData icon, required Color color, String? url}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: kDeepNavy)),
                Text(subtitle, style: const TextStyle(fontSize: 9.5, color: kTextMuted)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(url != null ? "Downloading $title..." : "File preview not generated"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.file_download_outlined, color: kBrandBlue, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: kTextMuted, letterSpacing: 0.6),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(message, style: const TextStyle(color: kTextMuted, fontSize: 11)),
    );
  }
}