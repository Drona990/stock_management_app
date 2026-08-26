import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../injection.dart';

// =============================================================================
// DESIGN SYSTEM & PALETTE
// =============================================================================
const Color kBrandBlue = Color(0xFF0066B3);
const Color kBrandRed = Color(0xFFD32027);
const Color kDarkSlate = Color(0xFF0B0E14);
const Color kTextMuted = Color(0xFF8B949E);
const Color kSurfaceBg = Color(0xFFF1F5F9);
const Color kCardBg = Color(0xFFF8FAFC);
const Color kAccentGreen = Color(0xFF10B981);
const Color kAccentAmber = Color(0xFFF59E0B);
const Color kAccentPurple = Color(0xFF8B5CF6);

// =============================================================================
// 1. DATA ENTITIES & REPOSITORY (Exact Django Model Mappings)
// =============================================================================

class AttendanceRecordEntity {
  final String id;
  final String employeeId;
  final String employeeCode;
  final String employeeName;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final double workHours;
  final bool isLate;
  final String status;
  final String statusDisplay;
  final bool isManualOverride;
  final String? overrideReason;
  final double deductionPenaltyAmount;

  AttendanceRecordEntity({
    required this.id,
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.workHours,
    required this.isLate,
    required this.status,
    required this.statusDisplay,
    required this.isManualOverride,
    this.overrideReason,
    required this.deductionPenaltyAmount,
  });

  factory AttendanceRecordEntity.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordEntity(
      id: (json['id'] ?? '').toString(),
      employeeId: (json['employee'] ?? '').toString(),
      employeeCode: json['employee_code'] ?? 'EMP',
      employeeName: json['employee_name'] ?? 'Staff',
      date: json['date'] ?? '',
      checkIn: json['check_in'],
      checkOut: json['check_out'],
      workHours: double.tryParse((json['total_work_hours'] ?? 0).toString()) ?? 0.0,
      isLate: json['is_late_entry'] ?? false,
      status: json['status'] ?? 'ABSENT',
      statusDisplay: json['status_display'] ?? json['status'] ?? 'Absent',
      isManualOverride: json['is_manual_override'] ?? false,
      overrideReason: json['override_reason'],
      deductionPenaltyAmount: double.tryParse((json['deduction_penalty_amount'] ?? 0).toString()) ?? 0.0,
    );
  }
}

class ShiftEntity {
  final String id;
  final String name;
  final String shiftCode;
  final String startTime;
  final String endTime;
  final int gracePeriodMinutes;
  final double halfDayHours;
  final double fullDayHours;
  final double? officeLat;
  final double? officeLon;
  final int radiusMeters;
  final bool isActive;

  ShiftEntity({
    required this.id,
    required this.name,
    required this.shiftCode,
    required this.startTime,
    required this.endTime,
    required this.gracePeriodMinutes,
    required this.halfDayHours,
    required this.fullDayHours,
    this.officeLat,
    this.officeLon,
    required this.radiusMeters,
    required this.isActive,
  });

  factory ShiftEntity.fromJson(Map<String, dynamic> json) {
    return ShiftEntity(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      shiftCode: json['shift_code'] ?? '',
      startTime: json['start_time'] ?? '09:30:00',
      endTime: json['end_time'] ?? '18:30:00',
      gracePeriodMinutes: int.tryParse((json['grace_period_minutes'] ?? 15).toString()) ?? 15,
      halfDayHours: double.tryParse((json['half_day_minimum_hours'] ?? 4.0).toString()) ?? 4.0,
      fullDayHours: double.tryParse((json['full_day_minimum_hours'] ?? 8.0).toString()) ?? 8.0,
      officeLat: json['office_latitude'] != null ? double.tryParse(json['office_latitude'].toString()) : null,
      officeLon: json['office_longitude'] != null ? double.tryParse(json['office_longitude'].toString()) : null,
      radiusMeters: int.tryParse((json['geofence_radius_meters'] ?? 100).toString()) ?? 100,
      isActive: json['is_active'] ?? true,
    );
  }
}

class HolidayEntity {
  final String id;
  final String name;
  final String date;
  final String holidayType;
  final String? description;
  final bool isOptional;

  HolidayEntity({
    required this.id,
    required this.name,
    required this.date,
    required this.holidayType,
    this.description,
    required this.isOptional,
  });

