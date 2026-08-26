import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';

// =============================================================================
// 1. DATA ENTITIES & MODELS (Exact Django CompanyProfile Schema)
// =============================================================================
class CompanyProfileEntity {
  final String id;
  final String companyName;
  final String tradeName;
  final String msmeUdyamRegNo;
  final String gstin;
  final String panNumber;
  final String cinNumber;
  final String officialEmail;
  final String hrContactEmail;
  final String phoneNumber;
  final String website;
  final String registeredAddress;
  final String city;
  final String state;
  final String pincode;
  final String country;
  final String? companyLogo;
  final String? authorizedSignature;
  final String authorizedSignatoryName;
  final String authorizedSignatoryDesignation;
  final String? officialStamp;
  final bool isActive;

  const CompanyProfileEntity({
    required this.id,
    required this.companyName,
    required this.tradeName,
    required this.msmeUdyamRegNo,
    required this.gstin,
    required this.panNumber,
    required this.cinNumber,
    required this.officialEmail,
    required this.hrContactEmail,
    required this.phoneNumber,
    required this.website,
    required this.registeredAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
    this.companyLogo,
    this.authorizedSignature,
    required this.authorizedSignatoryName,
    required this.authorizedSignatoryDesignation,
    this.officialStamp,
    required this.isActive,
  });

