import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_client.dart';
import '../../../../injection.dart';

// ==========================================================================
// 1. REPOSITORY LAYER (Cross-Platform Multipart Compilation Pipeline)
// ==========================================================================
class SuperuserRegistrationRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<Map<String, dynamic>> commitSuperuser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    XFile? pickedXFile,
  }) async {
    final Map<String, dynamic> payloadMap = {
      "first_name": firstName,
      "last_name": lastName,
      "email": email,
      "password": password,
    };

    if (pickedXFile != null) {
      final Uint8List fileBytes = await pickedXFile.readAsBytes();
      payloadMap["profile_image"] = dio.MultipartFile.fromBytes(
        fileBytes,
        filename: pickedXFile.name,
      );
    }

    dio.FormData formData = dio.FormData.fromMap(payloadMap);

    final response = await apiClient.post(
      '/api/superuser/create/',
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }
}

// ==========================================================================
// 2. MAIN CORE TERMINAL SCREEN UI (Softwing Tech Labs Theme)
// ==========================================================================
class SuperuserCreateScreen extends StatefulWidget {
  const SuperuserCreateScreen({super.key});

  @override
  State<SuperuserCreateScreen> createState() => _SuperuserCreateScreenState();
}

class _SuperuserCreateScreenState extends State<SuperuserCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = SuperuserRegistrationRepository();

  // --- Theme Color Palette ---
  static const Color brandBlue = Color(0xFF0066B3);
  static const Color brandRed = Color(0xFFD32027);
  static const Color deepCarbon = Color(0xFF0B0E14);
  static const Color surfaceCard = Color(0xFF141923);
  static const Color textMuted = Color(0xFF8B949E);

  // --- Input Data Controllers ---
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  XFile? _pickedXFile;
  Uint8List? _webImageBytes;
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        setState(() {
          _pickedXFile = image;
          _webImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("FileSystem Media Attachment Exception: $e");
    }
  }

  Future<void> _processRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: brandBlue),
      ),
    );

    final navigator = Navigator.of(context, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final routerContext = context;

    try {
      await _repo.commitSuperuser(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        pickedXFile: _pickedXFile,
      );

      navigator.pop();

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("✅ Softwing Superuser Account Initialized! Redirecting..."),
          backgroundColor: Color(0xFF0D9488),
          duration: Duration(seconds: 2),
        ),
      );

      _resetFormCanvas();

      if (mounted) {
        routerContext.go('/login');
      }
    } catch (e) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("❌ Superuser Initialization Failed: ${e.toString()}"),
          backgroundColor: brandRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetFormCanvas() {
    setState(() {
      _firstNameCtrl.clear();
      _lastNameCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _pickedXFile = null;
      _webImageBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0F141C),
      appBar: AppBar(
        backgroundColor: deepCarbon,
        elevation: 0,
        toolbarHeight: 70,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/icons/logo.png',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "SOFTWING TECH LABS • HRMS CORE",
                  style: TextStyle(fontSize: 12, color: brandBlue, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
                Text(
                  "INITIALIZE ROOT SUPERUSER PROFILE",
                  style: TextStyle(fontSize: 9, color: textMuted, letterSpacing: 0.8),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.white12, height: 1),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.white10),
                ),
                color: surfaceCard,
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 20 : 36),
                  child: Column(
                    children: [
                      isMobile
                          ? Column(children: [_buildAvatarSection(), const SizedBox(height: 28), _buildFormSection()])
                          : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildAvatarSection()),
                          const SizedBox(width: 40),
                          Expanded(flex: 5, child: _buildFormSection()),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 16),
                      _buildSubmissionActionBlock(isMobile),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "ROOT PROFILE AVATAR",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.0),
        ),
        const SizedBox(height: 16),
        Stack(
          children: [
            CircleAvatar(
              radius: 64,
              backgroundColor: deepCarbon,
              backgroundImage: _webImageBytes != null ? MemoryImage(_webImageBytes!) : null,
              child: _webImageBytes == null
                  ? const Icon(Icons.person_add_alt_1_rounded, size: 44, color: textMuted)
                  : null,
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: brandBlue,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                  onPressed: _pickProfileImage,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          "Upload official administrator picture for authentication logs and signature certificates.",
          style: TextStyle(fontSize: 9, color: textMuted, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "SUPERUSER CREDENTIALS SPECIFICATION",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
        ),
        const SizedBox(height: 6),
        const Text(
          "This account will have full access over company staff records, payroll generation, and system routes.",
          style: TextStyle(fontSize: 10, color: textMuted),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildInputField(_firstNameCtrl, "FIRST NAME", Icons.badge_outlined)),
            const SizedBox(width: 14),
            Expanded(child: _buildInputField(_lastNameCtrl, "LAST NAME", Icons.badge_outlined)),
          ],
        ),
        const SizedBox(height: 16),
        _buildInputField(
          _emailCtrl,
          "OFFICIAL ADMIN EMAIL",
          Icons.email_outlined,
          validator: (v) {
            if (v == null || v.isEmpty) return "Administrator email is required.";
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return "Enter a valid email format.";
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          validator: (v) => (v == null || v.length < 8) ? "Master password must be at least 8 characters." : null,
          decoration: InputDecoration(
            labelText: "MASTER SECURITY PASSWORD",
            labelStyle: const TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 16, color: brandBlue),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 16,
                color: textMuted,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: deepCarbon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: brandBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: brandRed, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: brandRed, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(TextEditingController ctrl, String label, IconData icon, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? "$label cannot be blank." : null,
      style: const TextStyle(fontSize: 13, color: Colors.white),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        prefixIcon: Icon(icon, size: 16, color: brandBlue),
        filled: true,
        fillColor: deepCarbon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: brandBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: brandRed, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: brandRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildSubmissionActionBlock(bool isMobile) {
    final List<Widget> submissionWidgets = [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.verified_user_outlined, color: Color(0xFF10B981), size: 16),
          SizedBox(width: 8),
          Text(
            "MSME Certified Portal Security Active",
            style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      if (isMobile) const SizedBox(height: 16),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          minimumSize: isMobile ? const Size(double.infinity, 48) : const Size(290, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: _isLoading ? null : _processRegistration,
        icon: const Icon(Icons.shield_outlined, size: 18),
        label: const Text(
          "INITIALIZE ROOT SUPERUSER",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
      ),
    ];

    return isMobile
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: submissionWidgets)
        : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: submissionWidgets);
  }
}