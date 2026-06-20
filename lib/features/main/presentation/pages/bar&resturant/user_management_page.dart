/*
import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';
import '../../widgets/create_user_dialog.dart';

// =============================================================================
// 1. BLOC LAYER: UNIFIED USER MANAGEMENT ENGINE
// =============================================================================
abstract class UserMgmtEvent {}
class LoadUsers extends UserMgmtEvent {}
class FilterUsers extends UserMgmtEvent {
  final String? query;
  final String? role;
  FilterUsers({this.query, this.role});
}
class ToggleUserStatus extends UserMgmtEvent {
  final String userId;
  final bool currentStatus;
  ToggleUserStatus(this.userId, this.currentStatus);
}

abstract class UserMgmtState {}
class UserMgmtLoading extends UserMgmtState {}
class UserMgmtLoaded extends UserMgmtState {
  final List directoryRecords;
  UserMgmtLoaded(this.directoryRecords);
}
class UserMgmtError extends UserMgmtState {
  final String message;
  UserMgmtError(this.message);
}

class UserMgmtBloc extends Bloc<UserMgmtEvent, UserMgmtState> {
  final ApiClient api;
  List _masterRecords = [];
  String _searchQuery = "";
  String _roleFilter = "All Roles";

  UserMgmtBloc(this.api) : super(UserMgmtLoading()) {
    on<LoadUsers>((event, emit) async {
      emit(UserMgmtLoading());
      try {
        // Calling your newly built unified directory matrix endpoint
        final res = await api.get('/api/users/directory/');
        print("user directory $res");
        _masterRecords = res.data['data'] ?? [];
        add(FilterUsers());
      } catch (e) {
        emit(UserMgmtError("Failed to synchronize user directories matrix."));
      }
    });

    on<FilterUsers>((event, emit) {
      if (event.query != null) _searchQuery = event.query!.toLowerCase().trim();
      if (event.role != null) _roleFilter = event.role!;

      List filteredList = _masterRecords.where((u) {
        final name = (u['name'] ?? "").toString().toLowerCase();
        final email = (u['email'] ?? "").toString().toLowerCase();
        final username = (u['username'] ?? "").toString().toLowerCase();
        final roleStr = (u['role'] ?? "admin").toString().toLowerCase();

        final matchesSearch = name.contains(_searchQuery) || email.contains(_searchQuery) || username.contains(_searchQuery);
        final matchesRole = _roleFilter == "All Roles" || roleStr == _roleFilter.toLowerCase();
        return matchesSearch && matchesRole;
      }).toList();

      emit(UserMgmtLoaded(filteredList));
    });

    on<ToggleUserStatus>((event, emit) async {
      try {
        final String action = event.currentStatus ? 'deactivate' : 'activate';
        // Intercepting with unified user profiles toggles endpoint matrix
        await api.post('/api/users/${event.userId}/status/$action/');
        add(LoadUsers());
      } catch (e) {
        debugPrint("Status Interceptor Fault: $e");
      }
    });
  }
}

// =============================================================================
// 2. MAIN VIEW SURFACE: HIGH-DENSITY DIRECTORY CANVAS
// =============================================================================
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String _selectedRole = "All Roles";
  String _userRoleStr = 'admin';

  @override
  void initState() {
    super.initState();
    _fetchRole();
  }

  Future<void> _fetchRole() async {
    final role = await const FlutterSecureStorage().read(key: 'user_role') ?? 'admin';
    if (mounted) setState(() => _userRoleStr = role.toLowerCase().trim());
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return BlocProvider(
      create: (context) => UserMgmtBloc(sl<ApiClient>())..add(LoadUsers()),
      child: Builder(builder: (newContext) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFB),
          body: Padding(
            padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(newContext, isMobile),
                const SizedBox(height: 16),
                Expanded(child: _buildMainContent(newContext, isMobile)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("FINANCIAL USER DIRECTORY", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(height: 2),
            Text("CURRENT AUTH SCOPE: ${_userRoleStr.toUpperCase()}", style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            final bloc = BlocProvider.of<UserMgmtBloc>(context);
            showDialog(
              context: context,
              builder: (_) => BlocProvider.value(value: bloc, child: const CreateUserDialog()),
            );
          },
          icon: const Icon(Icons.person_add_alt_1_outlined, size: 14),
          label: const Text("ONBOARD ADMINISTRATIVE REGISTRY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, bool isMobile) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
      child: BlocBuilder<UserMgmtBloc, UserMgmtState>(
        builder: (context, state) {
          if (state is UserMgmtLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4), strokeWidth: 2));
          if (state is UserMgmtLoaded) {
            return Column(
              children: [
                _buildFilterSection(context, isMobile),
                const Divider(height: 1),
                Expanded(child: _buildResponsiveList(context, state.directoryRecords, isMobile)),
              ],
            );
          }
          return const Center(child: Text("Error fetching security directories. Ensure network is active.", style: TextStyle(fontSize: 11)));
        },
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade200)),
              child: TextField(
                style: const TextStyle(fontSize: 11),
                onChanged: (v) => context.read<UserMgmtBloc>().add(FilterUsers(query: v)),
                decoration: const InputDecoration(hintText: "Search by Name, Email or Username...", hintStyle: TextStyle(fontSize: 11), prefixIcon: Icon(Icons.search, size: 14), border: InputBorder.none, contentPadding: EdgeInsets.only(bottom: 12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 140, height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRole,
                style: const TextStyle(fontSize: 11, color: Colors.black),
                items: ["All Roles", "Superuser", "Admin"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) {
                  setState(() => _selectedRole = v!);
                  context.read<UserMgmtBloc>().add(FilterUsers(role: v));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveList(BuildContext context, List users, bool isMobile) {
    if (users.isEmpty) return const Center(child: Text("Zero operational user mappings matched.", style: TextStyle(fontSize: 11)));

    if (!isMobile) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFF8FAFC),
            child: Row(children: [
              _hCell("IDENTITY ADMINISTRATIVE LAYER", 3),
              _hCell("SYSTEM USERNAME", 2),
              _hCell("TIER ACCESS SCOPE", 2),
              _hCell("ACCOUNT STATUS", 2),
              _hCell("MANAGEMENT TRANSACTIONS ACTIONS", 2, true)
            ]),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (ctx, i) => _buildTableRow(context, users[i]),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: users.length,
      padding: const EdgeInsets.all(10),
      itemBuilder: (ctx, i) => _buildMobileCard(context, users[i]),
    );
  }

  Widget _buildTableRow(BuildContext context, dynamic user) {
    bool active = user['is_active'] ?? true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: _userAvatarTitle(user)),
          Expanded(flex: 2, child: Text(user['username'] ?? "-", style: const TextStyle(fontSize: 11, color: Colors.black87))),
          Expanded(flex: 2, child: Text(user['role']?.toString().toUpperCase() ?? "ADMIN", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
          Expanded(flex: 2, child: _statusBadge(active)),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Switch(
                    value: active,
                    activeColor: const Color(0xFF00BCD4),
                    onChanged: (v) => _showStatusPrompt(context, user)
                ),
                IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.blueGrey),
                    onPressed: () => _showEditDialog(context, user)
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCard(BuildContext context, dynamic user) {
    bool active = user['is_active'] ?? true;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                _userAvatarTitle(user),
                const Spacer(),
                _statusBadge(active),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _mobileInfoItem("USERNAME", user['username'] ?? "-"),
                _mobileInfoItem("ACCESS SCOPE", user['role']?.toString().toUpperCase() ?? "ADMIN"),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: () => _showEditDialog(context, user), icon: const Icon(Icons.edit, size: 14), label: const Text("Modify Specifications", style: TextStyle(fontSize: 10)))),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showStatusPrompt(context, user),
                    style: ElevatedButton.styleFrom(backgroundColor: active ? Colors.red.shade50 : Colors.green.shade50, elevation: 0),
                    child: Text(active ? "Deactivate" : "Activate", style: TextStyle(color: active ? Colors.red : Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _userAvatarTitle(dynamic user) {
    String? profileUrl = user['profile_image'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: const Color(0xFF0F4C81),
          backgroundImage: profileUrl != null ? NetworkImage(profileUrl) : null,
          child: profileUrl == null ? Text(user['name']?[0] ?? "U", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)) : null,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E293B))),
            Text(user['email'] ?? "", style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        )
      ],
    );
  }

  Widget _mobileInfoItem(String l, String v) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
      Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
    ],
  );

  Widget _statusBadge(bool active) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: active ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
      child: Text(active ? "ACTIVE RUNNING" : "TERMINATED LOCK", style: TextStyle(color: active ? Colors.green : Colors.red, fontSize: 8, fontWeight: FontWeight.bold))
  );

  Widget _hCell(String t, int f, [bool r = false]) => Expanded(flex: f, child: Text(t, textAlign: r ? TextAlign.right : TextAlign.left, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)));

  Future<void> _showStatusPrompt(BuildContext context, dynamic user) async {
    final bool isActive = user['is_active'] ?? true;
    final String actionText = isActive ? "Deactivate" : "Activate";
    final Color actionColor = isActive ? Colors.redAccent : const Color(0xFF00BCD4);
    final bloc = context.read<UserMgmtBloc>();

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text("Confirm Master $actionText", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text("Are you completely verified to change state matrices for: ${user['name']}?", style: const TextStyle(fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("CANCEL", style: TextStyle(fontSize: 11))),
          ElevatedButton(
            onPressed: () {
              bloc.add(ToggleUserStatus(user['user_id'], isActive));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: actionColor, foregroundColor: Colors.white),
            child: Text("YES, EXECUTE", style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, dynamic user) {
    final bloc = BlocProvider.of<UserMgmtBloc>(context);
    showDialog(context: context, builder: (_) => BlocProvider.value(value: bloc, child: EditUserDialog(user: user)));
  }
}

// =============================================================================
// 🛡️ ONBOARDING MODAL COMPONENT: CREATE DIALOG (MULTIPART & WEB SAFE)
// =============================================================================
class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key});
  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();

  XFile? _pickedImage;
  Uint8List? _imageBytesMemory;
  String _selectedRole = "admin"; // Strictly locked to your 2 choices criteria architecture
  String _selectedGender = "MALE";
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _pickedImage = file;
          _imageBytesMemory = bytes;
        });
      }
    } catch (e) {
      debugPrint("Media Exception: $e");
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<UserMgmtBloc>();

    try {
      // Compiling parameters maps for combined validation pipelines
      final Map<String, dynamic> dataMap = {
        "first_name": _firstNameController.text.trim(),
        "last_name": _lastNameController.text.trim(),
        "email": _emailController.text.trim(),
        "password": _passwordController.text,
        "phone_number": _phoneController.text.trim(),
        "role": _selectedRole,
        "age": int.tryParse(_ageController.text) ?? 25,
        "gender": _selectedGender,
      };

      if (_pickedImage != null && _imageBytesMemory != null) {
        dataMap["profile_image"] = dio.MultipartFile.fromBytes(_imageBytesMemory!, filename: _pickedImage!.name);
      }

      final dio.FormData formData = dio.FormData.fromMap(dataMap);
      await sl<ApiClient>().post('/api/admin/create/', data: formData);

      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text("✅ Administrator Onboarded Successfully!"), backgroundColor: Colors.green));
      bloc.add(LoadUsers());
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("❌ Creation Fault: ${e.toString()}"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Onboard Account Registry", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const SizedBox(height: 16),

                // IMAGE PICKS ELEMENT
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFFF1F5F9),
                        backgroundImage: _imageBytesMemory != null ? MemoryImage(_imageBytesMemory!) : null,
                        child: _imageBytesMemory == null ? const Icon(Icons.add_a_photo_outlined, size: 20, color: Colors.blueGrey) : null,
                      ),
                      Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 11, backgroundColor: const Color(0xFF0F4C81), child: IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.edit, size: 10, color: Colors.white), onPressed: _pickImage))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: _buildInput(_firstNameController, "FIRST NAME", Icons.badge_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildInput(_lastNameController, "LAST NAME", Icons.badge_outlined)),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _buildInput(_phoneController, "PHONE NUMBER", Icons.phone_android_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildInput(_ageController, "AGE SPECS", Icons.calendar_month_outlined)),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        style: const TextStyle(fontSize: 11, color: Colors.black),
                        decoration: _inputStyle("GENDER", Icons.transgender_outlined),
                        items: const [DropdownMenuItem(value: "MALE", child: Text("Male")), DropdownMenuItem(value: "FEMALE", child: Text("Female"))],
                        onChanged: (v) => setState(() => _selectedGender = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        style: const TextStyle(fontSize: 11, color: Colors.black),
                        decoration: _inputStyle("ROLE MATRIX", Icons.admin_panel_settings_outlined),
                        items: const [DropdownMenuItem(value: "admin", child: Text("Admin / Manager")), DropdownMenuItem(value: "superuser", child: Text("Superuser System"))],
                        onChanged: (v) => setState(() => _selectedRole = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildInput(_emailController, "IDENTIFIER EMAIL ADDRESS", Icons.email_outlined),
                const SizedBox(height: 12),
                _buildInput(_passwordController, "SECURITY ACCESS KEY CODE", Icons.lock_outline, isPass: true),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(fontSize: 11))),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitData,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                      child: _isLoading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5)) : const Text("INITIALIZE SYSTEM ACCESS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String lbl, IconData icon, {bool isPass = false}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPass,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      decoration: _inputStyle(lbl, icon),
      validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
    );
  }

  InputDecoration _inputStyle(String lbl, IconData icon) => InputDecoration(
    labelText: lbl,
    labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
    prefixIcon: Icon(icon, size: 14, color: const Color(0xFF00BCD4)),
    border: const OutlineInputBorder(),
    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    isDense: true,
  );
}

*/


