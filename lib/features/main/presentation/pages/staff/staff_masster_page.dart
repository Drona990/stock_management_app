/*
import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';

// =============================================================================
// COLOR PALETTE & CONSTANTS
// =============================================================================
const Color kBrandBlue = Color(0xFF0066B3);
const Color kBrandRed = Color(0xFFD32027);
const Color kDarkSlate = Color(0xFF0B0E14);
const Color kTextMuted = Color(0xFF8B949E);
const Color kSurfaceBg = Color(0xFFF1F5F9);
const Color kCardBg = Color(0xFFF8FAFC);

const Map<String, String> kDocTypeOptions = {
  "AADHAAR_FRONT": "Aadhaar Card (Front Side)",
  "AADHAAR_BACK": "Aadhaar Card (Back Side)",
  "PAN_CARD": "PAN Card Copy",
  "VOTER_ID_FRONT": "Voter ID (Front Side)",
  "VOTER_ID_BACK": "Voter ID (Back Side)",
  "BANK_PASSBOOK": "Bank Passbook / Cheque",
  "RESUME_CV": "Curriculum Vitae / Resume",
  "EDUCATION_MARKSHEET": "Academic Certificate",
  "PREV_RELIEVING_LETTER": "Previous Relieving Letter",
  "PREV_EXPERIENCE_LETTER": "Previous Experience Letter",
  "PREV_PAYSLIP": "Previous Payslip",
  "SIGNED_OFFER_LETTER": "Signed Offer Letter",
  "OTHER": "Other Supporting Document",
};

// =============================================================================
// 1. DATA ENTITIES & MODELS
// =============================================================================
class AttachmentItem {
  final String id;
  final String employeeId;
  final String attachmentType;
  final String attachmentTypeDisplay;
  final String title;
  final String fileUrl;
  final String? notes;
  final String uploadedAt;

  const AttachmentItem({
    required this.id,
    required this.employeeId,
    required this.attachmentType,
    required this.attachmentTypeDisplay,
    required this.title,
    required this.fileUrl,
    this.notes,
    required this.uploadedAt,
  });

  factory AttachmentItem.fromJson(Map<String, dynamic> json) {
    return AttachmentItem(
      id: (json['id'] ?? '').toString(),
      employeeId: (json['employee'] ?? '').toString(),
      attachmentType: json['attachment_type'] ?? 'OTHER',
      attachmentTypeDisplay: json['attachment_type_display'] ?? json['attachment_type'] ?? 'Attachment',
      title: json['title'] ?? '',
      fileUrl: json['file'] ?? '',
      notes: json['notes'],
      uploadedAt: json['uploaded_at'] ?? '',
    );
  }
}

class EmployeeItem {
  final String id;
  final String empCode;
  final String firstName;
  final String middleName;
  final String lastName;
  final String fullName;
  final String officialEmail;
  final String personalEmail;
  final String phonePrimary;
  final String phoneSecondary;
  final String emergencyContactPerson;
  final String emergencyContactPhone;
  final String? dob;
  final String gender;
  final String maritalStatus;
  final String? bloodGroup;
  final String? profilePhoto;
  final String currentAddress;
  final String permanentAddress;
  final String panNumber;
  final String aadhaarNumber;
  final String uanNumber;
  final String pfNumber;
  final String esiNumber;
  final String? departmentId;
  final String departmentName;
  final String? designationId;
  final String designationTitle;
  final String employmentNature;
  final String employmentNatureDisplay;
  final String employmentStatus;
  final String employmentStatusDisplay;
  final String workLocation;
  final String dateOfJoining;
  final String? probationEndDate;
  final String? dateOfRelieving;
  final int noticePeriodDays;
  final double monthlyCtc;
  final double annualCtc;
  final String bankHolderName;
  final String bankName;
  final String bankAccountNumber;
  final String bankIfscCode;
  final String bankBranch;
  final String upiId;

  const EmployeeItem({
    required this.id,
    required this.empCode,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.fullName,
    required this.officialEmail,
    required this.personalEmail,
    required this.phonePrimary,
    required this.phoneSecondary,
    required this.emergencyContactPerson,
    required this.emergencyContactPhone,
    this.dob,
    required this.gender,
    required this.maritalStatus,
    this.bloodGroup,
    this.profilePhoto,
    required this.currentAddress,
    required this.permanentAddress,
    required this.panNumber,
    required this.aadhaarNumber,
    required this.uanNumber,
    required this.pfNumber,
    required this.esiNumber,
    this.departmentId,
    required this.departmentName,
    this.designationId,
    required this.designationTitle,
    required this.employmentNature,
    required this.employmentNatureDisplay,
    required this.employmentStatus,
    required this.employmentStatusDisplay,
    required this.workLocation,
    required this.dateOfJoining,
    this.probationEndDate,
    this.dateOfRelieving,
    required this.noticePeriodDays,
    required this.monthlyCtc,
    required this.annualCtc,
    required this.bankHolderName,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankIfscCode,
    required this.bankBranch,
    required this.upiId,
  });

  factory EmployeeItem.fromJson(Map<String, dynamic> json) {
    return EmployeeItem(
      id: (json['id'] ?? '').toString(),
      empCode: json['emp_code'] ?? 'N/A',
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      officialEmail: json['official_email'] ?? '',
      personalEmail: json['personal_email'] ?? '',
      phonePrimary: json['phone_primary'] ?? '',
      phoneSecondary: json['phone_secondary'] ?? '',
      emergencyContactPerson: json['emergency_contact_person'] ?? '',
      emergencyContactPhone: json['emergency_contact_phone'] ?? '',
      dob: json['dob'],
      gender: json['gender'] ?? 'MALE',
      maritalStatus: json['marital_status'] ?? 'SINGLE',
      bloodGroup: json['blood_group'],
      profilePhoto: json['profile_photo'],
      currentAddress: json['current_address'] ?? '',
      permanentAddress: json['permanent_address'] ?? '',
      panNumber: json['pan_number'] ?? '',
      aadhaarNumber: json['aadhaar_number'] ?? '',
      uanNumber: json['uan_number'] ?? '',
      pfNumber: json['pf_number'] ?? '',
      esiNumber: json['esi_number'] ?? '',
      departmentId: json['department']?.toString(),
      departmentName: json['department_name'] ?? 'General',
      designationId: json['designation']?.toString(),
      designationTitle: json['designation_title'] ?? 'Staff',
      employmentNature: json['employment_nature'] ?? 'FULL_TIME',
      employmentNatureDisplay: json['employment_nature_display'] ?? json['employment_nature'] ?? 'Full-time',
      employmentStatus: json['employment_status'] ?? 'ACTIVE',
      employmentStatusDisplay: json['employment_status_display'] ?? json['employment_status'] ?? 'Active',
      workLocation: json['work_location'] ?? 'Remote / In-Office',
      dateOfJoining: json['date_of_joining'] ?? '',
      probationEndDate: json['probation_end_date'],
      dateOfRelieving: json['date_of_relieving'],
      noticePeriodDays: int.tryParse((json['notice_period_days'] ?? 30).toString()) ?? 30,
      monthlyCtc: double.tryParse((json['monthly_ctc'] ?? 0).toString()) ?? 0.0,
      annualCtc: double.tryParse((json['annual_ctc'] ?? 0).toString()) ?? 0.0,
      bankHolderName: json['bank_account_holder_name'] ?? '',
      bankName: json['bank_name'] ?? '',
      bankAccountNumber: json['bank_account_number'] ?? '',
      bankIfscCode: json['bank_ifsc_code'] ?? '',
      bankBranch: json['bank_branch'] ?? '',
      upiId: json['upi_id'] ?? '',
    );
  }
}

// =============================================================================
// 2. REPOSITORY LAYER
// =============================================================================
class EmployeeDirectoryRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<EmployeeItem>> fetchEmployees({String? search, String? status}) async {
    final Map<String, dynamic> params = {};
    if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
    if (status != null && status != 'ALL') params['status'] = status;

    final res = await apiClient.get('/api/hrms/employees/', query: params);
    final dynamic data = res.data;
    List rawList = [];
    if (data is Map && data.containsKey('data')) {
      rawList = data['data'] as List;
    } else if (data is Map && data.containsKey('results')) {
      rawList = data['results'] as List;
    } else if (data is List) {
      rawList = data;
    }
    return rawList.map((e) => EmployeeItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> fetchStatistics() async {
    final res = await apiClient.get('/api/hrms/employees/statistics/');
    return res.data['data'] ?? {};
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchMeta() async {
    final deptsRes = await apiClient.get('/api/hrms/departments/');
    final desigsRes = await apiClient.get('/api/hrms/designations/');

    final List deptsData = (deptsRes.data is Map && deptsRes.data.containsKey('data'))
        ? deptsRes.data['data']
        : (deptsRes.data is Map && deptsRes.data.containsKey('results'))
        ? deptsRes.data['results']
        : deptsRes.data is List
        ? deptsRes.data
        : [];

    final List desigsData = (desigsRes.data is Map && desigsRes.data.containsKey('data'))
        ? desigsRes.data['data']
        : (desigsRes.data is Map && desigsRes.data.containsKey('results'))
        ? desigsRes.data['results']
        : desigsRes.data is List
        ? desigsRes.data
        : [];

    return {
      'departments': deptsData.cast<Map<String, dynamic>>(),
      'designations': desigsData.cast<Map<String, dynamic>>(),
    };
  }

  Future<void> updateEmployeeStatus(String id, String newStatus) async {
    await apiClient.patch('/api/hrms/employees/$id/', data: {'employment_status': newStatus});
  }

  Future<void> updateEmployeeDetails(String id, Map<String, dynamic> payload) async {
    await apiClient.patch('/api/hrms/employees/$id/', data: payload);
  }

  Future<void> deleteEmployee(String id) async {
    await apiClient.delete('/api/hrms/employees/$id/');
  }

  // Attachments Sub-APIs
  Future<List<AttachmentItem>> fetchAttachments(String employeeId) async {
    final res = await apiClient.get('/api/hrms/attachments/', query: {'employee_id': employeeId});
    final dynamic data = res.data;
    List rawList = [];
    if (data is Map && data.containsKey('data')) {
      rawList = data['data'] as List;
    } else if (data is Map && data.containsKey('results')) {
      rawList = data['results'] as List;
    } else if (data is List) {
      rawList = data;
    }
    return rawList.map((e) => AttachmentItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> uploadAttachment({
    required String employeeId,
    required String attachmentType,
    required String title,
    String? notes,
    PlatformFile? file,
  }) async {
    final Map<String, dynamic> map = {
      'employee': employeeId,
      'attachment_type': attachmentType,
      'title': title,
      'notes': notes ?? '',
    };

    if (file != null) {
      if (file.bytes != null) {
        map['file'] = dio.MultipartFile.fromBytes(file.bytes!, filename: file.name);
      } else if (file.path != null) {
        map['file'] = await dio.MultipartFile.fromFile(file.path!, filename: file.name);
      }
    }

    final dio.FormData formData = dio.FormData.fromMap(map);
    await apiClient.post('/api/hrms/attachments/', data: formData);
  }

  Future<void> deleteAttachment(String id) async {
    await apiClient.delete('/api/hrms/attachments/$id/');
  }
}

// =============================================================================
// 3. BLOC ENGINE
// =============================================================================
abstract class StaffMasterEvent {}

class LoadStaffDirectoryEvent extends StaffMasterEvent {}

class SearchStaffEvent extends StaffMasterEvent {
  final String query;
  SearchStaffEvent(this.query);
}

class FilterStaffByStatusEvent extends StaffMasterEvent {
  final String status;
  FilterStaffByStatusEvent(this.status);
}

class ChangeEmployeeStatusEvent extends StaffMasterEvent {
  final String id;
  final String newStatus;
  ChangeEmployeeStatusEvent({required this.id, required this.newStatus});
}

class EditEmployeeDetailsEvent extends StaffMasterEvent {
  final String id;
  final Map<String, dynamic> payload;
  EditEmployeeDetailsEvent({required this.id, required this.payload});
}

class DeleteEmployeeEvent extends StaffMasterEvent {
  final String id;
  DeleteEmployeeEvent(this.id);
}

abstract class StaffMasterState {}

class StaffMasterLoading extends StaffMasterState {}

class StaffMasterLoaded extends StaffMasterState {
  final List<EmployeeItem> employees;
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> departments;
  final List<Map<String, dynamic>> designations;
  final String activeStatusFilter;
  final String searchQuery;
  final bool isBusy;

  StaffMasterLoaded({
    required this.employees,
    required this.stats,
    required this.departments,
    required this.designations,
    this.activeStatusFilter = 'ALL',
    this.searchQuery = '',
    this.isBusy = false,
  });

  StaffMasterLoaded copyWith({
    List<EmployeeItem>? employees,
    Map<String, dynamic>? stats,
    List<Map<String, dynamic>>? departments,
    List<Map<String, dynamic>>? designations,
    String? activeStatusFilter,
    String? searchQuery,
    bool? isBusy,
  }) {
    return StaffMasterLoaded(
      employees: employees ?? this.employees,
      stats: stats ?? this.stats,
      departments: departments ?? this.departments,
      designations: designations ?? this.designations,
      activeStatusFilter: activeStatusFilter ?? this.activeStatusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isBusy: isBusy ?? this.isBusy,
    );
  }
}

class StaffMasterError extends StaffMasterState {
  final String message;
  StaffMasterError(this.message);
}

class StaffMasterBloc extends Bloc<StaffMasterEvent, StaffMasterState> {
  final EmployeeDirectoryRepository repository;
  List<EmployeeItem> _cachedList = [];
  Map<String, dynamic> _cachedStats = {};
  List<Map<String, dynamic>> _cachedDepts = [];
  List<Map<String, dynamic>> _cachedDesigs = [];
  String _currentStatus = 'ALL';
  String _currentSearch = '';

  StaffMasterBloc(this.repository) : super(StaffMasterLoading()) {
    on<LoadStaffDirectoryEvent>((event, emit) async {
      try {
        final results = await Future.wait([
          repository.fetchEmployees(),
          repository.fetchStatistics(),
          repository.fetchMeta(),
        ]);

        _cachedList = results[0] as List<EmployeeItem>;
        _cachedStats = results[1] as Map<String, dynamic>;
        final meta = results[2] as Map<String, List<Map<String, dynamic>>>;
        _cachedDepts = meta['departments'] ?? [];
        _cachedDesigs = meta['designations'] ?? [];

        _applyFilters(emit);
      } catch (e) {
        emit(StaffMasterError("Failed to fetch staff directory: $e"));
      }
    });

    on<SearchStaffEvent>((event, emit) {
      _currentSearch = event.query.toLowerCase().trim();
      _applyFilters(emit);
    });

    on<FilterStaffByStatusEvent>((event, emit) {
      _currentStatus = event.status;
      _applyFilters(emit);
    });

    on<ChangeEmployeeStatusEvent>((event, emit) async {
      if (state is StaffMasterLoaded) {
        emit((state as StaffMasterLoaded).copyWith(isBusy: true));
        try {
          await repository.updateEmployeeStatus(event.id, event.newStatus);
          add(LoadStaffDirectoryEvent());
        } catch (e) {
          emit(StaffMasterError("Status change failed: $e"));
        }
      }
    });

    on<EditEmployeeDetailsEvent>((event, emit) async {
      if (state is StaffMasterLoaded) {
        emit((state as StaffMasterLoaded).copyWith(isBusy: true));
        try {
          await repository.updateEmployeeDetails(event.id, event.payload);
          add(LoadStaffDirectoryEvent());
        } catch (e) {
          emit(StaffMasterError("Update failed: $e"));
        }
      }
    });

    on<DeleteEmployeeEvent>((event, emit) async {
      if (state is StaffMasterLoaded) {
        emit((state as StaffMasterLoaded).copyWith(isBusy: true));
        try {
          await repository.deleteEmployee(event.id);
          add(LoadStaffDirectoryEvent());
        } catch (e) {
          emit(StaffMasterError("Delete failed: $e"));
        }
      }
    });
  }

  void _applyFilters(Emitter<StaffMasterState> emit) {
    final filtered = _cachedList.where((emp) {
      final matchSearch = emp.fullName.toLowerCase().contains(_currentSearch) ||
          emp.empCode.toLowerCase().contains(_currentSearch) ||
          emp.officialEmail.toLowerCase().contains(_currentSearch) ||
          emp.phonePrimary.contains(_currentSearch);

      final matchStatus = _currentStatus == 'ALL' || emp.employmentStatus.toUpperCase() == _currentStatus.toUpperCase();

      return matchSearch && matchStatus;
    }).toList();

    emit(StaffMasterLoaded(
      employees: filtered,
      stats: _cachedStats,
      departments: _cachedDepts,
      designations: _cachedDesigs,
      activeStatusFilter: _currentStatus,
      searchQuery: _currentSearch,
      isBusy: false,
    ));
  }
}

// =============================================================================
// 4. MAIN CANVAS VIEW
// =============================================================================
class StaffMasterScreen extends StatelessWidget {
  const StaffMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 900;

    return BlocProvider(
      create: (context) => StaffMasterBloc(EmployeeDirectoryRepository())..add(LoadStaffDirectoryEvent()),
      child: Scaffold(
        backgroundColor: kSurfaceBg,
        body: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(context, isMobile),
              const SizedBox(height: 14),
              _buildMetricsBar(isMobile),
              const SizedBox(height: 14),
              Expanded(
                child: BlocConsumer<StaffMasterBloc, StaffMasterState>(
                  listener: (context, state) {
                    if (state is StaffMasterError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message), backgroundColor: kBrandRed, behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is StaffMasterLoading) {
                      return const Center(child: CircularProgressIndicator(color: kBrandBlue, strokeWidth: 2));
                    }
                    if (state is StaffMasterLoaded) {
                      return _buildTableContainer(context, state, isMobile);
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "STAFF RECORDS DIRECTORY & DOCUMENT VAULT",
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: kDarkSlate, letterSpacing: 0.6),
            ),
            SizedBox(height: 2),
            Text(
              "Manage personnel profiles, statutory KYC attachments, and employment lifecycles",
              style: TextStyle(fontSize: 9.5, color: kTextMuted, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => context.go('/staff_create'),
          icon: const Icon(Icons.person_add_rounded, size: 14),
          label: Text(
            isMobile ? "ADD" : "ONBOARD NEW EMPLOYEE",
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.4),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrandBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsBar(bool isMobile) {
    return BlocBuilder<StaffMasterBloc, StaffMasterState>(
      builder: (context, state) {
        int total = 0;
        int active = 0;
        int onNotice = 0;
        String liability = "₹0.00";

        if (state is StaffMasterLoaded) {
          total = state.stats['total_employees'] ?? 0;
          active = state.stats['active_employees'] ?? 0;
          onNotice = state.stats['on_notice'] ?? 0;
          liability = NumberFormat.currency(locale: 'en_IN', symbol: '₹')
              .format(double.tryParse((state.stats['monthly_payout_liability'] ?? 0).toString()) ?? 0);
        }

        final items = [
          _metricCard("TOTAL HEADCOUNT", "$total", Icons.people_outline_rounded, kBrandBlue),
          _metricCard("ACTIVE ON ROLL", "$active", Icons.verified_user_outlined, const Color(0xFF10B981)),
          _metricCard("SERVING NOTICE", "$onNotice", Icons.hourglass_top_rounded, const Color(0xFFF59E0B)),
          _metricCard("MONTHLY CTC LIABILITY", liability, Icons.account_balance_wallet_outlined, kBrandRed),
        ];

        if (isMobile) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: items.map((w) => Padding(padding: const EdgeInsets.only(right: 8), child: w)).toList()),
          );
        }

        return Row(children: items.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: w))).toList());
      },
    );
  }

  Widget _metricCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 8, color: kTextMuted, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
              const SizedBox(height: 2),
              Text(val, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: kDarkSlate)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTableContainer(BuildContext context, StaffMasterLoaded state, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildFilterSearchStrip(context, state),
          const Divider(height: 1),
          Expanded(
            child: state.employees.isEmpty
                ? const Center(child: Text("No staff members found matching criteria.", style: TextStyle(color: kTextMuted, fontSize: 11.5)))
                : isMobile
                ? _buildMobileView(context, state)
                : _buildDesktopTableView(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSearchStrip(BuildContext context, StaffMasterLoaded state) {
    final bloc = context.read<StaffMasterBloc>();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                style: const TextStyle(fontSize: 11.5),
                onChanged: (v) => bloc.add(SearchStaffEvent(v)),
                decoration: const InputDecoration(
                  hintText: "Search by Emp Code, Name, Email, Phone...",
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                  prefixIcon: Icon(Icons.search, size: 15, color: kBrandBlue),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(bottom: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Wrap(
            spacing: 6,
            children: ["ALL", "ACTIVE", "ON_NOTICE", "RELIEVED", "TERMINATED"].map((statusKey) {
              final isSelected = state.activeStatusFilter == statusKey;
              return ChoiceChip(
                label: Text(statusKey.replaceAll("_", " "), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : kDarkSlate)),
                selected: isSelected,
                selectedColor: kBrandBlue,
                backgroundColor: kSurfaceBg,
                onSelected: (_) => bloc.add(FilterStaffByStatusEvent(statusKey)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTableView(BuildContext context, StaffMasterLoaded state) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: kCardBg,
          child: Row(
            children: [
              _hCell("EMPLOYEE IDENTITY", 5),
              _hCell("ORGANIZATION & ROLE", 4),
              _hCell("COMMUNICATION MATRIX", 4),
              _hCell("MONTHLY COMPENSATION", 3),
              _hCell("STATUS", 3),
              _hCell("ACTIONS", 5, true),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: state.employees.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (ctx, i) {
              final emp = state.employees[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: kBrandBlue,
                            backgroundImage: emp.profilePhoto != null ? NetworkImage(emp.profilePhoto!) : null,
                            child: emp.profilePhoto == null
                                ? Text(emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : "E", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(emp.fullName, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: kDarkSlate)),
                                Text(emp.empCode, style: const TextStyle(fontSize: 9, color: kBrandBlue, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emp.designationTitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kDarkSlate)),
                          Text(emp.departmentName, style: const TextStyle(fontSize: 9, color: kTextMuted)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emp.officialEmail, style: const TextStyle(fontSize: 10.5, color: kDarkSlate), overflow: TextOverflow.ellipsis),
                          Text(emp.phonePrimary, style: const TextStyle(fontSize: 9, color: kTextMuted)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(emp.monthlyCtc),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kDarkSlate),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Align(alignment: Alignment.centerLeft, child: _statusBadge(emp.employmentStatus)),
                    ),
                    Expanded(
                      flex: 5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _actionBtn(Icons.folder_shared_outlined, "KYC & Attachments Vault", () => showEmployeeAttachmentVaultModal(context, emp), color: const Color(0xFF8B5CF6)),
                          const SizedBox(width: 4),
                          _actionBtn(Icons.visibility_outlined, "View Profile", () => showEmployeeProfileModal(context, emp)),
                          const SizedBox(width: 4),
                          _actionBtn(Icons.edit_note_rounded, "Edit Employee", () => showEmployeeEditModal(context, state, emp)),
                          const SizedBox(width: 4),
                          _actionBtn(
                            emp.employmentStatus == "ACTIVE" ? Icons.block_flipped : Icons.check_circle_outline,
                            emp.employmentStatus == "ACTIVE" ? "Mark Inactive" : "Mark Active",
                                () => _confirmStatusChange(context, emp),
                            color: emp.employmentStatus == "ACTIVE" ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          _actionBtn(Icons.delete_outline_rounded, "Delete Profile", () => _confirmDelete(context, emp), color: kBrandRed),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView(BuildContext context, StaffMasterLoaded state) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.employees.length,
      itemBuilder: (ctx, i) {
        final emp = state.employees[i];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(emp.empCode, style: const TextStyle(fontSize: 9.5, color: kBrandBlue, fontWeight: FontWeight.bold)),
                    _statusBadge(emp.employmentStatus),
                  ],
                ),
                const SizedBox(height: 4),
                Text(emp.fullName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: kDarkSlate)),
                Text("${emp.designationTitle} • ${emp.departmentName}", style: const TextStyle(fontSize: 10, color: kTextMuted)),
                const Divider(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(emp.officialEmail, style: const TextStyle(fontSize: 10, color: kDarkSlate)),
                    Text(NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(emp.monthlyCtc), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => showEmployeeAttachmentVaultModal(context, emp),
                      icon: const Icon(Icons.folder_shared_outlined, size: 13, color: Color(0xFF8B5CF6)),
                      label: const Text("KYC VAULT", style: TextStyle(fontSize: 9.5, color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                    ),
                    TextButton.icon(onPressed: () => showEmployeeProfileModal(context, emp), icon: const Icon(Icons.visibility, size: 12), label: const Text("VIEW", style: TextStyle(fontSize: 9.5))),
                    TextButton.icon(onPressed: () => showEmployeeEditModal(context, state, emp), icon: const Icon(Icons.edit, size: 12), label: const Text("EDIT", style: TextStyle(fontSize: 9.5))),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 14, color: kBrandRed), onPressed: () => _confirmDelete(context, emp)),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;

    if (status == "ACTIVE") {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    } else if (status == "ON_NOTICE") {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
    } else if (status == "RELIEVED" || status == "TERMINATED") {
      bg = kBrandRed.withValues(alpha: 0.08);
      fg = kBrandRed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3)),
      child: Text(
        status.replaceAll("_", " "),
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: fg, letterSpacing: 0.3),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String tip, VoidCallback onTap, {Color? color}) {
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: (color ?? Colors.blueGrey).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
          child: Icon(icon, size: 13.5, color: color ?? Colors.blueGrey.shade700),
        ),
      ),
    );
  }

  Widget _hCell(String t, int f, [bool r = false]) => Expanded(
    flex: f,
    child: Text(t, textAlign: r ? TextAlign.right : TextAlign.left, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: kTextMuted, letterSpacing: 0.5)),
  );

  void _confirmStatusChange(BuildContext context, EmployeeItem emp) {
    final bloc = context.read<StaffMasterBloc>();
    final String nextStatus = emp.employmentStatus == "ACTIVE" ? "RELIEVED" : "ACTIVE";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Change Status to $nextStatus?"),
        content: Text("Are you sure you want to mark ${emp.fullName} (${emp.empCode}) as $nextStatus?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: nextStatus == "ACTIVE" ? const Color(0xFF10B981) : const Color(0xFFF59E0B), foregroundColor: Colors.white),
            onPressed: () {
              bloc.add(ChangeEmployeeStatusEvent(id: emp.id, newStatus: nextStatus));
              Navigator.pop(ctx);
            },
            child: Text("MARK AS $nextStatus"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, EmployeeItem emp) {
    final bloc = context.read<StaffMasterBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: kBrandRed, size: 18),
            SizedBox(width: 8),
            Text("Delete Employee Record?", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrandRed)),
          ],
        ),
        content: Text("Are you sure you want to purge ${emp.fullName} (${emp.empCode})? This action cannot be reversed.", style: const TextStyle(fontSize: 11.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kBrandRed, foregroundColor: Colors.white),
            onPressed: () {
              bloc.add(DeleteEmployeeEvent(emp.id));
              Navigator.pop(ctx);
            },
            child: const Text("DELETE RECORD"),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 5. ATTACHMENT VAULT MODAL (INLINE KYC REPOSITORY & UPLOAD)
// =============================================================================
void showEmployeeAttachmentVaultModal(BuildContext context, EmployeeItem emp) {
  showDialog(
    context: context,
    builder: (dialogCtx) => EmployeeAttachmentVaultDialog(emp: emp),
  );
}

class EmployeeAttachmentVaultDialog extends StatefulWidget {
  final EmployeeItem emp;
  const EmployeeAttachmentVaultDialog({super.key, required this.emp});

  @override
  State<EmployeeAttachmentVaultDialog> createState() => _EmployeeAttachmentVaultDialogState();
}

class _EmployeeAttachmentVaultDialogState extends State<EmployeeAttachmentVaultDialog> {
  final EmployeeDirectoryRepository _repo = EmployeeDirectoryRepository();
  List<AttachmentItem> _attachments = [];
  bool _isLoading = true;
  bool _isUploading = false;

  String _selectedDocType = "AADHAAR_FRONT";
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  PlatformFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = kDocTypeOptions[_selectedDocType] ?? '';
    _loadVault();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVault() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repo.fetchAttachments(widget.emp.id);
      if (mounted) setState(() => _attachments = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _uploadDoc() async {
    if (_titleCtrl.text.trim().isEmpty || _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title and File are required."), backgroundColor: kBrandRed));
      return;
    }

    setState(() => _isUploading = true);
    try {
      await _repo.uploadAttachment(
        employeeId: widget.emp.id,
        attachmentType: _selectedDocType,
        title: _titleCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        file: _pickedFile,
      );
      _notesCtrl.clear();
      _pickedFile = null;
      await _loadVault();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload error: $e"), backgroundColor: kBrandRed));
    }
    if (mounted) setState(() => _isUploading = false);
  }

  Future<void> _deleteDoc(String id) async {
    setState(() => _isLoading = true);
    try {
      await _repo.deleteAttachment(id);
      await _loadVault();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _openFileUrl(String url) async {
    if (url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open file URL."), backgroundColor: kBrandRed));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 3.5, height: 18, color: const Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("KYC Vault: ${widget.emp.fullName}", style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900)),
                  Text("${widget.emp.empCode} • ${widget.emp.designationTitle} (${widget.emp.departmentName})", style: const TextStyle(fontSize: 9.5, color: kTextMuted)),
                ],
              ),
            ],
          ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 18)),
        ],
      ),
      content: SizedBox(
        width: 820,
        height: 500,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Upload Form
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("UPLOAD NEW DOCUMENT", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kDarkSlate, letterSpacing: 0.5)),
                      const Divider(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDocType,
                        style: const TextStyle(fontSize: 11.5, color: kDarkSlate),
                        decoration: _inputDeco("DOCUMENT CLASSIFICATION *"),
                        items: kDocTypeOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 11)))).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _selectedDocType = v;
                              _titleCtrl.text = kDocTypeOptions[v] ?? '';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(controller: _titleCtrl, style: const TextStyle(fontSize: 11.5), decoration: _inputDeco("DOCUMENT TITLE *")),
                      const SizedBox(height: 10),
                      TextFormField(controller: _notesCtrl, maxLines: 2, style: const TextStyle(fontSize: 11.5), decoration: _inputDeco("REMARKS (OPTIONAL)")),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () async {
                          final FilePickerResult? res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'], withData: true);
                          if (res != null && res.files.isNotEmpty) setState(() => _pickedFile = res.files.first);
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_upload_outlined, size: 16, color: kBrandBlue),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _pickedFile != null ? _pickedFile!.name : "CHOOSE PDF / IMAGE",
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: kBrandBlue),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _uploadDoc,
                          icon: _isUploading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5)) : const Icon(Icons.check_circle_outline, size: 14),
                          label: Text(_isUploading ? "UPLOADING..." : "COMMIT TO VAULT", style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: kBrandBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Right: Stored Attachments List
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("SAVED ATTACHMENTS", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kDarkSlate, letterSpacing: 0.5)),
                        Text("${_attachments.length} DOCUMENTS", style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: kBrandBlue)),
                      ],
                    ),
                    const Divider(height: 16),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: kBrandBlue, strokeWidth: 2))
                          : _attachments.isEmpty
                          ? const Center(child: Text("No documents in vault yet. Fresher records need no prior experience letters.", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: kTextMuted)))
                          : ListView.separated(
                        itemCount: _attachments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final doc = _attachments[i];
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: kBrandBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                                  child: const Icon(Icons.file_present_rounded, color: kBrandBlue, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(doc.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kDarkSlate), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text(doc.attachmentTypeDisplay, style: const TextStyle(fontSize: 9, color: kBrandBlue, fontWeight: FontWeight.w600)),
                                      if (doc.notes != null && doc.notes!.isNotEmpty) Text(doc.notes!, style: const TextStyle(fontSize: 8.5, color: kTextMuted), maxLines: 1),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.open_in_new_rounded, size: 15, color: kBrandBlue),
                                  tooltip: "Open / Download",
                                  onPressed: () => _openFileUrl(doc.fileUrl),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 15, color: kBrandRed),
                                  tooltip: "Delete",
                                  onPressed: () => _deleteDoc(doc.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String lbl) => InputDecoration(
    labelText: lbl,
    labelStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    isDense: true,
    filled: true,
    fillColor: Colors.white,
  );
}

// =============================================================================
// 6. ENTERPRISE TABBED MODAL: EDIT EMPLOYEE PROFILE
// =============================================================================
void showEmployeeEditModal(BuildContext context, StaffMasterLoaded state, EmployeeItem emp) {
  final bloc = context.read<StaffMasterBloc>();
  showDialog(
    context: context,
    builder: (dialogCtx) => EmployeeEditDialog(
      state: state,
      emp: emp,
      onSave: (payload) => bloc.add(EditEmployeeDetailsEvent(id: emp.id, payload: payload)),
    ),
  );
}

class EmployeeEditDialog extends StatefulWidget {
  final StaffMasterLoaded state;
  final EmployeeItem emp;
  final Function(Map<String, dynamic>) onSave;

  const EmployeeEditDialog({super.key, required this.state, required this.emp, required this.onSave});

  @override
  State<EmployeeEditDialog> createState() => _EmployeeEditDialogState();
}

class _EmployeeEditDialogState extends State<EmployeeEditDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Personal
  late TextEditingController _firstNameCtrl;
  late TextEditingController _middleNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _officialEmailCtrl;
  late TextEditingController _personalEmailCtrl;
  late TextEditingController _phonePrimaryCtrl;
  late TextEditingController _phoneSecondaryCtrl;
  late TextEditingController _emergencyPersonCtrl;
  late TextEditingController _emergencyPhoneCtrl;

  // Career
  String? _selectedDeptId;
  String? _selectedDesigId;
  late String _employmentNature;
  late String _employmentStatus;
  late TextEditingController _workLocationCtrl;
  late TextEditingController _noticeDaysCtrl;

  // Financial
  late TextEditingController _monthlyCtcCtrl;
  late TextEditingController _annualCtcCtrl;
  late TextEditingController _holderNameCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _accNoCtrl;
  late TextEditingController _ifscCtrl;
  late TextEditingController _branchCtrl;
  late TextEditingController _upiCtrl;

  // Statutory
  late TextEditingController _panCtrl;
  late TextEditingController _aadhaarCtrl;
  late TextEditingController _uanCtrl;
  late TextEditingController _pfCtrl;
  late TextEditingController _esiCtrl;
  late TextEditingController _currentAddrCtrl;
  late TextEditingController _permAddrCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _firstNameCtrl = TextEditingController(text: widget.emp.firstName);
    _middleNameCtrl = TextEditingController(text: widget.emp.middleName);
    _lastNameCtrl = TextEditingController(text: widget.emp.lastName);
    _officialEmailCtrl = TextEditingController(text: widget.emp.officialEmail);
    _personalEmailCtrl = TextEditingController(text: widget.emp.personalEmail);
    _phonePrimaryCtrl = TextEditingController(text: widget.emp.phonePrimary);
    _phoneSecondaryCtrl = TextEditingController(text: widget.emp.phoneSecondary);
    _emergencyPersonCtrl = TextEditingController(text: widget.emp.emergencyContactPerson);
    _emergencyPhoneCtrl = TextEditingController(text: widget.emp.emergencyContactPhone);

    _selectedDeptId = widget.emp.departmentId;
    _selectedDesigId = widget.emp.designationId;
    _employmentNature = widget.emp.employmentNature;
    _employmentStatus = widget.emp.employmentStatus;
    _workLocationCtrl = TextEditingController(text: widget.emp.workLocation);
    _noticeDaysCtrl = TextEditingController(text: widget.emp.noticePeriodDays.toString());

    _monthlyCtcCtrl = TextEditingController(text: widget.emp.monthlyCtc.toString());
    _annualCtcCtrl = TextEditingController(text: widget.emp.annualCtc.toString());
    _holderNameCtrl = TextEditingController(text: widget.emp.bankHolderName);
    _bankNameCtrl = TextEditingController(text: widget.emp.bankName);
    _accNoCtrl = TextEditingController(text: widget.emp.bankAccountNumber);
    _ifscCtrl = TextEditingController(text: widget.emp.bankIfscCode);
    _branchCtrl = TextEditingController(text: widget.emp.bankBranch);
    _upiCtrl = TextEditingController(text: widget.emp.upiId);

    _panCtrl = TextEditingController(text: widget.emp.panNumber);
    _aadhaarCtrl = TextEditingController(text: widget.emp.aadhaarNumber);
    _uanCtrl = TextEditingController(text: widget.emp.uanNumber);
    _pfCtrl = TextEditingController(text: widget.emp.pfNumber);
    _esiCtrl = TextEditingController(text: widget.emp.esiNumber);
    _currentAddrCtrl = TextEditingController(text: widget.emp.currentAddress);
    _permAddrCtrl = TextEditingController(text: widget.emp.permanentAddress);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _officialEmailCtrl.dispose();
    _personalEmailCtrl.dispose();
    _phonePrimaryCtrl.dispose();
    _phoneSecondaryCtrl.dispose();
    _emergencyPersonCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _workLocationCtrl.dispose();
    _noticeDaysCtrl.dispose();
    _monthlyCtcCtrl.dispose();
    _annualCtcCtrl.dispose();
    _holderNameCtrl.dispose();
    _bankNameCtrl.dispose();
    _accNoCtrl.dispose();
    _ifscCtrl.dispose();
    _branchCtrl.dispose();
    _upiCtrl.dispose();
    _panCtrl.dispose();
    _aadhaarCtrl.dispose();
    _uanCtrl.dispose();
    _pfCtrl.dispose();
    _esiCtrl.dispose();
    _currentAddrCtrl.dispose();
    _permAddrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDesigs = _selectedDeptId == null
        ? widget.state.designations
        : widget.state.designations.where((d) => d['department'].toString() == _selectedDeptId).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Row(
        children: [
          Container(width: 3.5, height: 18, color: kBrandBlue),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Edit Personnel Record: ${widget.emp.empCode}", style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900)),
              Text(widget.emp.fullName, style: const TextStyle(fontSize: 9.5, color: kTextMuted)),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 780,
        height: 480,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: kBrandBlue,
              unselectedLabelColor: Colors.blueGrey,
              indicatorColor: kBrandBlue,
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "1. Personal Matrix"),
                Tab(text: "2. Career & Hierarchy"),
                Tab(text: "3. Financial & Bank"),
                Tab(text: "4. Statutory KYC"),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Personal
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          _row([
                            _input(_firstNameCtrl, "FIRST NAME *", isRequired: true),
                            _input(_middleNameCtrl, "MIDDLE NAME"),
                            _input(_lastNameCtrl, "LAST NAME *", isRequired: true),
                          ]),
                          const SizedBox(height: 10),
                          _row([
                            _input(_officialEmailCtrl, "OFFICIAL EMAIL *", isRequired: true),
                            _input(_personalEmailCtrl, "PERSONAL EMAIL"),
                          ]),
                          const SizedBox(height: 10),
                          _row([
                            _input(_phonePrimaryCtrl, "PRIMARY CONTACT PHONE *", isRequired: true),
                            _input(_phoneSecondaryCtrl, "SECONDARY PHONE"),
                          ]),
                          const SizedBox(height: 10),
                          _row([
                            _input(_emergencyPersonCtrl, "EMERGENCY CONTACT PERSON"),
                            _input(_emergencyPhoneCtrl, "EMERGENCY PHONE NUMBER"),
                          ]),
                        ],
                      ),
                    ),

                    // Tab 2: Career
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          _row([
                            DropdownButtonFormField<String>(
                              value: _selectedDeptId,
                              decoration: _inputDeco("DEPARTMENT"),
                              items: widget.state.departments.map((d) => DropdownMenuItem(value: d['id'].toString(), child: Text(d['name']))).toList(),
                              onChanged: (v) => setState(() {
                                _selectedDeptId = v;
                                _selectedDesigId = null;
                              }),
                            ),
                            DropdownButtonFormField<String>(
                              value: _selectedDesigId,
                              decoration: _inputDeco("DESIGNATION"),
                              items: filteredDesigs.map((d) => DropdownMenuItem(value: d['id'].toString(), child: Text(d['title']))).toList(),
                              onChanged: (v) => setState(() => _selectedDesigId = v),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          _row([
                            DropdownButtonFormField<String>(
                              value: _employmentStatus,
                              decoration: _inputDeco("EMPLOYMENT STATUS"),
                              items: ["ACTIVE", "ON_NOTICE", "RELIEVED", "TERMINATED", "ABSCONDED"]
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll("_", " "))))
                                  .toList(),
                              onChanged: (v) => setState(() => _employmentStatus = v!),
                            ),
                            DropdownButtonFormField<String>(
                              value: _employmentNature,
                              decoration: _inputDeco("EMPLOYMENT NATURE"),
                              items: ["FULL_TIME", "PROBATION", "CONTRACT", "INTERN", "FREELANCE"]
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll("_", " "))))
                                  .toList(),
                              onChanged: (v) => setState(() => _employmentNature = v!),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          _row([
                            _input(_workLocationCtrl, "WORK LOCATION"),
                            _input(_noticeDaysCtrl, "NOTICE PERIOD (DAYS)", isNumber: true),
                          ]),
                        ],
                      ),
                    ),

                    // Tab 3: Financial
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          _row([
                            _input(_monthlyCtcCtrl, "MONTHLY CTC (₹) *", isRequired: true, isNumber: true, onChanged: (v) {
                              final m = double.tryParse(v) ?? 0.0;
                              _annualCtcCtrl.text = (m * 12).toStringAsFixed(2);
                            }),
                            _input(_annualCtcCtrl, "ANNUAL CTC (₹)", isNumber: true, isReadOnly: true),
                            _input(_upiCtrl, "UPI ID"),
                          ]),
                          const SizedBox(height: 10),
                          _row([
                            _input(_holderNameCtrl, "ACCOUNT HOLDER NAME"),
                            _input(_bankNameCtrl, "BANK NAME"),
                            _input(_accNoCtrl, "ACCOUNT NUMBER"),
                          ]),
                          const SizedBox(height: 10),
                          _row([
                            _input(_ifscCtrl, "IFSC CODE"),
                            _input(_branchCtrl, "BRANCH NAME"),
                          ]),
                        ],
                      ),
                    ),

                    // Tab 4: Statutory
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          _row([
                            _input(_panCtrl, "PAN CARD NUMBER"),
                            _input(_aadhaarCtrl, "AADHAAR NUMBER"),
                            _input(_uanCtrl, "UAN NUMBER"),
                          ]),
                          const SizedBox(height: 10),
                          _row([
                            _input(_pfCtrl, "PF NUMBER"),
                            _input(_esiCtrl, "ESI NUMBER"),
                          ]),
                          const SizedBox(height: 10),
                          _row([
                            _input(_currentAddrCtrl, "CURRENT ADDRESS", maxLines: 2),
                            _input(_permAddrCtrl, "PERMANENT ADDRESS", maxLines: 2),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kBrandBlue, foregroundColor: Colors.white),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            widget.onSave({
              "first_name": _firstNameCtrl.text.trim(),
              "middle_name": _middleNameCtrl.text.trim(),
              "last_name": _lastNameCtrl.text.trim(),
              "official_email": _officialEmailCtrl.text.trim(),
              "personal_email": _personalEmailCtrl.text.trim(),
              "phone_primary": _phonePrimaryCtrl.text.trim(),
              "phone_secondary": _phoneSecondaryCtrl.text.trim(),
              "emergency_contact_person": _emergencyPersonCtrl.text.trim(),
              "emergency_contact_phone": _emergencyPhoneCtrl.text.trim(),
              "department": _selectedDeptId,
              "designation": _selectedDesigId,
              "employment_status": _employmentStatus,
              "employment_nature": _employmentNature,
              "work_location": _workLocationCtrl.text.trim(),
              "notice_period_days": int.tryParse(_noticeDaysCtrl.text) ?? 30,
              "monthly_ctc": double.tryParse(_monthlyCtcCtrl.text) ?? 0.0,
              "annual_ctc": double.tryParse(_annualCtcCtrl.text) ?? 0.0,
              "bank_account_holder_name": _holderNameCtrl.text.trim(),
              "bank_name": _bankNameCtrl.text.trim(),
              "bank_account_number": _accNoCtrl.text.trim(),
              "bank_ifsc_code": _ifscCtrl.text.trim(),
              "bank_branch": _branchCtrl.text.trim(),
              "upi_id": _upiCtrl.text.trim(),
              "pan_number": _panCtrl.text.trim(),
              "aadhaar_number": _aadhaarCtrl.text.trim(),
              "uan_number": _uanCtrl.text.trim(),
              "pf_number": _pfCtrl.text.trim(),
              "esi_number": _esiCtrl.text.trim(),
              "current_address": _currentAddrCtrl.text.trim(),
              "permanent_address": _permAddrCtrl.text.trim(),
            });
            Navigator.pop(context);
          },
          child: const Text("COMMIT CHANGES"),
        ),
      ],
    );
  }

  Widget _row(List<Widget> children) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: c))).toList(),
  );

  Widget _input(TextEditingController ctrl, String lbl, {bool isRequired = false, bool isNumber = false, bool isReadOnly = false, int maxLines = 1, Function(String)? onChanged}) {
    return TextFormField(
      controller: ctrl,
      readOnly: isReadOnly,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 11.5),
      decoration: _inputDeco(lbl),
      onChanged: onChanged,
      validator: (v) => (isRequired && (v == null || v.trim().isEmpty)) ? "Required" : null,
    );
  }

  InputDecoration _inputDeco(String lbl) => InputDecoration(
    labelText: lbl,
    labelStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    isDense: true,
  );
}

// =============================================================================
// 7. ENTERPRISE TABBED MODAL: VIEW EMPLOYEE PROFILE
// =============================================================================
void showEmployeeProfileModal(BuildContext context, EmployeeItem emp) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: kBrandBlue,
            backgroundImage: emp.profilePhoto != null ? NetworkImage(emp.profilePhoto!) : null,
            child: emp.profilePhoto == null ? Text(emp.fullName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emp.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kDarkSlate)),
              Text("${emp.empCode} • ${emp.designationTitle} (${emp.departmentName})", style: const TextStyle(fontSize: 9.5, color: kTextMuted)),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoSec("EMPLOYMENT & CAREER LIFECYCLE"),
              _infoRow("Status", emp.employmentStatusDisplay),
              _infoRow("Nature", emp.employmentNatureDisplay),
              _infoRow("Joined Date", emp.dateOfJoining),
              _infoRow("Work Location", emp.workLocation),
              _infoRow("Notice Period", "${emp.noticePeriodDays} Days"),
              const Divider(height: 16),
              _infoSec("FINANCIAL PARAMETERS"),
              _infoRow("Monthly CTC", NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(emp.monthlyCtc)),
              _infoRow("Annual CTC", NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(emp.annualCtc)),
              _infoRow("Bank", emp.bankName.isEmpty ? "N/A" : emp.bankName),
              _infoRow("Account Number", emp.bankAccountNumber.isEmpty ? "N/A" : emp.bankAccountNumber),
              _infoRow("IFSC", emp.bankIfscCode.isEmpty ? "N/A" : emp.bankIfscCode),
              _infoRow("UPI ID", emp.upiId.isEmpty ? "N/A" : emp.upiId),
              const Divider(height: 16),
              _infoSec("STATUTORY KYC & CONTACT"),
              _infoRow("Official Email", emp.officialEmail),
              _infoRow("Primary Phone", emp.phonePrimary),
              _infoRow("Emergency Contact", "${emp.emergencyContactPerson} (${emp.emergencyContactPhone})"),
              _infoRow("PAN", emp.panNumber.isEmpty ? "N/A" : emp.panNumber),
              _infoRow("Aadhaar", emp.aadhaarNumber.isEmpty ? "N/A" : "[Aadhaar Redacted]"),
              _infoRow("UAN (PF)", emp.uanNumber.isEmpty ? "N/A" : emp.uanNumber),
              _infoRow("Current Address", emp.currentAddress.isEmpty ? "N/A" : emp.currentAddress),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CLOSE")),
      ],
    ),
  );
}

Widget _infoSec(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(t, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: kBrandBlue, letterSpacing: 0.5)),
);

Widget _infoRow(String l, String v) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 2.5),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(l, style: const TextStyle(fontSize: 10.5, color: kTextMuted)),
      Text(v, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: kDarkSlate)),
    ],
  ),
);*/


