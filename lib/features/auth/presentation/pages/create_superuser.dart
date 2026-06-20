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
    XFile? pickedXFile, // ✅ Fixed: Passed XFile instead of dart:io File for Web support
  }) async {

    // Base parameters creation
    final Map<String, dynamic> payloadMap = {
      "first_name": firstName,
      "last_name": lastName,
      "email": email,
      "password": password,
    };

    // If image exists, convert via cross-platform bytes reader pipeline
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
// 2. MAIN CORE TERMINAL SCREEN UI (Mobile + Web Responsive Canvas)
// ==========================================================================
class SuperuserCreateScreen extends StatefulWidget {
  const SuperuserCreateScreen({super.key});

  @override
  State<SuperuserCreateScreen> createState() => _SuperuserCreateScreenState();
}

class _SuperuserCreateScreenState extends State<SuperuserCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = SuperuserRegistrationRepository();

  // --- Input Data Controllers ---
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  XFile? _pickedXFile;          // Holds web-safe media reference pointer
  Uint8List? _webImageBytes;    // Holds local image matrix bytes for live rendering preview
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Cross-Platform Media Attachment Picker Framework
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

  // Pure Crashproof Execution Dispatch Sequence
  Future<void> _processRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      ),
    );

    // Dynamic Context Capture references before entering async operations gap
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

      navigator.pop(); // Safe loader dismissal via snapshot reference pointer

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("✅ Root Superuser Created Successfully! Redirecting to Auth Portal..."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      _resetFormCanvas();

      // GoRouter Safe Redirection Pipeline Trigger
      if (mounted) {
        routerContext.go('/login');
      }

    } catch (e) {
      navigator.pop(); // Dismiss loader safely on network exceptions bounds
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("❌ Platform Allocation Break: ${e.toString()}"),
          backgroundColor: Colors.red,
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
    const Color canvasThemeColor = Color(0xFF0F4C81); // Premium Royal Industrial Blue

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: canvasThemeColor,
        elevation: 1,
        toolbarHeight: 70,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ROOT SERVER PLATFORM SETUP", style: TextStyle(fontSize: 12, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            Text("ROOT SUPERUSER SPECIFICATION IDENTITY TERMINAL", style: TextStyle(fontSize: 9, color: Colors.white70)),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 950), // Symmetrical Layout Anchor Box
            child: Form(
              key: _formKey,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Symmetrical Form Canvas Layout Switcher Matrix
                      isMobile
                          ? Column(children: [_buildAvatarSection(), const SizedBox(height: 24), _buildFormSection()])
                          : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildAvatarSection()),
                          const SizedBox(width: 36),
                          Expanded(flex: 5, child: _buildFormSection()),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 12),
                      _buildSubmissionActionBlock(canvasThemeColor, isMobile),
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

  // --- Avatar Rendering Module (100% Web Compatible) ---
  Widget _buildAvatarSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("PROFILE IMAGE (OPTIONAL)", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        const SizedBox(height: 14),
        Stack(
          children: [
            CircleAvatar(
              radius: 65,
              backgroundColor: const Color(0xFFE2E8F0),
              // ✅ Fixed: Uses MemoryImage to circumvent Namespace browser violations completely
              backgroundImage: _webImageBytes != null ? MemoryImage(_webImageBytes!) : null,
              child: _webImageBytes == null
                  ? const Icon(Icons.person_add_alt_1_rounded, size: 45, color: Color(0xFF94A3B8))
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 4,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF0F4C81),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                  onPressed: _pickProfileImage,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          "Click camera icon to stream gallery image. Data is parsed via local memory buffers into core server filesystem endpoints directly.",
          style: TextStyle(fontSize: 8, color: Colors.blueGrey, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // --- Identity Fields Matrix Segment ---
  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("IDENTITY SPECIFICATIONS DATA MATRICES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildInputField(_firstNameCtrl, "FIRST NAME", Icons.badge_outlined)),
            const SizedBox(width: 12),
            Expanded(child: _buildInputField(_lastNameCtrl, "LAST NAME", Icons.badge_outlined)),
          ],
        ),
        const SizedBox(height: 16),
        _buildInputField(
          _emailCtrl,
          "ROOT SYSTEM OWNER EMAIL ADDRESS",
          Icons.email_outlined,
          validator: (v) {
            if (v == null || v.isEmpty) return "Email field data context tracking cannot be empty.";
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return "Invalid email matrix notation.";
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          validator: (v) => (v == null || v.length < 6) ? "Root master password must contain at least 6 tokens." : null,
          decoration: InputDecoration(
            labelText: "ROOT SECURITY MASTER PASSWORD",
            labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold),
            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.blueGrey),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 16),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(TextEditingController ctrl, String label, IconData icon, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      validator: validator ?? (v) => (v == null || v.trim().isEmpty) ? "$label mapping context cannot be blank." : null,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, size: 16, color: Colors.blueGrey),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        isDense: true,
      ),
    );
  }

  Widget _buildSubmissionActionBlock(Color activeColor, bool isMobile) {
    final List<Widget> submissionWidgets = [
      const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, color: Colors.green, size: 14),
          SizedBox(width: 6),
          Text("Security Sandbox Boundaries Checked & Mapped.", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
      if (isMobile) const SizedBox(height: 16),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: activeColor,
          foregroundColor: Colors.white,
          minimumSize: isMobile ? const Size(double.infinity, 46) : const Size(280, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 2,
        ),
        onPressed: _isLoading ? null : _processRegistration,
        icon: const Icon(Icons.cloud_done_outlined, size: 16),
        label: const Text("INITIALIZE PLATFORM ROOT OWNERSHIP", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    ];

    return isMobile
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: submissionWidgets)
        : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: submissionWidgets);
  }
}