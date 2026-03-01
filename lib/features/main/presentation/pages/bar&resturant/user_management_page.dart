
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';
import '../../../../inventory/presentation/bloc/location_bloc.dart';
import '../../widgets/create_user_dialog.dart';

// --- BLOC LAYER ---
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
  final List admins;
  final List staff;
  UserMgmtLoaded(this.admins, this.staff);
}
class UserMgmtError extends UserMgmtState { final String message; UserMgmtError(this.message); }

class UserMgmtBloc extends Bloc<UserMgmtEvent, UserMgmtState> {
  final ApiClient api;
  final storage = const FlutterSecureStorage();
  List _origAdmins = [];
  List _origStaff = [];
  String _lastQ = "";
  String _lastR = "All Roles";

  UserMgmtBloc(this.api) : super(UserMgmtLoading()) {
    on<LoadUsers>((event, emit) async {
      emit(UserMgmtLoading());
      try {
        final role = await storage.read(key: 'user_role') ?? 'staff';
        if (role == 'superuser') {
          final results = await Future.wait([
            api.get('/api/admin/list/'),
            api.get('/api/staff/list/')
          ]);
          _origAdmins = results[0].data['data'] ?? [];
          _origStaff = results[1].data['data'] ?? [];
        } else {
          final res = await api.get('/api/staff/list/');
          _origStaff = res.data['data'] ?? [];
          _origAdmins = [];
        }
        add(FilterUsers());
      } catch (e) { emit(UserMgmtError("Failed to fetch directory.")); }
    });

    on<FilterUsers>((event, emit) {
      if (event.query != null) _lastQ = event.query!.toLowerCase();
      if (event.role != null) _lastR = event.role!;

      List _runFilter(List list) {
        return list.where((u) {
          final name = (u['name'] ?? "").toString().toLowerCase();
          final email = (u['email'] ?? "").toString().toLowerCase();
          final roleStr = (u['role'] ?? "staff").toString().toLowerCase();
          final matchesSearch = name.contains(_lastQ) || email.contains(_lastQ);
          final matchesRole = _lastR == "All Roles" || roleStr == _lastR.toLowerCase();
          return matchesSearch && matchesRole;
        }).toList();
      }
      emit(UserMgmtLoaded(_runFilter(_origAdmins), _runFilter(_origStaff)));
    });

    on<ToggleUserStatus>((event, emit) async {
      try {
        await api.post('/api/staff/${event.userId}/${event.currentStatus ? 'deactivate' : 'activate'}/');
        add(LoadUsers());
      } catch (e) {}
    });
  }
}

// --- PRESENTATION LAYER ---
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});
  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String _selectedRole = "All Roles";
  String _userRoleStr = 'staff';

  @override
  void initState() {
    super.initState();
    _fetchRole();
  }

  Future<void> _fetchRole() async {
    final role = await const FlutterSecureStorage().read(key: 'user_role') ?? 'staff';
    if (mounted) setState(() { _userRoleStr = role.toLowerCase(); });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserMgmtBloc(sl<ApiClient>())..add(LoadUsers()),
      child: Builder(builder: (context) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopHeader(context),
                const SizedBox(height: 32),
                Expanded(child: _buildMainTableCard(context)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("User Management", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1C24))),
          Text("Role: ${_userRoleStr.toUpperCase()}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ]),
        ElevatedButton.icon(
          onPressed: () => showDialog(context: context, builder: (_) => BlocProvider.value(value: BlocProvider.of<UserMgmtBloc>(context), child: const CreateUserDialog())),
          icon: const Icon(Icons.person_add_alt_1, size: 18),
          label: const Text("CREATE NEW USER"),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1C24), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        ),
      ],
    );
  }

  Widget _buildMainTableCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: BlocBuilder<UserMgmtBloc, UserMgmtState>(
        builder: (context, state) {
          if (state is UserMgmtLoading) return const Center(child: CircularProgressIndicator());
          if (state is UserMgmtLoaded) {
            return Column(children: [
              _buildFilterSection(context),
              const Divider(height: 1),
              Expanded(child: _buildTabbedTable(context, state)),
            ]);
          }
          return const Center(child: Text("Error loading data"));
        },
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(children: [
        Expanded(child: Container(height: 40, decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)), child: TextField(onChanged: (v) => context.read<UserMgmtBloc>().add(FilterUsers(query: v)), decoration: const InputDecoration(hintText: "Search Employee", prefixIcon: Icon(Icons.search, size: 18), border: InputBorder.none, contentPadding: EdgeInsets.only(bottom: 8))))),
        const SizedBox(width: 12),
        _buildRoleDropdown(context),
      ]),
    );
  }

  Widget _buildRoleDropdown(BuildContext context) {
    return Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _selectedRole, items: ["All Roles", "Staff", "Admin"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (v) { setState(() { _selectedRole = v!; }); context.read<UserMgmtBloc>().add(FilterUsers(role: v)); })));
  }

  Widget _buildTabbedTable(BuildContext context, UserMgmtLoaded state) {
    bool isSuper = _userRoleStr == 'superuser';
    return DefaultTabController(length: isSuper ? 2 : 1, child: Column(children: [
      TabBar(isScrollable: true, tabAlignment: TabAlignment.start, labelColor: const Color(0xFF00BCD4), indicatorColor: const Color(0xFF00BCD4), tabs: [if (isSuper) const Tab(text: "ADMINS"), const Tab(text: "STAFF")]),
      Expanded(child: TabBarView(children: [if (isSuper) _buildTable(context, state.admins), _buildTable(context, state.staff)])),
    ]));
  }

  Widget _buildTable(BuildContext context, List users) {
    return Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), color: Colors.grey.shade50, child: Row(children: [_hCell("EMPLOYEE", 2), _hCell("LOCATION", 1), _hCell("GENDER", 1), _hCell("ROLE", 1), _hCell("STATUS", 1), _hCell("ACTION", 1, true)])),
      Expanded(child: ListView.separated(itemCount: users.length, separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100), itemBuilder: (ctx, i) => _buildRowUI(context, users[i]))),
    ]);
  }

  Widget _buildRowUI(BuildContext context, dynamic user) {
    bool active = user['is_active'] ?? true;
    String locName = user['location'] != null ? user['location']['name'] : "N/A";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(children: [
        Expanded(flex: 2, child: Row(children: [CircleAvatar(radius: 14, child: Text(user['name']?[0] ?? "U")), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), Text(user['email'] ?? "", style: const TextStyle(fontSize: 11, color: Colors.grey))])])),
        _cellCell(locName, 1),
        _cellCell(user['gender'] ?? "N/A", 1),
        _cellCell(user['role']?.toString().toUpperCase() ?? "STAFF", 1),
        Expanded(flex: 1, child: _statusBadge(active)),
        Expanded(flex: 1, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Switch(value: active, activeColor: const Color(0xFF00BCD4), onChanged: (v) => context.read<UserMgmtBloc>().add(ToggleUserStatus(user['user_id'], active))),
          IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _showEditDialog(context, user))
        ])),
      ]),
    );
  }

  void _showEditDialog(BuildContext context, dynamic user) {
    showDialog(context: context, builder: (_) => BlocProvider.value(value: BlocProvider.of<UserMgmtBloc>(context), child: EditUserDialog(user: user)));
  }

  Widget _statusBadge(bool active) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: active ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(12)), child: Text(active ? "ACTIVE" : "INACTIVE", style: TextStyle(color: active ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)));
  Widget _hCell(String t, int f, [bool r = false]) => Expanded(flex: f, child: Text(t, textAlign: r ? TextAlign.right : TextAlign.left, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)));
  Widget _cellCell(String t, int f) => Expanded(flex: f, child: Text(t, style: const TextStyle(fontSize: 12)));
}


