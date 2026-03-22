

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';
import '../../../../inventory/presentation/bloc/location_bloc.dart';
import '../../widgets/create_user_dialog.dart';

// =============================================================================
// 1. BLOC LAYER: USER MANAGEMENT
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
  final List admins;
  final List staff;
  UserMgmtLoaded(this.admins, this.staff);
}

class UserMgmtError extends UserMgmtState {
  final String message;
  UserMgmtError(this.message);
}

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
      } catch (e) {
        emit(UserMgmtError("Failed to fetch directory."));
      }
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
        final action = event.currentStatus ? 'deactivate' : 'activate';
        await api.post('/api/users/${event.userId}/status/$action/');
        add(LoadUsers());
      } catch (e) {
        debugPrint("Toggle Error: $e");
      }
    });
  }
}

// =============================================================================
// 2. PRESENTATION LAYER: MAIN PAGE
// =============================================================================
/*

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

  // --- PROFESSIONAL CONFIRMATION PROMPT ---
  Future<void> _showStatusPrompt(BuildContext context, dynamic user) async {
    final bool isActive = user['is_active'] ?? true;
    final String actionText = isActive ? "Deactivate" : "Activate";
    final Color actionColor = isActive ? Colors.redAccent : const Color(0xFF00BCD4);

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isActive ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: actionColor),
            const SizedBox(width: 12),
            Text("Confirm $actionText"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Are you sure you want to $actionText the user: ${user['name']}?"),
            const SizedBox(height: 12),
            if (isActive)
              const Text(
                "Warning: This user will be logged out immediately and will not be able to log back into the system until reactivated.",
                style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w500),
              )
            else
              const Text("The user will regain immediate access to their account and dashboard."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<UserMgmtBloc>().add(ToggleUserStatus(user['user_id'], isActive));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("YES, ${actionText.toUpperCase()}"),
          ),
        ],
      ),
    );
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
          Text("CURRENT ROLE: ${_userRoleStr.toUpperCase()}", style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 12, fontWeight: FontWeight.bold)),
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
          if (state is UserMgmtLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
          if (state is UserMgmtLoaded) {
            return Column(children: [
              _buildFilterSection(context),
              const Divider(height: 1),
              Expanded(child: _buildTabbedTable(context, state)),
            ]);
          }
          return const Center(child: Text("Error loading directory."));
        },
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(children: [
        Expanded(child: Container(height: 40, decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)), child: TextField(onChanged: (v) => context.read<UserMgmtBloc>().add(FilterUsers(query: v)), decoration: const InputDecoration(hintText: "Search Employees...", prefixIcon: Icon(Icons.search, size: 18), border: InputBorder.none, contentPadding: EdgeInsets.only(bottom: 8))))),
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
          // TRIGGER STATUS PROMPT INSTEAD OF DIRECT TOGGLE
          Switch(value: active, activeColor: const Color(0xFF00BCD4), onChanged: (v) => _showStatusPrompt(context, user)),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showEditDialog(context, user))
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

// =============================================================================
// 3. EDIT DIALOG: PROFILE & PASSWORD UPDATE
// =============================================================================

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
    _passwordController = TextEditingController();
    _locId = widget.user['location']?['id'];
    _loadCurrentRole();
  }

  Future<void> _loadCurrentRole() async {
    final role = await const FlutterSecureStorage().read(key: 'user_role') ?? 'staff';
    if (mounted) setState(() { _currentUserRole = role.toLowerCase(); });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _save() async {
    setState(() => _saving = true);
    try {
      final Map<String, dynamic> updateData = { "name": _nameController.text.trim(), "location": _locId };
      if (_passwordController.text.isNotEmpty) updateData["password"] = _passwordController.text;

      await sl<ApiClient>().put('/api/user/${widget.user['user_id']}/update/', data: updateData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully")));
        context.read<UserMgmtBloc>().add(LoadUsers());
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canEditPassword = _currentUserRole == 'superuser' || (_currentUserRole == 'admin' && widget.user['role'] != 'superuser');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Edit User Profile", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildLabel("FULL NAME"),
            TextField(controller: _nameController, decoration: _inputStyle("Full name", Icons.person_outline)),
            const SizedBox(height: 16),
            _buildLabel("LOCATION"),
            BlocBuilder<LocationBloc, LocationState>(builder: (context, state) {
              return DropdownButtonFormField<int>(
                value: _locId,
                items: state is LocationLoaded ? state.locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList() : [],
                onChanged: (v) => setState(() => _locId = v),
                decoration: _inputStyle("Location", Icons.location_on_outlined),
              );
            }),
            const SizedBox(height: 16),
            if (canEditPassword) ...[
              _buildLabel("RESET PASSWORD"),
              TextField(controller: _passwordController, obscureText: true, decoration: _inputStyle("New password", Icons.lock_reset_outlined)),
              const SizedBox(height: 8),
              const Text("Note: This will override the user's current password.", style: TextStyle(fontSize: 10, color: Colors.orange)),
            ],
            const SizedBox(height: 32),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1C24), foregroundColor: Colors.white),
                child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE"),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)));
  InputDecoration _inputStyle(String hint, IconData icon) => InputDecoration(hintText: hint, prefixIcon: Icon(icon, size: 20, color: const Color(0xFF00BCD4)), filled: true, fillColor: const Color(0xFFF8F9FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12));
}*/




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
    if (mounted) {
      setState(() {
        _userRoleStr = role.toLowerCase();
      });
    }
  }

  // --- PROFESSIONAL CONFIRMATION PROMPT ---
  Future<void> _showStatusPrompt(BuildContext context, dynamic user) async {
    final bool isActive = user['is_active'] ?? true;
    final String actionText = isActive ? "Deactivate" : "Activate";
    final Color actionColor = isActive ? Colors.redAccent : const Color(0xFF00BCD4);
    final double screenWidth = MediaQuery.of(context).size.width;

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: EdgeInsets.all(screenWidth < 600 ? 20 : 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isActive ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: actionColor),
            const SizedBox(width: 12),
            Expanded(child: Text("Confirm $actionText", style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Are you sure you want to $actionText the user: ${user['name']}?"),
            const SizedBox(height: 12),
            Text(
              isActive
                  ? "Warning: User will be logged out immediately."
                  : "The user will regain immediate access to their account.",
              style: TextStyle(fontSize: 12, color: isActive ? Colors.red : Colors.blueGrey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              // Using context from the parent which has the Bloc
              context.read<UserMgmtBloc>().add(ToggleUserStatus(user['user_id'], isActive));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: actionColor, foregroundColor: Colors.white),
            child: Text("YES, ${actionText.toUpperCase()}"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    return BlocProvider(
      create: (context) => UserMgmtBloc(sl<ApiClient>())..add(LoadUsers()),
      // ✅ Builder provides a context BELOW the BlocProvider to fix the "BlocProvider.of() called with a context that does not contain a Bloc" error
      child: Builder(builder: (newContext) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopHeader(newContext, isMobile),
                  SizedBox(height: isMobile ? 20 : 32),
                  Expanded(child: _buildMainContent(newContext, isMobile)),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isMobile) {
    Widget titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("User Management", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1C24))),
        Text("ROLE: ${_userRoleStr.toUpperCase()}", style: const TextStyle(color: Color(0xFF00BCD4), fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );

    Widget createBtn = ElevatedButton.icon(
      onPressed: () {
        // ✅ Grab the Bloc using the correct context from the Builder
        final bloc = BlocProvider.of<UserMgmtBloc>(context);
        showDialog(
          context: context,
          builder: (_) => BlocProvider.value(
            value: bloc,
            child: const CreateUserDialog(),
          ),
        );
      },
      icon: const Icon(Icons.person_add_alt_1, size: 18),
      label: const Text("NEW USER"),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A1C24),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        titleSection,
        if (!isMobile) createBtn else Icon(Icons.person_add_alt_1, color: Colors.transparent), // Placeholder
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, bool isMobile) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: BlocBuilder<UserMgmtBloc, UserMgmtState>(
        builder: (context, state) {
          if (state is UserMgmtLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4)));
          if (state is UserMgmtLoaded) {
            return Column(children: [
              _buildFilterSection(context, isMobile),
              const Divider(height: 1),
              Expanded(
                child: DefaultTabController(
                  length: _userRoleStr == 'superuser' ? 2 : 1,
                  child: Column(children: [
                    TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: const Color(0xFF00BCD4),
                      indicatorColor: const Color(0xFF00BCD4),
                      tabs: [if (_userRoleStr == 'superuser') const Tab(text: "ADMINS"), const Tab(text: "STAFF")],
                    ),
                    Expanded(
                      child: TabBarView(children: [
                        if (_userRoleStr == 'superuser') _buildResponsiveList(context, state.admins, isMobile),
                        _buildResponsiveList(context, state.staff, isMobile),
                      ]),
                    ),
                  ]),
                ),
              ),
            ]);
          }
          return const Center(child: Text("Error loading directory."));
        },
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        children: [
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Container(
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
              child: TextField(
                onChanged: (v) => context.read<UserMgmtBloc>().add(FilterUsers(query: v)),
                decoration: const InputDecoration(hintText: "Search Employees...", prefixIcon: Icon(Icons.search, size: 18), border: InputBorder.none, contentPadding: EdgeInsets.only(bottom: 8)),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 0 : 12, height: isMobile ? 12 : 0),
          _buildRoleDropdown(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown(BuildContext context, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 150,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedRole,
          items: ["All Roles", "Staff", "Admin"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (v) {
            setState(() => _selectedRole = v!);
            context.read<UserMgmtBloc>().add(FilterUsers(role: v));
          },
        ),
      ),
    );
  }

  Widget _buildResponsiveList(BuildContext context, List users, bool isMobile) {
    if (users.isEmpty) return const Center(child: Text("No users found."));

    if (!isMobile) {
      return Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: Colors.grey.shade50,
          child: Row(children: [
            _hCell("EMPLOYEE", 2),
            _hCell("LOCATION", 1),
            _hCell("GENDER", 1),
            _hCell("ROLE", 1),
            _hCell("STATUS", 1),
            _hCell("ACTION", 1, true)
          ]),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (ctx, i) => _buildTableRow(context, users[i]),
          ),
        ),
      ]);
    }

    return ListView.builder(
      itemCount: users.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (ctx, i) => _buildMobileCard(context, users[i]),
    );
  }

  Widget _buildTableRow(BuildContext context, dynamic user) {
    bool active = user['is_active'] ?? true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(children: [
        Expanded(flex: 2, child: _userAvatarTitle(user)),
        _cellCell(user['location']?['name'] ?? "N/A", 1),
        _cellCell(user['gender'] ?? "N/A", 1),
        _cellCell(user['role']?.toString().toUpperCase() ?? "STAFF", 1),
        Expanded(flex: 1, child: _statusBadge(active)),
        Expanded(flex: 1, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Switch(value: active, activeColor: const Color(0xFF00BCD4), onChanged: (v) => _showStatusPrompt(context, user)),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showEditDialog(context, user))
        ])),
      ]),
    );
  }

  Widget _buildMobileCard(BuildContext context, dynamic user) {
    bool active = user['is_active'] ?? true;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(children: [
              _userAvatarTitle(user),
              const Spacer(),
              _statusBadge(active),
            ]),
            const Divider(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              _mobileInfoItem("LOCATION", user['location']?['name'] ?? "N/A"),
              _mobileInfoItem("ROLE", user['role']?.toString().toUpperCase() ?? "STAFF"),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _showEditDialog(context, user), icon: const Icon(Icons.edit, size: 16), label: const Text("Edit"))),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showStatusPrompt(context, user),
                    style: ElevatedButton.styleFrom(backgroundColor: active ? Colors.red.shade50 : Colors.green.shade50, elevation: 0),
                    child: Text(active ? "Deactivate" : "Activate", style: TextStyle(color: active ? Colors.red : Colors.green, fontSize: 12)),
                  )),
            ])
          ],
        ),
      ),
    );
  }

  Widget _userAvatarTitle(dynamic user) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      CircleAvatar(radius: 16, backgroundColor: const Color(0xFF00BCD4), child: Text(user['name']?[0] ?? "U", style: const TextStyle(color: Colors.white, fontSize: 12))),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(user['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text(user['email'] ?? "", style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ])
    ]);
  }

  Widget _mobileInfoItem(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(l, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
    Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
  ]);

  void _showEditDialog(BuildContext context, dynamic user) {
    final bloc = BlocProvider.of<UserMgmtBloc>(context);
    showDialog(
        context: context,
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: EditUserDialog(user: user),
        ));
  }

  Widget _statusBadge(bool active) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: active ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
      child: Text(active ? "ACTIVE" : "INACTIVE", style: TextStyle(color: active ? Colors.green : Colors.red, fontSize: 9, fontWeight: FontWeight.bold)));
  Widget _hCell(String t, int f, [bool r = false]) => Expanded(flex: f, child: Text(t, textAlign: r ? TextAlign.right : TextAlign.left, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)));
  Widget _cellCell(String t, int f) => Expanded(flex: f, child: Text(t, style: const TextStyle(fontSize: 12)));
}