import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';
import '../../widgets/create_user_dialog.dart';

// =============================================================================
// 1. BLOC LAYER: UNIFIED USER MANAGEMENT ENGINE (WITH FORCE LOGOUT HOOKS)
// =============================================================================
abstract class UserMgmtEvent {}
class LoadUsers extends UserMgmtEvent {}
class FilterUsers extends UserMgmtEvent {
  final String? query;
  final String? role;
  FilterUsers({this.query, this.role});
}
class ToggleUserStatus extends UserMgmtEvent {
  final String userId;
  final bool currentStatus;
  ToggleUserStatus(this.userId, this.currentStatus);
}
class ForceLogoutUserSessions extends UserMgmtEvent {
  final String userId;
  final String userName;
  ForceLogoutUserSessions({required this.userId, required this.userName});
}

abstract class UserMgmtState {}
class UserMgmtLoading extends UserMgmtState {}
class UserMgmtLoaded extends UserMgmtState {
  final List directoryRecords;
  UserMgmtLoaded(this.directoryRecords);
}
class UserMgmtError extends UserMgmtState {
  final String message;
  UserMgmtError(this.message);
}

class UserMgmtBloc extends Bloc<UserMgmtEvent, UserMgmtState> {
  final ApiClient api;
  List _masterRecords = [];
  String _searchQuery = "";
  String _roleFilter = "All Roles";