  factory CompanyProfileEntity.fromJson(Map<String, dynamic> json) {
    return CompanyProfileEntity(
      id: (json['id'] ?? '').toString(),
      companyName: json['company_name'] ?? 'Softwing Tech Labs',
      tradeName: json['trade_name'] ?? '',
      msmeUdyamRegNo: json['msme_udyam_reg_no'] ?? '',
      gstin: json['gstin'] ?? '',
      panNumber: json['pan_number'] ?? '',
      cinNumber: json['cin_number'] ?? '',
      officialEmail: json['official_email'] ?? '',
      hrContactEmail: json['hr_contact_email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      website: json['website'] ?? 'https://softwingtechlabs.com',
      registeredAddress: json['registered_address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      country: json['country'] ?? 'India',
      companyLogo: json['company_logo'],
      authorizedSignature: json['authorized_signature'],
      authorizedSignatoryName: json['authorized_signatory_name'] ?? 'Authorized Signatory',
      authorizedSignatoryDesignation: json['authorized_signatory_designation'] ?? 'Director / Founder',
      officialStamp: json['official_stamp'],
      isActive: json['is_active'] ?? true,
    );
  }
}

// =============================================================================
// 2. REPOSITORY LAYER
// =============================================================================
class CompanyProfileRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<CompanyProfileEntity?> getCompanyProfile() async {
    final res = await apiClient.get('/api/hrms/company-profile/');

    dynamic rawData = res.data;
    if (rawData is Map && rawData.containsKey('data')) {
      rawData = rawData['data'];
    }

    if (rawData is Map<String, dynamic> && rawData.isNotEmpty) {
      return CompanyProfileEntity.fromJson(rawData);
    } else if (rawData is List && rawData.isNotEmpty) {
      return CompanyProfileEntity.fromJson(rawData.first as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> saveCompanyProfile({
    String? id,
    required Map<String, dynamic> fields,
    XFile? logo,
    XFile? signature,
    XFile? stamp,
  }) async {
    // 🌟 Direct FormData banayein taaki type mismatch bilkul na ho
    final dio.FormData formData = dio.FormData();

    // 1. Regular text fields add karein
    fields.forEach((key, value) {
      if (value != null) {
        formData.fields.add(MapEntry(key, value.toString()));
      }
    });

    // 2. Binary files add karein
    if (logo != null) {
      final Uint8List b = await logo.readAsBytes();
      formData.files.add(MapEntry(
        'company_logo',
        dio.MultipartFile.fromBytes(
          b,
          filename: logo.name.isNotEmpty ? logo.name : 'company_logo.png',
        ),
      ));
    }

    if (signature != null) {
      final Uint8List b = await signature.readAsBytes();
      formData.files.add(MapEntry(
        'authorized_signature',
        dio.MultipartFile.fromBytes(
          b,
          filename: signature.name.isNotEmpty ? signature.name : 'signature.png',
        ),
      ));
    }

    if (stamp != null) {
      final Uint8List b = await stamp.readAsBytes();
      formData.files.add(MapEntry(
        'official_stamp',
        dio.MultipartFile.fromBytes(
          b,
          filename: stamp.name.isNotEmpty ? stamp.name : 'stamp.png',
        ),
      ));
    }

    // 3. API Call
    if (id != null && id.isNotEmpty) {
      await apiClient.patch('/api/hrms/company-profile/$id/', data: formData);
    } else {
      await apiClient.post('/api/hrms/company-profile/', data: formData);
    }
  }
}
// =============================================================================
// 3. BLOC ENGINE
// =============================================================================
abstract class CompanyProfileEvent {}

class LoadCompanyProfileEvent extends CompanyProfileEvent {}

class SaveCompanyProfileEvent extends CompanyProfileEvent {
  final String? id;
  final Map<String, dynamic> fields;
  final XFile? logo;
  final XFile? signature;
  final XFile? stamp;

  SaveCompanyProfileEvent({
    this.id,
    required this.fields,
    this.logo,
    this.signature,
    this.stamp,
  });
}

abstract class CompanyProfileState {}

class CompanyProfileLoading extends CompanyProfileState {}

class CompanyProfileLoaded extends CompanyProfileState {
  final CompanyProfileEntity? profile;
  final bool isSaving;

  CompanyProfileLoaded({this.profile, this.isSaving = false});
}

class CompanyProfileSavedSuccess extends CompanyProfileState {}

class CompanyProfileError extends CompanyProfileState {
  final String message;
  CompanyProfileError(this.message);
}

class CompanyProfileBloc extends Bloc<CompanyProfileEvent, CompanyProfileState> {
  final CompanyProfileRepository repository;

  CompanyProfileBloc(this.repository) : super(CompanyProfileLoading()) {
    on<LoadCompanyProfileEvent>((event, emit) async {
      emit(CompanyProfileLoading());
      try {
        final profile = await repository.getCompanyProfile();
        emit(CompanyProfileLoaded(profile: profile));
      } catch (e) {
        emit(CompanyProfileError("Failed to fetch company profile details: $e"));
      }
    });

    on<SaveCompanyProfileEvent>((event, emit) async {
      if (state is CompanyProfileLoaded) {
        emit(CompanyProfileLoaded(profile: (state as CompanyProfileLoaded).profile, isSaving: true));
        try {
          await repository.saveCompanyProfile(
            id: event.id,
            fields: event.fields,
            logo: event.logo,
            signature: event.signature,
            stamp: event.stamp,
          );
          emit(CompanyProfileSavedSuccess());
          add(LoadCompanyProfileEvent());
        } catch (e) {
          emit(CompanyProfileError("Failed to save organization identity matrix: $e"));
        }
      }
    });
  }
}

// =============================================================================
// 4. RESPONSIVE UI CANVAS
// =============================================================================
class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  static const Color brandBlue = Color(0xFF0066B3);
  static const Color brandRed = Color(0xFFD32027);
  static const Color darkSlate = Color(0xFF0B0E14);
  static const Color textMuted = Color(0xFF8B949E);

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _nameCtrl = TextEditingController(text: "Softwing Tech Labs");
  final _tradeCtrl = TextEditingController();
  final _udyamCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _cinCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _hrEmailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController(text: "https://softwingtechlabs.com");
  final _addrCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: "India");
  final _signNameCtrl = TextEditingController(text: "Authorized Signatory");
  final _signDesigCtrl = TextEditingController(text: "Director / Founder");

  String? _existingId;
  String? _networkLogo;
  String? _networkSignature;
  String? _networkStamp;

  XFile? _logoFile;
  Uint8List? _logoBytes;
  XFile? _sigFile;
  Uint8List? _sigBytes;
  XFile? _stampFile;
  Uint8List? _stampBytes;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tradeCtrl.dispose();
    _udyamCtrl.dispose();
    _gstinCtrl.dispose();
    _panCtrl.dispose();
    _cinCtrl.dispose();
    _emailCtrl.dispose();
    _hrEmailCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _addrCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _countryCtrl.dispose();
    _signNameCtrl.dispose();
    _signDesigCtrl.dispose();
    super.dispose();
  }

  void _populateForm(CompanyProfileEntity p) {
    _existingId = p.id;
    _nameCtrl.text = p.companyName;
    _tradeCtrl.text = p.tradeName;
    _udyamCtrl.text = p.msmeUdyamRegNo;
    _gstinCtrl.text = p.gstin;
    _panCtrl.text = p.panNumber;
    _cinCtrl.text = p.cinNumber;
    _emailCtrl.text = p.officialEmail;
    _hrEmailCtrl.text = p.hrContactEmail;
    _phoneCtrl.text = p.phoneNumber;
    _websiteCtrl.text = p.website;
    _addrCtrl.text = p.registeredAddress;
    _cityCtrl.text = p.city;
    _stateCtrl.text = p.state;
    _pincodeCtrl.text = p.pincode;
    _countryCtrl.text = p.country;
    _signNameCtrl.text = p.authorizedSignatoryName;
    _signDesigCtrl.text = p.authorizedSignatoryDesignation;
    _networkLogo = p.companyLogo;
    _networkSignature = p.authorizedSignature;
    _networkStamp = p.officialStamp;
  }

  Future<void> _pickImage(String type) async {
    final ImagePicker picker = ImagePicker();
    final XFile? img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() {
        if (type == 'LOGO') {
          _logoFile = img;
          _logoBytes = bytes;
        } else if (type == 'SIG') {
          _sigFile = img;
          _sigBytes = bytes;
        } else if (type == 'STAMP') {
          _stampFile = img;
          _stampBytes = bytes;
        }
      });
    }
  }

  void _submitProfile(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final fields = {
      "company_name": _nameCtrl.text.trim(),
      "trade_name": _tradeCtrl.text.trim(),
      "msme_udyam_reg_no": _udyamCtrl.text.trim(),
      "gstin": _gstinCtrl.text.trim(),
      "pan_number": _panCtrl.text.trim(),
      "cin_number": _cinCtrl.text.trim(),
      "official_email": _emailCtrl.text.trim(),
      "hr_contact_email": _hrEmailCtrl.text.trim(),
      "phone_number": _phoneCtrl.text.trim(),
      "website": _websiteCtrl.text.trim(),
      "registered_address": _addrCtrl.text.trim(),
      "city": _cityCtrl.text.trim(),
      "state": _stateCtrl.text.trim(),
      "pincode": _pincodeCtrl.text.trim(),
      "country": _countryCtrl.text.trim(),
      "authorized_signatory_name": _signNameCtrl.text.trim(),
      "authorized_signatory_designation": _signDesigCtrl.text.trim(),
    };

    context.read<CompanyProfileBloc>().add(SaveCompanyProfileEvent(
      id: _existingId,
      fields: fields,
      logo: _logoFile,
      signature: _sigFile,
      stamp: _stampFile,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 900;

    return BlocProvider(
      create: (context) => CompanyProfileBloc(CompanyProfileRepository())..add(LoadCompanyProfileEvent()),
      child: BlocConsumer<CompanyProfileBloc, CompanyProfileState>(
        listener: (context, state) {
          if (state is CompanyProfileSavedSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("✅ Company letterhead profile updated successfully!"),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          } else if (state is CompanyProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("❌ ${state.message}"), backgroundColor: CompanyProfileScreen.brandRed),
            );
          } else if (state is CompanyProfileLoaded && state.profile != null) {
            _populateForm(state.profile!);
          }
        },
        builder: (context, state) {
          final bool isSaving = state is CompanyProfileLoaded && state.isSaving;

          return Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            body: state is CompanyProfileLoading
                ? const Center(child: CircularProgressIndicator(color: CompanyProfileScreen.brandBlue))
                : Padding(
              padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopHeader(context, isSaving),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: Column(
                              children: [
                                _buildBrandingAndMediaCard(isMobile),
                                const SizedBox(height: 16),
                                _buildLegalAndTaxMatrixCard(isMobile),
                                const SizedBox(height: 16),
                                _buildCommunicationAndAddressCard(isMobile),
                                const SizedBox(height: 16),
                                _buildSignatoryAuthorityCard(isMobile),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isSaving) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "COMPANY & MSME MASTER PROFILE",
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: CompanyProfileScreen.darkSlate,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Letterhead Branding, Verification Contact & Authorized Signatory Configurations",
              style: TextStyle(fontSize: 9.5, color: CompanyProfileScreen.textMuted, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: isSaving ? null : () => _submitProfile(context),
          icon: isSaving
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5))
              : const Icon(Icons.verified_outlined, size: 14),
          label: Text(
            isSaving ? "SAVING MATRIX..." : "SAVE PROFILE MATRIX",
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.4),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: CompanyProfileScreen.brandBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
      ],
    );
  }

  // 1. Digital Seals & Signatures
  Widget _buildBrandingAndMediaCard(bool isMobile) {
    return _cardWrapper(
      title: "1. DIGITAL BRANDING, SIGNATURES & VERIFICATION SEALS",
      icon: Icons.fingerprint_rounded,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _imagePickerSlot("COMPANY LOGO", _logoBytes, _networkLogo, () => _pickImage('LOGO')),
              _imagePickerSlot("OFFICIAL STAMP", _stampBytes, _networkStamp, () => _pickImage('STAMP')),
              _imagePickerSlot("AUTHORIZED SIGNATURE", _sigBytes, _networkSignature, () => _pickImage('SIG')),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "These digital assets will be dynamically embedded into all generated Salary Slips, Joining Letters, and Experience Certificates.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9.5, color: CompanyProfileScreen.textMuted, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // 2. Statutory & MSME Registration
  Widget _buildLegalAndTaxMatrixCard(bool isMobile) {
    return _cardWrapper(
      title: "2. CORPORATE REGISTRATION & STATUTORY TAX MATRIX",
      icon: Icons.account_balance_outlined,
      child: Column(
        children: [
          _row(isMobile, [
            _input(_nameCtrl, "REGISTERED LEGAL COMPANY NAME *", isRequired: true),
            _input(_tradeCtrl, "TRADE NAME (IF DIFFERENT)"),
          ]),
          const SizedBox(height: 12),
          _row(isMobile, [
            _input(_udyamCtrl, "MSME UDYAM REGISTRATION NO (e.g. UDYAM-XX-00-0000000) *", isRequired: true),
            _input(_gstinCtrl, "GSTIN IDENTIFIER NUMBER"),
          ]),
          const SizedBox(height: 12),
          _row(isMobile, [
            _input(_panCtrl, "CORPORATE / ENTITY PAN NUMBER"),
            _input(_cinCtrl, "CORPORATE IDENTITY NUMBER (CIN)"),
          ]),
        ],
      ),
    );
  }

  // 3. Communications & Registered Office
  Widget _buildCommunicationAndAddressCard(bool isMobile) {
    return _cardWrapper(
      title: "3. OFFICIAL COMMUNICATIONS & REGISTERED HEADQUARTERS",
      icon: Icons.business_outlined,
      child: Column(
        children: [
          _row(isMobile, [
            _input(_emailCtrl, "OFFICIAL VERIFICATION EMAIL (FOR BGV) *", isRequired: true),
            _input(_hrEmailCtrl, "HR HELPDESK EMAIL"),
          ]),
          const SizedBox(height: 12),
          _row(isMobile, [
            _input(_phoneCtrl, "PRIMARY CONTACT PHONE NUMBER *", isRequired: true),
            _input(_websiteCtrl, "OFFICIAL WEBSITE DOMAIN"),
          ]),
          const SizedBox(height: 12),
          _input(_addrCtrl, "REGISTERED OFFICE ADDRESS *", isRequired: true, maxLines: 2),
          const SizedBox(height: 12),
          _row(isMobile, [
            _input(_cityCtrl, "CITY *", isRequired: true),
            _input(_stateCtrl, "STATE / PROVINCE *", isRequired: true),
            _input(_pincodeCtrl, "PINCODE *", isRequired: true),
            _input(_countryCtrl, "COUNTRY *", isRequired: true),
          ]),
        ],
      ),
    );
  }

  // 4. Authorized Signatory Authority
  Widget _buildSignatoryAuthorityCard(bool isMobile) {
    return _cardWrapper(
      title: "4. AUTHORIZED SIGNATORY REPRESENTATION",
      icon: Icons.badge_outlined,
      child: Column(
        children: [
          _row(isMobile, [
            _input(_signNameCtrl, "SIGNATORY FULL NAME *", isRequired: true),
            _input(_signDesigCtrl, "SIGNATORY OFFICIAL DESIGNATION *", isRequired: true),
          ]),
        ],
      ),
    );
  }

  // --- UI HELPER ATOMS ---

  Widget _imagePickerSlot(String label, Uint8List? localBytes, String? networkUrl, VoidCallback onPick) {
    return Column(
      children: [
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 140,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 1.2),
            ),
            child: localBytes != null
                ? Image.memory(localBytes, fit: BoxFit.contain)
                : (networkUrl != null && networkUrl.isNotEmpty)
                ? Image.network(networkUrl, fit: BoxFit.contain)
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.cloud_upload_outlined, size: 24, color: CompanyProfileScreen.brandBlue),
                SizedBox(height: 4),
                Text("UPLOAD ASSET", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: CompanyProfileScreen.textMuted)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: CompanyProfileScreen.darkSlate)),
      ],
    );
  }

  Widget _cardWrapper({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                Icon(icon, size: 15, color: CompanyProfileScreen.brandBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: CompanyProfileScreen.darkSlate, letterSpacing: 0.4),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _row(bool isMobile, List<Widget> children) {
    if (isMobile) {
      return Column(children: children.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c)).toList());
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: c))).toList(),
    );
  }

  Widget _input(TextEditingController ctrl, String lbl, {bool isRequired = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: CompanyProfileScreen.darkSlate),
      decoration: InputDecoration(
        labelText: lbl,
        labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
      validator: (v) => (isRequired && (v == null || v.trim().isEmpty)) ? "Required field" : null,
    );
  }
}