import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';

// =============================================================================
// COLOR PALETTE & CONSTANTS
// =============================================================================
const Color kBrandBlue = Color(0xFF0066B3);
const Color kBrandRed = Color(0xFFD32027);
const Color kDarkSlate = Color(0xFF0B0E14);
const Color kTextMuted = Color(0xFF8B949E);
const Color kSurfaceBg = Color(0xFFF1F5F9);
const Color kCardBg = Color(0xFFF8FAFC);

const Map<String, String> kDocTypeOptions = {
  "AADHAAR_FRONT": "Aadhaar Card (Front Side)",
  "AADHAAR_BACK": "Aadhaar Card (Back Side)",
  "PAN_CARD": "PAN Card Copy",
  "VOTER_ID_FRONT": "Voter ID (Front Side)",
  "VOTER_ID_BACK": "Voter ID (Back Side)",
  "BANK_PASSBOOK": "Bank Passbook / Cheque",
  "RESUME_CV": "Curriculum Vitae / Resume",
  "EDUCATION_MARKSHEET": "Academic Certificate",
  "PREV_RELIEVING_LETTER": "Previous Relieving Letter",
  "PREV_EXPERIENCE_LETTER": "Previous Experience Letter",
  "PREV_PAYSLIP": "Previous Payslip",
  "SIGNED_OFFER_LETTER": "Signed Offer Letter",
  "OTHER": "Other Supporting Document",
};

