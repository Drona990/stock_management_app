import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';

// =============================================================================
// 1. DATA REPOSITORY & FORM PAYLOAD
// =============================================================================
class StaffCreateRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<Map<String, List<Map<String, dynamic>>>> fetchMetaOptions() async {
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

  Future<void> submitEmployeeRecord(Map<String, dynamic> payload, XFile? photo) async {
    if (photo != null) {
      final Uint8List bytes = await photo.readAsBytes();
      payload['profile_photo'] = dio.MultipartFile.fromBytes(bytes, filename: photo.name);
    }
    final dio.FormData formData = dio.FormData.fromMap(payload);
    await apiClient.post('/api/hrms/employees/', data: formData);
  }
}

// =============================================================================
// 2. BLOC STATE MANAGEMENT ENGINE
// =============================================================================
abstract class StaffCreateEvent {}
class LoadMetaOptionsEvent extends StaffCreateEvent {}
class SubmitStaffFormEvent extends StaffCreateEvent {
  final Map<String, dynamic> formData;
  final XFile? profileImage;
  SubmitStaffFormEvent(this.formData, this.profileImage);
}

abstract class StaffCreateState {}
class StaffCreateInitial extends StaffCreateState {}
class StaffCreateLoadingMeta extends StaffCreateState {}
class StaffCreateMetaLoaded extends StaffCreateState {
  final List<Map<String, dynamic>> departments;
  final List<Map<String, dynamic>> designations;
  StaffCreateMetaLoaded({required this.departments, required this.designations});
}
class StaffCreateSubmitting extends StaffCreateState {}
class StaffCreateSuccess extends StaffCreateState {
  final String empCode;
  StaffCreateSuccess(this.empCode);
}
class StaffCreateError extends StaffCreateState {
  final String message;
  StaffCreateError(this.message);
}

class StaffCreateBloc extends Bloc<StaffCreateEvent, StaffCreateState> {
  final StaffCreateRepository repository;
  List<Map<String, dynamic>> _cachedDepts = [];
  List<Map<String, dynamic>> _cachedDesigs = [];

  StaffCreateBloc(this.repository) : super(StaffCreateInitial()) {
    on<LoadMetaOptionsEvent>((event, emit) async {
      emit(StaffCreateLoadingMeta());
      try {
        final options = await repository.fetchMetaOptions();
        _cachedDepts = options['departments'] ?? [];
        _cachedDesigs = options['designations'] ?? [];
        emit(StaffCreateMetaLoaded(departments: _cachedDepts, designations: _cachedDesigs));
      } catch (e) {
        emit(StaffCreateError("Failed to fetch organizational metadata: ${e.toString()}"));
      }
    });

    on<SubmitStaffFormEvent>((event, emit) async {
      emit(StaffCreateSubmitting());
      try {
        await repository.submitEmployeeRecord(event.formData, event.profileImage);
        emit(StaffCreateSuccess(event.formData['emp_code'] ?? 'New Employee'));
      } catch (e) {
        emit(StaffCreateError("Submission Failed: ${e.toString()}"));
        emit(StaffCreateMetaLoaded(departments: _cachedDepts, designations: _cachedDesigs));
      }
    });
  }
}

// =============================================================================
// 3. RESPONSIVE MULTI-SECTION FORM SCREEN
// =============================================================================
class StaffCreateScreen extends StatefulWidget {
  const StaffCreateScreen({super.key});

  @override
  State<StaffCreateScreen> createState() => _StaffCreateScreenState();
}

class _StaffCreateScreenState extends State<StaffCreateScreen> {
  static const Color brandBlue = Color(0xFF0066B3);
  static const Color brandRed = Color(0xFFD32027);
  static const Color darkSlate = Color(0xFF0B0E14);
  static const Color textMuted = Color(0xFF8B949E);

  final _formKey = GlobalKey<FormState>();

  // Personal Controllers
  final _empCodeCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _officialEmailCtrl = TextEditingController();
  final _personalEmailCtrl = TextEditingController();
  final _phonePrimaryCtrl = TextEditingController();
  final _phoneSecondaryCtrl = TextEditingController();
  final _emergencyPersonCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  // Address Controllers
  final _currentAddressCtrl = TextEditingController();
  final _permanentAddressCtrl = TextEditingController();

