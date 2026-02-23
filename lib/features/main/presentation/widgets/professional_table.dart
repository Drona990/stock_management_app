import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- 1. Model ---
class Employee {
  final String id;
  final String name;
  final String email;
  final String roleLevel; // Lead, Sr, Jr
  final String roleName;  // UI/UX Designer, etc.
  final String department;
  final String status; // Full-time, Freelance

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.roleLevel,
    required this.roleName,
    required this.department,
    required this.status,
  });
}

// --- 2. BLoC State & Events ---
abstract class EmployeeEvent {}
class LoadEmployees extends EmployeeEvent {}

abstract class EmployeeState {}
class EmployeeLoading extends EmployeeState {}
class EmployeeLoaded extends EmployeeState {
  final List<Employee> employees;
  EmployeeLoaded(this.employees);
}

// --- 3. BLoC Logic ---
class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  EmployeeBloc() : super(EmployeeLoading()) {
    on<LoadEmployees>((event, emit) async {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulating network
      emit(EmployeeLoaded([
        Employee(id: 'EMP120124', name: 'Hazel Nutt', email: 'hazelnutt@mail.com', roleLevel: 'Lead', roleName: 'UI/UX Designer', department: 'Team Projects', status: 'Full-time'),
        Employee(id: 'EMP120124', name: 'Simon Cyrene', email: 'simoncyr@mail.com', roleLevel: 'Sr', roleName: 'UI/UX Designer', department: 'Team Projects', status: 'Full-time'),
        Employee(id: 'EMP120124', name: 'Aida Bugg', email: 'aidabug@mail.com', roleLevel: 'Jr', roleName: 'Graphics Designer', department: 'Team Marketing', status: 'Freelance'),
        Employee(id: 'EMP120124', name: 'Peg Legge', email: 'peglegge@mail.com', roleLevel: 'Jr', roleName: 'Animator', department: 'Team Marketing', status: 'Full-time'),
      ]));
    });
  }
}

// --- 4. Main UI App ---



/*BlocProvider(
create: (context) => EmployeeBloc()..add(LoadEmployees()),
child: const EmployeeListScreen(),
),*/

class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopHeader(),
            const SizedBox(height: 20),
            _buildTableContainer(),
          ],
        ),
      ),
    );
  }

  // Top Section: Title, Search, Filters, Export
  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("List Employee", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1D2939))),
        Row(
          children: [
            _buildSearchBox(),
            const SizedBox(width: 8),
            _buildFilterButton("All Status"),
            const SizedBox(width: 8),
            _buildFilterButton("All Role"),
            const SizedBox(width: 8),
            _buildExportButton(),
          ],
        )
      ],
    );
  }

  Widget _buildSearchBox() {
    return Container(
      width: 220,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: "Search Employee",
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
          prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(bottom: 12),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF344054))),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Row(
        children: [
          Icon(Icons.file_download_outlined, size: 18, color: Color(0xFF344054)),
          SizedBox(width: 4),
          Text("Export", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Table Section
  Widget _buildTableContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: BlocBuilder<EmployeeBloc, EmployeeState>(
        builder: (context, state) {
          if (state is EmployeeLoading) return const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator()));
          if (state is EmployeeLoaded) return _buildDataTable(state.employees);
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildDataTable(List<Employee> data) {
    return DataTable(
      headingRowColor: MaterialStateProperty.all(const Color(0xFFF9FAFB)),
      columnSpacing: 24,
      horizontalMargin: 12,
      columns: const [
        DataColumn(label: Checkbox(value: false, onChanged: null, visualDensity: VisualDensity.compact)),
        DataColumn(label: Text('Employee ID', style: TextStyle(color: Color(0xFF667085), fontSize: 13))),
        DataColumn(label: Text('Employee name', style: TextStyle(color: Color(0xFF667085), fontSize: 13))),
        DataColumn(label: Text('Email', style: TextStyle(color: Color(0xFF667085), fontSize: 13))),
        DataColumn(label: Text('Role', style: TextStyle(color: Color(0xFF667085), fontSize: 13))),
        DataColumn(label: Text('Departments', style: TextStyle(color: Color(0xFF667085), fontSize: 13))),
        DataColumn(label: Text('Status', style: TextStyle(color: Color(0xFF667085), fontSize: 13))),
        DataColumn(label: Text('Action', style: TextStyle(color: Color(0xFF667085), fontSize: 13))),
      ],
      rows: data.map((emp) => DataRow(cells: [
        DataCell(Checkbox(value: false, onChanged: (v) {}, visualDensity: VisualDensity.compact)),
        DataCell(Text(emp.id, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1D2939)))),
        DataCell(Row(children: [
          const CircleAvatar(radius: 14, backgroundImage: NetworkImage('https://via.placeholder.com/150')),
          const SizedBox(width: 10),
          Text(emp.name, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1D2939))),
        ])),
        DataCell(Text(emp.email, style: const TextStyle(color: Color(0xFF667085)))),
        DataCell(RichText(
          text: TextSpan(
            children: [
              TextSpan(text: "${emp.roleLevel} ", style: const TextStyle(color: Color(0xFF98A2B3), fontSize: 12)),
              TextSpan(text: emp.roleName, style: const TextStyle(color: Color(0xFF344054), fontWeight: FontWeight.w500, fontSize: 13)),
            ],
          ),
        )),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(emp.department, style: const TextStyle(fontSize: 12, color: Color(0xFF344054))),
        )),
        DataCell(_buildStatusChip(emp.status)),
        DataCell(Row(
          children: [
            Icon(Icons.visibility_outlined, size: 20, color: Colors.grey.shade400),
            const SizedBox(width: 8),
            Icon(Icons.more_vert, size: 20, color: Colors.grey.shade400),
          ],
        )),
      ])).toList(),
    );
  }

  Widget _buildStatusChip(String status) {
    bool isFullTime = status == "Full-time";
    Color themeColor = isFullTime ? const Color(0xFF039855) : const Color(0xFFF79009);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 6, color: themeColor),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(color: themeColor, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}