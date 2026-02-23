
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';
import '../../widgets/create_user_dialog.dart';

// --- 1. BLOC LAYER (Filter Sync Logic) ---

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
      final currentState = state;
      if (currentState is! UserMgmtLoaded) emit(UserMgmtLoading());
      try {
        final role = await storage.read(key: 'user_role') ?? 'staff';
        if (role == 'superuser') {
          final results = await Future.wait([api.get('/api/admin/list/'), api.get('/api/staff/list/')]);
          _origAdmins = results[0].data['data'] ?? [];
          _origStaff = results[1].data['data'] ?? [];
        } else {
          final res = await api.get('/api/staff/list/');
          _origStaff = res.data['data'] ?? [];
          _origAdmins = [];
        }
        emit(UserMgmtLoaded(_origAdmins, _origStaff));
      } catch (e) { emit(UserMgmtError("Failed to fetch directory.")); }
    });

    on<FilterUsers>((event, emit) {
      if (state is UserMgmtLoaded) {
        if (event.query != null) _lastQ = event.query!.toLowerCase();
        if (event.role != null) _lastR = event.role!;

        List _runFilter(List list) {
          return list.where((u) {
            final name = (u['name'] ?? "").toString().toLowerCase();
            final email = (u['email'] ?? "").toString().toLowerCase();
            final role = (u['role'] ?? "staff").toString().toLowerCase();
            final matchesSearch = name.contains(_lastQ) || email.contains(_lastQ);
            final matchesRole = _lastR == "All Roles" || role == _lastR.toLowerCase();
            return matchesSearch && matchesRole;
          }).toList();
        }
        emit(UserMgmtLoaded(_runFilter(_origAdmins), _runFilter(_origStaff)));
      }
    });

    on<ToggleUserStatus>((event, emit) async {
      try {
        await api.post('/api/staff/${event.userId}/${event.currentStatus ? 'deactivate' : 'activate'}/');
        add(LoadUsers());
      } catch (e) {}
    });
  }
}

// --- 2. PRESENTATION LAYER (Original Industrial UI) ---

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
                Expanded(child: Container(child: _buildMainTableCard(context))),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("User Management", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1C24))),
            Text("Logged in as: ${_userRoleStr.toUpperCase()}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => showDialog(context: context, builder: (_) => BlocProvider.value(value: BlocProvider.of<UserMgmtBloc>(context), child: const CreateUserDialog())),
          icon: const Icon(Icons.person_add_alt_1, size: 18),
          label: const Text("CREATE NEW USER"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1C24), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
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
            return Column(
              children: [
                _buildFilterSection(context),
                const Divider(height: 1),
                Expanded(child: _buildOriginalTabbedTable(context, state)),
              ],
            );
          }
          return const Center(child: Text("Error loading data"));
        },
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              height: 40,
              decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
              child: TextField(
                onChanged: (v) => context.read<UserMgmtBloc>().add(FilterUsers(query: v)),
                decoration: const InputDecoration(hintText: "Search Employee", prefixIcon: Icon(Icons.search, size: 18), border: InputBorder.none, contentPadding: EdgeInsets.only(bottom: 8)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildRoleDropdown(context),
          const SizedBox(width: 12),
          _buildExportBtn(),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown(BuildContext context) {
    return Container(
      height: 40, padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          items: ["All Roles", "Chef", "Barman", "Staff","Admin/Manager","Waiter"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (v) {
            setState(() { _selectedRole = v!; });
            context.read<UserMgmtBloc>().add(FilterUsers(role: v));
          },
        ),
      ),
    );
  }

  Widget _buildExportBtn() => OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.file_download_outlined, size: 16), label: const Text("EXPORT"), style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.shade300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))));

  Widget _buildOriginalTabbedTable(BuildContext context, UserMgmtLoaded state) {
    bool isSuper = _userRoleStr == 'superuser';
    return DefaultTabController(
      length: isSuper ? 2 : 1,
      child: Column(
        children: [
          TabBar(isScrollable: true, tabAlignment: TabAlignment.start, labelColor: const Color(0xFF00BCD4), indicatorColor: const Color(0xFF00BCD4), dividerColor: Colors.transparent, tabs: [if (isSuper) const Tab(text: "ADMINISTRATORS"), const Tab(text: "RESTAURANT TEAM")]),
          Expanded(
            child: TabBarView(children: [if (isSuper) _buildOriginalTable(context, state.admins), _buildOriginalTable(context, state.staff)]),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalTable(BuildContext context, List users) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: Colors.grey.shade50,
          child: Row(children: [_hCell("Employee ID", 1), _hCell("Employee name", 2), _hCell("Email", 2), _hCell("Role", 1), _hCell("Status", 1), _hCell("Action", 1, true)]),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (ctx, i) => _buildRowUI(context, users[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildRowUI(BuildContext context, dynamic user) {
    bool active = user['is_active'] ?? true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          _cellCell(user['user_id']?.toString().substring(0, 8) ?? "EMP120", 1),
          Expanded(flex: 2, child: Row(children: [CircleAvatar(radius: 14, child: Text(user['name'] != null ? user['name'][0] : "U")), const SizedBox(width: 12), Text(user['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))])),
          _cellCell(user['email'] ?? "", 2, color: Colors.grey.shade600),
          _cellCell((user['role'] ?? "Admin").toString().toUpperCase(), 1),
          Expanded(flex: 1, child: _statusBadgeUI(active)),
          Expanded(flex: 1, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Switch(value: active, activeColor: const Color(0xFF00BCD4), onChanged: (v) => context.read<UserMgmtBloc>().add(ToggleUserStatus(user['user_id'].toString(), active))),
            const Icon(Icons.more_vert, size: 20, color: Colors.grey),
          ])),
        ],
      ),
    );
  }

  Widget _hCell(String t, int f, [bool r = false]) => Expanded(flex: f, child: Text(t, textAlign: r ? TextAlign.right : TextAlign.left, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)));
  Widget _cellCell(String t, int f, {Color color = Colors.black87}) => Expanded(flex: f, child: Text(t, style: TextStyle(fontSize: 13, color: color)));

  Widget _statusBadgeUI(bool active) => UnconstrainedBox(alignment: Alignment.centerLeft, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: active ? Colors.green.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [CircleAvatar(radius: 3, backgroundColor: active ? Colors.green : Colors.orange), const SizedBox(width: 6), Text(active ? "Full-time" : "Disabled", style: TextStyle(color: active ? Colors.green.shade700 : Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.bold))])));
}