// --- Edit Dialog stays largely the same but with mobile inset fix ---

class EditUserDialog extends StatefulWidget {
  final dynamic user;
  const EditUserDialog({super.key, required this.user});
  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  late TextEditingController _nameController, _passwordController;
  int? _locId;
  bool _saving = false;
  String _currentUserRole = 'staff';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['name']);
    _passwordController = TextEditingController();
    _locId = widget.user['location']?['id'];
    _loadCurrentRole();
  }

  Future<void> _loadCurrentRole() async {
    final role = await const FlutterSecureStorage().read(key: 'user_role') ?? 'staff';
    if (mounted) setState(() { _currentUserRole = role.toLowerCase(); });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _save() async {
    setState(() => _saving = true);
    try {
      final updateData = {"name": _nameController.text.trim(), "location": _locId};
      if (_passwordController.text.isNotEmpty) updateData["password"] = _passwordController.text;
      await sl<ApiClient>().put('/api/user/${widget.user['user_id']}/update/', data: updateData);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updated Successfully")));
        context.read<UserMgmtBloc>().add(LoadUsers());
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    bool canEditPass = _currentUserRole == 'superuser' || (_currentUserRole == 'admin' && widget.user['role'] != 'superuser');

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Container(
          width: isMobile ? double.infinity : 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Edit Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: _nameController, decoration: _inputStyle("Full Name", Icons.person_outline)),
              const SizedBox(height: 16),
              // Ensure LocationBloc is available in your injection/main
              BlocBuilder<LocationBloc, LocationState>(builder: (context, state) {
                return DropdownButtonFormField<int>(
                  value: _locId,
                  items: state is LocationLoaded ? state.locations.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name, style: const TextStyle(fontSize: 13)))).toList() : [],
                  onChanged: (v) => setState(() => _locId = v),
                  decoration: _inputStyle("Location", Icons.location_on),
                );
              }),
              if (canEditPass) ...[
                const SizedBox(height: 16),
                TextField(controller: _passwordController, obscureText: true, decoration: _inputStyle("Reset Password", Icons.lock_reset)),
              ],
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
                const SizedBox(width: 8),
                ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1C24), foregroundColor: Colors.white),
                    child: _saving ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("SAVE")),
              ])
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String h, IconData i) => InputDecoration(
    hintText: h,
    prefixIcon: Icon(i, size: 20, color: const Color(0xFF00BCD4)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  );
}