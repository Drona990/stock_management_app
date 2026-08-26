import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';

// =============================================================================
// 1. DATA ENTITIES & MODELS (Exact Django Schema Match)
// =============================================================================
class DesignationItem {
  final String id;
  final String departmentId;
  final String departmentName;
  final String title;
  final String code;
  final String level;
  final bool isActive;

  const DesignationItem({
    required this.id,
    required this.departmentId,
    required this.departmentName,
    required this.title,
    required this.code,
    required this.level,
    required this.isActive,
  });

  factory DesignationItem.fromJson(Map<String, dynamic> json) {
    return DesignationItem(
      id: (json['id'] ?? '').toString(),
      departmentId: (json['department'] ?? '').toString(),
      departmentName: json['department_name'] ?? '',
      title: json['title'] ?? '',
      code: json['code'] ?? '',
      level: json['level'] ?? 'L1',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    "department": departmentId,
    "title": title,
    "code": code,
    "level": level,
    "is_active": isActive,
  };
}

class DepartmentItem {
  final String id;
  final String name;
  final String code;
  final String description;
  final String? defaultShift;
  final String shiftName;
  final String shiftCode;
  final bool isActive;
  final int staffCount;
  final List<DesignationItem> designations;

  const DepartmentItem({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    this.defaultShift,
    required this.shiftName,
    required this.shiftCode,
    required this.isActive,
    required this.staffCount,
    required this.designations,
  });