  UserMgmtBloc(this.api) : super(UserMgmtLoading()) {
    on<LoadUsers>((event, emit) async {
      emit(UserMgmtLoading());
      try {
        final res = await api.get('/api/users/directory/');
        print("user directory $res");
        _masterRecords = res.data['data'] ?? [];
        add(FilterUsers());
      } catch (e) {
        emit(UserMgmtError("Failed to synchronize user directories matrix."));
      }
    });

    on<FilterUsers>((event, emit) {
      if (event.query != null) _searchQuery = event.query!.toLowerCase().trim();
      if (event.role != null) _roleFilter = event.role!;

      List filteredList = _masterRecords.where((u) {
        final name = (u['name'] ?? "").toString().toLowerCase();
        final email = (u['email'] ?? "").toString().toLowerCase();
        final username = (u['username'] ?? "").toString().toLowerCase();
        final roleStr = (u['role'] ?? "admin").toString().toLowerCase();

        final matchesSearch = name.contains(_searchQuery) || email.contains(_searchQuery) || username.contains(_searchQuery);
        final matchesRole = _roleFilter == "All Roles" || roleStr == _roleFilter.toLowerCase();
        return matchesSearch && matchesRole;
      }).toList();

      emit(UserMgmtLoaded(filteredList));
    });

    on<ToggleUserStatus>((event, emit) async {
      try {
        final String action = event.currentStatus ? 'deactivate' : 'activate';
        await api.post('/api/users/${event.userId}/status/$action/');
        add(LoadUsers());
      } catch (e) {
        debugPrint("Status Interceptor Fault: $e");
      }
    });

    on<ForceLogoutUserSessions>((event, emit) async {
      try {
        await api.post('/api/admin/devices/', data: {
          "user_id": event.userId,
          "action": "logout_all_devices"
        });
        add(LoadUsers());
      } catch (e) {
        debugPrint("Force Logout Communication Error: $e");
      }
    });
  }
}