  factory HolidayEntity.fromJson(Map<String, dynamic> json) {
    return HolidayEntity(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      date: json['date'] ?? '',
      holidayType: json['holiday_type'] ?? 'FESTIVAL',
      description: json['description'],
      isOptional: json['is_optional'] ?? false,
    );
  }
}

class LeaveApplicationEntity {
  final String id;
  final String employeeCode;
  final String employeeName;
  final String leaveTypeName;
  final String startDate;
  final String endDate;
  final double totalDays;
  final String reason;
  final String status;
  final String? adminRemarks;

  LeaveApplicationEntity({
    required this.id,
    required this.employeeCode,
    required this.employeeName,
    required this.leaveTypeName,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    this.adminRemarks,
  });

  factory LeaveApplicationEntity.fromJson(Map<String, dynamic> json) {
    return LeaveApplicationEntity(
      id: (json['id'] ?? '').toString(),
      employeeCode: json['employee_code'] ?? 'EMP',
      employeeName: json['employee_name'] ?? 'Staff',
      leaveTypeName: json['leave_type_name'] ?? 'Leave',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      totalDays: double.tryParse((json['total_days'] ?? 1.0).toString()) ?? 1.0,
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'PENDING',
      adminRemarks: json['admin_remarks'],
    );
  }
}

class AttendanceLeaveMasterRepository {
  final ApiClient api = sl<ApiClient>();

  List _extractList(dynamic resData) {
    if (resData is Map && resData.containsKey('data')) return resData['data'] as List;
    if (resData is Map && resData.containsKey('results')) return resData['results'] as List;
    if (resData is List) return resData;
    return [];
  }

  Future<List<AttendanceRecordEntity>> fetchAttendanceRecords(String date) async {
    final res = await api.get('/api/attendance/records/', query: {'date': date});
    return _extractList(res.data).map((e) => AttendanceRecordEntity.fromJson(e)).toList();
  }

  Future<void> updateManualAttendance(String id, Map<String, dynamic> payload) async {
    await api.patch('/api/attendance/records/$id/', data: payload);
  }

  Future<List<LeaveApplicationEntity>> fetchLeaves() async {
    final res = await api.get('/api/attendance/leaves/');
    return _extractList(res.data).map((e) => LeaveApplicationEntity.fromJson(e)).toList();
  }

  Future<void> updateLeaveStatus(String id, String status, String remarks) async {
    await api.patch('/api/attendance/leaves/$id/', data: {
      'status': status,
      'admin_remarks': remarks,
    });
  }

  Future<List<ShiftEntity>> fetchShifts() async {
    final res = await api.get('/api/attendance/shifts/');
    return _extractList(res.data).map((e) => ShiftEntity.fromJson(e)).toList();
  }

  Future<void> createShift(Map<String, dynamic> payload) async {
    await api.post('/api/attendance/shifts/', data: payload);
  }

  Future<void> deleteShift(String id) async {
    await api.delete('/api/attendance/shifts/$id/');
  }

  Future<List<HolidayEntity>> fetchHolidays() async {
    final res = await api.get('/api/attendance/holidays/');
    return _extractList(res.data).map((e) => HolidayEntity.fromJson(e)).toList();
  }

  Future<void> createHoliday(Map<String, dynamic> payload) async {
    await api.post('/api/attendance/holidays/', data: payload);
  }

  Future<void> deleteHoliday(String id) async {
    await api.delete('/api/attendance/holidays/$id/');
  }

  Future<void> generateBulkRoster(Map<String, dynamic> payload) async {
    await api.post('/api/attendance/roster/generate-bulk/', data: payload);
  }
}

// =============================================================================
// 2. BLOC STATE MANAGEMENT ENGINE
// =============================================================================
abstract class AttMasterEvent {}

class LoadMasterConsoleEvent extends AttMasterEvent {
  final String date;
  LoadMasterConsoleEvent(this.date);
}

class SaveAttendanceOverrideEvent extends AttMasterEvent {
  final String id;
  final Map<String, dynamic> payload;
  final String currentDate;
  SaveAttendanceOverrideEvent(this.id, this.payload, this.currentDate);
}

class ReviewLeaveEvent extends AttMasterEvent {
  final String id;
  final String status;
  final String remarks;
  final String currentDate;
  ReviewLeaveEvent(this.id, this.status, this.remarks, this.currentDate);
}

class CreateShiftEvent extends AttMasterEvent {
  final Map<String, dynamic> payload;
  final String currentDate;
  CreateShiftEvent(this.payload, this.currentDate);
}