// =============================================================================
// 1. DATA ENTITIES & MODELS
// =============================================================================
class AttachmentItem {
  final String id;
  final String employeeId;
  final String attachmentType;
  final String attachmentTypeDisplay;
  final String title;
  final String fileUrl;
  final String? notes;
  final String uploadedAt;

  const AttachmentItem({
    required this.id,
    required this.employeeId,
    required this.attachmentType,
    required this.attachmentTypeDisplay,
    required this.title,
    required this.fileUrl,
    this.notes,
    required this.uploadedAt,
  });

  factory AttachmentItem.fromJson(Map<String, dynamic> json) {
    return AttachmentItem(
      id: (json['id'] ?? '').toString(),
      employeeId: (json['employee'] ?? '').toString(),
      attachmentType: json['attachment_type'] ?? 'OTHER',
      attachmentTypeDisplay: json['attachment_type_display'] ?? json['attachment_type'] ?? 'Attachment',
      title: json['title'] ?? '',
      fileUrl: json['file'] ?? '',
      notes: json['notes'],
      uploadedAt: json['uploaded_at'] ?? '',
    );
  }
}

class EmployeeItem {
  final String id;
  final String empCode;
  final String firstName;
  final String middleName;
  final String lastName;
  final String fullName;
  final String officialEmail;
  final String personalEmail;
  final String phonePrimary;
  final String phoneSecondary;
  final String emergencyContactPerson;
  final String emergencyContactPhone;
  final String? dob;
  final String gender;
  final String maritalStatus;
  final String? bloodGroup;
  final String? profilePhoto;
  final String currentAddress;
  final String permanentAddress;
  final String panNumber;
  final String aadhaarNumber;
  final String uanNumber;
  final String pfNumber;
  final String esiNumber;
  final String? departmentId;
  final String departmentName;
  final String? designationId;
  final String designationTitle;
  final String employmentNature;
  final String employmentNatureDisplay;
  final String employmentStatus;
  final String employmentStatusDisplay;
  final String workLocation;
  final String dateOfJoining;
  final String? probationEndDate;
  final String? dateOfRelieving;
  final int noticePeriodDays;
  final double monthlyCtc;
  final double annualCtc;
  final String bankHolderName;
  final String bankName;
  final String bankAccountNumber;
  final String bankIfscCode;
  final String bankBranch;
  final String upiId;