// --- UPDATED EDIT DIALOG ---
class EditUserDialog extends StatefulWidget {
  final dynamic user;
  const EditUserDialog({super.key, required this.user});
  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late TextEditingController _nameController;
  late TextEditingController _passwordController;
  int? _locId;
  bool _saving = false;
  String _currentUserRole = 'staff';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name']);
    _passwordController = TextEditingController(); // Password field empty rakhein
    _locId = widget.user['location']?['id'];
    _loadCurrentRole();
  }

  Future<void> _loadCurrentRole() async {
    final role = await const FlutterSecureStorage().read(key: 'user_role') ?? 'staff';
    setState(() {
      _currentUserRole = role.toLowerCase();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool canEditPassword = _currentUserRole == 'superuser' ||
        (_currentUserRole == 'admin' && widget.user['role'] != 'superuser');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Edit User Profile",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1C24))),
            const SizedBox(height: 24),

            _buildLabel("FULL NAME"),
            TextField(
              controller: _nameController,
              decoration: _inputStyle("Enter full name", Icons.person_outline),
            ),
            const SizedBox(height: 16),

            _buildLabel("LOCATION"),
            BlocBuilder<LocationBloc, LocationState>(builder: (context, state) {
              return DropdownButtonFormField<int>(
                value: _locId,
                items: state is LocationLoaded
                    ? state.locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList()
                    : [],
                onChanged: (v) => setState(() => _locId = v),
                decoration: _inputStyle("Select location", Icons.location_on_outlined),
              );
            }),
            const SizedBox(height: 16),

            if (canEditPassword) ...[
              _buildLabel("RESET PASSWORD (LEAVE BLANK TO KEEP CURRENT)"),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: _inputStyle("Enter new password", Icons.lock_reset_outlined),
              ),
              const SizedBox(height: 8),
              const Text("Note: Entering a password here will override the user's current password.",
                  style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w500)),
            ],

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1C24),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() async {
    setState(() => _saving = true);
    try {
      final Map<String, dynamic> updateData = {
        "name": _nameController.text.trim(),
        "location": _locId,
      };

      // Agar password field bhara hai, tabhi bhejein
      if (_passwordController.text.isNotEmpty) {
        updateData["password"] = _passwordController.text;
      }

      final response = await sl<ApiClient>().put(
          '/api/user/${widget.user['user_id']}/update/',
          data: updateData
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User updated successfully"), backgroundColor: Colors.green),
        );
        context.read<UserMgmtBloc>().add(LoadUsers());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  InputDecoration _inputStyle(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF00BCD4)),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    );
  }
}