class DeleteShiftEvent extends AttMasterEvent {
  final String id;
  final String currentDate;
  DeleteShiftEvent(this.id, this.currentDate);
}

class CreateHolidayEvent extends AttMasterEvent {
  final Map<String, dynamic> payload;
  final String currentDate;
  CreateHolidayEvent(this.payload, this.currentDate);
}

class DeleteHolidayEvent extends AttMasterEvent {
  final String id;
  final String currentDate;
  DeleteHolidayEvent(this.id, this.currentDate);
}

class TriggerRosterGenEvent extends AttMasterEvent {
  final Map<String, dynamic> payload;
  final String currentDate;
  TriggerRosterGenEvent(this.payload, this.currentDate);
}

abstract class AttMasterState {}
class AttMasterLoading extends AttMasterState {}

class AttMasterLoaded extends AttMasterState {
  final List<AttendanceRecordEntity> records;
  final List<LeaveApplicationEntity> leaves;
  final List<ShiftEntity> shifts;
  final List<HolidayEntity> holidays;
  final String selectedDate;
  final bool isBusy;

  AttMasterLoaded({
    required this.records,
    required this.leaves,
    required this.shifts,
    required this.holidays,
    required this.selectedDate,
    this.isBusy = false,
  });
}

class AttMasterActionSuccess extends AttMasterState {
  final String message;
  AttMasterActionSuccess(this.message);
}

class AttMasterError extends AttMasterState {
  final String message;
  AttMasterError(this.message);
}

class AttendanceMasterBloc extends Bloc<AttMasterEvent, AttMasterState> {
  final AttendanceLeaveMasterRepository repo;

  AttendanceMasterBloc(this.repo) : super(AttMasterLoading()) {
    on<LoadMasterConsoleEvent>((event, emit) async {
      emit(AttMasterLoading());
      try {
        final results = await Future.wait([
          repo.fetchAttendanceRecords(event.date),
          repo.fetchLeaves(),
          repo.fetchShifts(),
          repo.fetchHolidays(),
        ]);
        emit(AttMasterLoaded(
          records: results[0] as List<AttendanceRecordEntity>,
          leaves: results[1] as List<LeaveApplicationEntity>,
          shifts: results[2] as List<ShiftEntity>,
          holidays: results[3] as List<HolidayEntity>,
          selectedDate: event.date,
        ));
      } catch (e) {
        emit(AttMasterError("Failed to synchronize attendance data: $e"));
      }
    });

    on<SaveAttendanceOverrideEvent>((event, emit) async {
      try {
        await repo.updateManualAttendance(event.id, event.payload);
        add(LoadMasterConsoleEvent(event.currentDate));
      } catch (e) {
        emit(AttMasterError("Attendance adjustment failed: $e"));
      }
    });

    on<ReviewLeaveEvent>((event, emit) async {
      try {
        await repo.updateLeaveStatus(event.id, event.status, event.remarks);
        add(LoadMasterConsoleEvent(event.currentDate));
      } catch (e) {
        emit(AttMasterError("Leave review failed: $e"));
      }
    });

    on<CreateShiftEvent>((event, emit) async {
      try {
        await repo.createShift(event.payload);
        add(LoadMasterConsoleEvent(event.currentDate));
      } catch (e) {
        emit(AttMasterError("Shift creation failed: $e"));
      }
    });

    on<DeleteShiftEvent>((event, emit) async {
      try {
        await repo.deleteShift(event.id);
        add(LoadMasterConsoleEvent(event.currentDate));
      } catch (e) {
        emit(AttMasterError("Shift deletion failed: $e"));
      }
    });

    on<CreateHolidayEvent>((event, emit) async {
      try {
        await repo.createHoliday(event.payload);
        add(LoadMasterConsoleEvent(event.currentDate));
      } catch (e) {
        emit(AttMasterError("Holiday creation failed: $e"));
      }
    });

    on<DeleteHolidayEvent>((event, emit) async {
      try {
        await repo.deleteHoliday(event.id);
        add(LoadMasterConsoleEvent(event.currentDate));
      } catch (e) {
        emit(AttMasterError("Holiday deletion failed: $e"));
      }
    });

    on<TriggerRosterGenEvent>((event, emit) async {
      try {
        await repo.generateBulkRoster(event.payload);
        add(LoadMasterConsoleEvent(event.currentDate));
      } catch (e) {
        emit(AttMasterError("Roster matrix generation failed: $e"));
      }
    });
  }
}