  factory DepartmentItem.fromJson(Map<String, dynamic> json) {
    final List rawDesigs = json['designations'] ?? [];
    return DepartmentItem(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      defaultShift: json['default_shift'] != null ? json['default_shift'].toString() : null,
      shiftName: json['shift_name'] ?? 'General Shift',
      shiftCode: json['shift_code'] ?? 'GS-01',
      isActive: json['is_active'] ?? true,
      staffCount: int.tryParse((json['staff_count'] ?? 0).toString()) ?? 0,
      designations: rawDesigs.map((d) => DesignationItem.fromJson(d as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "code": code,
    "description": description,
    "default_shift": defaultShift,
    "is_active": isActive,
  };
}

// =============================================================================
// 2. REPOSITORY LAYER
// =============================================================================
class RolesMasterRepository {
  final ApiClient apiClient = sl<ApiClient>();

  Future<List<DepartmentItem>> getDepartments() async {
    final res = await apiClient.get('/api/hrms/departments/');
    final List data = (res.data is Map && res.data.containsKey('data'))
        ? res.data['data']
        : (res.data is Map && res.data.containsKey('results'))
        ? res.data['results']
        : res.data is List
        ? res.data
        : [];
    return data.map((e) => DepartmentItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> getActiveShifts() async {
    try {
      final res = await apiClient.get('/api/attendance/shifts/');
      final List data = (res.data is Map && res.data.containsKey('results'))
          ? res.data['results']
          : (res.data is List ? res.data : []);
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> createDepartment(Map<String, dynamic> payload) async {
    await apiClient.post('/api/hrms/departments/', data: payload);
  }

  Future<void> updateDepartment(String id, Map<String, dynamic> payload) async {
    await apiClient.put('/api/hrms/departments/$id/', data: payload);
  }

  Future<void> deleteDepartment(String id) async {
    await apiClient.delete('/api/hrms/departments/$id/');
  }

  Future<void> createDesignation(Map<String, dynamic> payload) async {
    await apiClient.post('/api/hrms/designations/', data: payload);
  }

  Future<void> updateDesignation(String id, Map<String, dynamic> payload) async {
    await apiClient.put('/api/hrms/designations/$id/', data: payload);
  }

  Future<void> deleteDesignation(String id) async {
    await apiClient.delete('/api/hrms/designations/$id/');
  }
}

// =============================================================================
// 3. BLOC ENGINE
// =============================================================================
abstract class RolesMasterEvent {}

class LoadRolesData extends RolesMasterEvent {
  final String? targetDeptId;
  LoadRolesData({this.targetDeptId});
}

class SelectDepartment extends RolesMasterEvent {
  final String departmentId;
  SelectDepartment(this.departmentId);
}

class SearchRoles extends RolesMasterEvent {
  final String query;
  SearchRoles(this.query);
}

class SubmitDepartmentForm extends RolesMasterEvent {
  final String? id;
  final Map<String, dynamic> payload;
  SubmitDepartmentForm({this.id, required this.payload});
}

class DeleteDepartmentAction extends RolesMasterEvent {
  final String id;
  DeleteDepartmentAction(this.id);
}

class SubmitDesignationForm extends RolesMasterEvent {
  final String? id;
  final Map<String, dynamic> payload;
  SubmitDesignationForm({this.id, required this.payload});
}

class DeleteDesignationAction extends RolesMasterEvent {
  final String id;
  final String departmentId;
  DeleteDesignationAction({required this.id, required this.departmentId});
}

abstract class RolesMasterState {}

class RolesMasterLoading extends RolesMasterState {}

class RolesMasterLoaded extends RolesMasterState {
  final List<DepartmentItem> departments;
  final List<Map<String, dynamic>> availableShifts;
  final DepartmentItem? selectedDepartment;
  final String searchQuery;
  final bool isSubmitting;

  RolesMasterLoaded({
    required this.departments,
    this.availableShifts = const [],
    this.selectedDepartment,
    this.searchQuery = '',
    this.isSubmitting = false,
  });

  RolesMasterLoaded copyWith({
    List<DepartmentItem>? departments,
    List<Map<String, dynamic>>? availableShifts,
    DepartmentItem? selectedDepartment,
    String? searchQuery,
    bool? isSubmitting,
  }) {
    return RolesMasterLoaded(
      departments: departments ?? this.departments,
      availableShifts: availableShifts ?? this.availableShifts,
      selectedDepartment: selectedDepartment ?? this.selectedDepartment,
      searchQuery: searchQuery ?? this.searchQuery,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class RolesMasterError extends RolesMasterState {
  final String message;
  RolesMasterError(this.message);
}

class RolesMasterBloc extends Bloc<RolesMasterEvent, RolesMasterState> {
  final RolesMasterRepository repository;
  String? _selectedDeptId;
  String _searchQuery = '';
  List<Map<String, dynamic>> _cachedShifts = [];

  RolesMasterBloc(this.repository) : super(RolesMasterLoading()) {
    on<LoadRolesData>((event, emit) async {
      try {
        final freshDepts = await repository.getDepartments();
        _cachedShifts = await repository.getActiveShifts();

        final String? activeId = event.targetDeptId ?? _selectedDeptId;

        DepartmentItem? selected;
        if (freshDepts.isNotEmpty) {
          selected = freshDepts.firstWhere(
                (d) => d.id == activeId,
            orElse: () => freshDepts.first,
          );
          _selectedDeptId = selected.id;
        }

        emit(RolesMasterLoaded(
          departments: List<DepartmentItem>.from(freshDepts),
          availableShifts: _cachedShifts,
          selectedDepartment: selected,
          searchQuery: _searchQuery,
          isSubmitting: false,
        ));
      } catch (e) {
        emit(RolesMasterError("Department & Designation sync failed: $e"));
      }
    });

    on<SelectDepartment>((event, emit) {
      if (state is RolesMasterLoaded) {
        final currentState = state as RolesMasterLoaded;
        _selectedDeptId = event.departmentId;
        final selected = currentState.departments.firstWhere(
              (d) => d.id == event.departmentId,
          orElse: () => currentState.departments.first,
        );
        emit(currentState.copyWith(selectedDepartment: selected));
      }
    });

    on<SearchRoles>((event, emit) {
      if (state is RolesMasterLoaded) {
        _searchQuery = event.query.toLowerCase().trim();
        emit((state as RolesMasterLoaded).copyWith(searchQuery: _searchQuery));
      }
    });

    on<SubmitDepartmentForm>((event, emit) async {
      if (state is RolesMasterLoaded) {
        emit((state as RolesMasterLoaded).copyWith(isSubmitting: true));
        try {
          if (event.id != null) {
            await repository.updateDepartment(event.id!, event.payload);
          } else {
            await repository.createDepartment(event.payload);
          }
          add(LoadRolesData(targetDeptId: event.id));
        } catch (e) {
          emit(RolesMasterError("Department save failed. Code/Name must be unique."));
        }
      }
    });

    on<DeleteDepartmentAction>((event, emit) async {
      if (state is RolesMasterLoaded) {
        emit((state as RolesMasterLoaded).copyWith(isSubmitting: true));
        try {
          await repository.deleteDepartment(event.id);
          _selectedDeptId = null;
          add(LoadRolesData());
        } catch (e) {
          emit(RolesMasterError("Cannot delete department with active staff members."));
        }
      }
    });

    on<SubmitDesignationForm>((event, emit) async {
      if (state is RolesMasterLoaded) {
        emit((state as RolesMasterLoaded).copyWith(isSubmitting: true));
        final String deptId = event.payload['department'].toString();
        _selectedDeptId = deptId;

        try {
          if (event.id != null) {
            await repository.updateDesignation(event.id!, event.payload);
          } else {
            await repository.createDesignation(event.payload);
          }
          add(LoadRolesData(targetDeptId: deptId));
        } catch (e) {
          emit(RolesMasterError("Designation save failed. Title must be unique within department."));
        }
      }
    });

    on<DeleteDesignationAction>((event, emit) async {
      if (state is RolesMasterLoaded) {
        emit((state as RolesMasterLoaded).copyWith(isSubmitting: true));
        try {
          await repository.deleteDesignation(event.id);
          add(LoadRolesData(targetDeptId: event.departmentId));
        } catch (e) {
          emit(RolesMasterError("Cannot delete role assigned to active staff."));
        }
      }
    });
  }
}

// =============================================================================
// 4. MAIN WORKFORCE CANVAS UI
// =============================================================================
class RolesMasterScreen extends StatelessWidget {
  const RolesMasterScreen({super.key});

  static const Color brandBlue = Color(0xFF0066B3);
  static const Color brandRed = Color(0xFFD32027);
  static const Color darkSlate = Color(0xFF0B0E14);
  static const Color textMuted = Color(0xFF8B949E);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 900;

    return BlocProvider(
      create: (context) => RolesMasterBloc(RolesMasterRepository())..add(LoadRolesData()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: _buildAppBar(context),
        body: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(context, isMobile),
              const SizedBox(height: 14),
              _buildMetricCounters(),
              const SizedBox(height: 14),
              Expanded(
                child: BlocConsumer<RolesMasterBloc, RolesMasterState>(
                  listener: (context, state) {
                    if (state is RolesMasterError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          backgroundColor: brandRed,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is RolesMasterLoading) {
                      return const Center(child: CircularProgressIndicator(color: brandBlue, strokeWidth: 2));
                    }
                    if (state is RolesMasterLoaded) {
                      if (state.departments.isEmpty) {
                        return _buildZeroState(context, state.availableShifts);
                      }
                      return isMobile ? _buildMobileView(context, state) : _buildDesktopPanels(context, state);
                    }
                    return const Center(child: Text("Registry offline.", style: TextStyle(color: textMuted)));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 56,
      title: Row(
        children: [
          Container(width: 3.5, height: 16, color: brandBlue),
          const SizedBox(width: 8),
          const Text(
            "ORGANIZATIONAL MATRIX • DEPARTMENTS & DESIGNATIONS",
            style: TextStyle(color: darkSlate, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ],
      ),
      shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
    );
  }

  Widget _buildTopHeader(BuildContext context, bool isMobile) {
    return BlocBuilder<RolesMasterBloc, RolesMasterState>(
      builder: (context, state) {
        final shifts = state is RolesMasterLoaded ? state.availableShifts : <Map<String, dynamic>>[];
        final depts = state is RolesMasterLoaded ? state.departments : <DepartmentItem>[];
        final selectedDept = state is RolesMasterLoaded ? state.selectedDepartment : null;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "WORKFORCE HIERARCHY ENGINE",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: darkSlate, letterSpacing: 0.5),
                ),
                SizedBox(height: 2),
                Text(
                  "Define operational departments, assign work shifts and map career level designations",
                  style: TextStyle(fontSize: 9.5, color: textMuted, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => showDepartmentModal(context, availableShifts: shifts),
                  icon: const Icon(Icons.add_business_outlined, size: 14, color: brandBlue),
                  label: const Text("NEW DEPARTMENT", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: brandBlue)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: brandBlue, width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    if (selectedDept != null) {
                      showDesignationModal(context, allDepartments: depts, preselectedDeptId: selectedDept.id);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Select or create a department first."), backgroundColor: brandRed),
                      );
                    }
                  },
                  icon: const Icon(Icons.badge_outlined, size: 14),
                  label: const Text("NEW DESIGNATION", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCounters() {
    return BlocBuilder<RolesMasterBloc, RolesMasterState>(
      builder: (context, state) {
        int deptCount = 0;
        int roleCount = 0;
        int staffCount = 0;

        if (state is RolesMasterLoaded) {
          deptCount = state.departments.length;
          for (var d in state.departments) {
            roleCount += d.designations.length;
            staffCount += d.staffCount;
          }
        }

        return Row(
          children: [
            Expanded(child: _metricCard("DEPARTMENTS", "$deptCount", Icons.apartment_rounded, brandBlue)),
            const SizedBox(width: 10),
            Expanded(child: _metricCard("DESIGNATIONS", "$roleCount", Icons.workspace_premium_outlined, const Color(0xFF10B981))),
            const SizedBox(width: 10),
            Expanded(child: _metricCard("TOTAL ACTIVE STAFF", "$staffCount", Icons.groups_outlined, const Color(0xFFF59E0B))),
          ],
        );
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
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 8.5, color: textMuted, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
              const SizedBox(height: 2),
              Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: darkSlate)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDesktopPanels(BuildContext context, RolesMasterLoaded state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: _buildDepartmentsLeftPanel(context, state)),
        const SizedBox(width: 16),
        Expanded(flex: 7, child: _buildDesignationsRightPanel(context, state)),
      ],
    );
  }

  Widget _buildDepartmentsLeftPanel(BuildContext context, RolesMasterLoaded state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF8FAFC),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("DEPARTMENT DIRECTORY", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: darkSlate, letterSpacing: 0.5)),
                Text("${state.departments.length} ACTIVE", style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: brandBlue)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: state.departments.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (ctx, i) {
                final dept = state.departments[i];
                final bool isSelected = state.selectedDepartment?.id == dept.id;

                return InkWell(
                  onTap: () => context.read<RolesMasterBloc>().add(SelectDepartment(dept.id)),
                  child: Container(
                    color: isSelected ? brandBlue.withOpacity(0.06) : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 3.5,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isSelected ? brandBlue : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      dept.name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? brandBlue : darkSlate,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // 🌟 Shift Code Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: brandBlue.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(color: brandBlue.withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      dept.shiftCode,
                                      style: const TextStyle(color: brandBlue, fontSize: 8, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  if (!dept.isActive) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(color: brandRed.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
                                      child: const Text("INACTIVE", style: TextStyle(color: brandRed, fontSize: 7.5, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "Code: ${dept.code} • Shift: ${dept.shiftName} • ${dept.designations.length} Roles • ${dept.staffCount} Staff",
                                style: const TextStyle(fontSize: 8.5, color: textMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 15, color: textMuted),
                          tooltip: "Edit Department & Shift",
                          onPressed: () => showDepartmentModal(context, department: dept, availableShifts: state.availableShifts),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 15, color: brandRed),
                          tooltip: "Delete Department",
                          onPressed: () => _confirmDelete(
                            context,
                            title: "Delete Department",
                            body: "Are you sure you want to delete ${dept.name} (${dept.code})?",
                            onConfirm: () => context.read<RolesMasterBloc>().add(DeleteDepartmentAction(dept.id)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignationsRightPanel(BuildContext context, RolesMasterLoaded state) {
    final selectedDept = state.selectedDepartment;

    List<DesignationItem> roles = selectedDept?.designations ?? [];
    if (state.searchQuery.isNotEmpty) {
      roles = roles.where((r) => r.title.toLowerCase().contains(state.searchQuery) || r.code.toLowerCase().contains(state.searchQuery)).toList();
    }

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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF8FAFC),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DESIGNATIONS: ${selectedDept?.name.toUpperCase() ?? 'NO DEPT SELECTED'}",
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: darkSlate, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedDept?.description.isNotEmpty == true ? selectedDept!.description : "No description available",
                      style: const TextStyle(fontSize: 8.5, color: textMuted),
                    ),
                  ],
                ),
                if (selectedDept != null)
                  ElevatedButton.icon(
                    onPressed: () => showDesignationModal(context, allDepartments: state.departments, preselectedDeptId: selectedDept.id),
                    icon: const Icon(Icons.add, size: 13),
                    label: const Text("ADD ROLE", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                style: const TextStyle(fontSize: 11),
                onChanged: (v) => context.read<RolesMasterBloc>().add(SearchRoles(v)),
                decoration: const InputDecoration(
                  hintText: "Filter designations by title or code...",
                  hintStyle: TextStyle(fontSize: 10.5, color: Colors.grey),
                  prefixIcon: Icon(Icons.search, size: 14, color: brandBlue),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(bottom: 14),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: (selectedDept == null || roles.isEmpty)
                ? Center(
              child: Text(
                selectedDept == null ? "Select a department from the left directory." : "No designation roles configured in ${selectedDept.name}.",
                style: const TextStyle(color: textMuted, fontSize: 11),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(10),
              itemCount: roles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (ctx, i) {
                final role = roles[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: brandBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          role.level.toUpperCase(),
                          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: brandBlue),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(role.title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: darkSlate)),
                                const SizedBox(width: 6),
                                if (!role.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(color: brandRed.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
                                    child: const Text("DISABLED", style: TextStyle(color: brandRed, fontSize: 7.5, fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                            if (role.code.isNotEmpty) Text("Code: ${role.code}", style: const TextStyle(fontSize: 9, color: textMuted)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 15, color: textMuted),
                        tooltip: "Edit Designation",
                        onPressed: () => showDesignationModal(
                          context,
                          allDepartments: state.departments,
                          preselectedDeptId: selectedDept.id,
                          designation: role,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 15, color: brandRed),
                        tooltip: "Delete Designation",
                        onPressed: () => _confirmDelete(
                          context,
                          title: "Delete Designation Role",
                          body: "Are you sure you want to delete ${role.title} (${role.code})?",
                          onConfirm: () => context.read<RolesMasterBloc>().add(
                            DeleteDesignationAction(id: role.id, departmentId: selectedDept.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileView(BuildContext context, RolesMasterLoaded state) {
    return ListView.builder(
      itemCount: state.departments.length,
      itemBuilder: (ctx, i) {
        final dept = state.departments[i];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6), side: BorderSide(color: Colors.grey.shade200)),
          child: ExpansionTile(
            title: Text(dept.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: darkSlate)),
            subtitle: Text("Code: ${dept.code} • Shift: ${dept.shiftCode} • ${dept.designations.length} Roles • ${dept.staffCount} Staff", style: const TextStyle(fontSize: 9, color: textMuted)),
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("DESIGNATIONS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textMuted)),
                        TextButton.icon(
                          onPressed: () => showDesignationModal(context, allDepartments: state.departments, preselectedDeptId: dept.id),
                          icon: const Icon(Icons.add, size: 12),
                          label: const Text("ADD ROLE", style: TextStyle(fontSize: 9.5)),
                        ),
                      ],
                    ),
                    const Divider(height: 10),
                    ...dept.designations.map((d) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(d.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      subtitle: Text("Level: ${d.level} | Code: ${d.code}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 14),
                            onPressed: () => showDesignationModal(context, allDepartments: state.departments, preselectedDeptId: dept.id, designation: d),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 14, color: brandRed),
                            onPressed: () => _confirmDelete(
                              context,
                              title: "Delete Designation",
                              body: "Delete ${d.title}?",
                              onConfirm: () => context.read<RolesMasterBloc>().add(
                                DeleteDesignationAction(id: d.id, departmentId: dept.id),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildZeroState(BuildContext context, List<Map<String, dynamic>> shifts) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.corporate_fare_outlined, size: 42, color: textMuted),
          const SizedBox(height: 10),
          const Text("No organizational departments initialized yet.", style: TextStyle(color: darkSlate, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => showDepartmentModal(context, availableShifts: shifts),
            style: ElevatedButton.styleFrom(backgroundColor: brandBlue, foregroundColor: Colors.white),
            child: const Text("INITIALIZE FIRST DEPARTMENT", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, {required String title, required String body, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: brandRed, size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: brandRed)),
          ],
        ),
        content: Text(body, style: const TextStyle(fontSize: 11.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(fontSize: 10.5))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white),
            onPressed: () {
              onConfirm();
              Navigator.pop(ctx);
            },
            child: const Text("DELETE", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 5. MODAL FORM 1: DEPARTMENT FORM DIALOG (WITH DEFAULT SHIFT DROPDOWN)
// =============================================================================
void showDepartmentModal(
    BuildContext context, {
      DepartmentItem? department,
      List<Map<String, dynamic>> availableShifts = const [],
    }) {
  final bloc = context.read<RolesMasterBloc>();

  showDialog(
    context: context,
    builder: (dialogCtx) => DepartmentModalDialog(
      department: department,
      availableShifts: availableShifts,
      onSave: (payload) {
        bloc.add(SubmitDepartmentForm(id: department?.id, payload: payload));
      },
    ),
  );
}

class DepartmentModalDialog extends StatefulWidget {
  final DepartmentItem? department;
  final List<Map<String, dynamic>> availableShifts;
  final Function(Map<String, dynamic>) onSave;

  const DepartmentModalDialog({
    super.key,
    this.department,
    this.availableShifts = const [],
    required this.onSave,
  });

  @override
  State<DepartmentModalDialog> createState() => _DepartmentModalDialogState();
}

class _DepartmentModalDialogState extends State<DepartmentModalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _descCtrl;
  late bool _isActive;
  String? _selectedShiftId;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.department?.name ?? '');
    _codeCtrl = TextEditingController(text: widget.department?.code ?? '');
    _descCtrl = TextEditingController(text: widget.department?.description ?? '');
    _isActive = widget.department?.isActive ?? true;
    _selectedShiftId = widget.department?.defaultShift;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Row(
        children: [
          Container(width: 3.5, height: 16, color: RolesMasterScreen.brandBlue),
          const SizedBox(width: 8),
          Text(
            widget.department == null ? "Create Department" : "Edit Department",
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: RolesMasterScreen.darkSlate),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(fontSize: 11.5),
                decoration: _modalInputStyle("DEPARTMENT NAME (e.g. IT & Software Development)"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeCtrl,
                style: const TextStyle(fontSize: 11.5),
                decoration: _modalInputStyle("DEPARTMENT CODE (e.g. DEPT-IT)"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 12),
              // 🌟 Default Work Shift Dropdown
              DropdownButtonFormField<String>(
                value: _selectedShiftId,
                style: const TextStyle(fontSize: 11.5, color: RolesMasterScreen.darkSlate),
                decoration: _modalInputStyle("DEFAULT WORK SHIFT"),
                hint: const Text("Select Default Shift (Optional)", style: TextStyle(fontSize: 11, color: Colors.grey)),
                items: widget.availableShifts.map((s) {
                  final shiftCode = s['shift_code'] ?? '';
                  final shiftName = s['name'] ?? '';
                  final startTime = s['start_time'] ?? '';
                  final endTime = s['end_time'] ?? '';
                  return DropdownMenuItem<String>(
                    value: s['id'].toString(),
                    child: Text(
                      "$shiftName ($shiftCode) • $startTime-$endTime",
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedShiftId = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 11.5),
                decoration: _modalInputStyle("DESCRIPTION / RESPONSIBILITY SCOPE (OPTIONAL)"),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Operational Status", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Switch(
                    value: _isActive,
                    activeThumbColor: RolesMasterScreen.brandBlue,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(fontSize: 10.5, color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: RolesMasterScreen.brandBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            widget.onSave({
              "name": _nameCtrl.text.trim(),
              "code": _codeCtrl.text.trim().toUpperCase(),
              "default_shift": _selectedShiftId,
              "description": _descCtrl.text.trim(),
              "is_active": _isActive,
            });
            Navigator.pop(context);
          },
          child: const Text("COMMIT DEPARTMENT", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// =============================================================================
// 6. MODAL FORM 2: DESIGNATION FORM DIALOG
// =============================================================================
void showDesignationModal(
    BuildContext context, {
      required List<DepartmentItem> allDepartments,
      required String preselectedDeptId,
      DesignationItem? designation,
    }) {
  final bloc = context.read<RolesMasterBloc>();

  showDialog(
    context: context,
    builder: (dialogCtx) => DesignationModalDialog(
      allDepartments: allDepartments,
      preselectedDeptId: preselectedDeptId,
      designation: designation,
      onSave: (payload) {
        bloc.add(SubmitDesignationForm(id: designation?.id, payload: payload));
      },
    ),
  );
}

class DesignationModalDialog extends StatefulWidget {
  final List<DepartmentItem> allDepartments;
  final String preselectedDeptId;
  final DesignationItem? designation;
  final Function(Map<String, dynamic>) onSave;

  const DesignationModalDialog({
    super.key,
    required this.allDepartments,
    required this.preselectedDeptId,
    this.designation,
    required this.onSave,
  });

  @override
  State<DesignationModalDialog> createState() => _DesignationModalDialogState();
}

class _DesignationModalDialogState extends State<DesignationModalDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _deptId;
  late TextEditingController _titleCtrl;
  late TextEditingController _codeCtrl;
  late String _level;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _deptId = widget.designation?.departmentId.isNotEmpty == true ? widget.designation!.departmentId : widget.preselectedDeptId;
    _titleCtrl = TextEditingController(text: widget.designation?.title ?? '');
    _codeCtrl = TextEditingController(text: widget.designation?.code ?? '');
    _level = widget.designation?.level ?? 'L1';
    _isActive = widget.designation?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Row(
        children: [
          Container(width: 3.5, height: 16, color: RolesMasterScreen.brandBlue),
          const SizedBox(width: 8),
          Text(
            widget.designation == null ? "Add Designation Role" : "Edit Designation Role",
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: RolesMasterScreen.darkSlate),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _deptId,
                style: const TextStyle(fontSize: 11.5, color: RolesMasterScreen.darkSlate),
                decoration: _modalInputStyle("PARENT DEPARTMENT"),
                items: widget.allDepartments.map((d) {
                  return DropdownMenuItem(value: d.id, child: Text(d.name, style: const TextStyle(fontSize: 11.5)));
                }).toList(),
                onChanged: (v) => setState(() => _deptId = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(fontSize: 11.5),
                decoration: _modalInputStyle("DESIGNATION TITLE (e.g. Senior Flutter Developer)"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeCtrl,
                style: const TextStyle(fontSize: 11.5),
                decoration: _modalInputStyle("ROLE CODE (e.g. SDE-FLUTTER)"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _level,
                style: const TextStyle(fontSize: 11.5, color: RolesMasterScreen.darkSlate),
                decoration: _modalInputStyle("CAREER HIERARCHY LEVEL"),
                items: ["L1", "L2", "L3", "Lead", "Architect", "Executive", "Director"]
                    .map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl, style: const TextStyle(fontSize: 11.5))))
                    .toList(),
                onChanged: (v) => setState(() => _level = v!),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Role Active Status", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  Switch(
                    value: _isActive,
                    activeThumbColor: RolesMasterScreen.brandBlue,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(fontSize: 10.5, color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: RolesMasterScreen.brandBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            widget.onSave({
              "department": _deptId,
              "title": _titleCtrl.text.trim(),
              "code": _codeCtrl.text.trim().toUpperCase(),
              "level": _level,
              "is_active": _isActive,
            });
            Navigator.pop(context);
          },
          child: const Text("SAVE DESIGNATION", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

InputDecoration _modalInputStyle(String lbl) {
  return InputDecoration(
    labelText: lbl,
    labelStyle: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
    contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
    isDense: true,
  );
}