  // Statutory Controllers
  final _panCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final _uanCtrl = TextEditingController();
  final _pfCtrl = TextEditingController();
  final _esiCtrl = TextEditingController();

  // Financial Controllers
  final _monthlyCtcCtrl = TextEditingController();
  final _annualCtcCtrl = TextEditingController();
  final _holderNameCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accNoCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _noticeDaysCtrl = TextEditingController(text: "30");

  // Selection Variables
  String _gender = "MALE";
  String _maritalStatus = "SINGLE";
  String _employmentNature = "FULL_TIME";
  String _employmentStatus = "ACTIVE";
  String _workLocation = "Remote / In-Office";

  DateTime _doj = DateTime.now();
  DateTime? _dob;
  DateTime? _probationEnd;

  String? _selectedDeptId;
  String? _selectedDesigId;

  XFile? _pickedImage;
  Uint8List? _imageBytes;

  @override
  void dispose() {
    _empCodeCtrl.dispose();
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _officialEmailCtrl.dispose();
    _personalEmailCtrl.dispose();
    _phonePrimaryCtrl.dispose();
    _phoneSecondaryCtrl.dispose();
    _emergencyPersonCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    _currentAddressCtrl.dispose();
    _permanentAddressCtrl.dispose();
    _panCtrl.dispose();
    _aadhaarCtrl.dispose();
    _uanCtrl.dispose();
    _pfCtrl.dispose();
    _esiCtrl.dispose();
    _monthlyCtcCtrl.dispose();
    _annualCtcCtrl.dispose();
    _holderNameCtrl.dispose();
    _bankNameCtrl.dispose();
    _accNoCtrl.dispose();
    _ifscCtrl.dispose();
    _branchCtrl.dispose();
    _upiCtrl.dispose();
    _noticeDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _pickedImage = image;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Media Picker Error: $e");
    }
  }

  void _calculateAnnualCtc(String val) {
    final double monthly = double.tryParse(val.trim()) ?? 0.0;
    _annualCtcCtrl.text = (monthly * 12).toStringAsFixed(2);
  }

  void _submitForm(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDeptId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a Department"), backgroundColor: brandRed),
      );
      return;
    }

    if (_selectedDesigId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a Designation Role"), backgroundColor: brandRed),
      );
      return;
    }

    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final Map<String, dynamic> payload = {
      "emp_code": _empCodeCtrl.text.trim(),
      "first_name": _firstNameCtrl.text.trim(),
      "middle_name": _middleNameCtrl.text.trim(),
      "last_name": _lastNameCtrl.text.trim(),
      "official_email": _officialEmailCtrl.text.trim(),
      "personal_email": _personalEmailCtrl.text.trim(),
      "phone_primary": _phonePrimaryCtrl.text.trim(),
      "phone_secondary": _phoneSecondaryCtrl.text.trim(),
      "emergency_contact_person": _emergencyPersonCtrl.text.trim(),
      "emergency_contact_phone": _emergencyPhoneCtrl.text.trim(),
      "gender": _gender,
      "marital_status": _maritalStatus,
      "date_of_joining": formatter.format(_doj),
      "employment_nature": _employmentNature,
      "employment_status": _employmentStatus,
      "work_location": _workLocation,
      "notice_period_days": int.tryParse(_noticeDaysCtrl.text) ?? 30,
      "current_address": _currentAddressCtrl.text.trim(),
      "permanent_address": _permanentAddressCtrl.text.trim(),
      "pan_number": _panCtrl.text.trim(),
      "aadhaar_number": _aadhaarCtrl.text.trim(),
      "uan_number": _uanCtrl.text.trim(),
      "pf_number": _pfCtrl.text.trim(),
      "esi_number": _esiCtrl.text.trim(),
      "monthly_ctc": double.tryParse(_monthlyCtcCtrl.text) ?? 0.0,
      "annual_ctc": double.tryParse(_annualCtcCtrl.text) ?? 0.0,
      "bank_account_holder_name": _holderNameCtrl.text.trim(),
      "bank_name": _bankNameCtrl.text.trim(),
      "bank_account_number": _accNoCtrl.text.trim(),
      "bank_ifsc_code": _ifscCtrl.text.trim(),
      "bank_branch": _branchCtrl.text.trim(),
      "upi_id": _upiCtrl.text.trim(),
      "department": _selectedDeptId,
      "designation": _selectedDesigId,
    };

    if (_dob != null) payload["dob"] = formatter.format(_dob!);
    if (_probationEnd != null) payload["probation_end_date"] = formatter.format(_probationEnd!);

    context.read<StaffCreateBloc>().add(SubmitStaffFormEvent(payload, _pickedImage));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 800;

    return BlocProvider(
      create: (context) => StaffCreateBloc(StaffCreateRepository())..add(LoadMetaOptionsEvent()),
      child: BlocConsumer<StaffCreateBloc, StaffCreateState>(
        listener: (context, state) {
          if (state is StaffCreateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("✅ Employee ${state.empCode} onboarded successfully!"),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
            context.go('/staff_master');
          } else if (state is StaffCreateError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("❌ ${state.message}"), backgroundColor: brandRed),
            );
          }
        },
        builder: (context, state) {
          List<Map<String, dynamic>> depts = [];
          List<Map<String, dynamic>> allDesigs = [];

          if (state is StaffCreateMetaLoaded) {
            depts = state.departments;
            allDesigs = state.designations;
          }

          // 🌟 Department ke hisaab se Designation filter karein
          final List<Map<String, dynamic>> filteredDesigs = _selectedDeptId == null
              ? []
              : allDesigs.where((d) => d['department'].toString() == _selectedDeptId).toList();

          final bool isBusy = state is StaffCreateSubmitting || state is StaffCreateLoadingMeta;

          return Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              toolbarHeight: 60,
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ONBOARD NEW STAFF MEMBER",
                    style: TextStyle(color: darkSlate, fontSize: 13.5, fontWeight: FontWeight.w900, letterSpacing: 0.6),
                  ),
                  Text(
                    "Softwing Tech Labs • Master Personnel Onboarding Matrix",
                    style: TextStyle(color: textMuted, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
            ),
            body: state is StaffCreateLoadingMeta
                ? const Center(child: CircularProgressIndicator(color: brandBlue))
                : Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 32, vertical: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Personal & Identity Card
                        _buildCardContainer(
                          title: "1. PERSONAL IDENTITY & CONTACT MATRIX",
                          icon: Icons.badge_outlined,
                          child: Column(
                            children: [
                              _buildAvatarUploadBlock(),
                              const SizedBox(height: 20),
                              _buildResponsiveRow(
                                isMobile,
                                [
                                  _inputField(_empCodeCtrl, "EMPLOYEE CODE (e.g. SW-EMP-001)", isRequired: true),
                                  _dropdownField("GENDER", _gender, ["MALE", "FEMALE", "OTHER"], (v) => setState(() => _gender = v!)),
                                  _dropdownField("MARITAL STATUS", _maritalStatus, ["SINGLE", "MARRIED", "OTHER"], (v) => setState(() => _maritalStatus = v!)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildResponsiveRow(
                                isMobile,
                                [
                                  _inputField(_firstNameCtrl, "FIRST NAME", isRequired: true),
                                  _inputField(_middleNameCtrl, "MIDDLE NAME"),
                                  _inputField(_lastNameCtrl, "LAST NAME", isRequired: true),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildResponsiveRow(
                                isMobile,
                                [
                                  _inputField(_officialEmailCtrl, "OFFICIAL WORK EMAIL", isRequired: true, isEmail: true),
                                  _inputField(_personalEmailCtrl, "PERSONAL EMAIL", isEmail: true),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildResponsiveRow(
                                isMobile,
                                [
                                  _inputField(_phonePrimaryCtrl, "PRIMARY CONTACT PHONE", isRequired: true),
                                  _inputField(_phoneSecondaryCtrl, "SECONDARY PHONE"),
                                  _datePickerField("DATE OF BIRTH", _dob, (d) => setState(() => _dob = d)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildResponsiveRow(
                                isMobile,
                                [
                                  _inputField(_emergencyPersonCtrl, "EMERGENCY CONTACT PERSON"),
                                  _inputField(_emergencyPhoneCtrl, "EMERGENCY PHONE NUMBER"),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 2. Organization & Employment Lifecycle
                        _buildCardContainer(
                          title: "2. ORGANIZATIONAL HIERARCHY & DATES LIFECYCLE",
                          icon: Icons.corporate_fare_outlined,
                          child: Column(
                            children: [
                              _buildResponsiveRow(
                                isMobile,
                                [
                                  // 🌟 Dynamic Department Dropdown
                                  DropdownButtonFormField<String>(
                                    value: _selectedDeptId,
                                    hint: const Text("Select Department", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    items: depts.map((e) {
                                      return DropdownMenuItem<String>(
                                        value: e['id'].toString(),
                                        child: Text(e['name'] ?? 'Department', style: const TextStyle(fontSize: 11.5)),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedDeptId = val;
                                        _selectedDesigId = null; // Reset designation on department change
                                      });
                                    },
                                    decoration: _inputStyle("DEPARTMENT *"),
                                    validator: (v) => v == null ? "Department is required" : null,
                                  ),

                                  // 🌟 Dynamic Designation Dropdown (Filtered)
                                  DropdownButtonFormField<String>(
                                    value: _selectedDesigId,
                                    hint: Text(
                                      _selectedDeptId == null ? "Select Department First" : "Select Designation Role",
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    items: filteredDesigs.map((e) {
                                      return DropdownMenuItem<String>(
                                        value: e['id'].toString(),
                                        child: Text("${e['title']} (${e['level'] ?? 'L1'})", style: const TextStyle(fontSize: 11.5)),
                                      );
                                    }).toList(),
                                    onChanged: _selectedDeptId == null
                                        ? null
                                        : (val) {
                                      setState(() => _selectedDesigId = val);
                                    },
                                    decoration: _inputStyle("DESIGNATION ROLE *"),
                                    validator: (v) => v == null ? "Designation is required" : null,
                                  ),

                                  _dropdownField(
                                    "EMPLOYMENT NATURE",
                                    _employmentNature,
                                    ["FULL_TIME", "PROBATION", "CONTRACT", "INTERN", "FREELANCE"],
                                        (v) => setState(() => _employmentNature = v!),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildResponsiveRow(
                                isMobile,
                                [
                                  _datePickerField("DATE OF JOINING", _doj, (d) => setState(() => _doj = d ?? DateTime.now()), isRequired: true),
                                  _datePickerField("PROBATION END DATE", _probationEnd, (d) => setState(() => _probationEnd = d)),
                                  _inputField(_noticeDaysCtrl, "NOTICE PERIOD (DAYS)", isNumber: true),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildResponsiveRow(
                                isMobile,
                                [
                                  _dropdownField("EMPLOYMENT STATUS", _employmentStatus, ["ACTIVE", "ON_NOTICE", "RELIEVED", "TERMINATED"], (v) => setState(() => _employmentStatus = v!)),
                                  _inputField(TextEditingController(text: _workLocation), "WORK LOCATION", onChanged: (v) => _workLocation = v),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 3. Statutory KYC & Addresses
                        _buildCardContainer(
                          title: "3. STATUTORY KYC & RESIDENTIAL ADDRESS",
                          icon: Icons.verified_user_outlined,
                          child: Column(
                            children: [
                              _buildResponsiveRow(
                                isMobile,
                                [
                                  _inputField(_panCtrl, "PAN CARD NUMBER"),
                                  _inputField(_aadhaarCtrl, "AADHAAR NUMBER"),
                                  _inputField(_uanCtrl, "UAN NUMBER (PF)"),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildResponsiveRow(
                                isMobile,
                                [
                                  _inputField(_pfCtrl, "PF MEMBER ID"),
                                  _inputField(_esiCtrl, "ESI NUMBER"),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildResponsiveRow(
                                isMobile,
                                [
                                  _inputField(_currentAddressCtrl, "CURRENT RESIDENTIAL ADDRESS", maxLines: 2),
                                  _inputField(_permanentAddressCtrl, "PERMANENT ADDRESS", maxLines: 2),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 4. Financial & Bank Accounts
                        _buildCardContainer(
                          title: "4. FINANCIAL COMPENSATION & BANK PAYOUT",
                          icon: Icons.account_balance_outlined,
                          child: Column(
                            children: [
                              _buildResponsiveRow(
                                isMobile,
                                [
                                  _inputField(_monthlyCtcCtrl, "MONTHLY CTC (₹)", isRequired: true, isNumber: true, onChanged: _calculateAnnualCtc),
                                  _inputField(_annualCtcCtrl, "ANNUAL CTC (₹)", isNumber: true, isReadOnly: true),
                                  _inputField(_upiCtrl, "UPI ID (FOR DIGITAL PAYOUT)"),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildResponsiveRow(
                                isMobile,
                                [
                                  _inputField(_holderNameCtrl, "BANK ACCOUNT HOLDER NAME"),
                                  _inputField(_bankNameCtrl, "BANK NAME"),
                                  _inputField(_accNoCtrl, "ACCOUNT NUMBER"),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildResponsiveRow(
                                isMobile,
                                [
                                  _inputField(_ifscCtrl, "IFSC CODE"),
                                  _inputField(_branchCtrl, "BRANCH NAME"),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Action Buttons Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => context.go('/staff_master'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("CANCEL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),
                            const SizedBox(width: 14),
                            ElevatedButton.icon(
                              onPressed: isBusy ? null : () => _submitForm(context),
                              icon: isBusy
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5))
                                  : const Icon(Icons.cloud_upload_outlined, size: 16),
                              label: Text(
                                isBusy ? "REGISTERING..." : "COMMIT & SAVE EMPLOYEE RECORD",
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildCardContainer({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: brandBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: darkSlate, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarUploadBlock() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: const Color(0xFFF1F5F9),
                backgroundImage: _imageBytes != null ? MemoryImage(_imageBytes!) : null,
                child: _imageBytes == null ? const Icon(Icons.person_add_alt_1_rounded, size: 36, color: Colors.blueGrey) : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: brandBlue,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                    onPressed: _pickAvatar,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text("UPLOAD OFFICIAL PROFILE PHOTO", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: textMuted)),
        ],
      ),
    );
  }

  Widget _buildResponsiveRow(bool isMobile, List<Widget> children) {
    if (isMobile) {
      return Column(
        children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: c))).toList(),
    );
  }

  Widget _inputField(
      TextEditingController ctrl,
      String label, {
        bool isRequired = false,
        bool isEmail = false,
        bool isNumber = false,
        bool isReadOnly = false,
        int maxLines = 1,
        Function(String)? onChanged,
      }) {
    return TextFormField(
      controller: ctrl,
      readOnly: isReadOnly,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: darkSlate),
      decoration: _inputStyle(label),
      validator: (v) {
        if (isRequired && (v == null || v.trim().isEmpty)) return "$label is required";
        if (isEmail && v != null && v.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
          return "Invalid email format";
        }
        return null;
      },
    );
  }

  Widget _dropdownField(String label, String value, List<String> options, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 11.5)))).toList(),
      onChanged: onChanged,
      decoration: _inputStyle(label),
    );
  }

  Widget _datePickerField(String label, DateTime? selectedDate, Function(DateTime?) onSelected, {bool isRequired = false}) {
    final String displayStr = selectedDate != null ? DateFormat('dd-MM-yyyy').format(selectedDate) : "Select Date";

    return FormField<DateTime>(
      validator: (_) => (isRequired && selectedDate == null) ? "$label is required" : null,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(1960),
                  lastDate: DateTime(2040),
                );
                if (d != null) onSelected(d);
              },
              borderRadius: BorderRadius.circular(6),
              child: InputDecorator(
                decoration: _inputStyle(label),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(displayStr, style: TextStyle(fontSize: 11.5, color: selectedDate != null ? darkSlate : Colors.grey)),
                    const Icon(Icons.calendar_month_outlined, size: 14, color: brandBlue),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8),
                child: Text(state.errorText!, style: const TextStyle(color: brandRed, fontSize: 10)),
              ),
          ],
        );
      },
    );
  }

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: brandBlue, width: 1.2)),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
    );
  }
}