// =============================================================================
// 2. MAIN VIEW SURFACE: HIGH-DENSITY DIRECTORY CANVAS
// =============================================================================
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String _selectedRole = "All Roles";
  String _userRoleStr = 'admin';
  String _currentLoggedInUserId = ''; // 🌟 Tracks central active log session key

  @override
  void initState() {
    super.initState();
    _fetchSessionMetadata();
  }

  Future<void> _fetchSessionMetadata() async {
    const storage = FlutterSecureStorage();
    final role = await storage.read(key: 'user_role') ?? 'admin';
    final currentUid = await storage.read(key: 'user_id') ?? '';
    if (mounted) {
      setState(() {
        _userRoleStr = role.toLowerCase().trim();
        _currentLoggedInUserId = currentUid.trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 900;

    return BlocProvider(
      create: (context) => UserMgmtBloc(sl<ApiClient>())..add(LoadUsers()),
      child: Builder(builder: (newContext) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFB),
          body: Padding(
            padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(newContext, isMobile),
                const SizedBox(height: 16),
                Expanded(child: _buildMainContent(newContext, isMobile)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("FINANCIAL USER DIRECTORY", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
            const SizedBox(height: 2),
            Text("CURRENT AUTH SCOPE: ${_userRoleStr.toUpperCase()}", style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () {
            final bloc = BlocProvider.of<UserMgmtBloc>(context);
            showDialog(
              context: context,
              builder: (_) => BlocProvider.value(value: bloc, child: const CreateUserDialog()),
            );
          },
          icon: const Icon(Icons.person_add_alt_1_outlined, size: 14),
          label: const Text("ONBOARD ADMINISTRATIVE REGISTRY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, bool isMobile) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.shade200)),
      child: BlocBuilder<UserMgmtBloc, UserMgmtState>(
        builder: (context, state) {
          if (state is UserMgmtLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4), strokeWidth: 2));
          if (state is UserMgmtLoaded) {
            return Column(
              children: [
                _buildFilterSection(context, isMobile),
                const Divider(height: 1),
                Expanded(child: _buildResponsiveList(context, state.directoryRecords, isMobile)),
              ],
            );
          }
          return const Center(child: Text("Error fetching security directories. Ensure network is active.", style: TextStyle(fontSize: 11)));
        },
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade200)),
              child: TextField(
                style: const TextStyle(fontSize: 11),
                onChanged: (v) => context.read<UserMgmtBloc>().add(FilterUsers(query: v)),
                decoration: const InputDecoration(hintText: "Search by Name, Email or Username...", hintStyle: TextStyle(fontSize: 11), prefixIcon: Icon(Icons.search, size: 14), border: InputBorder.none, contentPadding: EdgeInsets.only(bottom: 12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 140, height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey.shade300)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRole,
                style: const TextStyle(fontSize: 11, color: Colors.black),
                items: ["All Roles", "Superuser", "Admin"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) {
                  setState(() => _selectedRole = v!);
                  context.read<UserMgmtBloc>().add(FilterUsers(role: v));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveList(BuildContext context, List users, bool isMobile) {
    if (users.isEmpty) return const Center(child: Text("Zero operational user mappings matched.", style: TextStyle(fontSize: 11)));

    if (!isMobile) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF8FAFC),
            child: Row(children: [
              _hCell("IDENTITY ADMINISTRATIVE LAYER", 6), // 🌟 Pure Integer
              _hCell("SYSTEM USERNAME", 4),                // 🌟 Pure Integer
              _hCell("TIER ACCESS SCOPE", 3),             // 🌟 Pure Integer
              _hCell("ACCOUNT STATUS", 3),                // 🌟 Pure Integer
              _hCell("SECURITY CONTEXT ACTIONS", 4, true)  // 🌟 Pure Integer
            ]),
          ),          Expanded(
            child: ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (ctx, i) => _buildTableRow(context, users[i]),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: users.length,
      padding: const EdgeInsets.all(10),
      itemBuilder: (ctx, i) => _buildMobileCard(context, users[i]),
    );
  }

  Widget _buildTableRow(BuildContext context, dynamic user) {
    final bool active = user['is_active'] ?? true;
    final String rowUserId = (user['user_id'] ?? '').toString().trim();
    // 🌟 Identify whether this row record is the current active logged admin context instance
    final bool isSelf = rowUserId == _currentLoggedInUserId && _currentLoggedInUserId.isNotEmpty;

    return Container(
      color: isSelf ? const Color(0xFFE0F7FA).withOpacity(0.4) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 6, child: _userAvatarTitle(user, isSelf)), // 🌟 Clean 6
          Expanded(flex: 4, child: Text(user['username'] ?? "-", style: TextStyle(fontSize: 11, fontWeight: isSelf ? FontWeight.bold : FontWeight.normal, color: Colors.black87), overflow: TextOverflow.ellipsis)), // 🌟 Clean 4
          Expanded(flex: 3, child: Text(user['role']?.toString().toUpperCase() ?? "ADMIN", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey))), // 🌟 Clean 3
          Expanded(flex: 3, child: Align(alignment: Alignment.centerLeft, child: _statusBadge(active))), // 🌟 Clean 3
          Expanded(
            flex: 4, // 🌟 Clean 4
            child: _buildProfessionalActionRow(context, user, active, isSelf),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCard(BuildContext context, dynamic user) {
    final bool active = user['is_active'] ?? true;
    final String rowUserId = (user['user_id'] ?? '').toString().trim();
    final bool isSelf = rowUserId == _currentLoggedInUserId && _currentLoggedInUserId.isNotEmpty;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: isSelf ? const Color(0xFFE0F7FA).withOpacity(0.3) : Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: isSelf ? const Color(0xFF00BCD4).withOpacity(0.4) : Colors.grey.shade200, width: isSelf ? 1.5 : 1)
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _userAvatarTitle(user, isSelf)),
                _statusBadge(active),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _mobileInfoItem("USERNAME", user['username'] ?? "-"),
                _mobileInfoItem("ACCESS SCOPE", user['role']?.toString().toUpperCase() ?? "ADMIN"),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: () => _showEditDialog(context, user), icon: const Icon(Icons.edit, size: 14), label: const Text("Modify Specifications", style: TextStyle(fontSize: 10)))),
                const SizedBox(width: 8),
                if (!isSelf) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showForceLogoutPrompt(context, user),
                      icon: const Icon(Icons.gpp_bad_outlined, size: 12, color: Colors.white),
                      label: const Text("Force Out", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, elevation: 0, padding: EdgeInsets.zero),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showStatusPrompt(context, user),
                      style: ElevatedButton.styleFrom(backgroundColor: active ? Colors.red.shade50 : Colors.green.shade50, elevation: 0, padding: EdgeInsets.zero),
                      child: Text(active ? "Deactivate" : "Activate", style: TextStyle(color: active ? Colors.red : Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else ...[
                  const Expanded(
                    child: Center(
                      child: Text("ACTIVE SESSION (YOU)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00BCD4), letterSpacing: 0.3)),
                    ),
                  )
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // 💎 HIGH-DENSITY HIGH-DEFINITION ERP ACTION BUTTONS CELL
  // =============================================================================
  Widget _buildProfessionalActionRow(BuildContext context, dynamic user, bool active, bool isSelf) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Edit Action
        _actionContainerButton(
          tooltip: "Edit Account Specs",
          icon: Icons.edit_outlined,
          iconColor: Colors.blueGrey.shade700,
          bgColor: Colors.blueGrey.shade50,
          onPressed: () => _showEditDialog(context, user),
        ),
        const SizedBox(width: 8),

        // Self Protection Shield Layers
        if (!isSelf) ...[
          // 2. Realtime Force Session Revoke
          _actionContainerButton(
            tooltip: "Force Terminate Multi-Devices Real-Time",
            icon: Icons.gpp_bad_rounded,
            iconColor: Colors.red.shade700,
            bgColor: Colors.red.shade50,
            onPressed: () => _showForceLogoutPrompt(context, user),
          ),
          const SizedBox(width: 10),

          // 3. Status Matrix Switch
          SizedBox(
            height: 24,
            child: Tooltip(
              message: active ? "Deactivate Master Registry" : "Activate Master Registry",
              child: Switch(
                value: active,
                activeColor: const Color(0xFF00BCD4),
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade200,
                onChanged: (v) => _showStatusPrompt(context, user),
              ),
            ),
          ),
        ] else ...[
          // Safe lock banner context loops
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF00BCD4).withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
            child: const Text("CURRENT SELF", style: TextStyle(color: Color(0xFF00BCD4), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
          )
        ]
      ],
    );
  }

  Widget _actionContainerButton({
    required String tooltip,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
          child: Icon(icon, size: 14, color: iconColor),
        ),
      ),
    );
  }

  Widget _userAvatarTitle(dynamic user, bool isSelf) {
    String? profileUrl = user['profile_image'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isSelf ? const Color(0xFF00BCD4) : const Color(0xFF0F4C81),
          backgroundImage: profileUrl != null ? NetworkImage(profileUrl) : null,
          child: profileUrl == null ? Text(user['name']?[0] ?? "U", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)) : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(user['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E293B)), overflow: TextOverflow.ellipsis),
                  ),
                  if (isSelf) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.stars, color: Color(0xFF00BCD4), size: 11) // Visual crown bookmark indicator
                  ]
                ],
              ),
              Text(user['email'] ?? "", style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis),
            ],
          ),
        )
      ],
    );
  }

  Widget _mobileInfoItem(String l, String v) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l, style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
      Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
    ],
  );

  Widget _statusBadge(bool active) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: active ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
      child: Text(active ? "ACTIVE" : "TERMINATED", style: TextStyle(color: active ? Colors.green : Colors.red, fontSize: 8, fontWeight: FontWeight.bold))
  );

  Widget _hCell(String t, int f, [bool r = false]) => Expanded(flex: f, child: Text(t, textAlign: r ? TextAlign.right : TextAlign.left, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)));

  Future<void> _showForceLogoutPrompt(BuildContext context, dynamic user) async {
    final bloc = context.read<UserMgmtBloc>();
    final String targetName = user['name'] ?? "This Admin";
    final String targetUserId = user['user_id'].toString();

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
            SizedBox(width: 8),
            Text("CRITICAL: Force Session Terminate", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent)),
          ],
        ),
        content: Text("Are you absolutely sure you want to forcibly expire all tokens and logout $targetName on all mobile/desktop/web instances immediately?", style: const TextStyle(fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("CANCEL", style: TextStyle(fontSize: 11, color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              bloc.add(ForceLogoutUserSessions(userId: targetUserId, userName: targetName));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("⚡ Force Logout Sent Command Matrix for $targetName"), backgroundColor: Colors.orange.shade800)
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("TERMINATE ALL SESSIONS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _showStatusPrompt(BuildContext context, dynamic user) async {
    final bool isActive = user['is_active'] ?? true;
    final String actionText = isActive ? "Deactivate" : "Activate";
    final Color actionColor = isActive ? Colors.redAccent : const Color(0xFF00BCD4);
    final bloc = context.read<UserMgmtBloc>();

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text("Confirm Master $actionText", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text("Are you completely verified to change state matrices for: ${user['name']}?", style: const TextStyle(fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("CANCEL", style: TextStyle(fontSize: 11))),
          ElevatedButton(
            onPressed: () {
              bloc.add(ToggleUserStatus(user['user_id'], isActive));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: actionColor, foregroundColor: Colors.white),
            child: Text("YES, EXECUTE", style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, dynamic user) {
    final bloc = BlocProvider.of<UserMgmtBloc>(context);
    showDialog(context: context, builder: (_) => BlocProvider.value(value: bloc, child: EditUserDialog(user: user)));
  }
}

// =============================================================================
// 🛡️ ONBOARDING MODAL COMPONENT: CREATE DIALOG (MULTIPART & WEB SAFE)
// =============================================================================
class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key});
  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();

  XFile? _pickedImage;
  Uint8List? _imageBytesMemory;
  String _selectedRole = "admin";
  String _selectedGender = "MALE";
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _pickedImage = file;
          _imageBytesMemory = bytes;
        });
      }
    } catch (e) {
      debugPrint("Media Exception: $e");
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<UserMgmtBloc>();

    try {
      final Map<String, dynamic> dataMap = {
        "first_name": _firstNameController.text.trim(),
        "last_name": _lastNameController.text.trim(),
        "email": _emailController.text.trim(),
        "password": _passwordController.text,
        "phone_number": _phoneController.text.trim(),
        "role": _selectedRole,
        "age": int.tryParse(_ageController.text) ?? 25,
        "gender": _selectedGender,
      };

      if (_pickedImage != null && _imageBytesMemory != null) {
        dataMap["profile_image"] = dio.MultipartFile.fromBytes(_imageBytesMemory!, filename: _pickedImage!.name);
      }

      final dio.FormData formData = dio.FormData.fromMap(dataMap);
      await sl<ApiClient>().post('/api/admin/create/', data: formData);

      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text("✅ Administrator Onboarded Successfully!"), backgroundColor: Colors.green));
      bloc.add(LoadUsers());
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("❌ Creation Fault: ${e.toString()}"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Onboard Account Registry", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const SizedBox(height: 16),

                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFFF1F5F9),
                        backgroundImage: _imageBytesMemory != null ? MemoryImage(_imageBytesMemory!) : null,
                        child: _imageBytesMemory == null ? const Icon(Icons.add_a_photo_outlined, size: 20, color: Colors.blueGrey) : null,
                      ),
                      Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 11, backgroundColor: const Color(0xFF0F4C81), child: IconButton(padding: EdgeInsets.zero, icon: const Icon(Icons.edit, size: 10, color: Colors.white), onPressed: _pickImage))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: _buildInput(_firstNameController, "FIRST NAME", Icons.badge_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildInput(_lastNameController, "LAST NAME", Icons.badge_outlined)),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(child: _buildInput(_phoneController, "PHONE NUMBER", Icons.phone_android_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildInput(_ageController, "AGE SPECS", Icons.calendar_month_outlined)),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        style: const TextStyle(fontSize: 11, color: Colors.black),
                        decoration: _inputStyle("GENDER", Icons.transgender_outlined),
                        items: const [DropdownMenuItem(value: "MALE", child: Text("Male")), DropdownMenuItem(value: "FEMALE", child: Text("Female"))],
                        onChanged: (v) => setState(() => _selectedGender = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        style: const TextStyle(fontSize: 11, color: Colors.black),
                        decoration: _inputStyle("ROLE MATRIX", Icons.admin_panel_settings_outlined),
                        items: const [DropdownMenuItem(value: "admin", child: Text("Admin / Manager")), DropdownMenuItem(value: "superuser", child: Text("Superuser System"))],
                        onChanged: (v) => setState(() => _selectedRole = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildInput(_emailController, "IDENTIFIER EMAIL ADDRESS", Icons.email_outlined),
                const SizedBox(height: 12),
                _buildInput(_passwordController, "SECURITY ACCESS KEY CODE", Icons.lock_outline, isPass: true),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(fontSize: 11))),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitData,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                      child: _isLoading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5)) : const Text("INITIALIZE SYSTEM ACCESS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String lbl, IconData icon, {bool isPass = false}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPass,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      decoration: _inputStyle(lbl, icon),
      validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
    );
  }

  InputDecoration _inputStyle(String lbl, IconData icon) => InputDecoration(
    labelText: lbl,
    labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
    prefixIcon: Icon(icon, size: 14, color: const Color(0xFF00BCD4)),
    border: const OutlineInputBorder(),
    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    isDense: true,
  );
}

class EditUserDialog extends StatelessWidget {
  final dynamic user;
  const EditUserDialog({super.key, required this.user});
  @override
  Widget build(BuildContext context) => const AlertDialog(title: Text("Edit View Placeholder"));
}