  const EmployeeItem({
    required this.id,
    required this.empCode,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.fullName,
    required this.officialEmail,
    required this.personalEmail,
    required this.phonePrimary,
    required this.phoneSecondary,
    required this.emergencyContactPerson,
    required this.emergencyContactPhone,
    this.dob,
    required this.gender,
    required this.maritalStatus,
    this.bloodGroup,
    this.profilePhoto,
    required this.currentAddress,
    required this.permanentAddress,
    required this.panNumber,
    required this.aadhaarNumber,
    required this.uanNumber,
    required this.pfNumber,
    required this.esiNumber,
    this.departmentId,
    required this.departmentName,
    this.designationId,
    required this.designationTitle,
    required this.employmentNature,
    required this.employmentNatureDisplay,
    required this.employmentStatus,
    required this.employmentStatusDisplay,
    required this.workLocation,
    required this.dateOfJoining,
    this.probationEndDate,
    this.dateOfRelieving,
    required this.noticePeriodDays,
    required this.monthlyCtc,
    required this.annualCtc,
    required this.bankHolderName,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankIfscCode,
    required this.bankBranch,
    required this.upiId,
  });

  factory EmployeeItem.fromJson(Map<String, dynamic> json) {
    return EmployeeItem(
      id: (json['id'] ?? '').toString(),
      empCode: json['emp_code'] ?? 'N/A',
      firstName: json['first_name'] ?? '',
      middleName: json['middle_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      officialEmail: json['official_email'] ?? '',
      personalEmail: json['personal_email'] ?? '',
      phonePrimary: json['phone_primary'] ?? '',
      phoneSecondary: json['phone_secondary'] ?? '',
      emergencyContactPerson: json['emergency_contact_person'] ?? '',
      emergencyContactPhone: json['emergency_contact_phone'] ?? '',
      dob: json['dob'],
      gender: json['gender'] ?? 'MALE',
      maritalStatus: json['marital_status'] ?? 'SINGLE',
      bloodGroup: json['blood_group'],
      profilePhoto: json['profile_photo'],
      currentAddress: json['current_address'] ?? '',
      permanentAddress: json['permanent_address'] ?? '',
      panNumber: json['pan_number'] ?? '',
      aadhaarNumber: json['aadhaar_number'] ?? '',
      uanNumber: json['uan_number'] ?? '',
      pfNumber: json['pf_number'] ?? '',
      esiNumber: json['esi_number'] ?? '',
      departmentId: json['department']?.toString(),
      departmentName: json['department_name'] ?? 'General',
      designationId: json['designation']?.toString(),
      designationTitle: json['designation_title'] ?? 'Staff',
      employmentNature: json['employment_nature'] ?? 'FULL_TIME',
      employmentNatureDisplay: json['employment_nature_display'] ?? json['employment_nature'] ?? 'Full-time',
      employmentStatus: json['employment_status'] ?? 'ACTIVE',
      employmentStatusDisplay: json['employment_status_display'] ?? json['employment_status'] ?? 'Active',
      workLocation: json['work_location'] ?? 'Remote / In-Office',
      dateOfJoining: json['date_of_joining'] ?? '',
      probationEndDate: json['probation_end_date'],
      dateOfRelieving: json['date_of_relieving'],
      noticePeriodDays: int.tryParse((json['notice_period_days'] ?? 30).toString()) ?? 30,
      monthlyCtc: double.tryParse((json['monthly_ctc'] ?? 0).toString()) ?? 0.0,
      annualCtc: double.tryParse((json['annual_ctc'] ?? 0).toString()) ?? 0.0,
      bankHolderName: json['bank_account_holder_name'] ?? '',
      bankName: json['bank_name'] ?? '',
      bankAccountNumber: json['bank_account_number'] ?? '',
      bankIfscCode: json['bank_ifsc_code'] ?? '',
      bankBranch: json['bank_branch'] ?? '',
      upiId: json['upi_id'] ?? '',
    );
  }
}

// =============================================================================
// 2. REPOSITORY LAYER
// =============================================================================
class EmployeeDirectoryRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<EmployeeItem>> fetchEmployees({String? search, String? status}) async {
    final Map<String, dynamic> params = {};
    if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
    if (status != null && status != 'ALL') params['status'] = status;

