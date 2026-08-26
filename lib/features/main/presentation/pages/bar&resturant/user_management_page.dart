import 'dart:typed_data';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';

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
// 2. MAIN DIRECTORY CANVAS (Softwing UI Architecture)
// =============================================================================
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  static const Color brandBlue = Color(0xFF0066B3);
  static const Color brandRed = Color(0xFFD32027);
  static const Color darkSlate = Color(0xFF0B0E14);
  static const Color textMuted = Color(0xFF8B949E);

  String _selectedRole = "All Roles";
  String _userRoleStr = 'admin';
  String _currentLoggedInUserId = '';

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
          backgroundColor: const Color(0xFFF1F5F9),
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
            const Text(
              "STAFF & ACCESS DIRECTORY",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: darkSlate,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "ACTIVE ROLE: ${_userRoleStr.toUpperCase()}",
              style: const TextStyle(
                color: brandBlue,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
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
          icon: const Icon(Icons.person_add_alt_1_outlined, size: 15),
          label: const Text(
            "ONBOARD NEW STAFF",
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: brandBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: BlocBuilder<UserMgmtBloc, UserMgmtState>(
        builder: (context, state) {
          if (state is UserMgmtLoading) {
            return const Center(child: CircularProgressIndicator(color: brandBlue, strokeWidth: 2));
          }
          if (state is UserMgmtLoaded) {
            return Column(
              children: [
                _buildFilterSection(context, isMobile),
                const Divider(height: 1),
                Expanded(child: _buildResponsiveList(context, state.directoryRecords, isMobile)),
              ],
            );
          }
          return const Center(
            child: Text("Error syncing directory records. Check connection.", style: TextStyle(fontSize: 11)),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                style: const TextStyle(fontSize: 11.5),
                onChanged: (v) => context.read<UserMgmtBloc>().add(FilterUsers(query: v)),
                decoration: const InputDecoration(
                  hintText: "Search by Name, Work Email or Username...",
                  hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                  prefixIcon: Icon(Icons.search, size: 15, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(bottom: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 140,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRole,
                style: const TextStyle(fontSize: 11, color: Colors.black87),
                items: ["All Roles", "Superuser", "Admin", "Staff"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
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
    if (users.isEmpty) {
      return const Center(child: Text("No operational staff records matched.", style: TextStyle(fontSize: 11)));
    }

    if (!isMobile) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                _hCell("EMPLOYEE IDENTITY", 6),
                _hCell("SYSTEM USERNAME", 4),
                _hCell("PORTAL ROLE", 3),
                _hCell("STATUS", 3),
                _hCell("ACTIONS", 4, true),
              ],
            ),
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
    final bool active = user['is_active'] ?? true;
    final String rowUserId = (user['user_id'] ?? '').toString().trim();
    final bool isSelf = rowUserId == _currentLoggedInUserId && _currentLoggedInUserId.isNotEmpty;

    return Container(
      color: isSelf ? brandBlue.withOpacity(0.04) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 6, child: _userAvatarTitle(user, isSelf)),
          Expanded(
            flex: 4,
            child: Text(
              user['username'] ?? "-",
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelf ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              user['role']?.toString().toUpperCase() ?? "STAFF",
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ),
          Expanded(flex: 3, child: Align(alignment: Alignment.centerLeft, child: _statusBadge(active))),
          Expanded(
            flex: 4,
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
      color: isSelf ? brandBlue.withOpacity(0.03) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelf ? brandBlue.withOpacity(0.4) : Colors.grey.shade200,
          width: isSelf ? 1.5 : 1,
        ),
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
            const Divider(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _mobileInfoItem("USERNAME", user['username'] ?? "-"),
                _mobileInfoItem("PORTAL ROLE", user['role']?.toString().toUpperCase() ?? "STAFF"),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditDialog(context, user),
                    icon: const Icon(Icons.edit, size: 13),
                    label: const Text("Edit", style: TextStyle(fontSize: 10)),
                  ),
                ),
                const SizedBox(width: 8),
                if (!isSelf) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showForceLogoutPrompt(context, user),
                      icon: const Icon(Icons.gpp_bad_outlined, size: 12, color: Colors.white),
                      label: const Text("Force Out", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showStatusPrompt(context, user),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: active ? Colors.red.shade50 : Colors.green.shade50,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        active ? "Deactivate" : "Activate",
                        style: TextStyle(
                          color: active ? brandRed : Colors.green.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const Expanded(
                    child: Center(
                      child: Text(
                        "CURRENT SESSION",
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: brandBlue, letterSpacing: 0.4),
                      ),
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

  Widget _buildProfessionalActionRow(BuildContext context, dynamic user, bool active, bool isSelf) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionContainerButton(
          tooltip: "Edit Profile Specs",
          icon: Icons.edit_outlined,
          iconColor: Colors.blueGrey.shade700,
          bgColor: Colors.blueGrey.shade50,
          onPressed: () => _showEditDialog(context, user),
        ),
        const SizedBox(width: 8),
        if (!isSelf) ...[
          _actionContainerButton(
            tooltip: "Force Terminate Active Sessions",
            icon: Icons.gpp_bad_rounded,
            iconColor: brandRed,
            bgColor: brandRed.withOpacity(0.08),
            onPressed: () => _showForceLogoutPrompt(context, user),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 24,
            child: Tooltip(
              message: active ? "Deactivate User" : "Activate User",
              child: Switch(
                value: active,
                activeColor: brandBlue,
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade200,
                onChanged: (v) => _showStatusPrompt(context, user),
              ),
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: brandBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: const Text("YOU", style: TextStyle(color: brandBlue, fontSize: 8.5, fontWeight: FontWeight.w900)),
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
          radius: 15,
          backgroundColor: isSelf ? brandBlue : darkSlate,
          backgroundImage: profileUrl != null ? NetworkImage(profileUrl) : null,
          child: profileUrl == null
              ? Text(
            user['name']?[0] ?? "U",
            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
          )
              : null,
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
                    child: Text(
                      user['name'] ?? "Unknown",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: darkSlate),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelf) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, color: brandBlue, size: 12)
                  ]
                ],
              ),
              Text(
                user['email'] ?? "",
                style: const TextStyle(fontSize: 9, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
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
      Text(v, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: darkSlate)),
    ],
  );

  Widget _statusBadge(bool active) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: active ? Colors.green.shade50 : brandRed.withOpacity(0.08),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      active ? "ACTIVE" : "INACTIVE",
      style: TextStyle(
        color: active ? Colors.green.shade700 : brandRed,
        fontSize: 8,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _hCell(String t, int f, [bool r = false]) => Expanded(
    flex: f,
    child: Text(
      t,
      textAlign: r ? TextAlign.right : TextAlign.left,
      style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
    ),
  );

  Future<void> _showForceLogoutPrompt(BuildContext context, dynamic user) async {
    final bloc = context.read<UserMgmtBloc>();
    final String targetName = user['name'] ?? "This User";
    final String targetUserId = user['user_id'].toString();

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: brandRed, size: 20),
            SizedBox(width: 8),
            Text(
              "Force Session Termination",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: brandRed),
            ),
          ],
        ),
        content: Text(
          "Forcibly terminate active tokens and log out $targetName across all devices?",
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("CANCEL", style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              bloc.add(ForceLogoutUserSessions(userId: targetUserId, userName: targetName));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Force Logout dispatched for $targetName"), backgroundColor: brandRed),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white),
            child: const Text("TERMINATE SESSIONS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _showStatusPrompt(BuildContext context, dynamic user) async {
    final bool isActive = user['is_active'] ?? true;
    final String actionText = isActive ? "Deactivate" : "Activate";
    final Color actionColor = isActive ? brandRed : brandBlue;
    final bloc = context.read<UserMgmtBloc>();

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text("Confirm $actionText", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text("Change operational status for ${user['name']}?", style: const TextStyle(fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("CANCEL", style: TextStyle(fontSize: 11)),
          ),
          ElevatedButton(
            onPressed: () {
              bloc.add(ToggleUserStatus(user['user_id'], isActive));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: actionColor, foregroundColor: Colors.white),
            child: Text("EXECUTE", style: const TextStyle(fontSize: 11)),
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
// 🛡️ ONBOARDING MODAL COMPONENT (Softwing Brand Styling)
// =============================================================================
class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key});
  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  static const Color brandBlue = Color(0xFF0066B3);
  static const Color brandRed = Color(0xFFD32027);
  static const Color darkSlate = Color(0xFF0B0E14);

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
      messenger.showSnackBar(
        const SnackBar(content: Text("✅ Staff Member Onboarded Successfully!"), backgroundColor: Colors.green),
      );
      bloc.add(LoadUsers());
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("❌ Creation Fault: ${e.toString()}"), backgroundColor: brandRed),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Onboard New Staff Member",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: darkSlate),
                ),
                const SizedBox(height: 18),

                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFFF1F5F9),
                        backgroundImage: _imageBytesMemory != null ? MemoryImage(_imageBytesMemory!) : null,
                        child: _imageBytesMemory == null
                            ? const Icon(Icons.add_a_photo_outlined, size: 20, color: Colors.blueGrey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: brandBlue,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.edit, size: 12, color: Colors.white),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

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
                    Expanded(child: _buildInput(_ageController, "AGE", Icons.calendar_month_outlined)),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                        decoration: _inputStyle("GENDER", Icons.transgender_outlined),
                        items: const [
                          DropdownMenuItem(value: "MALE", child: Text("Male")),
                          DropdownMenuItem(value: "FEMALE", child: Text("Female")),
                        ],
                        onChanged: (v) => setState(() => _selectedGender = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                        decoration: _inputStyle("PORTAL ROLE", Icons.admin_panel_settings_outlined),
                        items: const [
                          DropdownMenuItem(value: "admin", child: Text("Admin / Manager")),
                          DropdownMenuItem(value: "superuser", child: Text("Superuser")),
                        ],
                        onChanged: (v) => setState(() => _selectedRole = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildInput(_emailController, "OFFICIAL WORK EMAIL", Icons.email_outlined),
                const SizedBox(height: 12),
                _buildInput(_passwordController, "ACCOUNT ACCESS PASSWORD", Icons.lock_outline, isPass: true),
                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("CANCEL", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5))
                          : const Text("ONBOARD EMPLOYEE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
      decoration: _inputStyle(lbl, icon),
      validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
    );
  }

  InputDecoration _inputStyle(String lbl, IconData icon) => InputDecoration(
    labelText: lbl,
    labelStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey),
    prefixIcon: Icon(icon, size: 15, color: brandBlue),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: brandBlue, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    isDense: true,
  );
}

class EditUserDialog extends StatelessWidget {
  final dynamic user;
  const EditUserDialog({super.key, required this.user});
  @override
  Widget build(BuildContext context) => const AlertDialog(title: Text("Edit User Placeholder"));
}