// =============================================================================
// 3. MAIN UI CONSOLE CANVAS
// =============================================================================
class AttendanceLeaveMasterScreen extends StatefulWidget {
  const AttendanceLeaveMasterScreen({super.key});

  @override
  State<AttendanceLeaveMasterScreen> createState() => _AttendanceLeaveMasterScreenState();
}

class _AttendanceLeaveMasterScreenState extends State<AttendanceLeaveMasterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _currentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 950;
    final String dateStr = DateFormat('yyyy-MM-dd').format(_currentDate);

    return BlocProvider(
      create: (context) => AttendanceMasterBloc(AttendanceLeaveMasterRepository())..add(LoadMasterConsoleEvent(dateStr)),
      child: Scaffold(
        backgroundColor: kSurfaceBg,
        body: Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(isMobile),
              const SizedBox(height: 14),
              _buildTabBar(),
              const SizedBox(height: 14),
              Expanded(
                child: BlocConsumer<AttendanceMasterBloc, AttMasterState>(
                  listener: (context, state) {
                    if (state is AttMasterError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message), backgroundColor: kBrandRed, behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is AttMasterLoading) {
                      return const Center(child: CircularProgressIndicator(color: kBrandBlue, strokeWidth: 2));
                    }
                    if (state is AttMasterLoaded) {
                      return TabBarView(
                        controller: _tabController,
                        children: [
                          _buildRecordsTab(context, state),
                          _buildLeavesTab(context, state),
                          _buildShiftsTab(context, state),
                          _buildHolidaysRosterTab(context, state),
                        ],
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ATTENDANCE, ROSTER & LEAVE MANAGEMENT CONSOLE",
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: kDarkSlate, letterSpacing: 0.6),
            ),
            SizedBox(height: 2),
            Text(
              "Real-time Punches, Leave Approvals, Geofenced Shift Policies & Calendar Automation",
              style: TextStyle(fontSize: 9.5, color: kTextMuted, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: kBrandBlue,
        unselectedLabelColor: kTextMuted,
        indicatorColor: kBrandBlue,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(icon: Icon(Icons.fingerprint_rounded, size: 16), text: "1. Daily Attendance Logs"),
          Tab(icon: Icon(Icons.beach_access_rounded, size: 16), text: "2. Leave Approvals Desk"),
          Tab(icon: Icon(Icons.schedule_rounded, size: 16), text: "3. Shifts & Geofencing"),
          Tab(icon: Icon(Icons.calendar_month_rounded, size: 16), text: "4. Holiday Calendar & Roster"),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: ATTENDANCE RECORDS & ADJUSTMENTS
  // ===========================================================================
  Widget _buildRecordsTab(BuildContext context, AttMasterLoaded state) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.today_rounded, size: 16, color: kBrandBlue),
                    const SizedBox(width: 8),
                    Text(DateFormat('EEEE, MMMM d, yyyy').format(_currentDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kDarkSlate)),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(context: context, initialDate: _currentDate, firstDate: DateTime(2024), lastDate: DateTime(2035));
                    if (d != null) {
                      setState(() => _currentDate = d);
                      if (context.mounted) {
                        context.read<AttendanceMasterBloc>().add(LoadMasterConsoleEvent(DateFormat('yyyy-MM-dd').format(d)));
                      }
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 13),
                  label: const Text("CHANGE DATE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: state.records.isEmpty
                ? const Center(child: Text("No attendance records logged for this date.", style: TextStyle(color: kTextMuted, fontSize: 11)))
                : ListView.separated(
              itemCount: state.records.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (ctx, i) {
                final r = state.records[i];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: kBrandBlue.withValues(alpha: 0.1),
                    child: const Icon(Icons.person_outline, size: 14, color: kBrandBlue),
                  ),
                  title: Text("${r.employeeName} (${r.employeeCode})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                  subtitle: Text(
                    "In: ${r.checkIn != null ? r.checkIn!.split('T').last.substring(0, 5) : '--:--'} • Out: ${r.checkOut != null ? r.checkOut!.split('T').last.substring(0, 5) : '--:--'} • Total: ${r.workHours} hrs ${r.deductionPenaltyAmount > 0 ? '• Fine: ₹${r.deductionPenaltyAmount}' : ''}",
                    style: const TextStyle(fontSize: 10),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: _statusBg(r.status), borderRadius: BorderRadius.circular(4)),
                        child: Text(r.statusDisplay, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: _statusFg(r.status))),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.tune_rounded, size: 16, color: kBrandBlue),
                        tooltip: "Manual Override / Deduction",
                        onPressed: () => _openAttendanceOverrideDialog(context, r, state.selectedDate),
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

  Color _statusBg(String s) => s == 'PRESENT' ? Colors.green.shade50 : (s == 'HALF_DAY' ? Colors.amber.shade50 : kBrandRed.withValues(alpha: 0.1));
  Color _statusFg(String s) => s == 'PRESENT' ? Colors.green.shade800 : (s == 'HALF_DAY' ? Colors.amber.shade900 : kBrandRed);

  // ===========================================================================
  // TAB 2: LEAVE APPLICATIONS
  // ===========================================================================
  Widget _buildLeavesTab(BuildContext context, AttMasterLoaded state) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
      child: state.leaves.isEmpty
          ? const Center(child: Text("No leave applications in review queue.", style: TextStyle(color: kTextMuted, fontSize: 11)))
          : ListView.separated(
        itemCount: state.leaves.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (ctx, i) {
          final l = state.leaves[i];
          final isPending = l.status == 'PENDING';
          return ListTile(
            dense: true,
            title: Text("${l.employeeName} (${l.employeeCode}) • ${l.leaveTypeName}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
            subtitle: Text("${l.startDate} to ${l.endDate} (${l.totalDays} Days) • Reason: ${l.reason}", style: const TextStyle(fontSize: 10, color: kTextMuted)),
            trailing: isPending
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kAccentGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                  onPressed: () => context.read<AttendanceMasterBloc>().add(ReviewLeaveEvent(l.id, 'APPROVED', 'Approved by HR', state.selectedDate)),
                  child: const Text("APPROVE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kBrandRed, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                  onPressed: () => context.read<AttendanceMasterBloc>().add(ReviewLeaveEvent(l.id, 'REJECTED', 'Operational constraints', state.selectedDate)),
                  child: const Text("REJECT", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            )
                : Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: l.status == 'APPROVED' ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
              child: Text(l.status, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: l.status == 'APPROVED' ? Colors.green.shade800 : kBrandRed)),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // TAB 3: SHIFTS & GEOFENCE
  // ===========================================================================
  Widget _buildShiftsTab(BuildContext context, AttMasterLoaded state) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("CONFIGURED WORK SHIFTS & GEOFENCE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kDarkSlate)),
                ElevatedButton.icon(
                  onPressed: () => _openCreateShiftDialog(context, state.selectedDate),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text("NEW SHIFT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: kBrandBlue, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: state.shifts.isEmpty
                ? const Center(child: Text("No shifts configured.", style: TextStyle(color: kTextMuted, fontSize: 11)))
                : ListView.separated(
              itemCount: state.shifts.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (ctx, i) {
                final s = state.shifts[i];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.access_time_filled, color: kBrandBlue, size: 20),
                  title: Text("${s.name} (${s.shiftCode})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                  subtitle: Text("Timing: ${s.startTime} - ${s.endTime} • Grace: ${s.gracePeriodMinutes} mins • Radius: ${s.radiusMeters}m", style: const TextStyle(fontSize: 10, color: kTextMuted)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16, color: kBrandRed),
                    onPressed: () => context.read<AttendanceMasterBloc>().add(DeleteShiftEvent(s.id, state.selectedDate)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 4: HOLIDAYS & AUTO ROSTER
  // ===========================================================================
  Widget _buildHolidaysRosterTab(BuildContext context, AttMasterLoaded state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Holiday List
        Expanded(
          flex: 6,
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("COMPANY HOLIDAY CALENDAR", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kDarkSlate)),
                      ElevatedButton.icon(
                        onPressed: () => _openCreateHolidayDialog(context, state.selectedDate),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text("ADD HOLIDAY", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: kBrandBlue, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: state.holidays.isEmpty
                      ? const Center(child: Text("No declared holidays.", style: TextStyle(color: kTextMuted, fontSize: 11)))
                      : ListView.separated(
                    itemCount: state.holidays.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (ctx, i) {
                      final h = state.holidays[i];
                      return ListTile(
                        dense: true,
                        title: Text(h.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                        subtitle: Text("Date: ${h.date} • Type: ${h.holidayType} ${h.isOptional ? '• (Restricted)' : ''}", style: const TextStyle(fontSize: 10, color: kTextMuted)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: kBrandRed),
                          onPressed: () => context.read<AttendanceMasterBloc>().add(DeleteHolidayEvent(h.id, state.selectedDate)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        // Right: 1-Click Roster Automation
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("AUTO-GENERATE MONTHLY ROSTER", style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: kDarkSlate)),
                const SizedBox(height: 4),
                const Text("Bulk populates weekly-offs and default shift duties for all registered staff.", style: TextStyle(fontSize: 9.5, color: kTextMuted)),
                const Divider(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: kAccentPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14)),
                  icon: const Icon(Icons.auto_awesome, size: 14),
                  label: const Text("POPULATE THIS MONTH'S ROSTER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    context.read<AttendanceMasterBloc>().add(TriggerRosterGenEvent({
                      'month': DateTime.now().month,
                      'year': DateTime.now().year,
                      'weekly_off_pattern': 'SUN_ONLY',
                      'shift_id': state.shifts.isNotEmpty ? state.shifts.first.id : null,
                    }, state.selectedDate));
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // MODALS & INPUT HANDLERS (Exact Match with Models & Views)
  // ===========================================================================
  void _openAttendanceOverrideDialog(BuildContext context, AttendanceRecordEntity r, String date) {
    String status = r.status;
    final fineCtrl = TextEditingController(text: r.deductionPenaltyAmount.toString());
    final reasonCtrl = TextEditingController(text: r.overrideReason ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text("Override: ${r.employeeName}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: "STATUS", border: OutlineInputBorder(), isDense: true),
                items: const [
                  DropdownMenuItem(value: "PRESENT", child: Text("Present (Full Day)")),
                  DropdownMenuItem(value: "HALF_DAY", child: Text("Half Day")),
                  DropdownMenuItem(value: "ABSENT", child: Text("Absent")),
                  DropdownMenuItem(value: "LOSS_OF_PAY", child: Text("Loss of Pay (LOP)")),
                  DropdownMenuItem(value: "WEEKLY_OFF", child: Text("Weekly Off")),
                ],
                onChanged: (v) => setS(() => status = v!),
              ),
              const SizedBox(height: 10),
              TextField(controller: fineCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "DEDUCTION / FINE (₹)", border: OutlineInputBorder(), isDense: true)),
              const SizedBox(height: 10),
              TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: "ADJUSTMENT REASON", border: OutlineInputBorder(), isDense: true)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kBrandBlue, foregroundColor: Colors.white),
              onPressed: () {
                context.read<AttendanceMasterBloc>().add(SaveAttendanceOverrideEvent(
                  r.id,
                  {
                    'status': status,
                    'deduction_penalty_amount': double.tryParse(fineCtrl.text) ?? 0.0,
                    'override_reason': reasonCtrl.text.trim(),
                    'is_manual_override': true,
                  },
                  date,
                ));
                Navigator.pop(ctx);
              },
              child: const Text("SAVE ADJUSTMENT"),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateShiftDialog(BuildContext context, String date) {
    // 🌟 Parent context se BLoC ka reference pehle hi le lein
    final bloc = context.read<AttendanceMasterBloc>();

    final Map<String, Map<String, dynamic>> shiftTemplates = {
      "General Shift": {
        "code": "GS-01",
        "start": "09:30:00",
        "end": "18:30:00",
        "half": "4.0",
        "full": "8.0",
        "grace": "15"
      },
      "Morning Shift": {
        "code": "MS-01",
        "start": "06:00:00",
        "end": "14:30:00",
        "half": "4.0",
        "full": "8.0",
        "grace": "10"
      },
      "Evening / Second Shift": {
        "code": "ES-01",
        "start": "14:00:00",
        "end": "22:30:00",
        "half": "4.0",
        "full": "8.0",
        "grace": "10"
      },
      "Night Shift": {
        "code": "NS-01",
        "start": "22:00:00",
        "end": "06:30:00",
        "half": "4.0",
        "full": "8.0",
        "grace": "15"
      },
      "Custom Shift": {
        "code": "CS-01",
        "start": "10:00:00",
        "end": "19:00:00",
        "half": "4.0",
        "full": "8.0",
        "grace": "15"
      },
    };

    String selectedShiftName = "General Shift";
    final codeCtrl = TextEditingController(text: shiftTemplates["General Shift"]!["code"]);
    final inCtrl = TextEditingController(text: shiftTemplates["General Shift"]!["start"]);
    final outCtrl = TextEditingController(text: shiftTemplates["General Shift"]!["end"]);
    final graceCtrl = TextEditingController(text: shiftTemplates["General Shift"]!["grace"]);
    final halfDayCtrl = TextEditingController(text: shiftTemplates["General Shift"]!["half"]);
    final fullDayCtrl = TextEditingController(text: shiftTemplates["General Shift"]!["full"]);

    final latCtrl = TextEditingController(text: "12.971600");
    final lonCtrl = TextEditingController(text: "77.594600");
    final radiusCtrl = TextEditingController(text: "100");

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: kBrandBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.more_time_rounded, color: kBrandBlue, size: 18),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Configure Work Shift & Geofence",
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: kDarkSlate, letterSpacing: 0.3),
                  ),
                  Text(
                    "Define operational duty schedules, grace rules & GPS radius",
                    style: TextStyle(fontSize: 9.5, color: kTextMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  _modalSectionHeader("1. SHIFT PRESET & IDENTIFIER"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: DropdownButtonFormField<String>(
                          value: selectedShiftName,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: kDarkSlate),
                          decoration: _modalInputDeco("SHIFT TYPE / NAME *"),
                          items: shiftTemplates.keys.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(s, style: const TextStyle(fontSize: 11.5)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                selectedShiftName = val;
                                final t = shiftTemplates[val]!;
                                codeCtrl.text = t["code"]!;
                                inCtrl.text = t["start"]!;
                                outCtrl.text = t["end"]!;
                                graceCtrl.text = t["grace"]!;
                                halfDayCtrl.text = t["half"]!;
                                fullDayCtrl.text = t["full"]!;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          controller: codeCtrl,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: kBrandBlue),
                          decoration: _modalInputDeco("SHIFT CODE *"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _modalSectionHeader("2. TIMINGS & ATTENDANCE THRESHOLDS"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: inCtrl,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          decoration: _modalInputDeco("START TIME (HH:MM:SS) *"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: outCtrl,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          decoration: _modalInputDeco("END TIME (HH:MM:SS) *"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: graceCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          decoration: _modalInputDeco("GRACE (MINUTES)"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: halfDayCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          decoration: _modalInputDeco("HALF-DAY MIN (HOURS)"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: fullDayCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          decoration: _modalInputDeco("FULL-DAY MIN (HOURS)"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _modalSectionHeader("3. OFFICE GEOFENCE GPS COORDINATES"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          controller: latCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 11.5),
                          decoration: _modalInputDeco("LATITUDE (e.g. 12.9716)"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          controller: lonCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 11.5),
                          decoration: _modalInputDeco("LONGITUDE (e.g. 77.5946)"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: radiusCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: kAccentGreen),
                          decoration: _modalInputDeco("RADIUS (METERS)"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("CANCEL", style: TextStyle(color: kTextMuted, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
              label: const Text("SAVE SHIFT & GEOFENCE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
              onPressed: () {
                if (codeCtrl.text.trim().isEmpty) return;

                // 🌟 Yahan direct captured `bloc` use hoga
                bloc.add(CreateShiftEvent({
                  'name': selectedShiftName,
                  'shift_code': codeCtrl.text.trim(),
                  'start_time': inCtrl.text.trim(),
                  'end_time': outCtrl.text.trim(),
                  'grace_period_minutes': int.tryParse(graceCtrl.text) ?? 15,
                  'half_day_minimum_hours': double.tryParse(halfDayCtrl.text) ?? 4.0,
                  'full_day_minimum_hours': double.tryParse(fullDayCtrl.text) ?? 8.0,
                  'office_latitude': double.tryParse(latCtrl.text),
                  'office_longitude': double.tryParse(lonCtrl.text),
                  'geofence_radius_meters': int.tryParse(radiusCtrl.text) ?? 100,
                  'is_active': true,
                }, date));

                Navigator.pop(dialogCtx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _modalSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w900,
        color: kBrandBlue,
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _modalInputDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kTextMuted),
      filled: true,
      fillColor: kCardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: kBrandBlue, width: 1.2),
      ),
    );
  }

  void _openCreateHolidayDialog(BuildContext context, String date) {
    // 🌟 Step 1: Parent valid context se BLoC nikal lein
    final AttendanceMasterBloc bloc = BlocProvider.of<AttendanceMasterBloc>(context);

    final List<Map<String, String>> holidayPresets = [
      {"name": "Republic Day", "type": "NATIONAL"},
      {"name": "Independence Day", "type": "NATIONAL"},
      {"name": "Gandhi Jayanti", "type": "NATIONAL"},
      {"name": "Diwali / Deepavali", "type": "FESTIVAL"},
      {"name": "Holi", "type": "FESTIVAL"},
      {"name": "Eid-ul-Fitr", "type": "FESTIVAL"},
      {"name": "Christmas Day", "type": "FESTIVAL"},
      {"name": "Makar Sankranti / Pongal", "type": "FESTIVAL"},
      {"name": "Ganesh Chaturthi", "type": "FESTIVAL"},
      {"name": "Dussehra / Vijaya Dashami", "type": "FESTIVAL"},
      {"name": "Annual Company Day", "type": "COMPANY_SPECIAL"},
      {"name": "Custom Holiday...", "type": "FESTIVAL"},
    ];

    String selectedPreset = "Republic Day";
    final nameCtrl = TextEditingController(text: "Republic Day");
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final descCtrl = TextEditingController();
    String holidayType = "NATIONAL";
    bool isOptional = false;
    bool isCustom = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (innerCtx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: kBrandBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.celebration_rounded, color: kBrandBlue, size: 18),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Add Company Holiday",
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: kDarkSlate, letterSpacing: 0.3),
                  ),
                  Text(
                    "Declare paid public, regional, or company-wide special off",
                    style: TextStyle(fontSize: 9.5, color: kTextMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  _modalSectionHeader("1. HOLIDAY PRESET & IDENTITY"),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedPreset,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: kDarkSlate),
                    decoration: _modalInputDeco("SELECT OCCASION PRESET *"),
                    items: holidayPresets.map((h) {
                      return DropdownMenuItem(
                        value: h["name"],
                        child: Text(h["name"]!, style: const TextStyle(fontSize: 11.5)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedPreset = val;
                          if (val == "Custom Holiday...") {
                            isCustom = true;
                            nameCtrl.clear();
                          } else {
                            isCustom = false;
                            nameCtrl.text = val;
                            final match = holidayPresets.firstWhere((element) => element["name"] == val);
                            holidayType = match["type"]!;
                          }
                        });
                      }
                    },
                  ),
                  if (isCustom) ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: nameCtrl,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                      decoration: _modalInputDeco("ENTER CUSTOM OCCASION NAME *"),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _modalSectionHeader("2. SCHEDULE & CLASSIFICATION"),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.tryParse(dateCtrl.text) ?? DateTime.now(),
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setState(() => dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked));
                            }
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9.5),
                            decoration: BoxDecoration(
                              color: kCardBg,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("DATE (YYYY-MM-DD)", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: kTextMuted)),
                                    const SizedBox(height: 2),
                                    Text(dateCtrl.text, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: kDarkSlate)),
                                  ],
                                ),
                                const Icon(Icons.calendar_month_outlined, size: 16, color: kBrandBlue),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 5,
                        child: DropdownButtonFormField<String>(
                          value: holidayType,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: kDarkSlate),
                          decoration: _modalInputDeco("HOLIDAY CATEGORY *"),
                          items: const [
                            DropdownMenuItem(value: "NATIONAL", child: Text("National Gazetted")),
                            DropdownMenuItem(value: "FESTIVAL", child: Text("Festival / Regional")),
                            DropdownMenuItem(value: "COMPANY_SPECIAL", child: Text("Company Special")),
                          ],
                          onChanged: (v) => setState(() => holidayType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _modalSectionHeader("3. REMARKS & RESTRICTIONS"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 11.5),
                    decoration: _modalInputDeco("DESCRIPTION / CIRCULAR NOTES (OPTIONAL)"),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: kBrandBlue,
                      title: const Text("Optional / Restricted Holiday (RH)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kDarkSlate)),
                      subtitle: const Text("Staff can choose from designated RH quota", style: TextStyle(fontSize: 9, color: kTextMuted)),
                      value: isOptional,
                      onChanged: (v) => setState(() => isOptional = v ?? false),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("CANCEL", style: TextStyle(color: kTextMuted, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
              label: const Text("SAVE HOLIDAY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;

                // 🌟 Captured `bloc` instance par sidha event dispatch karein
                bloc.add(CreateHolidayEvent({
                  'name': nameCtrl.text.trim(),
                  'date': dateCtrl.text.trim(),
                  'holiday_type': holidayType,
                  'description': descCtrl.text.trim(),
                  'is_optional': isOptional,
                }, date));

                Navigator.pop(dialogCtx);
              },
            ),
          ],
        ),
      ),
    );
  }

}