    final res = await apiClient.get('/api/hrms/employees/', query: params);
    final dynamic data = res.data;
    List rawList = [];
    if (data is Map && data.containsKey('data')) {
      rawList = data['data'] as List;
    } else if (data is Map && data.containsKey('results')) {
      rawList = data['results'] as List;
    } else if (data is List) {
      rawList = data;
    }
    return rawList.map((e) => EmployeeItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> fetchStatistics() async {
    final res = await apiClient.get('/api/hrms/employees/statistics/');
    return res.data['data'] ?? {};
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchMeta() async {
    final deptsRes = await apiClient.get('/api/hrms/departments/');
    final desigsRes = await apiClient.get('/api/hrms/designations/');

    final List deptsData = (deptsRes.data is Map && deptsRes.data.containsKey('data'))
        ? deptsRes.data['data']
        : (deptsRes.data is Map && deptsRes.data.containsKey('results'))
        ? deptsRes.data['results']
        : deptsRes.data is List
        ? deptsRes.data
        : [];

    final List desigsData = (desigsRes.data is Map && desigsRes.data.containsKey('data'))
        ? desigsRes.data['data']
        : (desigsRes.data is Map && desigsRes.data.containsKey('results'))
        ? desigsRes.data['results']
        : desigsRes.data is List
        ? desigsRes.data
        : [];

    return {
      'departments': deptsData.cast<Map<String, dynamic>>(),
      'designations': desigsData.cast<Map<String, dynamic>>(),
    };
  }

  Future<void> updateEmployeeStatus(String id, String newStatus) async {
    await apiClient.patch('/api/hrms/employees/$id/', data: {'employment_status': newStatus});
  }

  Future<void> updateEmployeeDetails(String id, Map<String, dynamic> payload) async {
    await apiClient.patch('/api/hrms/employees/$id/', data: payload);
  }

  Future<void> deleteEmployee(String id) async {
    await apiClient.delete('/api/hrms/employees/$id/');
  }

  // QR Management APIs
  Future<Map<String, dynamic>> fetchEmployeeLoginQR(String employeeId) async {
    final res = await apiClient.get('/api/hrms/employees/$employeeId/login-qr/');
    return (res.data is Map<String, dynamic>) ? res.data : {};
  }

  Future<Map<String, dynamic>> refreshEmployeeLoginQR(String employeeId) async {
    final res = await apiClient.post('/api/hrms/employees/$employeeId/login-qr/');
    return (res.data is Map<String, dynamic>) ? res.data : {};
  }

  // Attachments Sub-APIs
  Future<List<AttachmentItem>> fetchAttachments(String employeeId) async {
    final res = await apiClient.get('/api/hrms/attachments/', query: {'employee_id': employeeId});
    final dynamic data = res.data;
    List rawList = [];
    if (data is Map && data.containsKey('data')) {
      rawList = data['data'] as List;
    } else if (data is Map && data.containsKey('results')) {
      rawList = data['results'] as List;
    } else if (data is List) {
      rawList = data;
    }
    return rawList.map((e) => AttachmentItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> uploadAttachment({
    required String employeeId,
    required String attachmentType,
    required String title,
    String? notes,
    PlatformFile? file,
  }) async {
    final Map<String, dynamic> map = {
      'employee': employeeId,
      'attachment_type': attachmentType,
      'title': title,
      'notes': notes ?? '',
    };

    if (file != null) {
      if (file.bytes != null) {
        map['file'] = dio.MultipartFile.fromBytes(file.bytes!, filename: file.name);
      } else if (file.path != null) {
        map['file'] = await dio.MultipartFile.fromFile(file.path!, filename: file.name);
      }
    }

    final dio.FormData formData = dio.FormData.fromMap(map);
    await apiClient.post('/api/hrms/attachments/', data: formData);
  }

  Future<void> deleteAttachment(String id) async {
    await apiClient.delete('/api/hrms/attachments/$id/');
  }
}

// =============================================================================
// 3. BLOC ENGINE
// =============================================================================
abstract class StaffMasterEvent {}

class LoadStaffDirectoryEvent extends StaffMasterEvent {}

class SearchStaffEvent extends StaffMasterEvent {
  final String query;
  SearchStaffEvent(this.query);
}

class FilterStaffByStatusEvent extends StaffMasterEvent {
  final String status;
  FilterStaffByStatusEvent(this.status);
}

class ChangeEmployeeStatusEvent extends StaffMasterEvent {
  final String id;
  final String newStatus;
  ChangeEmployeeStatusEvent({required this.id, required this.newStatus});
}

class EditEmployeeDetailsEvent extends StaffMasterEvent {
  final String id;
  final Map<String, dynamic> payload;
  EditEmployeeDetailsEvent({required this.id, required this.payload});
}

class DeleteEmployeeEvent extends StaffMasterEvent {
  final String id;
  DeleteEmployeeEvent(this.id);
}

abstract class StaffMasterState {}

class StaffMasterLoading extends StaffMasterState {}

class StaffMasterLoaded extends StaffMasterState {
  final List<EmployeeItem> employees;
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> departments;
  final List<Map<String, dynamic>> designations;
  final String activeStatusFilter;
  final String searchQuery;
  final bool isBusy;

  StaffMasterLoaded({
    required this.employees,
    required this.stats,
    required this.departments,
    required this.designations,
    this.activeStatusFilter = 'ALL',
    this.searchQuery = '',
    this.isBusy = false,
  });

  StaffMasterLoaded copyWith({
    List<EmployeeItem>? employees,
    Map<String, dynamic>? stats,
    List<Map<String, dynamic>>? departments,
    List<Map<String, dynamic>>? designations,
    String? activeStatusFilter,
    String? searchQuery,
    bool? isBusy,
  }) {
    return StaffMasterLoaded(
      employees: employees ?? this.employees,
      stats: stats ?? this.stats,
      departments: departments ?? this.departments,
      designations: designations ?? this.designations,
      activeStatusFilter: activeStatusFilter ?? this.activeStatusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isBusy: isBusy ?? this.isBusy,
    );
  }
}

class StaffMasterError extends StaffMasterState {
  final String message;
  StaffMasterError(this.message);
}

class StaffMasterBloc extends Bloc<StaffMasterEvent, StaffMasterState> {
  final EmployeeDirectoryRepository repository;
  List<EmployeeItem> _cachedList = [];
  Map<String, dynamic> _cachedStats = {};
  List<Map<String, dynamic>> _cachedDepts = [];
  List<Map<String, dynamic>> _cachedDesigs = [];
  String _currentStatus = 'ALL';
  String _currentSearch = '';

  StaffMasterBloc(this.repository) : super(StaffMasterLoading()) {
    on<LoadStaffDirectoryEvent>((event, emit) async {
      try {
        final results = await Future.wait([
          repository.fetchEmployees(),
          repository.fetchStatistics(),
          repository.fetchMeta(),
        ]);

        _cachedList = results[0] as List<EmployeeItem>;
        _cachedStats = results[1] as Map<String, dynamic>;
        final meta = results[2] as Map<String, List<Map<String, dynamic>>>;
        _cachedDepts = meta['departments'] ?? [];
        _cachedDesigs = meta['designations'] ?? [];

        _applyFilters(emit);
      } catch (e) {
        emit(StaffMasterError("Failed to fetch staff directory: $e"));
      }
    });

    on<SearchStaffEvent>((event, emit) {
      _currentSearch = event.query.toLowerCase().trim();
      _applyFilters(emit);
    });

    on<FilterStaffByStatusEvent>((event, emit) {
      _currentStatus = event.status;
      _applyFilters(emit);
    });

    on<ChangeEmployeeStatusEvent>((event, emit) async {
      if (state is StaffMasterLoaded) {
        emit((state as StaffMasterLoaded).copyWith(isBusy: true));
        try {
          await repository.updateEmployeeStatus(event.id, event.newStatus);
          add(LoadStaffDirectoryEvent());
        } catch (e) {
          emit(StaffMasterError("Status change failed: $e"));
        }
      }
    });

    on<EditEmployeeDetailsEvent>((event, emit) async {
      if (state is StaffMasterLoaded) {
        emit((state as StaffMasterLoaded).copyWith(isBusy: true));
        try {
          await repository.updateEmployeeDetails(event.id, event.payload);
          add(LoadStaffDirectoryEvent());
        } catch (e) {
          emit(StaffMasterError("Update failed: $e"));
        }
      }
    });

    on<DeleteEmployeeEvent>((event, emit) async {
      if (state is StaffMasterLoaded) {
        emit((state as StaffMasterLoaded).copyWith(isBusy: true));
        try {
          await repository.deleteEmployee(event.id);
          add(LoadStaffDirectoryEvent());
        } catch (e) {
          emit(StaffMasterError("Delete failed: $e"));
        }
      }
    });
  }

  void _applyFilters(Emitter<StaffMasterState> emit) {
    final filtered = _cachedList.where((emp) {
      final matchSearch = emp.fullName.toLowerCase().contains(_currentSearch) ||
          emp.empCode.toLowerCase().contains(_currentSearch) ||
          emp.officialEmail.toLowerCase().contains(_currentSearch) ||
          emp.phonePrimary.contains(_currentSearch);

      final matchStatus = _currentStatus == 'ALL' || emp.employmentStatus.toUpperCase() == _currentStatus.toUpperCase();

      return matchSearch && matchStatus;
    }).toList();

    emit(StaffMasterLoaded(
      employees: filtered,
      stats: _cachedStats,
      departments: _cachedDepts,
      designations: _cachedDesigs,
      activeStatusFilter: _currentStatus,
      searchQuery: _currentSearch,
      isBusy: false,
    ));
  }
}

// =============================================================================
// 4. MAIN CANVAS VIEW
// =============================================================================
class StaffMasterScreen extends StatelessWidget {
  const StaffMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 900;

    return BlocProvider(
      create: (context) => StaffMasterBloc(EmployeeDirectoryRepository())..add(LoadStaffDirectoryEvent()),
      child: Scaffold(
        backgroundColor: kSurfaceBg,
        body: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(context, isMobile),
              const SizedBox(height: 14),
              _buildMetricsBar(isMobile),
              const SizedBox(height: 14),
              Expanded(
                child: BlocConsumer<StaffMasterBloc, StaffMasterState>(
                  listener: (context, state) {
                    if (state is StaffMasterError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message), backgroundColor: kBrandRed, behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is StaffMasterLoading) {
                      return const Center(child: CircularProgressIndicator(color: kBrandBlue, strokeWidth: 2));
                    }
                    if (state is StaffMasterLoaded) {
                      return _buildTableContainer(context, state, isMobile);
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "STAFF RECORDS DIRECTORY & ACCESS VAULT",
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: kDarkSlate, letterSpacing: 0.6),
            ),
            SizedBox(height: 2),
            Text(
              "Manage personnel profiles, digital QR access cards, KYC attachments & lifecycle",
              style: TextStyle(fontSize: 9.5, color: kTextMuted, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => context.go('/staff_create'),
          icon: const Icon(Icons.person_add_rounded, size: 14),
          label: Text(
            isMobile ? "ADD" : "ONBOARD NEW EMPLOYEE",
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.4),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrandBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsBar(bool isMobile) {
    return BlocBuilder<StaffMasterBloc, StaffMasterState>(
      builder: (context, state) {
        int total = 0;
        int active = 0;
        int onNotice = 0;
        String liability = "₹0.00";

        if (state is StaffMasterLoaded) {
          total = state.stats['total_employees'] ?? 0;
          active = state.stats['active_employees'] ?? 0;
          onNotice = state.stats['on_notice'] ?? 0;
          liability = NumberFormat.currency(locale: 'en_IN', symbol: '₹')
              .format(double.tryParse((state.stats['monthly_payout_liability'] ?? 0).toString()) ?? 0);
        }

        final items = [
          _metricCard("TOTAL HEADCOUNT", "$total", Icons.people_outline_rounded, kBrandBlue),
          _metricCard("ACTIVE ON ROLL", "$active", Icons.verified_user_outlined, const Color(0xFF10B981)),
          _metricCard("SERVING NOTICE", "$onNotice", Icons.hourglass_top_rounded, const Color(0xFFF59E0B)),
          _metricCard("MONTHLY CTC LIABILITY", liability, Icons.account_balance_wallet_outlined, kBrandRed),
        ];

        if (isMobile) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: items.map((w) => Padding(padding: const EdgeInsets.only(right: 8), child: w)).toList()),
          );
        }

        return Row(children: items.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: w))).toList());
      },
    );
  }

  Widget _metricCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 8, color: kTextMuted, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
              const SizedBox(height: 2),
              Text(val, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: kDarkSlate)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTableContainer(BuildContext context, StaffMasterLoaded state, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildFilterSearchStrip(context, state),
          const Divider(height: 1),
          Expanded(
            child: state.employees.isEmpty
                ? const Center(child: Text("No staff members found matching criteria.", style: TextStyle(color: kTextMuted, fontSize: 11.5)))
                : isMobile
                ? _buildMobileView(context, state)
                : _buildDesktopTableView(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSearchStrip(BuildContext context, StaffMasterLoaded state) {
    final bloc = context.read<StaffMasterBloc>();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                style: const TextStyle(fontSize: 11.5),
                onChanged: (v) => bloc.add(SearchStaffEvent(v)),
                decoration: const InputDecoration(
                  hintText: "Search by Emp Code, Name, Email, Phone...",
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                  prefixIcon: Icon(Icons.search, size: 15, color: kBrandBlue),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(bottom: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Wrap(
            spacing: 6,
            children: ["ALL", "ACTIVE", "ON_NOTICE", "RELIEVED", "TERMINATED"].map((statusKey) {
              final isSelected = state.activeStatusFilter == statusKey;
              return ChoiceChip(
                label: Text(statusKey.replaceAll("_", " "), style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : kDarkSlate)),
                selected: isSelected,
                selectedColor: kBrandBlue,
                backgroundColor: kSurfaceBg,
                onSelected: (_) => bloc.add(FilterStaffByStatusEvent(statusKey)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                showCheckmark: false,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTableView(BuildContext context, StaffMasterLoaded state) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: kCardBg,
          child: Row(
            children: [
              _hCell("EMPLOYEE IDENTITY", 5),
              _hCell("ORGANIZATION & ROLE", 4),
              _hCell("COMMUNICATION MATRIX", 4),
              _hCell("MONTHLY COMPENSATION", 3),
              _hCell("STATUS", 3),
              _hCell("ACTIONS", 5, true),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: state.employees.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (ctx, i) {
              final emp = state.employees[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          // Interactive Avatar with Full Image Zoom Dialog
                          Tooltip(
                            message: "Click to preview full photo",
                            child: InkWell(
                              onTap: () => showFullAvatarPreview(context, emp.profilePhoto, emp.fullName),
                              borderRadius: BorderRadius.circular(20),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: kBrandBlue,
                                backgroundImage: emp.profilePhoto != null ? NetworkImage(emp.profilePhoto!) : null,
                                child: emp.profilePhoto == null
                                    ? Text(emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : "E", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(emp.fullName, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: kDarkSlate)),
                                Text(emp.empCode, style: const TextStyle(fontSize: 9, color: kBrandBlue, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emp.designationTitle, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kDarkSlate)),
                          Text(emp.departmentName, style: const TextStyle(fontSize: 9, color: kTextMuted)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emp.officialEmail, style: const TextStyle(fontSize: 10.5, color: kDarkSlate), overflow: TextOverflow.ellipsis),
                          Text(emp.phonePrimary, style: const TextStyle(fontSize: 9, color: kTextMuted)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(emp.monthlyCtc),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kDarkSlate),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Align(alignment: Alignment.centerLeft, child: _statusBadge(emp.employmentStatus)),
                    ),
                    Expanded(
                      flex: 5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 🌟 QR Code Login Card
                          _actionBtn(
                            Icons.qr_code_2_rounded,
                            "Digital Access & Login QR",
                                () => showEmployeeLoginQRModal(context, emp),
                            color: const Color(0xFF0284C7),
                          ),
                          const SizedBox(width: 4),
                          _actionBtn(Icons.folder_shared_outlined, "KYC & Attachments Vault", () => showEmployeeAttachmentVaultModal(context, emp), color: const Color(0xFF8B5CF6)),
                          const SizedBox(width: 4),
                          _actionBtn(Icons.visibility_outlined, "View Profile", () => showEmployeeProfileModal(context, emp)),
                          const SizedBox(width: 4),
                          _actionBtn(Icons.edit_note_rounded, "Edit Employee", () => showEmployeeEditModal(context, state, emp)),
                          const SizedBox(width: 4),
                          _actionBtn(
                            emp.employmentStatus == "ACTIVE" ? Icons.block_flipped : Icons.check_circle_outline,
                            emp.employmentStatus == "ACTIVE" ? "Mark Inactive" : "Mark Active",
                                () => _confirmStatusChange(context, emp),
                            color: emp.employmentStatus == "ACTIVE" ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          _actionBtn(Icons.delete_outline_rounded, "Delete Profile", () => _confirmDelete(context, emp), color: kBrandRed),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView(BuildContext context, StaffMasterLoaded state) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.employees.length,
      itemBuilder: (ctx, i) {
        final emp = state.employees[i];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => showFullAvatarPreview(context, emp.profilePhoto, emp.fullName),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: kBrandBlue,
                            backgroundImage: emp.profilePhoto != null ? NetworkImage(emp.profilePhoto!) : null,
                            child: emp.profilePhoto == null ? Text(emp.fullName[0], style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)) : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(emp.empCode, style: const TextStyle(fontSize: 9.5, color: kBrandBlue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    _statusBadge(emp.employmentStatus),
                  ],
                ),
                const SizedBox(height: 4),
                Text(emp.fullName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: kDarkSlate)),
                Text("${emp.designationTitle} • ${emp.departmentName}", style: const TextStyle(fontSize: 10, color: kTextMuted)),
                const Divider(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(emp.officialEmail, style: const TextStyle(fontSize: 10, color: kDarkSlate)),
                    Text(NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(emp.monthlyCtc), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.qr_code_2_rounded, size: 16, color: Color(0xFF0284C7)),
                      tooltip: "Login QR",
                      onPressed: () => showEmployeeLoginQRModal(context, emp),
                    ),
                    TextButton.icon(
                      onPressed: () => showEmployeeAttachmentVaultModal(context, emp),
                      icon: const Icon(Icons.folder_shared_outlined, size: 13, color: Color(0xFF8B5CF6)),
                      label: const Text("VAULT", style: TextStyle(fontSize: 9.5, color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
                    ),
                    TextButton.icon(onPressed: () => showEmployeeProfileModal(context, emp), icon: const Icon(Icons.visibility, size: 12), label: const Text("VIEW", style: TextStyle(fontSize: 9.5))),
                    TextButton.icon(onPressed: () => showEmployeeEditModal(context, state, emp), icon: const Icon(Icons.edit, size: 12), label: const Text("EDIT", style: TextStyle(fontSize: 9.5))),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 14, color: kBrandRed), onPressed: () => _confirmDelete(context, emp)),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;

    if (status == "ACTIVE") {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    } else if (status == "ON_NOTICE") {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
    } else if (status == "RELIEVED" || status == "TERMINATED") {
      bg = kBrandRed.withValues(alpha: 0.08);
      fg = kBrandRed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3)),
      child: Text(
        status.replaceAll("_", " "),
        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: fg, letterSpacing: 0.3),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String tip, VoidCallback onTap, {Color? color}) {
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: (color ?? Colors.blueGrey).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
          child: Icon(icon, size: 13.5, color: color ?? Colors.blueGrey.shade700),
        ),
      ),
    );
  }

  Widget _hCell(String t, int f, [bool r = false]) => Expanded(
    flex: f,
    child: Text(t, textAlign: r ? TextAlign.right : TextAlign.left, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: kTextMuted, letterSpacing: 0.5)),
  );

  void _confirmStatusChange(BuildContext context, EmployeeItem emp) {
    final bloc = context.read<StaffMasterBloc>();
    final String nextStatus = emp.employmentStatus == "ACTIVE" ? "RELIEVED" : "ACTIVE";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Change Status to $nextStatus?"),
        content: Text("Are you sure you want to mark ${emp.fullName} (${emp.empCode}) as $nextStatus?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: nextStatus == "ACTIVE" ? const Color(0xFF10B981) : const Color(0xFFF59E0B), foregroundColor: Colors.white),
            onPressed: () {
              bloc.add(ChangeEmployeeStatusEvent(id: emp.id, newStatus: nextStatus));
              Navigator.pop(ctx);
            },
            child: Text("MARK AS $nextStatus"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, EmployeeItem emp) {
    final bloc = context.read<StaffMasterBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: kBrandRed, size: 18),
            SizedBox(width: 8),
            Text("Delete Employee Record?", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrandRed)),
          ],
        ),
        content: Text("Are you sure you want to purge ${emp.fullName} (${emp.empCode})? This action cannot be reversed.", style: const TextStyle(fontSize: 11.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kBrandRed, foregroundColor: Colors.white),
            onPressed: () {
              bloc.add(DeleteEmployeeEvent(emp.id));
              Navigator.pop(ctx);
            },
            child: const Text("DELETE RECORD"),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 5. FULL IMAGE AVATAR ZOOM MODAL
// =============================================================================
void showFullAvatarPreview(BuildContext context, String? photoUrl, String fullName) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          width: 380,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 4)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        fullName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kDarkSlate),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? Image.network(
                    photoUrl,
                    height: 320,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (c, child, p) => p == null ? child : const Center(heightFactor: 4, child: CircularProgressIndicator(strokeWidth: 2)),
                    errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(fullName),
                  )
                      : _buildAvatarPlaceholder(fullName),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildAvatarPlaceholder(String name) {
  return Container(
    height: 260,
    color: kBrandBlue.withValues(alpha: 0.08),
    alignment: Alignment.center,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.account_circle_outlined, size: 72, color: kBrandBlue.withValues(alpha: 0.6)),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kDarkSlate)),
        const SizedBox(height: 2),
        const Text("No profile photo uploaded", style: TextStyle(fontSize: 10, color: kTextMuted)),
      ],
    ),
  );
}

// =============================================================================
// 6. EMPLOYEE DIGITAL ACCESS & QR CODE MODAL
// =============================================================================
void showEmployeeLoginQRModal(BuildContext context, EmployeeItem emp) {
  showDialog(
    context: context,
    builder: (dialogCtx) => EmployeeLoginQRDialog(emp: emp),
  );
}

class EmployeeLoginQRDialog extends StatefulWidget {
  final EmployeeItem emp;
  const EmployeeLoginQRDialog({super.key, required this.emp});

  @override
  State<EmployeeLoginQRDialog> createState() => _EmployeeLoginQRDialogState();
}

class _EmployeeLoginQRDialogState extends State<EmployeeLoginQRDialog> {
  final EmployeeDirectoryRepository _repo = EmployeeDirectoryRepository();
  bool _isLoading = true;
  bool _isResetting = false;
  String? _qrToken;

  @override
  void initState() {
    super.initState();
    _fetchQR();
  }

  Future<void> _fetchQR() async {
    setState(() => _isLoading = true);
    try {
      final res = await _repo.fetchEmployeeLoginQR(widget.emp.id);
      if (mounted) setState(() => _qrToken = res['qr_token']?.toString());
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _resetQR() async {
    setState(() => _isResetting = true);
    try {
      final res = await _repo.refreshEmployeeLoginQR(widget.emp.id);
      if (mounted) {
        setState(() => _qrToken = res['qr_token']?.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("QR Access Token revoked and renewed successfully."), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Reset failed: $e"), backgroundColor: kBrandRed));
    }
    if (mounted) setState(() => _isResetting = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.all(20),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("SOFTWING HRMS", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.8, color: kBrandBlue)),
                    Text("DIGITAL ACCESS PASS", style: TextStyle(color: kTextMuted, fontSize: 8.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 16), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ],
            ),
            const Divider(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300, width: 1.2),
              ),
              child: _isLoading
                  ? const SizedBox(width: 170, height: 170, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: kBrandBlue)))
                  : (_qrToken == null || _qrToken!.isEmpty)
                  ? const SizedBox(width: 170, height: 170, child: Center(child: Text("QR Not Available", style: TextStyle(fontSize: 11, color: kTextMuted))))
                  : QrImageView(
                data: _qrToken!,
                version: QrVersions.auto,
                size: 170.0,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: kDarkSlate),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: kDarkSlate),
              ),
            ),
            const SizedBox(height: 14),
            Text(widget.emp.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: kDarkSlate)),
            const SizedBox(height: 2),
            Text("${widget.emp.empCode} • ${widget.emp.designationTitle}", style: const TextStyle(fontSize: 10, color: kBrandBlue, fontWeight: FontWeight.bold)),
            Text("Department: ${widget.emp.departmentName}", style: const TextStyle(fontSize: 9.5, color: kTextMuted)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: kSurfaceBg, borderRadius: BorderRadius.circular(4)),
              child: const Text(
                "Scan using Employee Mobile App on ANY device to authenticate instantly.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 8.5, color: kTextMuted, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: (_isLoading || _isResetting) ? null : _resetQR,
          icon: _isResetting
              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: kBrandRed))
              : const Icon(Icons.refresh_rounded, size: 14, color: kBrandRed),
          label: const Text("RESET ACCESS QR", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kBrandRed)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kBrandBlue, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context),
          child: const Text("DONE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// =============================================================================
// 7. ATTACHMENT VAULT MODAL (INLINE KYC REPOSITORY & UPLOAD)
// =============================================================================
void showEmployeeAttachmentVaultModal(BuildContext context, EmployeeItem emp) {
  showDialog(
    context: context,
    builder: (dialogCtx) => EmployeeAttachmentVaultDialog(emp: emp),
  );
}

class EmployeeAttachmentVaultDialog extends StatefulWidget {
  final EmployeeItem emp;
  const EmployeeAttachmentVaultDialog({super.key, required this.emp});

  @override
  State<EmployeeAttachmentVaultDialog> createState() => _EmployeeAttachmentVaultDialogState();
}

class _EmployeeAttachmentVaultDialogState extends State<EmployeeAttachmentVaultDialog> {
  final EmployeeDirectoryRepository _repo = EmployeeDirectoryRepository();
  List<AttachmentItem> _attachments = [];
  bool _isLoading = true;
  bool _isUploading = false;

  String _selectedDocType = "AADHAAR_FRONT";
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  PlatformFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = kDocTypeOptions[_selectedDocType] ?? '';
    _loadVault();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVault() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repo.fetchAttachments(widget.emp.id);
      if (mounted) setState(() => _attachments = list);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _uploadDoc() async {
    if (_titleCtrl.text.trim().isEmpty || _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title and File are required."), backgroundColor: kBrandRed));
      return;
    }

    setState(() => _isUploading = true);
    try {
      await _repo.uploadAttachment(
        employeeId: widget.emp.id,
        attachmentType: _selectedDocType,
        title: _titleCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        file: _pickedFile,
      );
      _notesCtrl.clear();
      _pickedFile = null;
      await _loadVault();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload error: $e"), backgroundColor: kBrandRed));
    }
    if (mounted) setState(() => _isUploading = false);
  }

  Future<void> _deleteDoc(String id) async {
    setState(() => _isLoading = true);
    try {
      await _repo.deleteAttachment(id);
      await _loadVault();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _openFileUrl(String url) async {
    if (url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open file URL."), backgroundColor: kBrandRed));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 3.5, height: 18, color: const Color(0xFF8B5CF6)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("KYC Vault: ${widget.emp.fullName}", style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900)),
                  Text("${widget.emp.empCode} • ${widget.emp.designationTitle} (${widget.emp.departmentName})", style: const TextStyle(fontSize: 9.5, color: kTextMuted)),
                ],
              ),
            ],
          ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 18)),
        ],
      ),
      content: SizedBox(
        width: 820,
        height: 500,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Upload Form
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("UPLOAD NEW DOCUMENT", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kDarkSlate, letterSpacing: 0.5)),
                      const Divider(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedDocType,
                        style: const TextStyle(fontSize: 11.5, color: kDarkSlate),
                        decoration: _inputDeco("DOCUMENT CLASSIFICATION *"),
                        items: kDocTypeOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 11)))).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _selectedDocType = v;
                              _titleCtrl.text = kDocTypeOptions[v] ?? '';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(controller: _titleCtrl, style: const TextStyle(fontSize: 11.5), decoration: _inputDeco("DOCUMENT TITLE *")),
                      const SizedBox(height: 10),
                      TextFormField(controller: _notesCtrl, maxLines: 2, style: const TextStyle(fontSize: 11.5), decoration: _inputDeco("REMARKS (OPTIONAL)")),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () async {
                          final FilePickerResult? res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'], withData: true);
                          if (res != null && res.files.isNotEmpty) setState(() => _pickedFile = res.files.first);
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade300)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_upload_outlined, size: 16, color: kBrandBlue),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _pickedFile != null ? _pickedFile!.name : "CHOOSE PDF / IMAGE",
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: kBrandBlue),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _uploadDoc,
                          icon: _isUploading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5)) : const Icon(Icons.check_circle_outline, size: 14),
                          label: Text(_isUploading ? "UPLOADING..." : "COMMIT TO VAULT", style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(backgroundColor: kBrandBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Right: Stored Attachments List
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("SAVED ATTACHMENTS", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: kDarkSlate, letterSpacing: 0.5)),
                        Text("${_attachments.length} DOCUMENTS", style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: kBrandBlue)),
                      ],
                    ),
                    const Divider(height: 16),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: kBrandBlue, strokeWidth: 2))
                          : _attachments.isEmpty
                          ? const Center(child: Text("No documents in vault yet. Fresher records need no prior experience letters.", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: kTextMuted)))
                          : ListView.separated(
                        itemCount: _attachments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final doc = _attachments[i];
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: kBrandBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                                  child: const Icon(Icons.file_present_rounded, color: kBrandBlue, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(doc.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kDarkSlate), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text(doc.attachmentTypeDisplay, style: const TextStyle(fontSize: 9, color: kBrandBlue, fontWeight: FontWeight.w600)),
                                      if (doc.notes != null && doc.notes!.isNotEmpty) Text(doc.notes!, style: const TextStyle(fontSize: 8.5, color: kTextMuted), maxLines: 1),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.open_in_new_rounded, size: 15, color: kBrandBlue),
                                  tooltip: "Open / Download",
                                  onPressed: () => _openFileUrl(doc.fileUrl),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 15, color: kBrandRed),
                                  tooltip: "Delete",
                                  onPressed: () => _deleteDoc(doc.id),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String lbl) => InputDecoration(
    labelText: lbl,
    labelStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    isDense: true,
    filled: true,
    fillColor: Colors.white,
  );
}

// =============================================================================
// 8. ENTERPRISE TABBED MODAL: EDIT EMPLOYEE PROFILE
// =============================================================================
void showEmployeeEditModal(BuildContext context, StaffMasterLoaded state, EmployeeItem emp) {
  final bloc = context.read<StaffMasterBloc>();
  showDialog(
    context: context,
    builder: (dialogCtx) => EmployeeEditDialog(
      state: state,
      emp: emp,
      onSave: (payload) => bloc.add(EditEmployeeDetailsEvent(id: emp.id, payload: payload)),
    ),
  );
}

class EmployeeEditDialog extends StatefulWidget {
  final StaffMasterLoaded state;
  final EmployeeItem emp;
  final Function(Map<String, dynamic>) onSave;

  const EmployeeEditDialog({super.key, required this.state, required this.emp, required this.onSave});

  @override
  State<EmployeeEditDialog> createState() => _EmployeeEditDialogState();
}

class _EmployeeEditDialogState extends State<EmployeeEditDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Personal
  late TextEditingController _firstNameCtrl;
  late TextEditingController _middleNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _officialEmailCtrl;
  late TextEditingController _personalEmailCtrl;
  late TextEditingController _phonePrimaryCtrl;
  late TextEditingController _phoneSecondaryCtrl;
  late TextEditingController _emergencyPersonCtrl;
  late TextEditingController _emergencyPhoneCtrl;

  // Career
  String? _selectedDeptId;
  String? _selectedDesigId;
  late String _employmentNature;
  late String _employmentStatus;
  late TextEditingController _workLocationCtrl;
  late TextEditingController _noticeDaysCtrl;

  // Financial
  late TextEditingController _monthlyCtcCtrl;
  late TextEditingController _annualCtcCtrl;
  late TextEditingController _holderNameCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _accNoCtrl;
  late TextEditingController _ifscCtrl;
  late TextEditingController _branchCtrl;
  late TextEditingController _upiCtrl;

  // Statutory
  late TextEditingController _panCtrl;
  late TextEditingController _aadhaarCtrl;
  late TextEditingController _uanCtrl;
  late TextEditingController _pfCtrl;
  late TextEditingController _esiCtrl;
  late TextEditingController _currentAddrCtrl;
  late TextEditingController _permAddrCtrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _firstNameCtrl = TextEditingController(text: widget.emp.firstName);
    _middleNameCtrl = TextEditingController(text: widget.emp.middleName);
    _lastNameCtrl = TextEditingController(text: widget.emp.lastName);
    _officialEmailCtrl = TextEditingController(text: widget.emp.officialEmail);
    _personalEmailCtrl = TextEditingController(text: widget.emp.personalEmail);
    _phonePrimaryCtrl = TextEditingController(text: widget.emp.phonePrimary);
    _phoneSecondaryCtrl = TextEditingController(text: widget.emp.phoneSecondary);
    _emergencyPersonCtrl = TextEditingController(text: widget.emp.emergencyContactPerson);
    _emergencyPhoneCtrl = TextEditingController(text: widget.emp.emergencyContactPhone);

    _selectedDeptId = widget.emp.departmentId;
    _selectedDesigId = widget.emp.designationId;
    _employmentNature = widget.emp.employmentNature;
    _employmentStatus = widget.emp.employmentStatus;
    _workLocationCtrl = TextEditingController(text: widget.emp.workLocation);
    _noticeDaysCtrl = TextEditingController(text: widget.emp.noticePeriodDays.toString());

    _monthlyCtcCtrl = TextEditingController(text: widget.emp.monthlyCtc.toString());
    _annualCtcCtrl = TextEditingController(text: widget.emp.annualCtc.toString());
    _holderNameCtrl = TextEditingController(text: widget.emp.bankHolderName);
    _bankNameCtrl = TextEditingController(text: widget.emp.bankName);
    _accNoCtrl = TextEditingController(text: widget.emp.bankAccountNumber);
    _ifscCtrl = TextEditingController(text: widget.emp.bankIfscCode);
    _branchCtrl = TextEditingController(text: widget.emp.bankBranch);
    _upiCtrl = TextEditingController(text: widget.emp.upiId);

    _panCtrl = TextEditingController(text: widget.emp.panNumber);
    _aadhaarCtrl = TextEditingController(text: widget.emp.aadhaarNumber);
    _uanCtrl = TextEditingController(text: widget.emp.uanNumber);
    _pfCtrl = TextEditingController(text: widget.emp.pfNumber);
    _esiCtrl = TextEditingController(text: widget.emp.esiNumber);
    _currentAddrCtrl = TextEditingController(text: widget.emp.currentAddress);
    _permAddrCtrl = TextEditingController(text: widget.emp.permanentAddress);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _officialEmailCtrl.dispose();
    _personalEmailCtrl.dispose();
    _phonePrimaryCtrl.dispose();
    _phoneSecondaryCtrl.dispose();
    _emergencyPersonCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _workLocationCtrl.dispose();
    _noticeDaysCtrl.dispose();
    _monthlyCtcCtrl.dispose();
    _annualCtcCtrl.dispose();
    _holderNameCtrl.dispose();
    _bankNameCtrl.dispose();
    _accNoCtrl.dispose();
    _ifscCtrl.dispose();
    _branchCtrl.dispose();
    _upiCtrl.dispose();
    _panCtrl.dispose();
    _aadhaarCtrl.dispose();
    _uanCtrl.dispose();
    _pfCtrl.dispose();
    _esiCtrl.dispose();
    _currentAddrCtrl.dispose();
    _permAddrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDesigs = _selectedDeptId == null
        ? widget.state.designations
        : widget.state.designations.where((d) => d['department'].toString() == _selectedDeptId).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Row(
        children: [
          Container(width: 3.5, height: 18, color: kBrandBlue),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Edit Personnel Record: ${widget.emp.empCode}", style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900)),
              Text(widget.emp.fullName, style: const TextStyle(fontSize: 9.5, color: kTextMuted)),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 780,
        height: 480,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: kBrandBlue,
              unselectedLabelColor: Colors.blueGrey,
              indicatorColor: kBrandBlue,
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "1. Personal Matrix"),
                Tab(text: "2. Career & Hierarchy"),
                Tab(text: "3. Financial & Bank"),
                Tab(text: "4. Statutory KYC"),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Form(
                key: _formKey,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Personal
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          _row([
                            _input(_firstNameCtrl, "FIRST NAME *", isRequired: true),
                            _input(_middleNameCtrl, "MIDDLE NAME"),
                            _input(_lastNameCtrl, "LAST NAME *", isRequired: true),
                          ]),
                          const SizedBox(height: 10),
                          _row([
                            _input(_officialEmailCtrl, "OFFICIAL EMAIL *", isRequired: true),
                            _input(_personalEmailCtrl, "PERSONAL EMAIL"),
                          ]),
                          const SizedBox(height: 10),
                          _row([
                            _input(_phonePrimaryCtrl, "PRIMARY CONTACT PHONE *", isRequired: true),
                            _input(_phoneSecondaryCtrl, "SECONDARY PHONE"),
                          ]),
                          const SizedBox(height: 10),
                          _row([
                            _input(_emergencyPersonCtrl, "EMERGENCY CONTACT PERSON"),
                            _input(_emergencyPhoneCtrl, "EMERGENCY PHONE NUMBER"),
                          ]),
                        ],
                      ),
                    ),

                    // Tab 2: Career
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          _row([
                            DropdownButtonFormField<String>(
                              value: _selectedDeptId,
                              decoration: _inputDeco("DEPARTMENT"),
                              items: widget.state.departments.map((d) => DropdownMenuItem(value: d['id'].toString(), child: Text(d['name']))).toList(),
                              onChanged: (v) => setState(() {
                                _selectedDeptId = v;
                                _selectedDesigId = null;
                              }),
                            ),
                            DropdownButtonFormField<String>(
                              value: _selectedDesigId,
                              decoration: _inputDeco("DESIGNATION"),
                              items: filteredDesigs.map((d) => DropdownMenuItem(value: d['id'].toString(), child: Text(d['title']))).toList(),
                              onChanged: (v) => setState(() => _selectedDesigId = v),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          _row([
                            DropdownButtonFormField<String>(
                              value: _employmentStatus,
                              decoration: _inputDeco("EMPLOYMENT STATUS"),
                              items: ["ACTIVE", "ON_NOTICE", "RELIEVED", "TERMINATED", "ABSCONDED"]
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll("_", " "))))
                                  .toList(),
                              onChanged: (v) => setState(() => _employmentStatus = v!),
                            ),
                            DropdownButtonFormField<String>(
                              value: _employmentNature,
                              decoration: _inputDeco("EMPLOYMENT NATURE"),
                              items: ["FULL_TIME", "PROBATION", "CONTRACT", "INTERN", "FREELANCE"]
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s.replaceAll("_", " "))))
                                  .toList(),
                              onChanged: (v) => setState(() => _employmentNature = v!),
                            ),
                          ]),
                          const SizedBox(height: 10),
                          _row([
                            _input(_workLocationCtrl, "WORK LOCATION"),
                            _input(_noticeDaysCtrl, "NOTICE PERIOD (DAYS)", isNumber: true),
                          ]),
                        ],
                      ),
                    ),

                    // Tab 3: Financial
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          _row([
                            _input(_monthlyCtcCtrl, "MONTHLY CTC (₹) *", isRequired: true, isNumber: true, onChanged: (v) {
                              final m = double.tryParse(v) ?? 0.0;
                              _annualCtcCtrl.text = (m * 12).toStringAsFixed(2);
                            }),
                            _input(_annualCtcCtrl, "ANNUAL CTC (₹)", isNumber: true, isReadOnly: true),
                            _input(_upiCtrl, "UPI ID"),
                          ]),
                          const SizedBox(height: 10),
                          _row([
                            _input(_holderNameCtrl, "ACCOUNT HOLDER NAME"),
                            _input(_bankNameCtrl, "BANK NAME"),
                            _input(_accNoCtrl, "ACCOUNT NUMBER"),
                          ]),
                          const SizedBox(height: 10),
                          _row([
                            _input(_ifscCtrl, "IFSC CODE"),
                            _input(_branchCtrl, "BRANCH NAME"),
                          ]),
                        ],
                      ),
                    ),

                    // Tab 4: Statutory
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          _row([
                            _input(_panCtrl, "PAN CARD NUMBER"),
                            _input(_aadhaarCtrl, "AADHAAR NUMBER"),
                            _input(_uanCtrl, "UAN NUMBER"),
                          ]),
                          const SizedBox(height: 10),
                          _row([
                            _input(_pfCtrl, "PF NUMBER"),
                            _input(_esiCtrl, "ESI NUMBER"),
                          ]),
                          const SizedBox(height: 10),
                          _row([
                            _input(_currentAddrCtrl, "CURRENT ADDRESS", maxLines: 2),
                            _input(_permAddrCtrl, "PERMANENT ADDRESS", maxLines: 2),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kBrandBlue, foregroundColor: Colors.white),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            widget.onSave({
              "first_name": _firstNameCtrl.text.trim(),
              "middle_name": _middleNameCtrl.text.trim(),
              "last_name": _lastNameCtrl.text.trim(),
              "official_email": _officialEmailCtrl.text.trim(),
              "personal_email": _personalEmailCtrl.text.trim(),
              "phone_primary": _phonePrimaryCtrl.text.trim(),
              "phone_secondary": _phoneSecondaryCtrl.text.trim(),
              "emergency_contact_person": _emergencyPersonCtrl.text.trim(),
              "emergency_contact_phone": _emergencyPhoneCtrl.text.trim(),
              "department": _selectedDeptId,
              "designation": _selectedDesigId,
              "employment_status": _employmentStatus,
              "employment_nature": _employmentNature,
              "work_location": _workLocationCtrl.text.trim(),
              "notice_period_days": int.tryParse(_noticeDaysCtrl.text) ?? 30,
              "monthly_ctc": double.tryParse(_monthlyCtcCtrl.text) ?? 0.0,
              "annual_ctc": double.tryParse(_annualCtcCtrl.text) ?? 0.0,
              "bank_account_holder_name": _holderNameCtrl.text.trim(),
              "bank_name": _bankNameCtrl.text.trim(),
              "bank_account_number": _accNoCtrl.text.trim(),
              "bank_ifsc_code": _ifscCtrl.text.trim(),
              "bank_branch": _branchCtrl.text.trim(),
              "upi_id": _upiCtrl.text.trim(),
              "pan_number": _panCtrl.text.trim(),
              "aadhaar_number": _aadhaarCtrl.text.trim(),
              "uan_number": _uanCtrl.text.trim(),
              "pf_number": _pfCtrl.text.trim(),
              "esi_number": _esiCtrl.text.trim(),
              "current_address": _currentAddrCtrl.text.trim(),
              "permanent_address": _permAddrCtrl.text.trim(),
            });
            Navigator.pop(context);
          },
          child: const Text("COMMIT CHANGES"),
        ),
      ],
    );
  }

  Widget _row(List<Widget> children) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: c))).toList(),
  );

  Widget _input(TextEditingController ctrl, String lbl, {bool isRequired = false, bool isNumber = false, bool isReadOnly = false, int maxLines = 1, Function(String)? onChanged}) {
    return TextFormField(
      controller: ctrl,
      readOnly: isReadOnly,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 11.5),
      decoration: _inputDeco(lbl),
      onChanged: onChanged,
      validator: (v) => (isRequired && (v == null || v.trim().isEmpty)) ? "Required" : null,
    );
  }

  InputDecoration _inputDeco(String lbl) => InputDecoration(
    labelText: lbl,
    labelStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    isDense: true,
  );
}

// =============================================================================
// 9. ENTERPRISE TABBED MODAL: VIEW EMPLOYEE PROFILE
// =============================================================================
void showEmployeeProfileModal(BuildContext context, EmployeeItem emp) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Row(
        children: [
          InkWell(
            onTap: () {
              Navigator.pop(ctx);
              showFullAvatarPreview(context, emp.profilePhoto, emp.fullName);
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: kBrandBlue,
              backgroundImage: emp.profilePhoto != null ? NetworkImage(emp.profilePhoto!) : null,
              child: emp.profilePhoto == null ? Text(emp.fullName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emp.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: kDarkSlate)),
              Text("${emp.empCode} • ${emp.designationTitle} (${emp.departmentName})", style: const TextStyle(fontSize: 9.5, color: kTextMuted)),
            ],
          ),
        ],
      ),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoSec("EMPLOYMENT & CAREER LIFECYCLE"),
              _infoRow("Status", emp.employmentStatusDisplay),
              _infoRow("Nature", emp.employmentNatureDisplay),
              _infoRow("Joined Date", emp.dateOfJoining),
              _infoRow("Work Location", emp.workLocation),
              _infoRow("Notice Period", "${emp.noticePeriodDays} Days"),
              const Divider(height: 16),
              _infoSec("FINANCIAL PARAMETERS"),
              _infoRow("Monthly CTC", NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(emp.monthlyCtc)),
              _infoRow("Annual CTC", NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(emp.annualCtc)),
              _infoRow("Bank", emp.bankName.isEmpty ? "N/A" : emp.bankName),
              _infoRow("Account Number", emp.bankAccountNumber.isEmpty ? "N/A" : emp.bankAccountNumber),
              _infoRow("IFSC", emp.bankIfscCode.isEmpty ? "N/A" : emp.bankIfscCode),
              _infoRow("UPI ID", emp.upiId.isEmpty ? "N/A" : emp.upiId),
              const Divider(height: 16),
              _infoSec("STATUTORY KYC & CONTACT"),
              _infoRow("Official Email", emp.officialEmail),
              _infoRow("Primary Phone", emp.phonePrimary),
              _infoRow("Emergency Contact", "${emp.emergencyContactPerson} (${emp.emergencyContactPhone})"),
              _infoRow("PAN", emp.panNumber.isEmpty ? "N/A" : emp.panNumber),
              _infoRow("Aadhaar", emp.aadhaarNumber.isEmpty ? "N/A" : "[Aadhaar Redacted]"),
              _infoRow("UAN (PF)", emp.uanNumber.isEmpty ? "N/A" : emp.uanNumber),
              _infoRow("Current Address", emp.currentAddress.isEmpty ? "N/A" : emp.currentAddress),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CLOSE")),
      ],
    ),
  );
}

Widget _infoSec(String t) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(t, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: kBrandBlue, letterSpacing: 0.5)),
);

Widget _infoRow(String l, String v) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 2.5),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(l, style: const TextStyle(fontSize: 10.5, color: kTextMuted)),
      Text(v, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: kDarkSlate)),
    ],
  ),
);